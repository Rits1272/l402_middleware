require 'net/http'
require 'json'
require 'base64'
require 'uri'

class L402Tester
  def initialize(base_url, node_alice, node_bob)
    @base_url = base_url
    @node_alice = node_alice
    @node_bob = node_bob
    @macaroon = nil
    @preimage = nil
  end

  def run_tests
    puts "Starting L402 Authentication Tests..."
    
    # Test 1: Verify L402 challenge headers
    response = make_initial_request
    unless verify_l402_challenge_headers(response)
      puts "❌ Test 1 Failed: Invalid L402 challenge headers"
      return
    end
    puts "✅ Test 1 Passed: L402 challenge headers verified"

    # Parse L402 headers
    auth_header = response['WWW-Authenticate']
    @macaroon = extract_macaroon(auth_header)
    invoice = extract_invoice(auth_header)
    
    puts "📝 Extracted Invoice: #{invoice}"
    puts "🔑 Extracted Macaroon: #{@macaroon}"

    # Test 2: Pay the invoice and verify preimage
    @preimage = pay_invoice(invoice)
    puts "Preimage: #{@preimage}"
    unless @preimage && valid_preimage?(@preimage)
      puts "❌ Test 2 Failed: Invalid payment preimage"
      return
    end
    puts "✅ Test 2 Passed: Payment preimage verified"

    # Test 3: Verify authenticated request headers
    response = make_authenticated_request
    unless verify_authenticated_headers(response)
      puts "❌ Test 3 Failed: Invalid authenticated response headers"
      return
    end
    puts "✅ Test 3 Passed: Authenticated headers verified"
    
    puts "🎉 All tests passed successfully!"
  end

  private

  def make_initial_request
    uri = URI.parse("#{@base_url}/protected-endpoint")
    Net::HTTP.get_response(uri)
  end

  def make_authenticated_request
    uri = URI.parse("#{@base_url}/protected-endpoint")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "L402 #{@preimage}"
    request['WWW-Authenticate'] = "L402 macaroon=\"#{@macaroon}\""
    
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  end

  def verify_l402_challenge_headers(response)
    # Check status code
    return false unless response.code == "402"

    # Verify WWW-Authenticate header exists and starts with L402
    auth_header = response['WWW-Authenticate']
    return false unless auth_header && auth_header.start_with?('l402')

    # Verify required L402 components are present
    macaroon = extract_macaroon(auth_header)
    invoice = extract_invoice(auth_header)
    puts("macaroon: #{macaroon}\ninvoice: #{invoice}")
    return false unless macaroon && invoice

    # Verify macaroon is valid base64
    begin
      Base64.strict_decode64(macaroon)
    rescue ArgumentError
      return false
    end

    # Verify invoice is valid BOLT11 format (starts with 'lnbc' or 'lntb')
    return false unless invoice.match?(/^(lnbc|lntb)/)

    true
  end

  def verify_authenticated_headers(response)
    # For successful authentication
    return false unless response.code == "200"

    # Check for any required response headers after successful authentication
    required_headers = ['Content-Type']
    required_headers.all? { |header| response[header] }
  end

  def extract_macaroon(header)
    puts("HEADER: #{header}")
    match = header.match(/macaroon=([^,]+)/)
    match ? match[1] : nil
  end

  def extract_invoice(header)
    match = header.match(/invoice=([^,]+)/)
    match ? match[1] : nil
  end

  def pay_invoice(invoice)
    decode_invoice(invoice)
    command = "docker exec #{@node_bob} lncli -n regtest payinvoice --force #{invoice}"
    result = `#{command}`
    
    begin
      payment_result = JSON.parse(result)
      payment_result['payment_preimage']
    rescue JSON::ParserError
      nil
    end
  end

  def valid_preimage?(preimage)
    # Verify preimage is 32 bytes (64 hex characters)
    return false unless preimage.match?(/^[0-9a-f]{64}$/i)
    true
  end

  def decode_invoice(invoice)
    command = "docker exec #{@node_alice} lncli -n regtest decodepayreq #{invoice}"
    result = `#{command}`
    puts("DECODED INVOICE INFO:\n#{result}")
    
    begin
      JSON.parse(result)
    rescue JSON::ParserError
      nil
    end
  end

  def get_pubkey(node)
    macaroon_path = "/root/.lnd/data/chain/bitcoin/regtest/admin.macaroon"
    command = "docker exec #{node} lncli --macaroonpath #{macaroon_path} -n regtest getinfo"
    result = `#{command}`
    JSON.parse(result)['identity_pubkey']
  end
end

## Example usage:
# **IMPORTANT: Before running the tests, make sure to run `docker-compose up` to bring up the necessary containers.**
# This will start Alice, Bob, and Bitcoin Core nodes in Docker. If the containers are not running, the tests will fail.
#
# Configuration to specify the base URL and node names for Alice and Bob.
config = {
  base_url: 'http://localhost:3000',  # Your Rails app URL
  node_alice: 'lndnode-alice',        # Server node container name
  node_bob: 'lndnode-bob'            # Client node container name
}

# Run tests
begin
  tester = L402Tester.new(config[:base_url], config[:node_alice], config[:node_bob])
  tester.run_tests
rescue StandardError => e
  puts "❌ Test failed with error: #{e.message}"
  puts e.backtrace
end
