require 'spec_helper'

describe ForteGateway do
  subject { ForteGateway::Forte.new() }
  let(:credit_card_payment) {
  	{
      type: 'credit_card',
  		first_name: 'Steve',
  		last_name:  'Smith',
  		month: '9',
  		year:  '2016',
  		brand:  'visa',
  		number:  '4111111111111111'
	  }
  }
  let(:eft_payment) {
    {
      type: 'eft',
      ecom_payment_check_account_type: "S",
      ecom_payment_check_account: "987654322",
      ecom_payment_check_trn: "021000021"
    }
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
    	subject.purchase(0.40, credit_card_payment, options)
    }
    let(:output_for_incorrect) { 
    	subject.purchase(0.40, incorrect_payment, options) 
    }
    let(:output_for_eft) {
      subject.purchase(0.40, eft_payment, options)
    }

    it 'gets a successful response for credit card payment' do
      expect(output_for_correct[:pg_response_code]).to eq("A01")
    end
    it 'gets a successful response for eft payment' do
      expect(output_for_eft[:pg_response_code]).to eq("A01")
    end
    it 'gets an error response for credit card payment' do
      expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
    end
    it 'gets the right error response code if card details missing' do
       expect(output_for_incorrect[:pg_response_code]).to eq("F01")
    end
  end
  describe '#authorize' do

    let(:output_for_correct) { 
    	subject.authorize(5.6, credit_card_payment, options) 
    }
    let(:output_for_incorrect) { 
    	subject.authorize(5.6, incorrect_payment, options) 
    }

    it 'gets a successful response' do
      expect(output_for_correct[:pg_response_code]).to eq("A01")
    end
    it 'gets an error response' do
      expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
    end
    it 'gets the right error response code if card details missing' do
       expect(output_for_incorrect[:pg_response_code]).to eq("F01")
    end
  end
  describe '#capture' do
    let(:auth_hash) {
    	subject.authorize(100, credit_card_payment, options) 
    }
    let(:auth_hash_for_eft) {
      subject.authorize(0.40, eft_payment, options)
    }
    let(:output_for_correct) {
      pg_authorization_code = auth_hash[:pg_authorization_code]
      pg_trace_number = auth_hash[:pg_trace_number]
    	 subject.capture(100,pg_authorization_code, pg_trace_number, credit_card_payment) 
    }
    let(:output_for_eft) {
      pg_authorization_code = auth_hash_for_eft[:pg_authorization_code]
      pg_trace_number = auth_hash_for_eft[:pg_trace_number]
      subject.capture(100,pg_authorization_code, pg_trace_number, eft_payment) 
    }
    let(:output_for_incorrect) { 
    	pg_authorization_code = auth_hash[:pg_authorization_code]
      pg_trace_number = ""
    	subject.capture(100,pg_authorization_code, pg_trace_number, eft_payment) 
    }

    it 'gets a successful response for credit card payment' do
      expect(output_for_correct[:pg_response_code]).to eq("A01")
    end
    it 'gets a successful response for eft payment' do
      expect(output_for_eft[:pg_response_code]).to eq("A01")
    end
    it 'gets an error response' do
       expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
    end
    it 'gets the right error response code if card details missing' do
       expect(output_for_incorrect[:pg_response_code]).to eq("F01")
    end
  end
  describe '#void' do
    let(:auth_hash) {
    	subject.authorize(100, credit_card_payment, options) 
    }
    let(:auth_hash_for_eft) {
      subject.authorize(0.40, eft_payment, options)
    }
    let(:output_for_correct) {
        pg_authorization_code = auth_hash[:pg_authorization_code]
        pg_trace_number = auth_hash[:pg_trace_number]
    	subject.void(pg_authorization_code, pg_trace_number,credit_card_payment) 
    }
    let(:output_for_eft) {
      pg_authorization_code = auth_hash_for_eft[:pg_authorization_code]
      pg_trace_number = auth_hash_for_eft[:pg_trace_number]
      subject.capture(100,pg_authorization_code, pg_trace_number, eft_payment) 
    }
    let(:output_for_incorrect) { 
    	pg_authorization_code = auth_hash[:pg_authorization_code]
        pg_trace_number = ""
    	subject.void(pg_authorization_code, pg_trace_number,credit_card_payment) 
    }

    it 'gets a successful response' do
      expect(output_for_correct[:pg_response_code]).to eq("A01")
    end
    it 'gets an error response' do
       expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
    end
    it 'gets a successful response for eft payment' do
      expect(output_for_eft[:pg_response_code]).to eq("A01")
    end
    it 'gets the right error response code if card details missing' do
       expect(output_for_incorrect[:pg_response_code]).to eq("F01")
    end
  end
  describe '#pre_auth' do
    let(:auth_hash) {
    	subject.authorize(100, credit_card_payment, options) 
    }
    let(:output_for_correct) {
        pg_authorization_code = auth_hash[:pg_authorization_code]
    	subject.pre_auth(100, pg_authorization_code, credit_card_payment,options) 
    }
    let(:output_for_incorrect) { 
    	pg_authorization_code = ''
    	subject.pre_auth(100, pg_authorization_code, incorrect_payment,options) 
    }

    it 'gets a successful response' do
      expect(output_for_correct[:pg_response_code]).to eq("A01")
    end
    it 'gets an error response' do
       expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
    end
    it 'gets the right error response code if card details missing' do
       expect(output_for_incorrect[:pg_response_code]).to eq("F01")
    end
  end
  describe '#credit' do

    let(:output_for_correct) { 
    	subject.credit(20, credit_card_payment, options) 
    }
    let(:output_for_incorrect) { 
    	subject.credit(20, incorrect_payment, options) 
    }
    let(:output_for_eft) {
      subject.credit(20, eft_payment, options) 
    }
    it 'gets a successful response for credit card payment' do
      expect(output_for_correct[:pg_response_code]).to eq("A01")
    end
    it 'gets a successful response eft payment' do
      expect(output_for_correct[:pg_response_code]).to eq("A01")
    end
    it 'gets an error response' do
       expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
    end
    it 'gets the right error response code if card details missing' do
       expect(output_for_incorrect[:pg_response_code]).to eq("F01")
    end
  end
  describe '#recurring_transaction' do

    let(:output_for_correct) { 
    	subject.recurring_transaction(333,:monthly,12, credit_card_payment, options) 
    }
    let(:output_for_incorrect) { 
    	subject.recurring_transaction(333,:monthly,12, incorrect_payment, options) 
    }

    it 'gets a successful response' do
      expect(output_for_correct[:pg_response_code]).to eq("A01")
    end
    it 'gets an error response' do
       expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
    end

  	it 'gets the right error response code if card details missing' do
      expect(output_for_incorrect[:pg_response_code]).to eq("F01")
    end
  end
end
