#swagger_ui_documenter
Using swagger_ui to feed a custom json

<a href="#newversion">Goto New Version</a>


Example format: [OLD Version]

```

  Service Name :: Type
  post              1
  get               2
  put               3
  delete            4


```


```
  #host = '0.0.0.0:9292'
    #baseurl = '/transporter'

    #body parameters  - the next line should follow with parameters in given format, and this line should contain 'body parameters'
    # lots : array[string] : required, something : integer
  post '/lots/accept' do # used for accept lot information (Summary)  
    return_errors(lots: I18n.t('common.errors.required')) unless params[:lots] && params[:lots].is_a?(Array) 
    params[:lots].each { |number| Ycs::Transporter::UpdateLot.accepted(number) } ## double hashes for internal comments
    { status: 'success' }.to_json
  end

  #-
  #200 :  success!
  #405 :  error
  #
  #.... further codes..
  #
  #-

  # Anything written in single comment before the next service will be added to its description 

  post '/lots/reject' do #writing summary here is unknown to aliens # in summary just include -d to make it depricated
   return_errors(lots: I18n.t('common.errors.required')) unless params[:lots] && params[:lots].is_a?(Array)
   params[:lots].each { |number| Ycs::Transporter::UpdateLot.rejected(number) }
   { status: 'success' }.to_json
  end




```



<h4 id="#newversion">Example format: [New Version]</h4>

This file would be an extract from inside a ycs-api project.

path : ycs-api/app/handlers/FooHandler.rb 

```
  class Ycs::FooHandler < Boo
  # name : The Foo Module
  # description : used to do this and that task

    # service_name :  sample_name
    # service_description : sample_description
    #
    #<multiple line description supported> 
    #
  < single line/ multiple line gap >
  post '/lots/accept' do 
    return_errors(lots: I18n.t('common.errors.required')) unless params[:lots] && params[:lots].is_a?(Array) 
    params[:lots].each { |number| Ycs::Transporter::UpdateLot.accepted(number) } ## double hashes for internal comments
    { status: 'success' }.to_json
  end
  

```

The corresponding files for given service ```post '/lots/accept'``` will be stored in 

path : ycs-api/spec/foo/sample_name/ 

In this folder, we need to have 

 - <a href="#payload">payload.rb</a> (for get/delete, only query parameters are included in payload)
 - <a href="#response">response.rb </a>


<h4 id="#payload">Inside payload.rb:</h4>

The paramters passed through path, like ```lots/get_lot_status/:lot_id```
Here, {lot_id} is passed through path, it is defaultly considered as a string.
Note : Path parameters need NOT be included in the payload

if you have something like ```lots/get_lots_by_filter/filters```
and you have to pass an array of all filters applied, then it is considered as query parameter.

query parameters have to be included in the payload. 
All body parameters should also be included in the payload

```
class Payload
  cattr_accessor :pay_load, :ref_schema  # payload is an array of hashes, and ref_schema is a hash

  def initialize

    pay_load = [  # array of hashes
      
      {
        "name" => "simple_example",
        "in" => "body",
        "description" => "simple description",
        "required" => true,
        "type" => "string"
        },

      { 
        "name" => "status",
        "in" => "query", # if this data should be sent in the query; note: the path variables are not needed to be included in payload.
        "description" => "Status values that need to be considered for filter",
        "required" => true,  # assign false if not a required parameter
        "type" => "array", # if type is array, then items have to be defined, or else not needed.
        "items" => {
            "type" => "string",
            "enum" => ["available","pending","sold"],  # if enum, else not required; Note: notice its an array of possible values
            "default" => "available" # if an enum, then default is needed.
          }
        },

      {
        "name" => "body",
        "in" => "body",        
        "description" => "Pet object that needs to be added to the store",
        "required" => true,
            
        # if the data to be sent is of a particular format, defined already then add a reference to it.
        # or if you want to define a custom format, define it in ref_schema. see 'Inside response.rb' for more details on format

        "schema" =>{
            "$ref":"#/definitions/Category"  # this Category is already defined in your project
          }
        }
    ]

    ref_schema = {
      # for details on ref_schema, go down and see 'Inside response.rb'
      }
  end
end


```



<h4 id="#response">Inside response.rb:</h4>

There should be a model of response.  
```
  class Response
    cattr_accesor :response_codes, :ref_schema  # here, response_codes and ref_schema are required hashes. 

    def initialize
      response_codes = {
        "200" => {
            "description" => "a lot number to be returned",
              # if the response does not have a return value, you need not include the content
              "content" => {
                 "application/json" => {
                   "schema" => {
                      "type" => "string"  # if the return type of response is a string
                      "type" => "integer" # if the return type of response is an integer

                      # if type is an array, then

                      "type" => "array"
                      "items" => {
                        "type" => "string"
                       }

                      # if the return type has a specific schema(say, Lot_schema) that you want to define, then 

                      "$ref"=> "#/definitions/Lot_schema" # custom schemas should start with a capitalized letter

                      # Now, you need to add a lot_schema hash also that defines this reference
                      # if, you have already defined this schema before, then simply give the reference.
                      # Make, sure the names you use for the schema matches the one you used before.
                    }
                  }
                }
              },

        "405" => {
          "description" => "invalid input"
          },

        "default": {
           "description": "Unexpected error",
          }
            
      }
    
      # if there are no references to any schema, then you can define an empty hash.
      
      ref_schema = {
        # for simple schema: 
          
        "Lot_schema" => {
          "type" => "integer",
          "format" => "int64" # not compulsory
        },

        # if your schema is complex, then you can also add references inside: 

        "Yard_member" =>{
          "type" => "object",
          "required" => ["name"], # not compulsory
          "properties" => {
            "id" => {
              "type" => "integer",
              "format":"int64"
              },
            "category" => {
              "$ref":"#/definitions/Category" # this Category is already defined, or may be defined in the same hash along with Yard_member
            },
            "name" => {
              "type" => "string",
              "example" => "doggie"
              }
            }
          }
      }

    end
  end

```











