module Weary
  class Resource
    attr_accessor :name, :domain, :with, :requires, :via, :format, :url, :authenticates, :follows, :headers, :oauth, :access_token
    
    def initialize(name)
      self.name = name
      self.via = :get
      self.authenticates = false
      self.follows = true
      self.with = []
      self.requires = []
      self.oauth = false
    end
    
    def name=(resource_name)
      resource_name = resource_name.to_s unless resource_name.is_a?(String)
      @name = resource_name.downcase.strip.gsub(/\s/,'_')
    end
    
    def via=(http_verb)
      verb = HTTPVerb.new(http_verb).normalize
      @via = if Methods.include?(verb)
        verb
      else
        :get
      end
    end
    
    def format=(type)
      type = type.downcase if type.is_a?(String)
      @format = case type
        when *ContentTypes[:json]
          :json
        when *ContentTypes[:xml]
          :xml
        when *ContentTypes[:html]
          :html
        when *ContentTypes[:yaml]
          :yaml
        when *ContentTypes[:plain]
          :plain
        else
          raise ArgumentError, "#{type} is not a recognized format."
      end
    end
        
    def with=(params)
      if params.is_a?(Hash)
        @requires.each { |key| params[key] = nil unless params.has_key?(key) }
        @with = params
      else
        if @requires.nil?
          @with = params.collect {|x| x.to_sym}
        else
          @with = params.collect {|x| x.to_sym} | @requires
        end
      end
    end
    
    def requires=(params)
      if @with.is_a?(Hash)
        params.each { |key| @with[key] = nil unless @with.has_key?(key) }
        @requires = params.collect {|x| x.to_sym}
      else
        @with = @with | params.collect {|x| x.to_sym}
        @requires = params.collect {|x| x.to_sym}
      end
    end
    
    def url=(pattern)
      if pattern.index("<domain>")
        raise StandardError, "Domain flag found but the domain is not defined" if @domain.nil?
        pattern = pattern.gsub("<domain>", @domain)
      end
      pattern = pattern.gsub("<resource>", @name)
      pattern = pattern.gsub("<format>", @format.to_s)
      @url = pattern
    end
    
    def oauth=(bool)
      @authenticates = false if bool
      @oauth = if bool
        true
      else
        false
      end
    end
    
    def authenticates=(bool)
      @oauth = false if bool
      @authenticates = if bool
        true
      else
        false
      end
    end
    
    def authenticates?
      @authenticates
    end
    
    def oauth?
      @oauth
    end
    
    def access_token=(token)
      raise ArgumentError, "Token needs to be an OAuth::AccessToken object" unless token.is_a?(OAuth::AccessToken)
      @oauth = true
      @access_token = token
    end
    
    def follows_redirects?
      if @follows
        true
      else
        false
      end
    end

    def to_hash
      {@name.to_sym => { :via => @via,
                         :with => @with,
                         :requires => @requires,
                         :follows => follows_redirects?,
                         :authenticates => authenticates?,
                         :format => @format,
                         :url => @url,
                         :domain => @domain,
                         :headers => @headers,
                         :oauth => oauth?,
                         :access_token => @access_token}}
    end
    
    def craft_methods
      code = %Q{
        def #{name}(params={})
          options ||= {}
          url = "#{url}"
        }

      if with.is_a?(Hash)
        hash_string = ""
        with.each_pair {|k,v| 
          if k.is_a?(Symbol)
            k_string = ":#{k}"
          else
            k_string = "'#{k}'"
          end
          hash_string << "#{k_string} => '#{v}',"
        }
        code << %Q{
          params = {#{hash_string.chop}}.delete_if {|key,value| value.empty? }.merge(params)
        }
      end
      
      
      unless requires.nil?
        if requires.is_a?(Array)
          requires.each do |required|
            code << %Q{  raise ArgumentError, "This resource requires parameter: ':#{required}'" unless params.has_key?(:#{required}) \n}
          end
        else
          requires.each_key do |required|
            code << %Q{  raise ArgumentError, "This resource requires parameter: ':#{required}'" unless params.has_key?(:#{required}) \n}
          end
        end
      end
      
      unless with.empty?
        if with.is_a?(Array)
          with_params = %Q{[#{with.collect {|x| x.is_a?(Symbol) ? ":#{x}" : "'#{x}'" }.join(',')}]}
        else
          with_params = %Q{[#{with.keys.collect {|x| x.is_a?(Symbol) ? ":#{x}" : "'#{x}'"}.join(',')}]}
        end
        code << %Q{ 
          unnecessary = params.keys - #{with_params} 
          unnecessary.each { |x| params.delete(x) } 
        }
      end
      
      if via == (:post || :put)
        code << %Q{options[:body] = params unless params.empty? \n}
      else
        code << %Q{
          options[:query] = params unless params.empty?
          url << "?" + options[:query].to_params unless options[:query].nil?
        }
      end
      
      
      unless (headers.nil? || headers.empty?)
        header_hash = ""
        headers.each_pair {|k,v|
          header_hash << "'#{k}' => '#{v}',"
        }
        code << %Q{ options[:headers] = {#{header_hash.chop}} \n}
      end
      
      
      if authenticates?
        code << %Q{options[:basic_auth] = {:username => "#{@username}", :password => "#{@password}"} \n}
      end
      
      
      
      if oauth?
        consumer_options = ""
        access_token.consumer.options.each_pair {|k,v| 
          if k.is_a?(Symbol)
            k_string = ":#{k}"
          else
            k_string = "'#{k}'"
          end
          if v.is_a?(Symbol)
            v_string = ":#{v}"
          else
            v_string = "'#{v}'"
          end
          consumer_options << "#{k_string} => #{v_string},"
        }
        code << %Q{ oauth_consumer = OAuth::Consumer.new("#{access_token.consumer.key}","#{access_token.consumer.secret}",#{consumer_options.chop}) \n}
        code << %Q{ options[:oauth] = OAuth::AccessToken.new(oauth_consumer, "#{access_token.token}", "#{access_token.secret}") \n}
      end
      
      
      
      
      
      
      unless follows_redirects?
        code << %Q{options[:no_follow] = true \n}
      end
      
      
      
      code << %Q{
          Weary::Request.new(url, :#{via}, options)
      }
      
      
      
      code << "end"
      return code
    end
    
  end
end