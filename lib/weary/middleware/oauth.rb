require 'weary/middleware'
require 'simple_oauth'

SimpleOAuth::Header::ATTRIBUTE_KEYS << :verifier

module Weary
  module Middleware
    class OAuth
      AUTH_HEADER = "HTTP_AUTHORIZATION"

      def initialize(app, oauth_options)
        @app = app
        @oauth = oauth_options
      end

      def call(env)
        env.update AUTH_HEADER => sign(env).to_s
        @app.call(env)
      end

      def sign(env)
        req = Rack::Request.new(env)
        post_body = req.body.read
        req.body.rewind
        SimpleOAuth::Header.new req.request_method,
                                req.url,
                                request_body_to_hash(post_body),
                                @oauth
      end

      # Stolen from Rack::Utils
      def request_body_to_hash(qs, d = nil)
        params = Rack::Utils::KeySpaceConstrainedParams.new
        default_sep = /[&;] */n

        (qs || '').split(d ? /[#{d}] */n : default_sep).each do |p|
          k, v = p.split('=', 2).map { |s| Rack::Utils.unescape(s, defined?(::Encoding) ? Encoding::BINARY : nil) }

          Rack::Utils.normalize_params(params, k, v)
        end

        return params.to_params_hash
      end
    end
  end
end