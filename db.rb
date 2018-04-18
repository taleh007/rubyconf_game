require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require_relative 'mega_db'

DB_WATIR = Sequel.sqlite(database: 'watir.db')
DB_YOUTUBE = Sequel.sqlite(database: 'youtube.db')
DB_ERRORS = Sequel.sqlite(database: 'errors.db')

_mega = MegaDB.new
_e = DB_ERRORS[:errors]
_t = DB_WATIR[:tasks]

def save_titles_in_file(name)
  tasks = DB_WATIR[:tasks]
  File.open(name, 'w+') do |f|
    tasks.map(:title).uniq.sort.each do |t|
      f.write t + "\n"
    end
  end
end

def tis(s,t,y,r,l,a)
  tasks = DB_WATIR[:tasks]
  tasks.insert({speaker: s, title: t, year: y, right: r, left: l, answer: a})
  tasks.insert({speaker: s, title: t, year: y, left: r, right: l, answer: a})
end

def save_titles_with_speaker_in_file(name)
  tasks = DB_WATIR[:tasks]
  File.open(name, 'w+') do |f|
    tasks.map([:title, :speaker]).uniq.sort.each do |t|
      f.write t.join("\t-->\t") + "\n"
    end
  end
end

def title_errors_arr
  errors = DB_ERRORS[:errors]
  errors.map(:title).each_with_object({}){|v, h| h[v]||=0; h[v]+=1}.sort_by{|x| -x.last}
end

def title_tasks_arr
  tasks = DB_WATIR[:tasks]
  tasks.map(:title).each_with_object({}){|v, h| h[v]||=0; h[v]+=1}.sort_by{|x| -x.last}
end

def win_rate2
  tasks = DB_WATIR[:tasks]
  th = tasks.map(:title).each_with_object({}){|v, h| h[v]||=0; h[v]+=1}
  errors = DB_ERRORS[:errors]
  eh = errors.map(:title).each_with_object({}){|v, h| h[v]||=0; h[v]+=1}
  th.each_with_object([]) do |(k, v), h|
    h << [k, (v - (eh[k]||0)).to_f / (v), v, eh[k]]
  end
end

def win_rate
  tasks = DB_WATIR[:tasks]
  th = tasks.map(:title).each_with_object({}){|v, h| h[v]||=0; h[v]+=1}
  errors = DB_ERRORS[:errors]
  eh = errors.map(:title).each_with_object({}){|v, h| h[v]||=0; h[v]+=1}
  th.each_with_object([]) do |(k, v), h|
    h << [k, (v - (eh[k]||0)).to_f / (v), v]
  end
end

binding.pry

puts "Exit"
# '
# SELECT t1.*
# FROM tasks as t1, tasks AS t2
# WHERE t1.title = t2.title
#   AND t1.answer <> t2.answer
#   AND t1.year <> t2.year
#   AND t1.speaker <> t2.speaker
#   AND (
#     (t1.left = t2.left AND t1.right = t2.right)
#     OR
#     (t1.left = t2.right AND t1.right = t2.left)
#   )
# '
