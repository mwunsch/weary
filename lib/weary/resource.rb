module Weary
  class Resource
    attr_reader :name, :via, :with, :requires, :url
    attr_accessor :headers
    
    def initialize(name)
      self.name = name
      self.via = :get
      self.authenticates = false
      self.follows = true
    end
    
    # The name of the Resource. Will be a lowercase string, whitespace replaced with underscores.
    def name=(resource_name)
      @name = resource_name.to_s.downcase.strip.gsub(/\s/,'_')
    end
    
    # The HTTP Method used to fetch the Resource
    def via=(http_verb)
      verb = HTTPVerb.new(http_verb).normalize
      @via = if Methods.include?(verb)
        verb
      else
        :get
      end
    end
    
    # Optional params. Should be an array. Merges with requires if that is set.
    def with=(params)
      @with = params.collect {|x| x.to_sym}
      @with = (requires | @with) if requires
    end
    
    # Required params. Should be an array. Merges with `with` or sets `with`.
    def requires=(params)
      @requires = params.collect {|x| x.to_sym}
      with ? @with = (with | @requires) : (@with = @requires)
    end
    
    # Sets whether the Resource requires authentication. Always sets to a boolean value.
    def authenticates=(bool)
      @authenticates = bool ? true : false
    end
    
    # Does the Resource require authentication?
    def authenticates?
      @authenticates
    end
    
    # Sets whether the Resource should follow redirection. Always sets to a boolean value.
    def follows=(bool)
      @follows = bool ? true : false
    end
    
    # Should the resource follow redirection?
    def follows?
      @follows
    end
    
    # Set the Resource's URL as a URI
    def url=(uri)
      @url = URI.parse(uri)
    end
    
    def to_hash
      {@name.to_sym => { :via => via,
                         :with => with,
                         :requires => requires,
                         :follows => follows?,
                         :authenticates => authenticates?,
                         :url => url,
                         :headers => @headers}}
    end
    
    def craft_methods
      code = %Q{
        def #{name}(params={})
          options ||= {}
          url = "#{url.normalize}"
          }
            
      code << %Q{
          missing_requirements = #{requires.inspect} - params.keys
          if !missing_requirements.empty?
            raise ArgumentError, "This resource is missing required parameters: '\#{missing_requirements.inspect}'"
          end} if requires
      
      code << %Q{
          params.delete_if {|k,v| !#{with.inspect}.include?(k) }} if with
      
      if (via == :post || via == :put)
        code << %Q{
          options[:body] = params unless params.empty?}
      else
        code << %Q{
          options[:query] = params unless params.empty?
          url << "?" + options[:query].to_params if options[:query]}
      end    
      
      if authenticates?
        # handle authentication
        # 
        # here's what it used to look like:
        # 
        #         if authenticates?
        #           code << %Q{options[:basic_auth] = {:username => "#{@username}", :password => "#{@password}"} \n}
        #         end
        # 
        # 
        # 
        #         if oauth?
        #           consumer_options = ""
        #           access_token.consumer.options.each_pair {|k,v| 
        #             if k.is_a?(Symbol)
        #               k_string = ":#{k}"
        #             else
        #               k_string = "'#{k}'"
        #             end
        #             if v.is_a?(Symbol)
        #               v_string = ":#{v}"
        #             else
        #               v_string = "'#{v}'"
        #             end
        #             consumer_options << "#{k_string} => #{v_string},"
        #           }
        #           code << %Q{ oauth_consumer = OAuth::Consumer.new("#{access_token.consumer.key}","#{access_token.consumer.secret}",#{consumer_options.chop}) \n}
        #           code << %Q{ options[:oauth] = OAuth::AccessToken.new(oauth_consumer, "#{access_token.token}", "#{access_token.secret}") \n}
        #         end
        # 
      end
      
      
      code << %Q{
          options[:no_follow]} if !follows?
      
      code << %Q{
          options[:headers] = #{headers.inspect}} if !headers.blank?
      
      code << %Q{\n
          Weary::Request.new(url, #{via.inspect}, options)
          
        end}
      return code
    end
    
  end
end