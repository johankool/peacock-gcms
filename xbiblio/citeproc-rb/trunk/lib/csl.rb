# extend Hash to allow easier access; from 
# http://ola-bini.blogspot.com/2006/09/ruby-metaprogramming-techniques.html
class Hash
  def method_missing(name,*args)
  if name.to_s =~ /=$/
    self[$`] = args[0]
  elsif args.empty?
    self[name.to_s]
  else
    raise NoMethodError, "#{name}"
  end
  end
end

# reads a MSL file and creates an object
class Style
  attr_reader :name, :content
  def initialize(name=nil, content=[])
    @name = name
    @content = content
  end
  def add_definition(dname)
    @content << Definition.new(name=dname)
  end
end

# need better name
class Definition
  attr_reader :name, :sort, :templates
  def initialize(name=nil, sort="author-date", templates=[])
    @name = name
    @sort = sort
    @templates = templates
  end
end

class Template
  attr_reader :name, :fields
  def initialize(name=nil, fields=[])
    @name = name
    @fields = fields
  end
end

class Field
  attr_reader :name, :style, :prefix, :suffix, :substitute
  def initialize(name=nil, style=nil, prefix=nil, suffix=nil, substitute=nil)
    @name = name
    @style = style
    @prefix = prefix
    @suffix = suffix
    @substitute = substitute
  end 
end
