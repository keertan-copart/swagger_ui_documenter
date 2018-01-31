require 'rubygems'
require 'json'
require 'swagger/blocks'



class Service
  include Swagger::Blocks

  @@hotwords = %w[POST post get GET put PUT DELETE delete ]
  @@baseurl = ""
  @@all_tags = %w[]

  attr_reader :name, :tag, :comment, :paramset, :path, :name, :type, :status, :param_flag


  def intialize(default_name="post", type = 0, status = 1, param_flag = false, paramset = %w[], default_comment = "", tag = "/")
    @name = default_name
    @tag = tag
    @type = type
    @path = "/"
    @status = status
    @param_flag = param_flag
    @paramset = default_params
    @comment = default_comment
    @testing_lotno = 12345
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


  def self.baseurl=(url)
    @@baseurl = url
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

  def self.all_tags
    @@all_tags
  end

  def comment=(extracted_comment)
    @comment = extracted_comment
  end

  
end
# end of class!

#Independent functions

def hotword?(line)
  /(post|POST|get|GET|DELETE|delete|put|PUT)\s(.*)/.match(line)
end


def commented?(line)
  temp = line.lstrip
  temp[0] == '#'? true : false
     
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
#**********************************************************


# get service_handler file location, implementation using parameter pending...




# read line by line


if ARGV.empty?
  puts "Error: Specify file location as argument"
else
  Service.baseurl = "hello/sample"
  service_count = 0
  temp_comment = ""
  tag_and_path_based_service_order = {}
  services_array = Array.new 

  temp_location = '/Users/kedakarapu/copart/ycs-api-transporter-app/ycs-api/app/handlers/transporter_handler.rb'  #Reading the file line by line
  File.readlines(ARGV[0].to_s).each do |line|
    if commented? line #check if its commented
      temp_comment += line
    elsif hotword? line
      s = Service.new
      service_count = service_count + 1
      s.extract_service_from_line line
      s.extract_path_from_line line
      s.extract_params
      temp_tag = s.extract_tag
      temp_path = s.format_path.to_s
      s.comment = (temp_comment + line[/[#](.)\1/].to_s)
        
      #format into order of json creation.



      if tagger(s.tag) #returns false if tag already exists
        tag_and_path_based_service_order[temp_tag] = { temp_path => [service_count-1]}
      else
        #check if the path exists. If yes, add (service_count-1) to it, if not create one and add.
        if tag_and_path_based_service_order.has_key?(temp_tag) && tag_and_path_based_service_order[temp_tag].has_key?(temp_path) 
          tag_and_path_based_service_order[temp_tag][temp_path] << service_count
        else
          tag_and_path_based_service_order[temp_tag][temp_path] = [service_count-1]
        end
      end

      services_array.push(s)
      s = nil
      
    end
  end
  
  puts service_count.to_s + " Routes Discovered"

end

Service.all_tags.sort!


# we need to have our services in the order of path and tags. 

#Service.all_tags.each do |tag|
#  puts tag 
#  services_array.each do |service_obj|
#      if service_obj.tag == tag
#        print "\t" + service_obj.path, service_obj.name + "\n"
#      end
#  end
#end

puts tag_and_path_based_service_order.inspect




#Generate json file

describe 'Swagger::Blocks v2' do
  describe 'build_json' do
    it 'outputs the correct data' do
      swaggered_classes = [
        PetControllerV2,
        PetV2,
        ErrorModelV2
      ]
      actual = Swagger::Blocks.build_root_json(swaggered_classes)
      actual = JSON.parse(actual.to_json)  # For access consistency.
      data = JSON.parse(RESOURCE_LISTING_JSON_V2)

      # Multiple expectations for better test diff output.
      expect(actual['info']).to eq(data['info'])
      expect(actual['paths']).to be
      expect(actual['paths']['/pets']).to be
      expect(actual['paths']['/pets']).to eq(data['paths']['/pets'])
      expect(actual['paths']['/pets/{id}']).to be
      expect(actual['paths']['/pets/{id}']['get']).to be
      expect(actual['paths']['/pets/{id}']['get']).to eq(data['paths']['/pets/{id}']['get'])
      expect(actual['paths']).to eq(data['paths'])
      expect(actual['definitions']).to eq(data['definitions'])
      expect(actual).to eq(data)
    end
    it 'is idempotent' do
      swaggered_classes = [PetControllerV2, PetV2, ErrorModelV2]
      actual = JSON.parse(Swagger::Blocks.build_root_json(swaggered_classes).to_json)
      data = JSON.parse(RESOURCE_LISTING_JSON_V2)
      expect(actual).to eq(data)
    end
    it 'errors if no swagger_root is declared' do
      expect {
        Swagger::Blocks.build_root_json([])
      }.to raise_error(Swagger::Blocks::DeclarationError)
    end
    it 'errors if mulitple swagger_roots are declared' do
      expect {
        Swagger::Blocks.build_root_json([PetControllerV2, PetControllerV2])
      }.to raise_error(Swagger::Blocks::DeclarationError)
    end
  end
end

