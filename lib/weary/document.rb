require 'crack'
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
          Crack::XML.parse document
        when :json
          Crack::JSON.parse document
        when :yaml
          YAML::load document
        else
          document
      end
    end
    
    def parse
      @parse
    end

  end
end