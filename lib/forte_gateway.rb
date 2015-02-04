require 'net/http'
require "uri"
require 'active_merchant'

module ForteGateway

  class Forte

    TEST_URL = "https://www.paymentsgateway.net/cgi-bin/posttest.pl"
    LIVE_URL = "https://www.paymentsgateway.net/cgi-bin/postauth.pl"

    TRANSACTIONS_TYPES = {sale: 10, authorize: 11, capture: 12, credit: 13, void: 14, pre_auth: 15, balance_inquiry: 16}

    attr_accessor :api_login_id,
                  :secure_transaction_key

    RECURRING_TRANSACTION_FREQUENCIES = {
        weekly: 10, # every seven days
        biweekly: 15, # every fourteen days
        monthly: 20, # same day every month
        bi_monthly: 25, # every two months
        quarterly: 30, # every 3 months
        semiannually: 35, # twice a year
        yearly: 40 # once a year
    }

    def initialize(api_login_id = '171673', secure_transaction_key= 'p48iJT4oB', test = true)
        @api_login_id           = api_login_id
        @secure_transaction_key = secure_transaction_key
        @output_url = test ? TEST_URL : LIVE_URL
    end

    # transaction_type 10

    def purchase(amount, payment, options={})
        payment_fields = {}
        if payment[:pg_client_id] || payment[:pg_payment_method_id]
            payment_fields[:pg_client_id] = payment[:pg_client_id] if payment[:pg_client_id]
            payment_fields[:pg_payment_method_id] = payment[:pg_payment_method_id] if payment[:pg_payment_method_id]
        else
            payment_fields = add_credit_card credit_card(payment)
        end
        payment_fields.merge! add_user_fields(amount, options)
        data = message fields_merge(payment_fields, TRANSACTIONS_TYPES[:sale])
        commit data
    end

    # transaction_type 11

    def authorize(amount, payment, options={})
        payment_fields = {}
        if payment[:pg_client_id] || payment[:pg_payment_method_id]
            payment_fields[:pg_client_id] = payment[:pg_client_id] if payment[:pg_client_id]
            payment_fields[:pg_payment_method_id] = payment[:pg_payment_method_id] if payment[:pg_payment_method_id]
        else
            payment_fields = add_credit_card credit_card(payment)
        end
        payment_fields.merge! add_user_fields(amount, options)
        data = message fields_merge(payment_fields, TRANSACTIONS_TYPES[:authorize])
        commit data
    end

    # transaction_type 12

    def capture(amount, pg_authorization_code, pg_trace_number)
        capture_fields = {
            pg_original_authorization_code: pg_authorization_code,
            pg_original_trace_number: pg_trace_number
        }
        data = message fields_merge(capture_fields, TRANSACTIONS_TYPES[:capture])
        commit data
    end

    # transaction_type 13

    def credit(amount, payment, options={})
        payment_fields = {}
        if payment[:pg_client_id] || payment[:pg_payment_method_id]
            payment_fields[:pg_client_id] = payment[:pg_client_id] if payment[:pg_client_id]
            payment_fields[:pg_payment_method_id] = payment[:pg_payment_method_id] if payment[:pg_payment_method_id]
        else
            payment_fields = add_credit_card credit_card(payment)
        end
        payment_fields.merge! add_user_fields(amount, options)
        data = message fields_merge(payment_fields, TRANSACTIONS_TYPES[:credit])
        commit data
    end

    # transaction_type 14

    def void(pg_authorization_code, pg_trace_number)
        void_fields = {
            pg_original_authorization_code: pg_authorization_code,
            pg_original_trace_number: pg_trace_number
        }
        data = message fields_merge(void_fields, TRANSACTIONS_TYPES[:void])
        commit data
    end

    # transaction_type 15

    def pre_auth(amount, pg_authorization_code, payment, options={})
        payment_fields = {}
        if payment[:pg_client_id] || payment[:pg_payment_method_id]
            payment_fields[:pg_client_id] = payment[:pg_client_id] if payment[:pg_client_id]
            payment_fields[:pg_payment_method_id] = payment[:pg_payment_method_id] if payment[:pg_payment_method_id]
        else
            payment_fields = add_credit_card credit_card(payment)
        end
        payment_fields[:pg_original_authorization_code] = pg_authorization_code
        payment_fields.merge! add_user_fields(amount, options)
        data = message fields_merge(payment_fields, TRANSACTIONS_TYPES[:pre_auth])
        commit data
    end

    # transaction_type 16

    def balance_inquiry(options={})

    end

    def recurring_transaction(amount, frequency, quantity, payment, options={})
        payment_fields = {}
        if payment[:pg_client_id] || payment[:pg_payment_method_id]
            payment_fields[:pg_client_id] = payment[:pg_client_id] if payment[:pg_client_id]
            payment_fields[:pg_payment_method_id] = payment[:pg_payment_method_id] if payment[:pg_payment_method_id]
        else
            payment_fields = add_credit_card credit_card(payment)
        end
        payment_fields[:pg_schedule_frequency] = RECURRING_TRANSACTION_FREQUENCIES[frequency]
        payment_fields[:pg_schedule_quantity] = quantity
        payment_fields.merge! add_user_fields(amount, options)
        data = message fields_merge(payment_fields, TRANSACTIONS_TYPES[:sale])
        commit data
    end

    private

    def commit data
        uri = URI(@output_url)
        url = URI.parse(@output_url)
        request = Net::HTTP::Post.new(url.path)
        request.body = data
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.read_timeout = 500
        response_hash = {}
        http.start do |http|
            response = http.request request
            response_hash = response_to_hash(response.body)
        end
        response_hash
    end

    def message fields
        message = ''
        fields.each do |key, value|
            message += "#{key}=#{value}&"
        end
        message += 'endofdata&'
    end

    def response_to_hash response_message
        response_hash = {}
        response_message.slice! "endofdata"
        data_lines = response_message.split("\n")
        data_lines.each do |data_line|
            key_and_value = data_line.split("=")
            response_hash[:"#{key_and_value[0]}"] = key_and_value[1]
        end
        response_hash
    end

    def required_fields
        {pg_merchant_id: @api_login_id, pg_password: @secure_transaction_key}
    end

    def add_user_fields amount, options
        user_fields_hash = {}
        user_fields_hash[:pg_total_amount] = amount
        options.each do |key, value|
            user_fields_hash[key] = value
        end
        user_fields_hash
    end

    def add_credit_card credit_card
        {
            ecom_payment_card_type: credit_card.brand,
            ecom_payment_card_number: credit_card.number,
            ecom_payment_card_expdate_month: credit_card.month,
            ecom_payment_card_expdate_year: credit_card.year
        }
    end

    def fields_merge custom_fields, tr_type
        basic_fields = required_fields
        basic_fields[:pg_transaction_type] = tr_type
        fields = basic_fields.merge(custom_fields)
    end

    def credit_card cc_options
        ActiveMerchant::Billing::CreditCard.new(
          first_name: cc_options[:first_name],
          last_name: cc_options[:last_name],
          month: cc_options[:month],
          year: cc_options[:year],
          brand: cc_options[:brand],
          number:   cc_options[:number]
        )
    end
  end
end
