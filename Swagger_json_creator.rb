require 'rubygems'
require 'json'



class Service
  @@all_tags = %w[]
  @@baseurl = ""
  @@host = ""
  @@schema_global = []

  attr_reader :name, :tag, :comment, :summary, :paramset, :path, :name, :type, :param_flag, :response_codes
  attr_accessor :deprecated, :body_params, :id

  def intialize(default_name="post", type = 0, path = "/", deprecated = false, param_flag = false, paramset = %w[], default_comment = "", default_summary = "Not provided")
    @name = default_name
    @tag = "/"
    @type = type
    @path = path
    @deprecated = deprecated
    @param_flag = param_flag
    @paramset = default_params
    @comment = default_comment
    @summary = default_summary
    @testing_lotno = 12345
    @body_params = {}
    @response_codes = {}
    @@host = "0.0.0.0:9292"
    @@baseurl = "0.0.0.0:9292/transporter/"
    id = "0"
  end

  def extraction line
    extract_service_from_line line
    extract_path_from_line line
    extract_params
    extract_tag
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
    unless @paramset.length==0
      @param_flag = true
    end
  end

  def extract_tag
    @tag = @path.scan(%r{/[a-zA-Z_]+})[0].to_s[1..-1]
  end

  def format_path
		if @param_flag
		  @paramset.each do |param|
      @path = @path.sub(/:#{param[0].to_s}/, "{"+param[0].to_s+"}")
      end
    end
    @path
	end

  def attach_body_params params
    @body_params = params
  end

  def attach_response_codes codes
    @response_codes = codes
  end

  def self.add_to_global_schema schema
    @@schema_global << schema
  end

  def self.check_duplicate_schema schema
    #@@schema_global&.each do |existing| 
    #  if existing==schema  
    #    return true
    #  else
    #    return false 
    #  end
    #end
    false
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

  def summary=(summary)
    @summary = summary
  end

  def comment=(extracted_comment)
    @comment = extracted_comment
  end

  
end
# end of class!

#Independent functions  ************************************

def capture_host_and_baseurl line
  line.include?("host") ? Service.host = line[/host = \'(.+)\'/,1] : true
  line.include?("baseurl") ? Service.baseurl = line[/baseurl = \'(.+)\'/,1] : true
end

def extract_title url
  url.split('/').last.chomp('.rb') || "Unknown API"
end

def extract_response_code line
  {
    line.sub("#","").split(":")[0]&.strip => { "description" => line.sub("#","").split(":")[1]&.strip }
  }
end

def hotword? line
  /(post|POST|get|GET|DELETE|delete|put|PUT)\s(.*)/.match(line)
end

def single_commented? line
  temp = line.lstrip
  temp[0] == '#' && temp[1] != '#'? true : false
end

def response_definition_toggle? line
  line.strip[0] == "#" && line.strip[1] == "-"
end

def double_commented? line
  temp = line.lstrip
  temp[0] == '#' && temp[1] == '#'? true : false
end

def format_comment line
  line.sub(/#/,"")
end

def format_internal_comment line
  format_comment line
end

def format_summary line
  line.scan(/#.+/)[0]&.sub('#','') || "Summary not provided"
end

def deprecated? line
  line.include?("-d") || line.include?("deprecated")
end

# check if a tag exists in our dictionary, if not it adds it and returns true. if yes, then it returns false.
def tagger(tag)
  if !Service.all_tags.include? tag
    Service.all_tags.push(tag)
    true
  else
    false
  end
end

def tag_array_creator tags
  tag_array = []
  tags.each { |tag| tag_array << { "name" =>  tag , "description" => ""} }
  tag_array
end

def body_params? line
  line.include?("body_parameters") || line.include?("body parameters") || line.include?("body params") || line.include?("bodyparameters")
end

def extract_body_params line
  body_params = []
  line = line.to_s.sub('#','').strip
  line.split(',').each do |paramset|
    temp_hash = {}
    temp_hash["name"] = paramset.split(':')[0].strip
    if paramset.split(':')[1].strip.include? "array"
      temp_array_definition = paramset.split(':')[1].strip
      temp_hash["type"] = "array"
      temp_hash["items"] = { "type" => temp_array_definition[/\[(.+)\]/,1] }
    else
      temp_hash["type"] = paramset.split(':')[1].strip
    end
    paramset.split(':')[2]&.strip ? temp_hash["required"] = true : temp_hash["required"] = false   
    body_params << temp_hash
  end
  body_params
end

def generate_array_schema_internal(array_parameter, schema_name)
  path = "#/definitions/"
  schema = {}
  schema["type"] = "array"
  schema["items"] = { "type" => array_parameter[0]["items"]["type"] }

  ####### Should work this out!!
  final_schema = {}
  final_schema[schema_name] = schema
  if Service.check_duplicate_schema final_schema
    return Service.check_duplicate_schema final_schema
  else
    Service.add_to_global_schema final_schema
  end

  puts "output is: " , final_schema
  path + schema_name
end

def basic_datatypes? data_type
  data_type.casecmp("integer") || data_type.casecmp("string")
end

def existing_type? data_type
  # implement checking it

end

def get_schema_reference data_type
  # implement fetching schemas here
end

def generate_schema_internal(body_parameters_internal_array, schema_name)
  path = "#/definitions/"
  schema = {}
  schema["type"] = "object"
  temp_hash = {}
  required_array = []

  body_parameters_internal_array.each do |body_param|    
    if body_param["required"]
      required_array << body_param["name"]
    end

    if body_param["type"] == "array" # contains array, then
      # temp_hash[body_param["name"]] = { "$ref" => generate_array_schema_internal( [{ "name" => body_param["name"], "items" => body_param["items"]  }], body_param["name"] ) }
      if basic_datatypes? body_param["items"]["type"]
        temp_hash[body_param["name"]] = { "type" => "array", "items" => { "type" => body_param["items"]["type"]} }
      elsif existing_type? body_param["items"]["type"]
        temp_hash[body_param["name"]] = { "type" => "array", "items" => { "type" => get_schema_reference(body_param["items"]["type"]) } }
      else
        # create new schema
        #temp_hash[body_param["name"]] = { "$ref" => generate_array_schema_internal( [{ "name" => body_param["name"], "items" => body_param["items"]  }], body_param["name"] ) }
      end  
    else
      temp_hash[body_param["name"]] = 
                                  { 
                                    "type" => body_param["type"]
                                  }
    end
  end

  puts required_array.inspect
  required_array&.empty? ? false : schema["required"] = required_array 
  schema["properties"] = temp_hash
  final_schema = {}
  final_schema[schema_name] = schema
  if Service.check_duplicate_schema final_schema
    return Service.check_duplicate_schema final_schema
  else
    Service.add_to_global_schema final_schema
  end
  path + schema_name
end

def generate_parameter_internal s
  temp_array = []

  s.paramset&.each do |inline_param|
    temp_hash = {
      "name" => inline_param,
      "in" => "path",
      "required" => true,
      "type" => "string",
    }  
    temp_array << temp_hash
  end

  if (s.type == 1 || s.type == 3) && !s.body_params.nil? # only for post or put services only schema is defined externally, or else it is defined in response
    body_parameters_internal_array = []
   
    s.body_params&.each do |body_param|
      temp_hash = {}
      temp_hash["name"] = body_param["name"]
      temp_hash["in"] = "body"
      temp_hash["required"] = body_param["required"] || false
      temp_hash["type"] = body_param["type"]
      body_param["items"] ? temp_hash["items"] = body_param["items"] : true
      body_parameters_internal_array << temp_hash
    end

    body_param_object = {
      "in" => "body",
      "name" => "body",
      "description" => "parameters to be sent in request",
      "required" => true,
    }

    if s.type == 1 || s.type == 3 
      body_param_object["schema"] = { "$ref" => generate_schema_internal(body_parameters_internal_array, s.tag + s.id) }
    end
    temp_array << body_param_object
  end
  temp_array
end

def generate_response_internal service_obj
  temp_hash = {}
  service_obj.response_codes&.each do |code|  
    temp_hash = temp_hash.merge(code)
  end
  temp_hash
end

def generate_service_internal service_obj # TODO
  {
    "tags" => [service_obj.tag],
    "description" => service_obj.comment
  }
  temp_hash["tags"] = [ service_obj.tag ]
  temp_hash["summary"] =  service_obj.summary
  temp_hash["description"] = 
  temp_hash["consumes"] = %w[ application/json application/xml]
  temp_hash["produces"] = %w[ application/json application/xml]
  temp_hash["parameters"] = generate_parameter_internal service_obj
  temp_hash["responses"] = generate_response_internal service_obj
  temp_hash["deprecated"] = service_obj.deprecated ? true : false
end

def generate_path_internal services 
  temp_hash = {}
  services.each do |service_obj_loc| 
    service_obj = $services_array[service_obj_loc]
    temp_hash["#{service_obj.name}"] = generate_service_internal service_obj
  end
  temp_hash
end

def generate_internal tag_and_path_based_service_order
  paths_internal_json = {}
  tag_and_path_based_service_order.each do |_tag, path_array| 
    path_array.each { |path, services_array| paths_internal_json["#{path}"] = generate_path_internal services_array } 
  end
  paths_internal_json
end

def generate_security_definitions
  # still to code
  {
    "petstore_auth":
      {"type":"oauth2",
        "authorizationUrl":"http://petstore.swagger.io/oauth/dialog",
        "flow":"implicit",
        "scopes":
          {"write:pets":"modify pets in your account",
            "read:pets":"read your pets"
          }
      },
      "api_key":
        {"type":"apiKey","name":"api_key","in":"header"}
  }
  
end

def generate_definitions
  temp_hash = {}
  Service.schema_global.each do |schema|
    temp_hash = temp_hash.merge(schema)
  end
  puts "definitions: " ,temp_hash
  temp_hash
end


def create_json(title, host = "127.0.0.1", baseurl = "/", tag_and_path_based_service_order)
  js = 
    { 
      "swagger": "2.0",
      "info": {
        "description": "",
        "version": "1.0.0",
        "title": title,
        "termsOfService": "http://swagger.io/terms/",
        "license": {
            "name": "Apache 2.0",
            "url": "http://www.apache.org/licenses/LICENSE-2.0.html",
          },
        },
    }

  js["host"] = host
  js["basePath"] = baseurl
  js["tags"] = tag_array_creator Service.all_tags
  js["schemes"] = %w[ http ]
  js["paths"] = generate_internal(tag_and_path_based_service_order)
  js["securityDefinitions"] = generate_security_definitions 
  js["definitions"] = generate_definitions
  js.to_json
end

#**********************************************************

if ARGV.empty?
  puts "Error: Specify file location as argument"
else
  service_count = 0
  comment_accumulator = ""
  response_accumulator = []
  current_body_params = {}
  body_params_flag = false
  response_code_flag = false
  tag_and_path_based_service_order = {}
  $services_array = Array.new # Declare a global array for handling services objects created

  temp_location = '/Users/kedakarapu/copart/ycs-api-transporter-app/ycs-api/app/handlers/transporter_handler.rb'  #Reading the file line by line
  ARGV[0] ||= temp_location #for testing, considering a hard coded path
  title = extract_title ARGV[0] 

  # read line by line

  File.readlines(ARGV[0].to_s).each do |line|
    if single_commented? line #check if its commented
      case
      when line.include?("host") || line.include?("baseurl")
        capture_host_and_baseurl line
      when !body_params_flag && body_params?(line)
        body_params_flag = true
      when body_params_flag
        current_body_params = extract_body_params line
        body_params_flag = false
      when response_definition_toggle?(line)
        if response_code_flag
          response_code_flag = false
          $services_array[service_count-1].attach_response_codes response_accumulator
          response_accumulator = []
        else
          response_code_flag = true
        end
      when response_code_flag && extract_response_code(line) != ""
        response_accumulator << extract_response_code(line)
      else
        comment_accumulator += format_comment(line)
      end
    elsif hotword? line
      s = Service.new
      service_count = service_count + 1
      s.id = service_count.to_s
      s.attach_body_params current_body_params
      s.extraction line      
      s.comment = comment_accumulator
      s.summary = format_summary line
      s.deprecated = deprecated? s.summary
      comment_accumulator = ""
      $services_array.push(s)
      
      #format into order of json creation.
      
      if tagger(s.tag) #returns false if tag already exists
        tag_and_path_based_service_order[s.tag] = { s.path => [ service_count-1 ] }
      else
        #check if the path exists. If yes, add (service_count-1) to it, if not create one and add.
        if tag_and_path_based_service_order.has_key?(s.tag) && tag_and_path_based_service_order[s.tag].has_key?(s.path) 
          tag_and_path_based_service_order[s.tag][s.path] << (service_count - 1)
        else
          tag_and_path_based_service_order[s.tag][s.path] = [ service_count-1 ]
        end
      end
      s = nil
      current_body_params = nil      
    elsif double_commented? line
      $services_array[service_count-1].comment += format_internal_comment line
    end
  end  
end

#Generate json file
puts create_json(title, Service.host , Service.baseurl, tag_and_path_based_service_order)

#print the json into an output file



