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
  attr_accessor :service_name, :deprecated, :body_params, :query_params, :id, :tag, :summary

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
    @response_codes =  {"default"=>{"description"=>"unknown error"}} 
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
    #get body params from the spec files given
    spec_file_path = "./../spec/doc/" + @tag + "/"+ @service_name + "/query.json"
    #spec_file = File.read(spec_file_path)
    begin
      File.open(spec_file_path, 'r') do |f|
      spec_file = f.read
      @query_params = JSON.parse(spec_file)
      end
    rescue
      @query_params = ""
    end
  end

  def attach_body_params
    #get body params from the spec files given
    spec_file_path = "./../spec/doc/" + @tag + "/"+ @service_name + "/request.json"
    #spec_file = File.read(spec_file_path)
    File.open(spec_file_path, 'r') do |f|
      spec_file = f.read
      @body_params = JSON.parse(spec_file)
    end
    #Service.add_to_global_schema Payload.ref_schema  # tried using self.add_to_gloabl_schema, but didnt seem to work
  end

  def attach_response_codes
    spec_file_path = "./../spec/doc/" + @tag + "/"+ @service_name + "/response.json"
    #spec_file = File.read(spec_file_path)
    File.open(spec_file_path, 'r') do |f|
      spec_file = f.read
      response = JSON.parse(spec_file)
    end
 
    #Service.add_to_global_schema Response.ref_schema

    #check errors.json
    spec_file_path = "./../spec/doc/" + @tag + "/"+ @service_name + "/errors.json"
    #spec_file = File.read(spec_file_path)
    File.open(spec_file_path, 'r') do |f|
      spec_file = f.read
      error_codes = JSON.parse(spec_file)
      @response_codes = @response_codes.merge(error_codes)
    end





  end


  def strip_required
    required_array = []
    #puts "body params is like this: ", @body_params
    @body_params.each do |key, value|
      if value["required"]
        required_array << key
      end 
    end
    required_array
  end

  def create_schema
    schema = {
      "type" => "object",
      "required" => strip_required,
      "properties" => @body_params
    }
    #self.add_to_global_schema({ @service_name => schema })
    @@schema_global = @@schema_global.merge({ @service_name => schema })
    "#/definitions/" + @service_name
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






