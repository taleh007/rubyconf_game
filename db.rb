require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
DB_WATIR = Sequel.sqlite(database: 'watir.db')
DB_YOUTUBE = Sequel.sqlite(database: 'youtube.db')

def save_titles_in_file(name)
  tasks = DB_WATIR[:tasks]
  File.open(name, 'w+') do |f|
    tasks.map(:title).uniq.sort.each do |t|
      f.write t + "\n"
    end
  end
end

def save_titles_with_speaker_in_file(name)
  tasks = DB_WATIR[:tasks]
  File.open(name, 'w+') do |f|
    tasks.map([:title, :speaker]).uniq.sort.each do |t|
      f.write t.join("\t-->\t") + "\n"
    end
  end
end

binding.pry

put "Exit"