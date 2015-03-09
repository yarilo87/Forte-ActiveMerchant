# ForteGateway

Forte gateway ActiveMerchant gateway class implementation.

## Installation

Add this line to your application's Gemfile:

    gem 'forte_gateway'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install forte_gateway

## Usage

Gem contains two classes: WebServiceAuthentication and ForteGateway.
WebServiceAuthentication object is used to created client and payment methods tokens. ForteGateway is used to process transactions.

Creating WebServiceAuthentication object:

```ruby

forte_authentication = ActiveMerchant::Billing::WebServiceAuthentication.new(merchant_id: '171673', api_login_id: 'F3cnU00H5s', secure_transaction_key: 'Q870agdTS', test: true)

```

api_login_id and secure_transaction_key are set up in gateway settings of your payments gateway panel, test: true option is used for test mode.

Method #create_client is used for creating client profile and returns hash with client_id token:

```ruby

response = forte_authentication.create_client({first_name: "John", last_name: "Black"})
client_id = response[:create_client_response][:create_client_result]

```
Methods #update_client, #delete_client, #get_client take client_id as argument to proceed:

```ruby

response = forte_authentication.delete_client({client_id: client_id})

```

If there was an issue, all methods return error hash like {fault: {faultstring: {}}

Methods to manage payment methods for particular #client create_payment_method, #update_payment_method, #delete_payment_method, #get_payment_method take client_id as argument and
return payment_method_id.

Example:

```ruby

payment_details = {
    payment_type: 'credit_card',
    acct_holder_name: 'Jack Foster',
    cc_expiration_date:  '201609',
    cc_card_type:  :american_express,
    cc_card_number:  '378282246310005',
    client_id: client_id
}

response = forte_authentication.create_payment_method(payment_details)
payment_method_id = response[:create_payment_method_response][:create_payment_method_result]

```
ForteGateway object takes login, password and test as arguments. Login and password are merchant's gateway credentials. 
Test is optional argument for test mode.

```ruby

gateway =  ActiveMerchant::Billing::ForteGateway.new({login: '171673', password: 'p48iJT4oB', test: true}) }

```
Methods to process transactions: #purchase, #authorize, #capture, #credit, #void, #pre_auth, #recurring_transaction, #recurring_suspend, #recurring_activate,#recurring_recur

```ruby

#Example for a sale transaction with client_id token:

gateway.purchase(2.40, pg_client_id: client_id)

#Example for a sale transaction with credit card details:

transaction_details = {
	first_name: 'Steve',
	last_name:  'Smith',
	month: '9',
	year:  '2016',
	brand:  'visa',
	number:  '4111111111111111'
}

options = { ecom_billto_postal_name_first: "Yaroslav", ecom_billto_postal_name_last: "Keda"}

gateway.purchase(2.40, transaction_details, options)

#Example for a credit transaction with payment_method_id token:

gateway.credit(2.40, pg_payment_method_id: payment_method_id, options)

```
Transactions without errors return pg_authorization_code and pg_trace_number, which are used for #capture, #void and #pre_auth transactions:

```ruby

   auth_hash = gateway.authorize(100, transaction_details, options)
   pg_authorization_code = auth_hash[:pg_authorization_code]
   pg_trace_number = auth_hash[:pg_trace_number]
   gateway.capture(100, pg_authorization_code, pg_trace_number)

```

In case there was a error, method return hash with pg_response_code and pg_response_description with a description of an error:

```ruby

{
	:pg_merchant_id => "171673",
    :pg_response_code => "U11",
    :pg_response_description => "SCHEDULED TRANS NOT FOUND",
    :pg_response_type => "D",
    :pg_trace_number => "627B5DA4-36F2-498E-ACD4-AA32769777C0",
    :pg_transaction_type => "40"
}

```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/forte_gateway/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
# Forte-ActiveMerchant
