#  == Synopsis
#
#  A citation processing library. Similar in principle to 
#  BibTeX, citeproc-rb uses an XML-based citation style 
#  language (CSL) for formatting configuration, and has a 
#  richer internal data model.
#
#  == Author
#
#  Bruce D'Arcus
#
#  == Copyright
#
#  Copyright (c) 2005, Bruce D'Arcus.
#  Licensed under the same terms as Ruby.
#
#  == Design
# 
#  CiteProc consists of the following pieces:
#  * input driver system for handling data formmats
#  * core formatting processor
#  * CSL reader to configure formatting
#  * output driver system for final output
#
#  As much as possible, then, citeproc is agnostic
#  about input and output format details.

require 'rubygems'
require 'open-uri'
require 'rexml/document'
require_gem 'builder'

# == Extensions
module Enumerable
  def group_by(store=Hash.new)
    self.each do |elem|
      group = yield elem
      (store[group] ||= []) << elem
    end
    store
  end

  def group_by_multiple(*criteria)
    return self if criteria.empty?

    self.group_by do |item|
      criteria.first.call(item)
    end.inject({}) do |result, (key, items)|
      subgrouped = items.group_by_multiple(*criteria[1 .. -1])
      result.merge(key => subgrouped)
    end
  end

  def sort_by_multiple(*criteria)
    self.sort_by do |item|
      criteria.map do |criterium|
        criterium.call(item)
      end
    end
  end
end

# == CiteProc Module
module CiteProc
  
  # === CitationStyle Class
  class CitationStyle    
    attr_reader :name, :language, :version
    def initialize(name, language, version=nil)
      @name = name
      @language = language
      @version = version
    end

    # loads a citation style (csl) file
    # * looks first locally; if not, then
    # * looks at online repository
    # * if it finds online file, it caches it locally
    def csl
      # TODO needs to be smarter; cache where possible
      url = "http://www.users.muohio.edu/darcusb/citations/csl/styles/apa/apa-en.csl"
      REXML::Document.new(open(url))
    end

    # creates a csl metadata object from csl file
    def info
      config = {}
      csl.elements.each("/citationstyle/info/*") do |e|
        if e.nil? then content = nil
        else content = e.text
        end
        config[e.name] = content
      end
      CSLInfo.new(title=config["title"], 
                  short_title=config["title-short"],
                  date_created=config["dateCreated"])
    end

    # creates an item layout object from csl file
    def create_layout(type)
      # TODO needs to distinguish generic formatting from reftype-based
      item_layout = []
      csl.elements.each("#{type}/item-layout/reftype/*") do |rt|
        node = FormattingNode.new(name = rt.name, 
                                 font_family = rt.attributes["font_family"],
                                 font_style = rt.attributes["font_style"])
        item_layout << node
      end
      return item_layout
    end

    # creates a citation object from csl file
    def citation
      et_al_rules = []
      csl_sort_order = csl.elements["/citationstyle/citation"].attributes["sort-order"]
      csl_delimiter = csl.elements["/citationstyle/citation"].attributes["delimiter"]
      CSLConfig.new(csl_sort_order,
                    csl_delimiter,
                    et_al_rules,
                    create_layout("citation"))
    end

    # creates a csl bibliography object from csl file
    def bibliography
      et_al_rules = []
      csl_sort_order = csl.elements["/citationstyle/bibliography"].attributes["sort-order"]
      csl_delimiter = csl.elements["/citationstyle/bibliography"].attributes["delimiter"]
      CSLBibliographyConfig.new(csl_sort_order,
                    csl_delimiter,
                    et_al_rules,
                    create_layout("bibliography"))
    end
    
  end

  class CSLInfo
    attr_reader :title, :short_title, :date_created, :date_modified
    def initialize(title, short_title, date_created, date_modified=nil)
      @title = title
      @short_title = short_title
      @date_created = date_created
      @date_modified = date_modified
    end
  end

  class CSLGeneral
    attr_reader :names, :dates, :genres, :media, :roles
    def initialize(names, dates, genres=nil, media=nil, roles=nil)
      @names = names
      @dates = dates
      @genres = genres
      @media = media
      @roles = roles
    end
  end

  class CSLConfig
    attr_reader :sort_order, :delim, :et_al_rules, :item_layout
    def initialize(sort_order, delimeter, et_al_rules, item_layout)
      @sort_order = sort_order
      @delimeter = delimeter
      @et_al_rules = et_al_rules
      @item_layout = item_layout
    end
  end

  class CSLBibliographyConfig < CSLConfig
    def initialize(sort_order, delimeter, et_al_rules, item_layout)
      super(sort_order, delimeter, et_al_rules, item_layout)
    end

    def list_layout
      
    end
    
  end

  class CSLReftype
    attr_reader :name
    # TODO need to figure out how to handle this best
    # again the distinction between generic/type-based
    def initialize(name, csl_defs = Array.new)
      @csl_defs = csl_defs
    end
  end

  class ItemLayout
    def initialize(csl_defs = Array.new)
      @csl_defs = csl_defs
    end
  end

  class FormattingNode
    attr_reader :name, :prefix, :suffix, :font_family, :font_style, :font_weight
    def initialize(name, prefix=nil, suffix=nil, font_family=nil,
                 font_style=nil, font_weight=nil)
      @name = name
      @prefix = prefix
      @suffix = suffix
      @font_family = font_family
      @font_style = font_style
      @font_weight = font_weight
    end
  end

