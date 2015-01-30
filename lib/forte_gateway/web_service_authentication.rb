require 'savon'
require 'hmac-md5'

module ForteGateway
	class WebServiceAuthentication
		TEST_URL = "https://sandbox.paymentsgateway.net/WS/Client.wsdl"
        LOCATION = "https://sandbox.paymentsgateway.net/WS/Client.svc"

        def initialize(merchant_id = '171673', api_login_id = 'F3cnU00H5s', secure_transaction_key= 'p48iJT4oB', test = true)
        	@api_login_id           = api_login_id
        	@merchant_id = merchant_id
        	@secure_transaction_key = secure_transaction_key
        	@output_url = test ? TEST_URL : LIVE_URL
    	end

	    def commit options = {}
	        customer = customer options
			client = Savon.client(wsdl: @output_url)
			response = client.call(:create_client) do |locals|
				locals.message "ticket" => get_client_auth_ticket, "client" => customer
			end
		end

	    def get_client_auth_ticket
	    	{
	    		"APILoginID" => @api_login_id,
            	"TSHash" => HMAC::MD5.new(@api_login_id + "|" + @secure_transaction_key).hexdigest,
            	"UTCTime" => time_in_ticks
	    	}
	    end

	    def customer(options = {})
	    	{
	    		"MerchantID" =>  @merchant_id,
	    		"FirstName" => "Bob",
	    		"LastName" => "Smith"
	    	}
	    end

	    def time_in_ticks
	    	ticks_since_epoch = Time.utc(0001,01,01).to_i * 10000000
	    	Time.now.to_i * 10000000 + Time.now.nsec / 100 - ticks_since_epoch
	    end

	end
end
