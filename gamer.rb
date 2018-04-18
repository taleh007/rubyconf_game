require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require_relative 'mega_db'
require 'rgl/adjacency'
require 'rgl/transitivity'

class Gamer
  TIME_FOR_LOADING = 1.3
  COPY_COUNTER = ->(key, hash) do
    hash[key] ||= 0
    hash[key] += 1
  end

  attr_reader :browser, :tasks, :db

  class << self
    def mega
      @@mega_db
    end
  end

  def initialize(login, password)
    @login = login
    @password = password
    @browser = Watir::Browser.new :chrome
    @db_conection = Sequel.sqlite(database: 'watir.db')
    @logger_connection = Sequel.sqlite(database: 'errors.db')
    @errors = @logger_connection[:errors]
    @tasks = @db_conection[:tasks]
    @@mega_db = MegaDB.new
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
    scope = @tasks.where(title: title, speaker: speaker, year: year)
    graph = RGL::DirectedAdjacencyGraph[*graph_params(scope)].transitive_closure

    if (one_scope = scope.where(left: left, right: right)).count.positive? || (one_scope = scope.where(left: right, right: left)).count.positive?
      answer = one_scope.all.last[:answer]
      puts "From gamer info --> already have that task"
    elsif (is_left = graph.has_edge?(left, right)) || (is_right = graph.has_edge?(right, left))
      answer = left if is_left
      answer = right if is_right
      puts "From gamer info --> GRAPH choose answer"
    elsif (answer = @@mega_db.compare(title, left, right))
      puts "From gamer info --> mega_db choose answer"
    elsif (answer = scope.map(:answer).include?(left) ? left : nil)
      puts "From gamer info --> left variant exist in answers"
    elsif (answer = scope.map(:answer).include?(right) ? right : nil)
      puts "From gamer info --> right variant exist in answers"
    end

    if answer
      if right == answer.strip.downcase
        right_btn.click()
      else
        left_btn.click()
      end
    else
      rand(0..1) > 0 ? left_btn.click() : right_btn.click()
      puts "From gamer info --> NEW TITLE MOTHERFUCKER"
    end

    sleep(1.5)

    task[:title]   = title
    task[:speaker] = speaker
    task[:year]    = year
    task[:left]    = left
    task[:right]   = right
    if answer_button.present?
      task[:answer]  = answer_button.text
      task_id = @tasks.insert(task)
      if answer == task[:answer]
        puts "From gamer info --> we WIN"
      else
        puts "From gamer info --> we LOSE"
        @errors.insert({
          title: title,
          speaker: speaker,
          our: answer,
          their: answer_button.text,
          task_id: task_id
        })
      end
      puts "From gamer info --> task saved"
      puts "From gamer info --> id:    #{task_id}\n" +
           "                    our:   #{answer}\n" +
           "                    their: #{task[:answer]}"
    else
      puts "From gamer info --> no answer for saving"
    end

    puts "From gamer info --> tasks count is #{@tasks.count}\n\n"
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

  def win_rate_more_than(e)
    th = @tasks.map(:title).each_with_object({}, &COPY_COUNTER)
    eh = @errors.map(:title).each_with_object({}, &COPY_COUNTER)
    th.each_with_object([]) do |(k, v), h|
      h << [k, (v - (eh[k]||0)).to_f / (v), v, eh[k]]
    end.sort_by{ |x| -x[1] }.select{ |x| (x[1] || 0) > e }.map { |x| x.first }
  end

  def errors_less_than(e)
    th = @tasks.map(:title).each_with_object({}, &COPY_COUNTER)
    eh = @errors.map(:title).each_with_object({}, &COPY_COUNTER)
    th.each_with_object([]) do |(k, v), h|
      h << [k, (v - (eh[k]||0)).to_f / (v), v, eh[k]]
    end.sort_by{ |x| -x[1] }.select{ |x| (x[-1] || 0) < e }.map { |x| x.first }
  end

  def graph_params(scope)
    scope.order(Sequel.desc(:id))
         .select(:answer, :left, :right)
         .map([:answer, :left, :right])
         .lazy
         .map { |x| a = x.shift; x.sort.unshift(a) }
         .map(&:uniq)
         .uniq{ |x| x.sort }
         .flat_map(&:itself)
         .force
  end
end
