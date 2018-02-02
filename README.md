# swagger_ui_documenter
Using swagger_ui to feed a custom json


```

  Service Name :: Type
  post              1
  get               2
  put               3
  delete            4
  

```


Example format: 

```
	 #body parameters - the next line should follow with parameters in given format, and this line should contain 'body parameters'
	 # name : Array, lot : string
	 post '/lots/accept' do # used for accept lot information (Summary)  
	    return_errors(lots: I18n.t('common.errors.required')) unless params[:lots] && params[:lots].is_a?(Array) 
	    params[:lots].each { |number| Ycs::Transporter::UpdateLot.accepted(number) } ## double hashes for internal comments
	    { status: 'success' }.to_json
	  end

	  # Anything written before the next service will be added to its description 

	 post '/lots/reject' do #writing summary here is unknown to aliens # in summary just include -d to make it depricated
	   return_errors(lots: I18n.t('common.errors.required')) unless params[:lots] && params[:lots].is_a?(Array)
	   params[:lots].each { |number| Ycs::Transporter::UpdateLot.rejected(number) }
	   { status: 'success' }.to_json
	  end

```