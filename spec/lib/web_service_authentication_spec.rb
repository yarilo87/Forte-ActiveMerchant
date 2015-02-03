require 'spec_helper'

describe ForteGateway do
  subject { ForteGateway::WebServiceAuthentication.new() }
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
      expect(output_for_correct[:create_client_response][:create_client_result]).to be
    end
    it 'gets an error response when no user name provided' do
      expect(output_for_incorrect[:fault][:faultstring]).to eq("Company name is required.")
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
      expect(output_for_correct[:delete_client_response][:delete_client_result]).to eq client_id
    end
    it 'gets an error response when no client_id provided' do
      expect(output_for_incorrect[:fault][:faultstring]).to be
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
      expect(output_for_correct[:update_client_response][:update_client_result]).to eq client_id
    end
    it 'gets an error response when no client_id provided' do
      expect(output_for_incorrect[:fault][:faultstring]).to be
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
      expect(output_for_correct[:get_client_response][:get_client_result]).to be
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
    let(:output_for_correct) {
      subject.create_payment_method(payment)
    }
    let(:payment) {
      {
        acct_holder_name: 'John Black',
        cc_expiration_date:  '201609',
        cc_card_type:  "VISA",
        cc_card_numbed:  '4111111111111111',
        client_id: client_id
      }
    }

    it 'gets a successful response' do
      expect(output_for_correct[:create_payment_method_response][:create_payment_method_result]).to be
    end
  end
  describe '#update_payment_method' do
    let(:options_for_payment_method) {
      {
        first_name: "Jack", last_name: "Foster"
      }
    }
    let(:payment) {
      {
        acct_holder_name: 'Jack Foster',
        cc_expiration_date:  '201609',
        cc_card_type:  "VISA",
        cc_card_numbed:  '4111111111111111',
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
      subject.update_payment_method(update_payment)
    }
    let(:update_payment) {
      {
        acct_holder_name: 'Jack Foster',
        cc_expiration_date:  '201712',
        client_id: client_id,
        payment_method_id: payment_method_id
      }
    }

    it 'gets a successful response' do
      expect(output_for_correct[:update_payment_method_response][:update_payment_method_result]).to be
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
        acct_holder_name: 'Jack Foster',
        cc_expiration_date:  '201609',
        cc_card_type:  "VISA",
        cc_card_numbed:  '4111111111111111',
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
      expect(output_for_correct[:delete_payment_method_response][:delete_payment_method_result]).to be
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
        acct_holder_name: 'Jack Foster',
        cc_expiration_date:  '201609',
        cc_card_type:  "VISA",
        cc_card_numbed:  '4111111111111111',
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
      expect(output_for_correct[:get_payment_method_response][:get_payment_method_result]).to be
    end
  end
end
