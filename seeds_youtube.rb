require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
DB = Sequel.sqlite(database: 'youtube.db')

subtitles = DB[:subtitles]
n = 'titles_with_speaker_with_link.txt'
binding.pry
file = File.read(n)

title_youtube_pairs = 
  file.split("\n")
      .lazy
      .select { |x| x != '' }
      .map { |x| x.split("\t-->\t").first }
      .each_slice(2)

title_youtube_pairs.each do |x|
  t = x.first
  l = x.last
  subtitle = {
    title: t,
    ready: false,
    text: nil,
    link: l,
  }
  subtitle[:youtube_id] = l.gsub(/.*watch\?v=/, '')
  subtitles.insert(subtitle)
end
puts 'Exit'