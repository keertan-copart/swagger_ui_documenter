#swagger_ui_documenter
Using swagger_ui to feed a custom json


```

  Service Name :: Type
  post              1
  get               2
  put               3
  delete            4


```


Example format: [OLD Version]

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

Example format: [New Version]

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
	< single line/ multiple line gap >
	#-
	# 200 :  success!
	# 405 :  error
	# <further codes>
	#-

```

The corresponding files for given service ```post '/lots/accept'``` will be stored in 

path : ycs-api/app/spec/FooHandler/sample_name/ 

In this folder, we need to have 

 - query.rb
 - payload.rb  (type = get, does not need to have this.) 
 - response.rb

Inside query.rb:

	Initial thought are to have a hash
	like: name : string
		  lot : integer


Inside payload.rb:

Inside response.rb:

There should be a model of response 
```
	{
		code : int
		status : string
		... 
	}
	
```










