require 'spec_helper'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "./spec/fixtures/vcr_cassettes"
  config.hook_into :webmock # or :fakeweb
end

describe ActiveMerchant::Billing::Gateways::WebServiceAuthentication do
  subject {  ActiveMerchant::Billing::Gateways::WebServiceAuthentication.new(merchant_id: '174641', api_login_id: 'q71T4Wt6Dl', secure_transaction_key: 't83AXt51Rh', test: true) }
  let(:options) {
  	{
	  	first_name: "Bob", last_name: "Brown"
		}
	}
  let(:incorrect_options) {
  	{}
  }
  describe '#create_client' do
  	
    let(:output_for_correct) { 
    	subject.create_client(options)
    }
    let(:output_for_incorrect) { 
    	subject.create_client(incorrect_options) 
    }

    it 'gets a successful response' do
      VCR.use_cassette "create client" do
        expect(output_for_correct[:create_client_response][:create_client_result]).to be
      end
    end
    it 'gets an error response when no user name provided' do
      VCR.use_cassette "create client with error" do
        expect(output_for_incorrect[:fault][:faultstring]).to eq("Company name is required.")
      end
    end
  end
  describe '#delete_client' do
    let(:options_for_payment_method) {
      {
        first_name: "Bob", last_name: "Brown"
      }
    }
    let(:client_id) {
      subject.create_client(options_for_payment_method)[:create_client_response][:create_client_result]
    }
    let(:output_for_correct) {
      subject.delete_client(client_id: client_id)
    }
     let(:output_for_incorrect) {
      subject.delete_client
    }
    it 'gets a successful response' do
      VCR.use_cassette "delete client" do
        expect(output_for_correct[:delete_client_response][:delete_client_result]).to eq client_id
      end
    end
    it 'gets an error response when no client_id provided' do
      VCR.use_cassette "delete client with error" do
        expect(output_for_incorrect[:fault][:faultstring]).to be
      end
    end
  end
  describe '#update_client' do
    let(:options_for_payment_method) {
      {
        first_name: "Bobby", last_name: "Brown"
      }
    }
    let(:client_id) {
      subject.create_client(options_for_payment_method)[:create_client_response][:create_client_result]
    }
    let(:output_for_correct) {
      subject.update_client(client_id: client_id)
    }
    let(:output_for_incorrect) {
      subject.update_client
    }
    it 'gets a successful response' do
      VCR.use_cassette "update client" do
        expect(output_for_correct[:update_client_response][:update_client_result]).to eq client_id
      end
    end
    it 'gets an error response when no client_id provided' do
      VCR.use_cassette "update client with error" do
        expect(output_for_incorrect[:fault][:faultstring]).to be
      end
    end
  end
  describe '#get_client' do
    let(:options_for_payment_method) {
      {
        first_name: "Bob", last_name: "Brown"
      }
    }
    let(:client_id) {
      subject.create_client(options_for_payment_method)[:create_client_response][:create_client_result]
    }
    let(:output_for_correct) {
      subject.get_client(client_id: client_id)
    }
    it 'gets a successful response' do
      VCR.use_cassette "get client" do
        expect(output_for_correct[:get_client_response][:get_client_result]).to be
      end
    end
  end
  describe '#create_payment_method' do
    let(:options_for_payment_method) {
      {
        first_name: "John", last_name: "Black"
      }
    }
    let(:client_id) {
      subject.create_client(options_for_payment_method)[:create_client_response][:create_client_result]
    }
    let(:output_for_correct_credit_card_payment) {
      subject.create_payment_method(credit_card_payment)
    }
    let(:output_for_incorrect_credit_card_payment) {
      subject.create_payment_method(incorrect_credit_card_payment)
    }
    let(:output_for_correct_e_check_payment) {
      subject.create_payment_method(e_check_payment)
    }
    let(:credit_card_payment) {
      {
        payment_type: 'credit_card',
        acct_holder_name: 'John Black',
        cc_expiration_date:  '201609',
        cc_card_type:  :master,
        cc_card_number:  '5555555555554444',
        client_id: client_id
      }
    }
    let(:incorrect_credit_card_payment) {
      {
        payment_type: 'credit_card',
        acct_holder_name: 'John Black',
        cc_expiration_date:  '201609',
        cc_card_type:  :master,
        cc_card_number:  '5555555555554444'
      }
    }
    let(:e_check_payment) {
      {
        acct_holder_name: 'John Black',
        ecom_payment_check_account: "1111111111111",
        ecom_payment_check_trn: "021000021",
        ecom_payment_check_account_type: :checking,
        client_id: client_id
      }
    }
    it 'gets a successful response for correct credit card payment' do
      VCR.use_cassette "create cc payment method" do
        expect(output_for_correct_credit_card_payment[:create_payment_method_response][:create_payment_method_result]).to be
      end
    end
    it 'gets a successful response for correct echeck payment' do
      VCR.use_cassette "create echeck payment method" do
        expect(output_for_correct_credit_card_payment[:create_payment_method_response][:create_payment_method_result]).to be
      end
    end
    it 'gets an error response when no client_id provided' do
      VCR.use_cassette "create payment method failed" do
        expect(output_for_incorrect_credit_card_payment[:fault][:faultstring]).to be
      end
    end
  end
  describe '#update_payment_method' do
    let(:options_for_payment_method) {
      {
        first_name: "Alex", last_name: "Cox"
      }
    }
    let(:credit_card_payment) {
      {
        payment_type: 'credit_card',
        acct_holder_name: 'Alex Cox',
        cc_expiration_date:  '201609',
        cc_card_type:  :visa,
        cc_card_number:  '4111111111111111',
        client_id: client_id
      }
    }
    let(:e_check_payment) {
      {
        acct_holder_name: 'John Black',
        ecom_payment_check_account: "987654322",
        ecom_payment_check_trn: "021000021",
        ecom_payment_check_account_type: :checking,
        client_id: client_id
      }
    }
    let(:client_id) {
      subject.create_client(options_for_payment_method)[:create_client_response][:create_client_result]
    }
    let(:credit_card_payment_method_id) {
      subject.create_payment_method(credit_card_payment)[:create_payment_method_response][:create_payment_method_result]
    }
    let(:e_check_method_id) {
      subject.create_payment_method(e_check_payment)[:create_payment_method_response][:create_payment_method_result]
    }
    let(:output_for_correct_credit_card_payment) {
      subject.update_payment_method(update_credit_card_payment)
    }
    let(:output_for_correct_e_check_payment) {
      subject.update_payment_method(update_e_check_payment)
    }
    let(:update_credit_card_payment) {
      {
        payment_type: 'credit_card',
        acct_holder_name: 'Alex Cox',
        cc_expiration_date:  '201712',
        client_id: client_id,
        payment_method_id: credit_card_payment_method_id
      }
    }
    let(:update_e_check_payment) {
      {
        acct_holder_name: 'Alex Cox',
        ecom_payment_check_account_type: :savings,
        client_id: client_id,
        payment_method_id: e_check_method_id
      }
    }
    it 'gets a successful response for credit card payment' do
      VCR.use_cassette "update cc payment method" do
        expect(output_for_correct_credit_card_payment[:update_payment_method_response][:update_payment_method_result]).to eq credit_card_payment_method_id
      end
    end
    it 'gets a successful response e check payment' do
      VCR.use_cassette "update echeck payment method" do
        expect(output_for_correct_e_check_payment[:update_payment_method_response][:update_payment_method_result]).to eq e_check_method_id
      end
    end
  end
  describe '#delete_payment_method' do
    let(:options_for_payment_method) {
      {
        first_name: "Jack", last_name: "Foster"
      }
    }
    let(:payment) {
      {
        payment_type: 'credit_card',
        acct_holder_name: 'Jack Foster',
        cc_expiration_date:  '201609',
        cc_card_type:  :visa,
        cc_card_number:  '4111111111111111',
        client_id: client_id
      }
    }
    let(:client_id) {
      subject.create_client(options_for_payment_method)[:create_client_response][:create_client_result]
    }
    let(:payment_method_id) {
      subject.create_payment_method(payment)[:create_payment_method_response][:create_payment_method_result]
    }
    let(:output_for_correct) {
      subject.delete_payment_method(client_id: client_id,payment_method_id: payment_method_id )
    }

    it 'gets a successful response' do
      VCR.use_cassette "delete payment method" do
        expect(output_for_correct[:delete_payment_method_response][:delete_payment_method_result]).to be
      end
    end
  end
  describe '#get_payment_method' do
    let(:options_for_payment_method) {
      {
        first_name: "Jack", last_name: "Foster"
      }
    }
    let(:payment) {
      {
        payment_type: 'credit_card',
        acct_holder_name: 'Jack Foster',
        cc_expiration_date:  '201609',
        cc_card_type:  :american_express,
        cc_card_number:  '378282246310005',
        client_id: client_id
      }
    }
    let(:client_id) {
      subject.create_client(options_for_payment_method)[:create_client_response][:create_client_result]
    }
    let(:payment_method_id) {
      subject.create_payment_method(payment)[:create_payment_method_response][:create_payment_method_result]
    }
    let(:output_for_correct) {
      subject.get_payment_method(client_id: client_id,payment_method_id: payment_method_id )
    }

    it 'gets a successful response' do
      VCR.use_cassette "get payment method" do
        expect(output_for_correct[:get_payment_method_response][:get_payment_method_result]).to be
      end
    end
  end
end
