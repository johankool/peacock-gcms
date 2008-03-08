#! /usr/bin/env ruby
# simple script to abbreviate titles
# give full title as the argument

require 'yaml'

title = ARGV[0]

class String
  IGNORE = ["of", "the"]

  TERMS = YAML::load(File.open("abbrev.yaml"))
    
  def abbreviate(form="display")
    words = self.split(/\W+/)
    abbreviated_words = []
    words.each do |word|
      if IGNORE.find{|w| w.downcase == word.downcase} then 
        nil
      elsif TERMS[word.downcase] then
        abbreviated_words << TERMS[word.downcase]
      else
        abbreviated_words << word
      end
    end
    if form == "filename" then
      abbreviated_words.join("_").downcase + ".csl"
    else
      abbreviated_words.join(" ")
    end
  end
end

puts "
Titles
===============================================================

"
puts "title: " + title
puts "short title: " + title.abbreviate
puts "file name: " + title.abbreviate(form="filename")
puts "
"
