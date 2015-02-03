require 'savon'

module ForteGateway
	class WebServiceAuthentication
		TEST_URL = "https://sandbox.paymentsgateway.net/WS/Client.wsdl"
        LIVE_URL = "https://ws.paymentsgateway.net/Service/v1/Client.wsdl"

        def initialize(merchant_id = '171673', api_login_id = 'F3cnU00H5s', secure_transaction_key= 'Q870agdTS', test = true)
        	@api_login_id           = api_login_id
        	@merchant_id = merchant_id
        	@secure_transaction_key = secure_transaction_key
        	@output_url = test ? TEST_URL : LIVE_URL
    	end

	    def create_client options = {}
			client = {
				"MerchantID" =>  @merchant_id,
				"FirstName" => options[:first_name],
				"LastName" => options[:last_name]
			}
			soap_client = Savon.client(wsdl: @output_url)
			now = time_in_ticks.to_s
			response = soap_client.call(:create_client) do |locals|
				locals.message "ticket" => get_client_auth_ticket(now), "client" => client
			end
			response.body
		rescue Savon::SOAPFault => error
			error.to_hash
		end

		def update_client options = {}
			client = {
				"MerchantID" =>  @merchant_id,
				"ClientID" => options[:client_id],
				"FirstName" => options[:first_name],
				"LastName" => options[:last_name]
			}
			soap_client = Savon.client(wsdl: @output_url)
			now = time_in_ticks.to_s
			response = soap_client.call(:update_client) do |locals|
				locals.message "ticket" => get_client_auth_ticket(now),"client" => client
			end
			response.body
		rescue Savon::SOAPFault => error
			error.to_hash
		end

		def delete_client options = {}
			soap_client = Savon.client(wsdl: @output_url)
			now = time_in_ticks.to_s
			response = soap_client.call(:delete_client) do |locals|
				locals.message "ticket" => get_client_auth_ticket(now),  "MerchantID" =>  @merchant_id, "ClientID" => options[:client_id]
			end
			response.body
		rescue Savon::SOAPFault => error
			error.to_hash
		end

		def get_client options = {}
			soap_client = Savon.client(wsdl: @output_url)
			now = time_in_ticks.to_s
			response = soap_client.call(:get_client) do |locals|
				locals.message "ticket" => get_client_auth_ticket(now), "MerchantID" =>  @merchant_id, "ClientID" => options[:client_id]
			end
			response.body
		rescue Savon::SOAPFault => error
			error.to_hash
		end

		def create_payment_method options = {}
			if options[:payment_type] == 'credit_card'
				payment = add_credit_card options
			else
				payment = add_e_check options
			end
			soap_client = Savon.client(wsdl: @output_url)
			now = time_in_ticks.to_s
			response = soap_client.call(:create_payment_method) do |locals|
				locals.message "ticket" => get_client_auth_ticket(now), "payment" =>  payment
			end
			response.body
		rescue Savon::SOAPFault => error
			error.to_hash
		end

		def update_payment_method options = {}
			if options[:payment_type] == 'credit_card'
				payment = add_credit_card options
			else
				payment = add_e_check options
			end
			soap_client = Savon.client(wsdl: @output_url)
			now = time_in_ticks.to_s
			response = soap_client.call(:update_payment_method) do |locals|
				locals.message "ticket" => get_client_auth_ticket(now), "payment" =>  payment
			end
			response.body
		rescue Savon::SOAPFault => error
			error.to_hash
		end

		def delete_payment_method options = {}
			soap_client = Savon.client(wsdl: @output_url)
			now = time_in_ticks.to_s
			response = soap_client.call(:delete_payment_method) do |locals|
				locals.message "ticket" => get_client_auth_ticket(now), "MerchantID" =>  @merchant_id, "ClientID" => options[:client_id],  "PaymentMethodID" =>  options[:payment_method_id]
			end
			response.body
		rescue Savon::SOAPFault => error
			error.to_hash
		end

		def get_payment_method options = {}
			soap_client = Savon.client(wsdl: @output_url)
			now = time_in_ticks.to_s
			response = soap_client.call(:get_payment_method) do |locals|
				locals.message "ticket" => get_client_auth_ticket(now), "MerchantID" =>  @merchant_id, "ClientID" => options[:client_id],  "PaymentMethodID" =>  options[:payment_method_id]
			end
			response.body
		rescue Savon::SOAPFault => error
			error.to_hash
		end

		private

	    def get_client_auth_ticket now
			key = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new("md5"),@secure_transaction_key, @api_login_id + "|" + now)
			{
				"APILoginID" => @api_login_id,
				"TSHash" =>  key,
				"UTCTime" => now
			}
	    end

	    def time_in_ticks
	    	ticks_since_epoch = Time.utc(0001,01,01).to_i * 10000000
	    	Time.now.to_i * 10000000 + Time.now.nsec / 100 - ticks_since_epoch
	    end

	    def add_e_check options = {}
			{
				"MerchantID" =>  @merchant_id,
				"ClientID" => options[:client_id],
				"AcctHolderName" => options[:acct_holder_name],
				"EcAccountNumber" => options[:ecom_payment_check_account],
				"EcAccountTRN" => options[:ecom_payment_check_trn],
				"EcAccountType" => options[:ecom_payment_check_account_type]
			}
	    end

	    def add_credit_card options = {}
			payment = {
				"MerchantID" =>  @merchant_id,
				"ClientID" => options[:client_id]
			}
			payment["PaymentMethodID"] = options[:payment_method_id] if options[:payment_method_id]
			payment["AcctHolderName"] = options[:acct_holder_name]
			payment["CcCardNumber"] = options[:cc_card_numbed] if options[:cc_card_numbed]
			payment["CcExpirationDate"] = options[:cc_expiration_date] if options[:cc_expiration_date]
			payment["CcCardType"] = options[:cc_card_type] if options[:cc_card_type]
			payment["Note"] = options[:note] if options[:note]
			payment
		end
	end
end
