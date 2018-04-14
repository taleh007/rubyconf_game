require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

class Gamer
  TIME_FOR_LOADING = 1.5

  attr_reader :browser, :tasks, :db

  def initialize(login, password)
    @login = login
    @password = password
    @browser = Watir::Browser.new :chrome
    @db = Sequel.sqlite(database: 'watir.db')
    @tasks = @db[:tasks]
  end

  def sign_in
    browser.goto 'https://play.rubyconference.by/users/auth/github'
    browser.text_field(:id, 'login_field').set(@login)
    browser.text_field(:id, 'password').set(@password)
    browser.input(type: 'submit').click
    @login = nil
    @password = nil
    sleep(5)
  end

  def start_play
    browser.element(class: 'welcome-button').click
    pause
  end

  def play_one_game
    play

    while next_btn.present?
      next_btn.click()
      pause
      play
    end
  end

  def playing!
    play

    while next_btn.present? || try_again_btn.present?
      next_btn.click() if next_btn.present?
      try_again_btn.click() if try_again_btn.present?
      pause
      play
    end
  end

  def play
    task = {}
    title = title_header.text.strip.downcase
    left = left_btn.text.strip.downcase
    right = right_btn.text.strip.downcase
    speaker, year =
      comment_body.text.split("\n").each do |x|
        x.slice!(/(When: )|(Speaker: )/)
      end

    if (scope = @tasks.where(title: title)).count.positive?
      answer =
        if scope.count == 1
          scope.first[:answer]
        else
          if (one_scope = scope.where(left: left, right: right).or(left: right, right: left)).count.positive?
            one_scope.first[:answer]
          else
            scope.map(:answer).include?(left) ? left : right
          end
        end
      if right == answer.strip.downcase
        right_btn.click()
      else
        left_btn.click()
      end
    else
      case rand(0..1)
      when 0
        right_btn.click()
      when 1
        left_btn.click()
      end
    end
    pause

    task[:title]   = title
    task[:speaker] = speaker
    task[:year]    = year
    task[:left]    = left
    task[:right]   = right
    if answer_button.present?
      task[:answer]  = answer_button.text
      @tasks.insert(task)
    end

    puts "From gamer info --> tasks count is #{@tasks.count}"
    pause
  end

  private

  def title_header
    browser.element(class: 'pull-request-title')
  end

  def right_btn
    browser.element(class: 'guess__actions-rejected')
  end

  def left_btn
    browser.element(class: 'guess__actions-merged')
  end

  def comment_body
    browser.element(class: 'pull-request-comment-body')
  end

  def answer_button
    browser.element(class: 'answer__actions').button
  end

  def next_btn
    browser.element(class: 'guess__result').button
  end

  def try_again_btn
    browser.element(class: 'game-finish-link')
  end

  def pause
    sleep(TIME_FOR_LOADING)
  end
end
