require 'pry'
require 'json'
require_relative "service.rb"
require_relative "gen_doc_methods.rb"

include GenDocMethods

task :default => :test

desc 'check working!'
task :test do
  puts "testing from Rake!"
end

namespace 'doc' do
  def fetch_spec(service_obj, path_to_spec_files)  # gets all spec information and adds to the service object
    # Comment
  end 

  def fetch_services handler
    services_found = []
    service_description_flag = false
    handler_tag = GenDocMethods.create_handler_tag(handler)
    service_name = ""
    group_description = ""
    service_description = ""
    summary = ""
    # iterate line by line, check for hotwords and call methods to extract data. create service objects, and attach them to services_found
    File.readlines(handler).each do |line|
      if GenDocMethods.single_commented? line #check if its commented
        #check for group description 
        group_description = GenDocMethods.group_description(line) if GenDocMethods.group_description?(line)        
        service_name = GenDocMethods.service_name(line) if GenDocMethods.service_name?(line)
        summary = GenDocMethods.summary(line) if GenDocMethods.summary?(line)
        if !service_description_flag && GenDocMethods.service_description?(line)
          service_description_flag = true
        elsif service_description_flag
          service_description += GenDocMethods.format_comment line
        end
      elsif hotword? line
        service_name = "default" if service_name.empty?
        summary = "default" if summary.empty?
        service_description = "Not provided" if service_description.empty?        
        group_description = "Not provided" if group_description.empty?
        s = Service.new(service_name, summary, handler_tag, service_description, GenDocMethods.deprecated?(service_description))     #TODO   
        s.extraction line
        s.add_tag(handler_tag, group_description)       
        s.attach_body_params  
        s.attach_response_codes 
        services_found << s
        service_description = ""
        service_description_flag = false
      end
    end 
    services_found
  end

  def extract_title

  end

  desc 'generates documentation'
  task :generate do
    puts "processing documents"
    services_collection = []
    Dir["./../app/handlers/*.rb"].each do |handler|
      print "."
      services_collection = services_collection.concat fetch_services(handler)
    end
    title = extract_title
    host = "0.0.0.0:9292"
    baseurl = "/transporter"
    all_tags = Service.group_description.keys
    json_created = GenDocMethods.design_json(title, host, baseurl, all_tags, services_collection)
    puts json_created
  end

end

