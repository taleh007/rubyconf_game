require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

DB = Sequel.sqlite(database: 'db/main.db', max_connections: 10, logger: Logger.new('log/db.log'))

gem_names = DB[:tasks].all.flat_map { |r| [r[:left], r[:right]] }.uniq.sort

Dir.chdir('./gemdata') do
  dirs = Dir.entries('.').each_with_object({}) do |name, memo|
    memo[name] = true unless name =~ %r/\.gem$/
  end

  gem_names.each do |gem_name|
    if dirs[gem_name]
      puts "GEM '#{gem_name}' already exist'"
      next
    end

    system("gem fetch -q #{gem_name}")

    gem_file = Dir.entries('.').select {|x| x =~ /^#{gem_name}.*gem$/ }.first
    FileUtils.mv(gem_file, "#{gem_name}.gem")
    system("gem unpack #{gem_name}.gem")
  end
end
