#swagger_ui_documenter
Using swagger_ui to feed a custom json

<a href="#newversion"><h2>Go to New Version</h2></a>

<div>
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

</div>

<h2 id="newversion">Example format: [New Version] - Note: Undergoing Changes</h2>

This file would be an extract from inside a ycs-api project.

path : ycs-api/app/handlers/FooHandler.rb 

```
  class Ycs::FooHandler < Boo
    
    # group_description: used to do this and that task use -d in description to flag as deprecated

    # TODO:  - this won't be in description

    # name: has to be a unique name for service
    # summary:  sample_name use -d anywhere in this line to make it deprecated
    # description: sample_description
    #
    # multiple line description
    #
  
    post '/lots/accept' do
      return_errors(lots: I18n.t('common.errors.required')) unless params[:lots] && params[:lots].is_a?(Array) 
      params[:lots].each { |number| Ycs::Transporter::UpdateLot.accepted(number) } ## double hashes for internal comments
      { status: 'success' }.to_json
    end
  

```

The corresponding files for given service ```post '/lots/accept'``` will be stored in 

path : ycs-api/spec/foo/sample_name/ 

In this folder, we need to have 

  (for get/delete, only query parameters are included in payload)
 - <a href="#response">response.json</a>


 error.json
 response.json
 - <a href="#request">request.json</a>
 header.json
 query.json


<h4 id="request">Inside request.json:</h4>

The paramters passed through path, like ```lots/get_lot_status/:lot_id```
Here, {lot_id} is passed through path, it is defaultly considered as a string.
Note : Path parameters need NOT be included in the payload

query parameters have to be included in the query. 
All body parameters should also be included in the request

request.json

```
{
    
   "simple_example" : { 

        "description" : "simple description",
        "required" : true,
        "type" : "string"
        },

    "another_example" : {

        "description" : "lot object that needs to be added to the store",
        "required" : true,
            
        "schema" : {
            "$ref":"#/definitions/Lot_schema" 
            }
        }
}

```



<h4 id="response">Inside response.rb:</h4>

There should be a model of response.  

```
  class Response
    @@response_codes = {
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
      
    @@ref_schema = {
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


    def self.response_codes
      @@response_codes
    end

    def self.ref_schema
      @@ref_schema
    end
  end

```





errors.json

Example:

```

{
    "200": {
          "description": "success! a lot number to be returned",        
         },

    "405": {
          "description": "invalid input",
          },
}

```










