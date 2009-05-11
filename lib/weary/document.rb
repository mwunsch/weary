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

    def extract
      case @parse
        when Nokogiri::XML::Document
          # Until I can figure out how to make a better to_hash method for Nokogiri:
          # http://gist.github.com/109799
          parse.to_hash
        #  Crack::XML.parse(@raw)
        when Hash
          parse
        else
          raise StandardError, "Cannot extract data from plain text"
      end
    end

  end
end