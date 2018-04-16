require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

class MegaDB
  MEGA_REGEX = /[\d@?"()=\\$+-_*!'&#%`é]/.freeze
  
  attr_reader :data
  
  def initialize
    @db = Sequel.sqlite(database: 'youtube.db')
    @subtitles = @db[:subtitles]
    @data = parse_subtitles
  end

  def compare(title, left, right)
    dataset = data[title]
    if dataset
      left_count = dataset[left] || 0
      right_count = dataset[right] || 0
      return left_count > right_count ? left : right
    end
  end

  private

  def parse_subtitles
    temp = {}
    @subtitles.where(ready: true).each do |s|
      text = s[:text]
      word_array = text.gsub(MEGA_REGEX, ' ')
                        .split(' ')
                        .select { |w| w.size > 0 }
      temp[s[:title]] = word_array.each_with_object({}) do |w, hash|
        hash[w] ||= 0
        hash[w] += 1
      end
    end
    direct_data_injection(temp)
  end

  def direct_data_injection(hash)
    mapper = {
      "contributors" => "contributers",
      "contributor" => "contributer"
    }
    hash_keys = hash.keys
    mapper.each_pair do |k, v|
      hash_keys.each do |title|
        hash[title][v] = hash[title][k] unless hash[title][v]
      end
    end
    hash
  end
end
