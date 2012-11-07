require "rubycas-strategy-token/version"
require "sequel"
require "addressable/uri"

module CASServer
  module Strategy
    module Token
      class Worker
        def initialize(config)
          raise "Expecting config" unless config.is_a?(::Hash)

          @config = config
          @connection = Sequel.connect(config['database'])
          @dataset = @connection.from config['user_table']
        end

        def match(token)
          return false if token.nil? || token.empty? # this should never happen, but what the hell, we're talking about authentication here
          matcher = @dataset.where(@config['token_column'].to_sym => token)
          matcher = matcher.filter("`#{@config['expire_column']}` >= ?", DateTime.now) if @config['expire_column']
          raise "Multiple matches, database tainted" if matcher.count > 1
          match = matcher.first
          matcher.update(@config['token_column'].to_sym => nil)
          match
        end
      end

      def self.registered(app)
        settings = app.workhorse

        app.set :token_worker, Worker.new(settings)

        app.get "#{app.uri_path}/auth/token/:token" do
          if match = app.settings.token_worker.match(params[:token])
            establish_session! match[:email], session["service"]
          end

          # Redirect to login page if we're still here. Preserve service and renew data
          redirector = Addressable::URI.new
          redirector.query_values = {
              :service => session[:service],
              :renew => session[:renew]
          }.delete_if{|_,v| v.nil? || v.empty?}
          redirector.path = "#{app.uri_path}/login"
          redirect to(redirector.to_s), 303
        end
      end
    end
  end
end
