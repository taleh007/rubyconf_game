require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
DB = Sequel.sqlite(database: 'youtube.db')

subtitles = DB[:subtitles]
browser = Watir::Browser.new :chrome
binding.pry

subtitles.where(ready: false).each do |s|
  puts 'Parsing:      ->     ' + s[:title]
  link = "http://diycaptions.com/php/get-automatic-captions-as-txt.php?id=#{s[:youtube_id]}"
  browser.goto link
  puts 'Open link:    ->     ' + link
  text = browser.element(class: 'well').text.split("\n\n").last
  if text.size > 10 && !text.include?('to obtain automatic captions for the video')
    puts 'Ready:      ->     ' + s[:id].to_s
    subtitles.where(id: s[:id]).update(text: text, ready: true)
  else
    puts 'Not parsed: ->     ' + s[:id].to_s
  end
end

puts 'exit'