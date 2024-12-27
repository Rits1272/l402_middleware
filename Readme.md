# L402 Middleware for Rails

#### [WIP] The middleware is still in active development

**L402 Middleware** is a Ruby gem designed to seamlessly integrate with your Rails application, enabling [L402](https://docs.lightning.engineering/the-lightning-network/l402) protocol functionality as a middleware. Whether you are building microservices, APIs, or payment gateways, this gem helps you implement authenticated, pay-per-request APIs using the L402 standard effortlessly.

---

## 🚀 Features

- **Plug-and-Play**: Integrate with your Rails application by adding a single line of configuration.
- **Lightning Network Integration**: Enforces payment and authentication standards based on L402.
- **Configurable**: Fine-tune how the middleware processes requests and manages payments.
- **Lightweight**: Minimal dependencies, optimized for performance.

---

## 🛠️ Installation

Add this gem to your application's `Gemfile`:

```ruby
gem 'l402_middleware'
```

Then, install it using:
```
bundle install
```

---

## Configuration

Initialize the middleware in your Rails app:

1. Add it to the middleware stack in your `application.rb`:
```
# config/application.rb
config.middleware.use L402Middleware, config.l402_middleware 
```

2. Define your configuration options. Here's an example:
```ruby
config.l402_middleware = {
  network_type: :lnd,
  root_key: 'your_root_key',
  caveats: [],
  lnd: {
    address: '<lnd-node-address>'
    tls_certificate_path: '<tls-cert-path>'
    macaroon_path: '<macaroon_path>'
  },
  invoice: {
    millisatoshis: 100,
    description: 'Payment required to access the API',
    payable: 'once',  # or, `indefinitely`
  },
  endpoints: ['/protected'] # endpoints on which to enable l402 paywall
}
```

---

📖 Usage
Once the middleware is configured, it will:

Inspect incoming HTTP headers for an L402-compliant payment token.
Validate the token with the configured token_validator.
Reject requests that don't meet the payment threshold with a 402 Payment Required status.

#### Example Request Flow:

1. Client sends a request:

```
GET /protected-resource HTTP/1.1
Host: example.com
Authorization: L402 <token>
```

2. Middleware validates the request and processes payment.

3. Rails App continues processing the request if the payment is successful.

---

🔧 Development

Clone the repository:
```bash
git clone https://github.com/rits1272/l402_middleware.git
cd l402_middleware
```

Run tests:
```
bundle exec rspec
```

---

📫 **Contact**

If you have any questions, feedback, or need support, feel free to reach out:

- **Email**: ritikjain1272@gmail.com
- **LinkedIn**: [Ritik Jain](https://linkedin.com/in/rits1272)

With this gem, you can bring the power of the Lightning Network to your Rails apps in minutes. Happy coding! ⚡
