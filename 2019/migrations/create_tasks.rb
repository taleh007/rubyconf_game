require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

DB = Sequel.sqlite(database: 'db/main.db') # memory database, requires sqlite3

DB.create_table :tasks do
  primary_key :id
  String :title
  String :answer
  String :our
  String :left
  String :right
  Integer :session_id
  Datetime :timestamp
end
