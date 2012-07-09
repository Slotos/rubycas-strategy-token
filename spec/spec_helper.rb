require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'rspec'

# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def config
  @config ||= YAML.load_file( File.expand_path(File.dirname(__FILE__) + '/example_config.yml') )
end

def init_db!
  @database = config["strategies"]["database"]
  db = Sequel.connect(@database)
  db.create_table :users do
    primary_key :id
    String :email, :unique => true
    String :access_token
    DateTime :access_token_expires
  end
  db.disconnect
end

def add_user(email, *args)
  options = args.last.is_a?(Hash) ? args.pop : {}
  db = Sequel.connect(@database)

  token = "this_is_secret_token"
  db[:users].truncate
  id = db[:users].insert(
    :email => email,
    :access_token_expires => (options[:expired] ? DateTime.now - 1 : DateTime.now + 1),
    :access_token => token
  )

  db.disconnect
  {:token => token, :id => id}
end

def user_by_token(token)
  db = Sequel.connect(@database)

  user = db[:users].where(:access_token => token).all
  db.disconnect
  user
end

def user_by_id(id)
  db = Sequel.connect(@database)

  user = db[:users][:id => id]
  db.disconnect
  user
end

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.after :all do
    FileUtils.rm_f(config["strategies"]["database"]["database"])
  end
  conf.before :all do
    init_db!
  end
end

class CASServer::Mock < Sinatra::Base
  enable :sessions
  set :config, config

  def self.uri_path
    ""
  end

  def self.add_oauth_link(link)
    @oauth_link = link
  end

  set :workhorse, config["strategies"]
  require File.expand_path(File.dirname(File.dirname(__FILE__)) + '/lib/rubycas-strategy-token')
  register CASServer::Strategy::Token
end

def app
  CASServer::Mock
end