# == Reference Classes; should these be a separate module?
  
  # the base metadata class
  class Reference
    attr_reader :title, :authors, :year, :type, :partOf,:bibparams

    def initialize(title, authors, year, type, partOf=nil, bibparams={})
      @title = title
      @authors = []
      @year = year
      @type = type
      @partOf = partOf
      @bibparams = bibparams
    end
    
    # returns a formatted reference
    def format
      # grab existing CitationStyle object and reference it in variable
      ObjectSpace.each_object(CiteProc::CitationStyle){|o| @csl = o}

      style = @csl.bibliography.item_layout
      result = ""
      style.each do |render|
        if render.prefix then 
          result << render.prefix 
        end
        if render.name == "author" then
          author_string = ""
          author.each do |c|
            creator_string << c.name
          end
          result << creator_string
        # a clever way to generate the method call dynamically
        else result << self.send(render.name)
        end
        if render.name == "year" and bibparams[:suffix] then
          result << bibparams[:suffix]
        end
        if render.suffix then 
          result << render.suffix
        end
      end
      puts result
    end

  end

  class ReferenceList
    include Enumerable
  
    def initialize
      @references = []
    end

    def empty?
      @references.size == 0
    end

    def each
      @references.each {|reference| yield reference} 
    end

    def add(reference)
      @references.push(reference)
    end

    def <<(reference)
      @references << reference 
    end 
  
    # configures sorting
    def sort_criteria 
      [
        lambda { |ref| ref.authors.each.join{|i| i.sortname} },
        lambda { |ref| ref.year },
        lambda { |ref| ref.title }
      ]
    end
  
    # the sorted reference list
    def sorted
      @references.sort_by_multiple(*sort_criteria)
    end

    # configures grouping
    def group_criteria
      [lambda {|ref| ref.authors.each.join{|i| i.sortname}}, lambda {|ref| ref.year}]
    end
   
    # the grouped (and sorted) reference list
    def grouped
      sorted.group_by_multiple(*group_criteria)
    end

    # the final processed reference list; ready for formatting
    def processed
      sort_algorithm = "author-year"
      if sort_algorithm == "cited" then process_cited 
      else process_author_date
      end
    end

    def process_cited

    end
   
    # processing for author-date style references
    def process_author_date
      processed = []
      grouped.keys.sort.each do |author|
        by_author = grouped[author]
        first_by_author = true
        year_suffix = "a"
        by_author.keys.sort.each do |year|
          by_year = by_author[year]
          first_by_year = true
          suffix = true if by_year.size > 1
          by_year.each_with_index do |ref, index|

            ref.bibparams[:first_by_author] = first_by_author
     
            # create year suffix value where relevant
            if suffix then
              ref.bibparams[:suffix] = year_suffix.dup
            end
            year_suffix.succ!
         
            first_by_author = first_by_year = false

            processed << ref

          end
        end
      end
      return processed
    end
  
    # format list
    def format
      processed.each do |reference| 
        reference.format 
      end
    end

    # dump reference list to RDF; TODO needs to be finished to dump
    # out agents and collections objects as separate resources
    def to_rdf
      xml = Builder::XmlMarkup.new(:target => STDOUT, :indent => 2)
      xml.tag!("rdf:RDF", "xmlns:rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#") do
      @references.each do |item|
        xml.Article do
          xml.title(item.title)
          xml.year(item.year)
#          xml.volumeNumber(item.volume_no) unless item.volume_no.nil?
#          xml.issueNumber(item.issue_no) unless item.issue_no.nil?
#          xml.pages(item.pages) unless item.pages.nil?
          xml.partOf do
            xml.Periodical {xml.title(item.partOf.title)}
          end
        end
      end
    end
  end

  end

  # non-citable resources such as periodicals, series, or
  # archival collections
  class Collection
    attr_reader :title
    def initialize(title)
      @title = title
    end
  end

  class Periodical < Collection
    def initialize(title)
      super(title)
    end
  end

  class Series < Collection
    def initialize(title)
      super(title)
    end
  end


  # == Agents

  class AgentList
    attr_reader :agents
    def initialize(agents=Array.new)
      @agents = agents
    end

    def each
      @agents.each {|agent| yield agent} 
    end

    # Check first if agent object exists. If yes, reference
    # object; if no, create new one.
    def add(sortname, name)
      agent = @agents.find {|a| a.sortname == sortname}
      if agent then
        return agent
      else 
        new_agent = Agent.new(name, sortname)
        @agents << new_agent
        return new_agent
      end
    end
    
  end

  class Agent
    attr_reader :name, :sortname
    def initialize(name, sortname)
      @name = name
      @sortname = sortname
    end

    def inspect()
      "#<#{self.class}: #{@name}>"
    end
  end

  class Person < Agent
    def initialize(name, sortname)
      super
    end
  end

  class Organization < Agent
    def initialize(name, sortname=nil)
      super
    end
  end

  class Publisher < Organization
    def initialize(name, place)
      super(name)
      @place = place
    end
  end


  # == Events

  class Event
    def initialize(name, date, sponsor)
      @name = name
      @date = date
      @sponsor = sponsor
    end  
  end

  class Conference < Event
    def initialize(name, date, sponsor)
      super(name, date, sponsor)
    end
  end
  
end

