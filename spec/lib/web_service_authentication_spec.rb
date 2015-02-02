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
    it 'gets an error response' do
      expect(output_for_incorrect[:fault][:faultstring]).to eq("Company name is required.")
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
        acct_holder_name: 'John Black',
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
        acct_holder_name: 'John Black',
        cc_expiration_date:  '201712',
        client_id: client_id,
        payment_method_id: payment_method_id
      }
    }

    it 'gets a successful response' do
      expect(output_for_correct[:update_payment_method_response][:update_payment_method_result]).to be
    end
  end
end
