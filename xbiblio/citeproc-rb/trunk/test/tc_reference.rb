#! /usr/bin/env ruby
require File.dirname(__FILE__) + '/../lib/citeproc'
require 'test/unit'

class TestReference < Test::Unit::TestCase
  include CiteProc
  def data
    [
      {
        :creator => ["Doe, Jane", "Jane Doe"],
        :title => "Some title",
        :year => "1999",
        :type => "book"
      }
    ]
  end

  def test_load
    data.each do |reference|
      t = reference[:title]
      y = reference[:year]
      ty = reference[:type]
      au = reference[:creator].each{|a| Person.new(a[0], a[1])}
      ref = Reference.new(title=t, authors=au, year=y, type=ty)
      assert_not_nil(ref.title)
    end
  end

end

