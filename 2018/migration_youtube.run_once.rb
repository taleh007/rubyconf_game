require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

DB = Sequel.sqlite(database: 'youtube.db') # memory database, requires sqlite3

DB.create_table :subtitles do
  primary_key :id
  String :title
  String :youtube_id
  String :text
  String :link
  Boolean :ready
end
