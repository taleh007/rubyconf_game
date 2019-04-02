require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

class RubyConfBot
  GAME_PORTAL = 'https://play.minskrb.community'.freeze
  GITHUB_AUTH_PATH = '/users/auth/github'.freeze
  GAME_PATH = '/users/auth/github'.freeze

  attr_reader :browser

  def initialize(login, password, db = nil, logfile = nil)
    @browser = Watir::Browser.new(:chrome)

    login(login, password)
  end

  private

  def login(login, password)
    browser.goto([GAME_PORTAL, GITHUB_AUTH_PATH].join)
    browser.text_field(:id, 'login_field').set(login)
    browser.text_field(:id, 'password').set(password)
    browser.input(type: 'submit').click
  end
end

config = YAML.load_file('config/secrets.yml')

login = config['credentials']['github']['login']
password = config['credentials']['github']['password']

bot = RubyConfBot.new(login, password)
