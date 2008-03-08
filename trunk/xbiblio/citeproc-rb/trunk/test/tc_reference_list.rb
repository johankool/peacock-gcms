#! /usr/bin/env ruby
require File.dirname(__FILE__) + '/../lib/citeproc'
require 'test/unit'

class TestReferenceList < Test::Unit::TestCase
  include CiteProc
  def data
    [
      {
        :author => [{:sortname => "Doe, Jane", :name => "Jane Doe"}],
        :title => "Some title",
        :year => "1999",
        :type => "book"
      },
      {
        :author => [{:sortname => "Smith, Steve", :name => "Steve Smith"},
          {:sortname => "Doe, Jane", :name => "Jane Doe"}],
        :title => "Another title",
        :year => "1999",
        :type => "book"
      },      
      {
        :author => [{:sortname => "Doe, Jane", :name => "Jane Doe"}],
        :title => "Title",
        :year => "1999",
        :type => "book"
      }
    ]
  end

  def setup
    @contributors = AgentList.new
    @refs = ReferenceList.new
    data.each do |reference|
      t = reference[:title]
      y = reference[:year]
      ty = reference[:type]
      author_list = []
      reference[:author].each do |a| 
        agent = @contributors.add(a[:sortname], a[:name])
        author_list << agent
      end
      # why isn't the author_list getting correctly added to creator
      # array?
      ref = Reference.new(title=t, creator=author_list, year=y, type=ty)
      @refs.add(ref)
    end
  end

  def test_authors?
    assert_not_nil(@refs.index(0).creator)
  end
    
  def test_process_author_year
    assert(@refs.processed.find do |r| 
      r.title == "Title"
    end.bibparams[:suffix] == "b")
  end

end
