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

begin
  gamer = Gamer.new('****', '****')
  gamer.sign_in
  binding.pry

  gamer.start_play

  gamer.playing!
  puts "Finish"

  binding.pry

  puts 'Total count = ' + gamer.tasks.count
  puts 'Exit'
rescue Exception => e
  puts "Error"
  binding.pry
  puts 'Exit'
end

trap "SIGINT" do
  binding.pry
  puts 'Exit'
end
