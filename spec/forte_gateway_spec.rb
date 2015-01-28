require 'spec_helper'

describe ForteGateway do
  subject { ForteGateway::Forte.new() }
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
  let(:options) {
  		{
	  		pg_billto_postal_name_company: "ASH", ecom_billto_postal_name_first: "Yaroslav", ecom_billto_postal_name_last: "Keda"
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
  describe '#authorize' do

    let(:output_for_correct) { 
    	subject.authorize(5.6, payment, options) 
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
      expect(output_for_correct[:pg_response_code]).to eq("A01")
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
      expect(output_for_correct[:pg_response_code]).to eq("A01")
    end
    it 'gets an error response' do
       expect(output_for_incorrect[:pg_response_code]).not_to eq("A01")
    end
    it 'gets the right error response code if card details missing' do
       expect(output_for_incorrect[:pg_response_code]).to eq("F01")
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
    	subject.credit(20, payment, options) 
    }
    let(:output_for_incorrect) { 
    	subject.credit(20, incorrect_payment, options) 
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
  describe '#recurring_transaction' do

    let(:output_for_correct) { 
    	subject.recurring_transaction(333,:monthly,12, payment, options) 
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
