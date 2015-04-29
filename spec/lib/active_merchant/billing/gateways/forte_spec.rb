require 'spec_helper'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "./spec/fixtures/vcr_cassettes"
  config.hook_into :webmock # or :fakeweb
end

describe ActiveMerchant::Billing::Gateways::ForteGateway do
  subject { ActiveMerchant::Billing::Gateways::ForteGateway.new({login: '174641', password: '2V2WS0al', test: true}) }
  let(:payment) {
    {
      first_name: 'Steve',
      last_name:  'Smith',
      month: '9',
      year:  '2016',
      brand:  'visa',
      number:  '4111111111111111'
    }
  }
  let(:create_client_options) {
    {
      first_name: "Yaroslav", last_name: "Keda"
    }
  }

  let(:payment_with_tokenization) {
    {
      payment_type: 'credit_card',
      acct_holder_name: 'Yaroslav Keda',
      cc_expiration_date:  '201609',
      cc_card_type:  :american_express,
      cc_card_number:  '378282246310005',
      client_id: client_id
    }
  }
  let(:client_id) {
    ActiveMerchant::Billing::Gateways::WebServiceAuthentication.new(merchant_id: '174641', api_login_id: 'q71T4Wt6Dl', secure_transaction_key: 't83AXt51Rh', test: true).create_client(create_client_options)[:create_client_response][:create_client_result]
  }
  let(:payment_method) {
    ActiveMerchant::Billing::Gateways::WebServiceAuthentication.new(merchant_id: '174641', api_login_id: 'q71T4Wt6Dl', secure_transaction_key: 't83AXt51Rh', test: true).create_payment_method(payment_with_tokenization)[:create_payment_method_response][:create_payment_method_result]
  }
  let(:options) {
    {
      ecom_billto_postal_name_first: "Yaroslav", ecom_billto_postal_name_last: "Keda"
    }
  }
  let(:incorrect_payment) {
    {}
  }
  describe '#purchase' do
    
    let(:output_for_correct) { 
      subject.purchase(0.40, payment, options)
    }
    let(:output_for_incorrect) { 
      subject.purchase(0.40, incorrect_payment, options) 
    }

    it 'gets a successful response for credit card payment' do
      VCR.use_cassette "credit card payment" do
        expect(output_for_correct[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets a successful response for payment_with_tokenization when client_id' do
      VCR.use_cassette "credit card payment with client_id" do
        payment_method
        token_payment = {pg_client_id: client_id}
        expect(subject.purchase(2.40, token_payment)[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets a successful response for payment_with_tokenization when payment_method_id' do
      VCR.use_cassette "credit card payment with payment_method_id" do
        payment_method
        token_payment = {pg_payment_method_id: payment_method}
        expect(subject.purchase(2.40, token_payment, options)[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets an error response for payment_with_tokenization when incorrect client_id' do
      VCR.use_cassette "credit card payment with incorrect client_id" do
        token_payment = {pg_client_id: "aaa"}
        expect(subject.purchase(2.40, token_payment)[:pg_response_code]).to eq("F04")
      end
    end
    it 'gets an error response' do
      VCR.use_cassette "credit card payment error" do
        expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
      end
    end
    it 'gets the right error response code if card details missing' do
      VCR.use_cassette "credit card payment error" do
        expect(output_for_incorrect[:pg_response_code]).to eq("F01")
      end
    end
  end
  describe '#authorize' do

    let(:output_for_correct) { 
      subject.authorize(5.6, payment, options) 
    }
    let(:output_for_incorrect) { 
      subject.authorize(5.6, incorrect_payment, options) 
    }

    it 'gets a successful response' do
      VCR.use_cassette "authorize" do
        expect(output_for_correct[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets an error response' do
      VCR.use_cassette "authorize error" do
        expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
      end
    end
    it 'gets the right error response code if card details missing' do
      VCR.use_cassette "authorize error" do
       expect(output_for_incorrect[:pg_response_code]).to eq("F01")
      end
    end
  end
  describe '#capture' do
    let(:auth_hash) {
      subject.authorize(100, payment, options) 
    }
    let(:output_for_correct) {
      pg_authorization_code = auth_hash[:pg_authorization_code]
      pg_trace_number = auth_hash[:pg_trace_number]
      subject.capture(100,pg_authorization_code, pg_trace_number) 
    }
    let(:output_for_incorrect) { 
      pg_authorization_code = auth_hash[:pg_authorization_code]
        pg_trace_number = ""
      subject.capture(100,pg_authorization_code, pg_trace_number) 
    }

    it 'gets a successful response' do
      VCR.use_cassette "capture" do
        expect(output_for_correct[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets an error response' do
      VCR.use_cassette "capture error" do
        expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
      end
    end
    it 'gets the right error response code if card details missing' do
      VCR.use_cassette "capture error" do
        expect(output_for_incorrect[:pg_response_code]).to eq("F01")
      end
    end
  end
  describe '#void' do
    let(:auth_hash) {
      subject.authorize(100, payment, options) 
    }
    let(:output_for_correct) {
        pg_authorization_code = auth_hash[:pg_authorization_code]
        pg_trace_number = auth_hash[:pg_trace_number]
      subject.void(pg_authorization_code, pg_trace_number) 
    }
    let(:output_for_incorrect) { 
      pg_authorization_code = auth_hash[:pg_authorization_code]
        pg_trace_number = ""
      subject.void(pg_authorization_code, pg_trace_number) 
    }

    it 'gets a successful response' do
      VCR.use_cassette "void" do
        expect(output_for_correct[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets an error response' do
      VCR.use_cassette "void error" do
        expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
      end
    end
    it 'gets the right error response code if card details missing' do
      VCR.use_cassette "void error" do
        expect(output_for_incorrect[:pg_response_code]).to eq("F01")
      end
    end
  end
  describe '#pre_auth' do
    let(:auth_hash) {
      subject.authorize(100, payment, options) 
    }
    let(:output_for_correct) {
        pg_authorization_code = auth_hash[:pg_authorization_code]
      subject.pre_auth(100, pg_authorization_code, payment,options) 
    }
    let(:output_for_incorrect) { 
      pg_authorization_code = ''
      subject.pre_auth(100, pg_authorization_code, incorrect_payment,options) 
    }

    it 'gets a successful response' do
      VCR.use_cassette "pre_auth" do
        expect(output_for_correct[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets an error response' do
      VCR.use_cassette "pre_auth error" do
        expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
      end
    end
    it 'gets the right error response code if card details missing' do
      VCR.use_cassette "pre_auth error" do
        expect(output_for_incorrect[:pg_response_code]).to eq("F01")
      end
    end
  end
  describe '#credit' do

    let(:output_for_correct) { 
      subject.credit(20, payment, options) 
    }
    let(:output_for_incorrect) { 
      subject.credit(20, incorrect_payment, options) 
    }

    it 'gets a successful response' do
      VCR.use_cassette "credit" do
        expect(output_for_correct[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets an error response' do
      VCR.use_cassette "credit error" do
        expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
      end
    end
    it 'gets the right error response code if card details missing' do
      VCR.use_cassette "credit error" do
        expect(output_for_incorrect[:pg_response_code]).to eq("F01")
      end
    end
  end
  describe '#balance_inquiry' do
    let(:auth_hash) {
      subject.authorize(100, payment, options)
    }
    let(:output_for_correct) {
      pg_authorization_code = auth_hash[:pg_authorization_code]
      pg_trace_number = auth_hash[:pg_trace_number]
      subject.balance_inquiry(100, pg_authorization_code, pg_trace_number)
    }
    let(:output_for_incorrect) {
      pg_authorization_code = ''
      pg_trace_number = ''
      subject.balance_inquiry(100, pg_authorization_code, pg_trace_number)
    }

    it 'gets a successful response' do
      VCR.use_cassette "balance_inquiry" do
        expect(output_for_correct[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets an error response' do
      VCR.use_cassette "balance_inquiry error" do
        expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
      end
    end
    it 'gets the right error response code if card details missing' do
      VCR.use_cassette "balance_inquiry error" do
        expect(output_for_incorrect[:pg_response_code]).to eq("F01")
      end
    end
  end
  describe '#recurring_transaction' do

    let(:output_for_correct) { 
      subject.recurring_transaction(333,:monthly,12,25, "6/1/2016", payment, options) 
    }
    let(:output_for_incorrect) { 
      subject.recurring_transaction(333,:monthly,12,25, "6/1/2016", incorrect_payment, options) 
    }

    it 'gets a successful response' do
      VCR.use_cassette "recurring_transaction" do
        expect(output_for_correct[:pg_response_code]).to eq("A01")
      end
    end
    it 'gets an error response' do
      VCR.use_cassette "recurring_transaction error" do
        expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
      end
    end

    it 'gets the right error response code if card details missing' do
      VCR.use_cassette "recurring_transaction error" do
        expect(output_for_incorrect[:pg_response_code]).to eq("F01")
      end
    end
  end
end