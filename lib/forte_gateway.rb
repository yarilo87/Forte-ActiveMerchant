require 'net/http'
require "uri"
require 'active_merchant'

module ForteGateway

  class Forte

    TEST_URL = "https://www.paymentsgateway.net/cgi-bin/posttest.pl"
    LIVE_URL = "https://www.paymentsgateway.net/cgi-bin/postauth.pl"

    TRANSACTIONS_TYPES = {sale: 10, authorize: 11, capture: 12, credit: 13, void: 14, pre_auth: 15, balance_inquiry: 16}
    EFT_TRANSACTIONS_TYPES = {sale: 20, authorize: 21, capture: 22, credit: 23, void: 24, pre_auth: 25, balance_inquiry: 26}

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
        if payment[:type] == 'credit_card' || !payment[:type]
            payment_fields = add_credit_card(credit_card(payment))
            transaction_type = TRANSACTIONS_TYPES[:sale]
        elsif payment[:type] == 'eft'
            payment_fields = payment
            transaction_type = EFT_TRANSACTIONS_TYPES[:sale]
        end
        data = collect_data payment_fields, transaction_type, options, amount
        commit data
    end

    # transaction_type 11

    def authorize(amount, payment, options={})
        if payment[:type] == 'credit_card' || !payment[:type]
            payment_fields = add_credit_card(credit_card(payment))
            transaction_type = TRANSACTIONS_TYPES[:authorize]
        elsif payment[:type] == 'eft'
            payment_fields = payment
            transaction_type = EFT_TRANSACTIONS_TYPES[:authorize]
        end
        data = collect_data payment_fields, transaction_type, options, amount
        commit data
    end

    # transaction_type 12

    def capture(amount, pg_authorization_code, pg_trace_number, payment, options={})
        if payment[:type] == 'credit_card' || !payment[:type]
            transaction_type = TRANSACTIONS_TYPES[:capture]
        elsif payment[:type] == 'eft'
            transaction_type = EFT_TRANSACTIONS_TYPES[:capture]
        end
        payment_fields = {
            pg_original_authorization_code: pg_authorization_code,
            pg_original_trace_number: pg_trace_number
        }
        data = collect_data payment_fields, transaction_type, options, amount
        commit data
    end

    # transaction_type 13

    def credit(amount, payment, options={})
        if payment[:type] == 'credit_card' || !payment[:type]
            payment_fields = add_credit_card(credit_card(payment))
            transaction_type = TRANSACTIONS_TYPES[:credit]
        elsif payment[:type] == 'eft'
            payment_fields = payment
            transaction_type = EFT_TRANSACTIONS_TYPES[:credit]
        end
        data = collect_data payment_fields, transaction_type, options, amount
        commit data
    end

    # transaction_type 14

    def void(pg_authorization_code, pg_trace_number ,payment ,options={})
        if payment[:type] == 'credit_card' || !payment[:type]
            transaction_type = TRANSACTIONS_TYPES[:void]
        elsif payment[:type] == 'eft'
            transaction_type = EFT_TRANSACTIONS_TYPES[:void]
        end
        payment_fields = {
            pg_original_authorization_code: pg_authorization_code,
            pg_original_trace_number: pg_trace_number
        }
        data = collect_data payment_fields, transaction_type, options
        commit data
    end

    # transaction_type 15

    def pre_auth(amount, pg_authorization_code, payment, options={})
        if payment[:type] == 'credit_card' || !payment[:type]
            payment_fields = add_credit_card(credit_card(payment))
            transaction_type = TRANSACTIONS_TYPES[:credit]
        elsif payment[:type] == 'eft'
            payment_fields = payment
            transaction_type = EFT_TRANSACTIONS_TYPES[:credit]
        end
        payment_fields[:pg_original_authorization_code] = pg_authorization_code
        data = collect_data payment_fields, transaction_type, options
        commit data
    end

    # transaction_type 16

    def balance_inquiry(options={})

    end

    def recurring_transaction(amount, frequency, quantity, payment, options={})
        cc = add_credit_card(credit_card(payment))
        transaction_type = TRANSACTIONS_TYPES[:sale]
        payment_fields = {
            pg_total_amount: amount,
            pg_billto_postal_name_company: options[:pg_billto_postal_name_company],
            pg_schedule_frequency: RECURRING_TRANSACTION_FREQUENCIES[frequency],
            pg_schedule_quantity: quantity
        }
        data = collect_data(payment_fields.merge(cc), transaction_type, options)
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

    def collect_data payment_fields, transaction_type, options, amount = nil
        options[:pg_total_amount] = amount if amount
        transaction_fields = payment_fields.merge options
        basic_fields = required_fields transaction_type
        message basic_fields.merge(transaction_fields)
    end

    def message fields
        message = ''
        fields.each do |key, value|
            message += "#{key}=#{value}&" if key != :type
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

    def required_fields transaction_type
        {
            pg_merchant_id: @api_login_id,
            pg_password: @secure_transaction_key,
            pg_transaction_type: transaction_type
        }
    end

    def add_user_fields options
        user_fields_hash = {}
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
