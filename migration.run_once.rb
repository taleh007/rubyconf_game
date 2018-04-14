require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

DB = Sequel.sqlite(database: 'watir.db') # memory database, requires sqlite3

DB.create_table :tasks do
  primary_key :id
  String :speaker
  String :title
  String :answer
  Integer :year
  String :left
  String :right
end
