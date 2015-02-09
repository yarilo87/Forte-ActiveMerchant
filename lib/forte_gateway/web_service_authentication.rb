require 'savon'

module ForteGateway
	class WebServiceAuthentication
		TEST_URL = "https://sandbox.paymentsgateway.net/WS/Client.wsdl"
        LIVE_URL = "https://ws.paymentsgateway.net/Service/v1/Client.wsdl"

        CARD_TYPES = {visa: "VISA", master: "MAST", american_express: "AMER", discover: "DISC", diners_club: "DINE", jcb: "JCB"}
        E_CHECK_TYPES = {checking: "CHECKING", savings: "SAVINGS"}

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
			now = time_in_ticks.to_s
			message = {"ticket" => get_client_auth_ticket(now), "client" => client}
			perform_soap_request __callee__, message
		end

		def update_client options = {}
			client = {
				"MerchantID" =>  @merchant_id,
				"ClientID" => options[:client_id],
				"FirstName" => options[:first_name],
				"LastName" => options[:last_name]
			}
			now = time_in_ticks.to_s
			message = {"ticket" => get_client_auth_ticket(now), "client" => client}
			perform_soap_request __callee__, message
		end

		def delete_client options = {}
			now = time_in_ticks.to_s
			message = {"ticket" => get_client_auth_ticket(now),  "MerchantID" =>  @merchant_id, "ClientID" => options[:client_id]}
			perform_soap_request __callee__, message
		end

		def get_client options = {}
			now = time_in_ticks.to_s
			message = {"ticket" => get_client_auth_ticket(now), "MerchantID" =>  @merchant_id, "ClientID" => options[:client_id]}
			perform_soap_request __callee__, message
		end

		def create_payment_method options = {}
			if options[:payment_type] == 'credit_card'
				payment = add_credit_card options
			else
				payment = add_e_check options
			end
			now = time_in_ticks.to_s
			message = {"ticket" => get_client_auth_ticket(now), "payment" =>  payment}
			perform_soap_request __callee__, message
		end

		# update_payment_method updates payment details

		# for credit card payment, credit card number cannot be updated
		# for eCheck payment,eCheck account number and account TRN cannot be updated

		def update_payment_method options = {}
			if options[:payment_type] == 'credit_card'
				payment = add_credit_card options
			else
				payment = add_e_check options
			end
			now = time_in_ticks.to_s
			message = {"ticket" => get_client_auth_ticket(now), "payment" =>  payment}
			perform_soap_request __callee__, message
		end

		def delete_payment_method options = {}
			now = time_in_ticks.to_s
			message = {"ticket" => get_client_auth_ticket(now), "MerchantID" =>  @merchant_id, "ClientID" => options[:client_id],  "PaymentMethodID" =>  options[:payment_method_id]}
			perform_soap_request __callee__, message
		end

		def get_payment_method options = {}
			now = time_in_ticks.to_s
			message = {"ticket" => get_client_auth_ticket(now), "MerchantID" =>  @merchant_id, "ClientID" => options[:client_id],  "PaymentMethodID" =>  options[:payment_method_id]}
			perform_soap_request __callee__, message
		end

		private

		def perform_soap_request method, message
			soap_client = Savon.client(wsdl: @output_url)
			response = soap_client.call(method) do |locals|
				locals.message message
			end
			response.body
		rescue Savon::SOAPFault => error
			error.to_hash
		end

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
			payment = {
				"MerchantID" =>  @merchant_id,
				"ClientID" => options[:client_id],
			}
			payment["PaymentMethodID"] = options[:payment_method_id] if options[:payment_method_id]
			payment["AcctHolderName"] = options[:acct_holder_name] if options[:acct_holder_name]
			payment["EcAccountNumber"] = options[:ecom_payment_check_account] if options[:ecom_payment_check_account]
			payment["EcAccountTRN"] = options[:ecom_payment_check_trn] if options[:ecom_payment_check_trn]
			payment["EcAccountType"] = E_CHECK_TYPES[options[:ecom_payment_check_account_type]] if options[:ecom_payment_check_account_type]
			payment
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
			payment["CcCardType"] = CARD_TYPES[options[:cc_card_type]] if options[:cc_card_type]
			payment["Note"] = options[:note] if options[:note]
			payment
		end
	end
end
