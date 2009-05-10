require 'active_support'
require 'nokogiri'

autoload :Yaml, 'yaml'

module Weary
  class Document
    
    attr_reader :raw, :type
    
    def initialize(doc, type)
      @raw = doc
      @type = type
      self.parse = doc
    end
    
    def parse=(document)
      @parse = case @type
        when :xml, :html
          Nokogiri.parse(document)
        when :json
          ActiveSupport::JSON.decode(document)
        when :yaml
          YAML::load(document)
        else
          document
      end
    end
    
    def parse
      @parse
    end

    # Having trouble conceptualizing 
    # def extract(root, *nodes)
    #   case @parse
    #     when Nokogiri::XML::Document
    #       return nil if parse.css(root).empty? #root node cannot be empty
    #       query_string = ""
    #       query_string = root if nodes.empty?
    #       unless nodes.empty?
    #         nodes.each { |node| query_string += "#{root} > #{node}," }
    #         query_string.chop!
    #       end
    #       parse.css(query_string)
    #     when Hash
    #       return nil unless parse.has_key? root
    #       extraction = parse[root]
    #       extraction.values_at(*nodes) unless nodes.empty?
    #     else
    #       raise StandardError, "Cannot extract data from plain text"
    #   end
    # end
    
  end
end