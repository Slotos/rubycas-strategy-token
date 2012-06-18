require "rubycas-token-matcher/version"
require "sequel"
require "addressable/uri"

module CASServer
  module Matchers
    module Token
      class Worker
        def initialize(config)
          raise "Expecting config" unless config.is_a?(::Hash)

          @config = config
          @connection = Sequel.connect(config['database'])
          @dataset = @connection.from config['user_table']
        end

        def match(token)
          matcher = @dataset.where(@config['token_column'].to_sym => token)
          matcher = matcher.filter("`#{@config['expire_column']}` >= ?", DateTime.now) if config['expire_column']
          raise "Multiple matches, database tainted" if matcher.count > 1
          match = matcher.first
          matcher.delete
          match
        end
      end

      def self.registered(app)
        settings = app.config["matcher"]["token"]

        app.set :token_matcher, Worker.new(settings)

        app.get "#{app.uri_path}/auth/token/:token" do
          if match = app.settings.token_matcher.match(params[:token])
            confirm_authentication! match[:email], session["service"]
          end

          # Redirect to login page if we're still here. Preserve service and renew data
          redirect_params = []
          redirect_params << "service=#{CGI.escape session[:service]}" if session[:service]
          redirect_params << "renew=#{session[:renew]}" if session[:renew]
          redirect to("#{app.uri_path}/login?#{redirect_params.join('&')}"), 303
        end
      end
    end
  end
end
