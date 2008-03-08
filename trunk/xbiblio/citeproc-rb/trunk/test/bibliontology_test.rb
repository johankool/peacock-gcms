#! /usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'bibliontology'

class BibliontologyTest < Test::Unit::TestCase
  include Bibliontology 
  
  # Sets up a document with a range of relational and literal properties
  def setup
    @document = Document.new('My Document')
    @document.translation_of = Document.new('Mon Document')
    
    author = Person.new
    author.given_name = 'Me'
    author.family_name = 'Myself'
    author.homepage = 'http://mydomain.com'
    author.mbox = 'me@mydomain.com'
    contribution = Contribution.new(author, @@author, 1)
    @document.add_contribution(contribution) 
    
    event = Event.new
    org = Organisation.new
    org.name = 'An Important Conference'
    event.agent = org
    event.product = 'Some textual product.'
    event.time = Interval.new(Time.now - 100000, Time.now - 90000)
    event.place = SpatialThing.new(50, 45, 0)
    @document.presented_at = event
  end
  
  
  # Test the basic document properties
  def test_simple_properties
    assert_equal('My Document', @document.title)
    assert_equal('Mon Document', @document.translation_of.title)
  end

  
  # Test for a single contribution
  def test_contribution
    assert_not_nil(@document.contributions[0])
    assert_equal('Me', @document.contributions[0].contributor.given_name)
    assert_equal('Myself', @document.contributions[0].contributor.family_name)
    assert_equal('http://mydomain.com', @document.contributions[0].contributor.homepage)
    assert_equal('me@mydomain.com', @document.contributions[0].contributor.mbox)
    assert_equal(@@author, @document.contributions[0].role)
    assert_equal(1, @document.contributions[0].position)

    # Try to add an invalid class
    assert_raise ArgumentError do 
      @document.add_contribution('A literal contribution!')
    end
  end
  
  
  # Tests for when the document was presented
  def test_presented_at
    assert_equal('An Important Conference', @document.presented_at.agent.name)
    assert_equal('Some textual product.', @document.presented_at.product)
    assert_equal(10000, @document.presented_at.time.end.to_i - @document.presented_at.time.start.to_i)
    assert_equal(50, @document.presented_at.place.latitude)
    assert_equal(45, @document.presented_at.place.longitude)
    assert_equal(0, @document.presented_at.place.altitude)

    # Try to add an invalid sub-event
    assert_raise ArgumentError do 
      @document.presented_at.sub_event = 'A workshop associated with the main event.'
    end
  end
end
