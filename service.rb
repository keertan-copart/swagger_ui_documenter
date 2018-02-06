require 'rubygems'
require 'json'



class Service
  @@all_tags = %w[]
  @@baseurl = ""
  @@host = ""
  @@group_description = {}
  @@schema_global = {}
  @@schema_references = {}

  attr_reader  :comment, :service_description, :paramset, :path, :name, :type, :param_flag, :response_codes
  attr_accessor :service_name, :deprecated, :body_params, :id, :tag, :summary

  def initialize(service_name, summary, tag, service_description, deprecated)
    @service_name = service_name
    @summary = summary
    @name = "post"
    @tag = tag
    @type = 0
    @path = "/"
    @deprecated = deprecated
    @param_flag = false
    @paramset = %w[]
    @service_description = service_description
    @testing_lotno = 12345
    @body_params = {}
    @response_codes = [ {"200"=>{"description"=>"success!"}} ]
    @@host = "0.0.0.0:9292"
    @@baseurl = "0.0.0.0:9292/transporter/"
    id = "0"
  end

  def extraction line
    extract_service_from_line line
    extract_path_from_line line
    extract_params
    format_path.to_s    
  end

  def extract_service_from_line(line)
   	@name, @type = extract_name_and_type line
    @status = 1 #By default, assigning working status.
  end

  
  def extract_path_from_line(line)
    @path = line.scan(%r{'/.*/?'}).to_s.gsub!(/[\'\"\]\[]/, '')    
  end

	def extract_name_and_type(line)
    if /(post|POST)\s(.*)/.match(line)
      ["post", 1]
    elsif /(get|GET)\s(.*)/.match(line)
      ["get", 2]
    elsif /(put|PUT)\s(.*)/.match(line) 
      ["put", 3]
    elsif /(delete|DELETE)\s(.*)/.match(line) 
      ["delete", 4]  
    end
	end

  def extract_params
    @paramset = @path.to_s.scan(%r{/:([a-zA-Z_]+)})
    puts @paramset
    unless @paramset&.length==0
      @param_flag = true
    end
  end

  def add_tag(k, v)
    @@group_description[k] ||= v
  end

  def format_path
		if @param_flag
		  @paramset.each do |param|
      @path = @path.sub(/:#{param[0].to_s}/, "{"+param[0].to_s+"}")
      end
    end
    @path
	end

  def attach_query_params
    # comment
  end

  def attach_body_params
    #get body params from the spec files given
    spec_file_path = "./../spec/" + @tag + "/"+ @service_name + "/request.json"
    @body_params = JSON.parse(spec_file_path)
    Service.add_to_global_schema Payload.ref_schema  # tried using self.add_to_gloabl_schema, but didnt seem to work
  end

  def attach_response_codes
    spec_file_path = "./../spec/" + @tag + "/"+ @service_name + "/response.rb"
    require spec_file_path
    @response_codes = Response.response_codes
    Service.add_to_global_schema Response.ref_schema
  end

  def self.add_to_global_schema schema
    @@schema_global = @@schema_global.merge(schema)
  end

  def self.baseurl=(url)
    @@baseurl = url
  end

  def self.host=(host)
    @@host = host
  end

  def self.schema_global=(schema)
    @@schema_global = schema
  end

  def self.all_tags=(given_all_tags)
    @@all_tags = given_all_tags
  end

  def self.push_tag(tag)
    @@all_tags.push(tag)
  end

  def self.baseurl
    @@baseurl
  end

  def self.host
    @@host
  end

  def self.schema_global
    @@schema_global
  end

  def self.all_tags
    @@all_tags
  end

  def self.group_description
    @@group_description
  end

  def service_description=(service_description)
    @service_description = service_description
  end

  def comment=(extracted_comment)
    @comment = extracted_comment
  end
  
end
# end of class!

#**********************************************************






