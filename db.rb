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

binding.pry

puts "Exit"