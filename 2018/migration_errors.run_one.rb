require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

DB = Sequel.sqlite(database: 'errors.db') # memory database, requires sqlite3

DB.create_table :errors do
  primary_key :id
  Integer :task_id
  String :title
  String :speaker
  String :our
  String :their
end
