module GenDocMethods

  def handler_tag? line
    line.include?("handler_tag")
  end

  def create_handler_tag handler
    newtag = handler.split('/').last.chomp('_handler.rb') || handler.split('/').last.chomp('handler.rb') || handler.split('/').last || "default"
  end

  def summary? line
    line.include?("summary")
  end

  def summary line
    line.sub("#","").split(":")[1]&.strip || line.sub("#","")
  end

  def group_description? line
    line.include?("group_description") 
  end

  def group_description line
    line.sub("#","").split(":")[1]&.strip || "Not provided"
  end

  def service_name? line
    line.include?("name")
  end

  def service_name line
    line.sub("#","").split(":")[1]&.strip
  end

  def service_description? line
    line.include?("description")
  end

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
    tags.each { |tag, desc| tag_array << { "name" =>  tag , "description" => desc} }
    tag_array
  end

  def generate_parameter_internal service_obj
    temp_array = []
    puts "this is now: " , service_obj.paramset.inspect
    # adding inline or path params
    service_obj.paramset.flatten!&.each do |inline_param|
      temp_hash = {
        "in" => "path",
        "name" => inline_param,       
        "required" => true,
        "type" => "string",
      }  
      temp_array << temp_hash
    end
    temp_array.concat service_obj.body_params
  end

  def generate_service_internal service_obj
    {
      "tags" => [service_obj.tag],
      "summary" => service_obj.summary,
      "description" => service_obj.service_description,
      "consumes" => %w[ application/json application/xml],
      "produces" => %w[ application/json application/xml],
      "parameters" => generate_parameter_internal(service_obj),
      "responses" => service_obj.response_codes,
      "deprecated" => service_obj.deprecated,
    }
  end

  def generate_path_internal(services_array, services)
    temp_hash = {}
    services.each do |service_obj_loc| 
      service_obj = services_array[service_obj_loc]
      temp_hash["#{service_obj.name}"] = generate_service_internal service_obj
    end
    temp_hash
  end

  def generate_internal(services_array, tag_and_path_based_service_order)
    paths_internal_json = {}
    tag_and_path_based_service_order.each do |_tag, path_array| 
      path_array.each { |path, services| paths_internal_json["#{path}"] = generate_path_internal(services_array, services) } 
    end
    paths_internal_json
  end

  def generate_security_definitions  # still to code
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
    temp_hash
  end

  def design_json(title, host, baseurl, all_tags, services_array)
    title = "project name"
    # sort services_array, to get tag_and_path_based_service_order
    tag_and_path_based_service_order = {}    
    all_tags.each do |tag|
      service_count = 0
      services_array.each do |service|       
        #check if the path exists. If yes, add (service_count-1) to it, if not create one and add.
        if service.tag == tag
          if tag_and_path_based_service_order.has_key?(tag) && tag_and_path_based_service_order[tag].has_key?(service.path)
            tag_and_path_based_service_order[tag][service.path] << service_count
          elsif !tag_and_path_based_service_order.has_key?(tag)
            tag_and_path_based_service_order[tag] = { service.path => [ service_count ] }
          end
        end
        service_count += 1     
      end
    end
    create_json(title, host, baseurl, services_array, tag_and_path_based_service_order)
  end

  def create_json(title, host = "127.0.0.1", baseurl = "/", services_array, tag_and_path_based_service_order)
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
    # can not add above, as it is of => format and above its : format. its better this way.
    js["host"] = host
    js["basePath"] = baseurl
    js["tags"] = tag_array_creator Service.group_description
    js["schemes"] = %w[ http ]
    js["paths"] = generate_internal(services_array, tag_and_path_based_service_order)
    js["securityDefinitions"] = generate_security_definitions 
    js["definitions"] = Service.schema_global
    js.to_json
  end
end