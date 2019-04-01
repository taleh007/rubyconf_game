require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require_relative 'gamer'

class Hacker < Gamer
  JS_HACK = <<~JS
    var e = document.getElementById('game').getAttribute('data-game-session-id') * 1;
    App.global_game.perform('next_guess', { game_session_id: e });
  JS
  MIN_WIN_RATE = 0.96
  MAX_ERRORS = 12

  def playing!
    play

    while next_btn.present? || try_again_btn.present? || answer_button.present? || left_btn.present?
      next_btn.click() if next_btn.present?
      try_again_btn.click() if try_again_btn.present?
      pause
      play
      pause
    end
  end

  def play
    win_arr = errors_less_than(MAX_ERRORS)
    task = {}
    title = title_header.text.strip.downcase
    unless win_arr.include?(title)
      browser.execute_script(JS_HACK)
      return
    end

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
    else
      if win_rate_more_than(MIN_WIN_RATE).include?(title) && (answer = @@mega_db.compare(title, left, right))
        puts "From gamer info --> mega_db choose answer"
      else
        browser.execute_script(JS_HACK)
        return
      end
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
end
