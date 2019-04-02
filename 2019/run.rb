require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
DB = Sequel.sqlite(database: 'db/main.db', max_connections: 10, logger: Logger.new('log/db.log'))

class Task < Struct.new(:id, :title, :answer, :our, :left, :right, :timestamp, :session_id)
  @@connection = DB.from(:tasks)

  class << self
    def db
      @@connection
    end
  end

  def initialize(data)
    self.id = data[:id]
    self.title = data[:title]
    self.answer = data[:answer]
    self.our = data[:our]
    self.left = data[:left]
    self.right = data[:right]
    self.timestamp = data[:timestamp]
    self.session_id = data[:session_id]
  end

  def save
    params = to_h
    if id.nil?
      self.id = @@connection.insert(params)
    else
      @@connection.where(id: params.delete(:id)).update(params)
      reload
    end

    self
  end

  def reload
    data = @@connection.where(id: id).first
    self.id = data[:id]
    self.title = data[:title]
    self.answer = data[:answer]
    self.our = data[:our]
    self.left = data[:left]
    self.right = data[:right]
    self.timestamp = data[:timestamp]
    self.session_id = data[:session_id]

    self
  end
end

module RubyConfHTMLHelper
  TIME_FOR_LOADING = 1

  def start_button
    browser.element(class: 'welcome-button')
  end

  def left_button
    browser.element(class: 'guess__actions-merged')
  end

  def right_button
    browser.element(class: 'guess__actions-rejected')
  end

  def next_button
    browser.element(class: 'guess__result')
  end

  def try_again_button
    browser.element(class: 'game-finish-link')
  end

  def answer_button
    browser.element(class: 'answer__actions').button
  end

  def current_level
    browser.element(class: 'score__budge--level').text.tr('Level ', '').to_i
  end

  def current_score
    browser.element(class: 'score__budge--score').text.tr('Score ', '').to_i
  end

  def current_session_id
    browser.element(id: 'game').attributes[:data_game_session_id].to_i
  end

  def current_title
    browser.element(class: 'question').text
  end

  def random_button
    return unless [left_button, right_button].all?(&:exist?)

    rand(0..1) == 0 ? left_button : right_button
  end

  def pause
    sleep(TIME_FOR_LOADING)
  end
end

class RubyConfBot
  GAME_PORTAL = 'https://play.minskrb.community'.freeze
  GITHUB_AUTH_PATH = '/users/auth/github'.freeze
  GAME_PATH = '/game'.freeze

  include RubyConfHTMLHelper

  attr_reader :browser

  def initialize(login, password, db = nil, logfile = nil)
    @browser = Watir::Browser.new(:chrome)

    login(login, password)
  end

  def start(number_of_actions = nil)
    enumerator = number_of_actions.nil? ? loop : number_of_actions.times

    enumerator.each do
      return if try_again_button.exist?

      action

      pause
    end
  end

  def action
    start_button.click if start_button.exist?
    next_button.click if next_button.exist?
    try_again_button.click if try_again_button.exist?

    if [left_button, right_button].all?(&:exist?)
      resolve_answer
    end
  end

  private

  def resolve_answer
    task = Task.new(
      title: current_title.strip,
      left: left_button.text.strip,
      right: right_button.text.strip,
      timestamp: Time.now,
      session_id: current_session_id
    )

    task.save

    btn = if current_level < 3
      random_button
    else
      btn = left_button
    end

    task.our = btn.text
    btn.click
    task.save
    while !answer_button.exist? && !try_again_button.exist?
      sleep(0.1)
    end

    return if try_again_button.exist?

    task.answer = answer_button.text.strip
    puts task.to_h
    task.save
  end

  def login(login, password)
    browser.goto([GAME_PORTAL, GITHUB_AUTH_PATH].join)
    browser.text_field(id: 'login_field').set(login)
    browser.text_field(id: 'password').set(password)
    browser.input(type: 'submit').click
  end
end

config = YAML.load_file('config/secrets.yml')

login = config['credentials']['github']['login']
password = config['credentials']['github']['password']

bot = RubyConfBot.new(login, password)
