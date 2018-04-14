require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require_relative 'gamer'
# Scheme
#
#  primary_key :id
#  string :speaker
#  string :title
#  string :answer
#  integer :year
#  string :left
#  string :right


gamer = Gamer.new('***', '***')
gamer.sign_in

gamer.start_play

gamer.play_one_game

binding.pry

puts 'Total count = ' + gamer.tasks.count
puts 'Exit'
