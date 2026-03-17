# frozen_string_literal: true

require 'spec_helper'
require 'support/api_helper'

RSpec.describe Trustly::Api::Signed do
  let(:uuid) { SecureRandom.uuid }
  let(:orderid) { SecureRandom.hex(5) }

  let(:api) do
    described_class.new(
      host: 'test.trustly.com',
      port: 443,
      is_https: true,
      username: 'testuser',
      password: 'testpass',
      private_pem: $test_certs[:private_pem],
      public_pem: $test_certs[:public_pem]
    )
  end

  before do
    allow_any_instance_of(Trustly::Data::JSONRPCRequest).to receive(:get_uuid).and_return(uuid)
    allow(api).to receive(:verify_trustly_signed_response).and_return(true)
  end

  def stub_success(method_name)
    stub_request(:post, 'https://test.trustly.com/api/1').to_return(
      status: 200,
      body: {
        version: '1.1',
        result: {
          method: method_name,
          uuid: uuid,
          data: { 'orderid' => orderid, 'result' => '1' }
        }
      }.to_json
    )
  end

  def stub_error(method_name)
    stub_request(:post, 'https://test.trustly.com/api/1').to_return(
      status: 200,
      body: {
        version: '1.1',
        error: {
          error: {
            method: method_name,
            uuid: uuid,
            data: { 'code' => 620, 'message' => 'ERROR_NOT_ALLOWED' }
          }
        }
      }.to_json
    )
  end

  # ---- direct_debit ----

  describe '#direct_debit' do
    let(:valid_options) do
      {
        'MessageID' => SecureRandom.uuid,
        'NotificationURL' => 'https://example.com/notify',
        'AccountID' => '123456789',
        'Amount' => '100.00',
        'Currency' => 'SEK'
      }
    end

    %w[MessageID NotificationURL AccountID Amount Currency].each do |param|
      it "raises DataError when #{param} is missing" do
        expect { api.direct_debit(valid_options.except(param)) }.to raise_error(
          Trustly::Exception::DataError, "Option not valid '#{param}'"
        )
      end
    end

    it 'raises DataError when Amount is 0' do
      expect { api.direct_debit(valid_options.merge('Amount' => '0')) }.to raise_error(
        Trustly::Exception::DataError, 'Amount is 0'
      )
    end

    context 'when API returns success' do
      before { stub_success('DirectDebit') }

      it 'returns a successful JSONRPCResponse' do
        response = api.direct_debit(valid_options)
        expect(response).to be_a(Trustly::Data::JSONRPCResponse)
        expect(response).to be_success
        expect(response.get_method).to eq('DirectDebit')
      end
    end

    context 'when API returns error' do
      before { stub_error('DirectDebit') }

      it 'returns a failed response with error details' do
        response = api.direct_debit(valid_options)
        expect(response).not_to be_success
        expect(response).to be_error
        expect(response.error_code).to eq(620)
        expect(response.error_msg).to eq('ERROR_NOT_ALLOWED')
      end
    end
  end

  # ---- direct_debit_mandate ----

  describe '#direct_debit_mandate' do
    let(:valid_options) do
      {
        'MessageID' => SecureRandom.uuid,
        'EndUserID' => SecureRandom.uuid,
        'NotificationURL' => 'https://example.com/notify',
        'MerchantReference' => '1234567890',
        'Country' => 'SE',
        'Currency' => 'SEK',
        'Firstname' => 'Test',
        'Lastname' => 'User',
        'Email' => 'test@example.com',
        'SuccessURL' => 'https://example.com/success',
        'FailURL' => 'https://example.com/fail'
      }
    end

    %w[MessageID EndUserID NotificationURL MerchantReference Country Currency Firstname Lastname Email SuccessURL FailURL].each do |param|
      it "raises DataError when #{param} is missing" do
        expect { api.direct_debit_mandate(valid_options.except(param)) }.to raise_error(
          Trustly::Exception::DataError, "Option not valid '#{param}'"
        )
      end
    end

    context 'when API returns success' do
      before { stub_success('DirectDebitMandate') }

      it 'returns a successful JSONRPCResponse' do
        response = api.direct_debit_mandate(valid_options)
        expect(response).to be_a(Trustly::Data::JSONRPCResponse)
        expect(response).to be_success
        expect(response.get_method).to eq('DirectDebitMandate')
      end
    end

    context 'when API returns error' do
      before { stub_error('DirectDebitMandate') }

      it 'returns a failed response' do
        response = api.direct_debit_mandate(valid_options)
        expect(response).not_to be_success
        expect(response.error_code).to eq(620)
      end
    end
  end

  # ---- direct_debit_mandate_with_payment ----

  describe '#direct_debit_mandate_with_payment' do
    let(:valid_options) do
      {
        'MessageID' => SecureRandom.uuid,
        'EndUserID' => SecureRandom.uuid,
        'NotificationURL' => 'https://example.com/notify',
        'MerchantReference' => '1234567890',
        'Country' => 'SE',
        'Currency' => 'SEK',
        'Amount' => '100.00',
        'Firstname' => 'Test',
        'Lastname' => 'User',
        'Email' => 'test@example.com',
        'SuccessURL' => 'https://example.com/success',
        'FailURL' => 'https://example.com/fail'
      }
    end

    %w[MessageID EndUserID NotificationURL MerchantReference Country Currency Amount Firstname Lastname Email SuccessURL FailURL].each do |param|
      it "raises DataError when #{param} is missing" do
        expect { api.direct_debit_mandate_with_payment(valid_options.except(param)) }.to raise_error(
          Trustly::Exception::DataError, "Option not valid '#{param}'"
        )
      end
    end

    it 'raises DataError when Amount is 0' do
      expect { api.direct_debit_mandate_with_payment(valid_options.merge('Amount' => '0')) }.to raise_error(
        Trustly::Exception::DataError, 'Amount is 0'
      )
    end

    context 'when API returns success' do
      before { stub_success('DirectDebitMandateWithPayment') }

      it 'returns a successful JSONRPCResponse' do
        response = api.direct_debit_mandate_with_payment(valid_options)
        expect(response).to be_a(Trustly::Data::JSONRPCResponse)
        expect(response).to be_success
        expect(response.get_method).to eq('DirectDebitMandateWithPayment')
      end

      it 'excludes blank optional fields from the request' do
        request_body = nil
        stub_request(:post, 'https://test.trustly.com/api/1').to_return do |request|
          request_body = JSON.parse(request.body)
          { status: 200, body: { version: '1.1', result: { method: 'DirectDebitMandateWithPayment', uuid: uuid, data: { 'orderid' => orderid, 'result' => '1' } } }.to_json }
        end
        api.direct_debit_mandate_with_payment(valid_options)
        attributes = request_body.dig('params', 'Data', 'Attributes') || {}
        expect(attributes).not_to have_key('MobilePhone')
        expect(attributes).not_to have_key('DateOfBirth')
        expect(attributes).not_to have_key('AddressLine1')
      end

      it 'includes optional fields when explicitly provided' do
        request_body = nil
        stub_request(:post, 'https://test.trustly.com/api/1').to_return do |request|
          request_body = JSON.parse(request.body)
          { status: 200, body: { version: '1.1', result: { method: 'DirectDebitMandateWithPayment', uuid: uuid, data: { 'orderid' => orderid, 'result' => '1' } } }.to_json }
        end
        api.direct_debit_mandate_with_payment(valid_options.merge('MobilePhone' => '+46701234567'))
        attributes = request_body.dig('params', 'Data', 'Attributes') || {}
        expect(attributes['MobilePhone']).to eq('+46701234567')
      end
    end

    context 'when API returns error' do
      before { stub_error('DirectDebitMandateWithPayment') }

      it 'returns a failed response' do
        response = api.direct_debit_mandate_with_payment(valid_options)
        expect(response).not_to be_success
        expect(response.error_code).to eq(620)
      end
    end
  end

  # ---- cancel_direct_debit_mandate ----

  describe '#cancel_direct_debit_mandate' do
    let(:valid_options) do
      {
        'MessageID' => SecureRandom.uuid,
        'NotificationURL' => 'https://example.com/notify',
        'AccountID' => '123456789'
      }
    end

    %w[MessageID NotificationURL AccountID].each do |param|
      it "raises DataError when #{param} is missing" do
        expect { api.cancel_direct_debit_mandate(valid_options.except(param)) }.to raise_error(
          Trustly::Exception::DataError, "Option not valid '#{param}'"
        )
      end
    end

    context 'when API returns success' do
      before { stub_success('CancelDirectDebitMandate') }

      it 'returns a successful JSONRPCResponse' do
        response = api.cancel_direct_debit_mandate(valid_options)
        expect(response).to be_a(Trustly::Data::JSONRPCResponse)
        expect(response).to be_success
        expect(response.get_method).to eq('CancelDirectDebitMandate')
      end
    end

    context 'when API returns error' do
      before { stub_error('CancelDirectDebitMandate') }

      it 'returns a failed response' do
        response = api.cancel_direct_debit_mandate(valid_options)
        expect(response).not_to be_success
        expect(response.error_code).to eq(620)
      end
    end
  end

  # ---- import_direct_debit_mandate (NEW) ----

  describe '#import_direct_debit_mandate' do
    let(:valid_options) do
      {
        'MessageID' => SecureRandom.uuid,
        'EndUserID' => SecureRandom.uuid,
        'NotificationURL' => 'https://example.com/notify',
        'AccountID' => '123456789',
        'ImportType' => 'REGISTER',
        'MerchantReference' => '1234567890',
        'Firstname' => 'Test',
        'Lastname' => 'User',
        'NationalIdentificationNumber' => '198001011234'
      }
    end

    %w[MessageID EndUserID NotificationURL AccountID ImportType MerchantReference Firstname Lastname NationalIdentificationNumber].each do |param|
      it "raises DataError when #{param} is missing" do
        expect { api.import_direct_debit_mandate(valid_options.except(param)) }.to raise_error(
          Trustly::Exception::DataError, "Option not valid '#{param}'"
        )
      end
    end

    context 'when API returns success' do
      before { stub_success('ImportDirectDebitMandate') }

      it 'returns a successful JSONRPCResponse' do
        response = api.import_direct_debit_mandate(valid_options)
        expect(response).to be_a(Trustly::Data::JSONRPCResponse)
        expect(response).to be_success
        expect(response.get_method).to eq('ImportDirectDebitMandate')
      end

      it 'accepts optional Email, MobilePhone, and DateOfBirth' do
        options = valid_options.merge(
          'Email' => 'test@example.com',
          'MobilePhone' => '+46701234567',
          'DateOfBirth' => '1980-01-01'
        )
        response = api.import_direct_debit_mandate(options)
        expect(response).to be_success
      end
    end

    context 'when API returns error' do
      before { stub_error('ImportDirectDebitMandate') }

      it 'returns a failed response' do
        response = api.import_direct_debit_mandate(valid_options)
        expect(response).not_to be_success
        expect(response.error_code).to eq(620)
      end
    end
  end

  # ---- refund_direct_debit (NEW) ----

  describe '#refund_direct_debit' do
    let(:valid_options) do
      {
        'OrderID' => '12345',
        'Amount' => '50.00',
        'Currency' => 'SEK',
        'MessageID' => SecureRandom.uuid,
        'NotificationURL' => 'https://example.com/notify'
      }
    end

    %w[OrderID Amount Currency MessageID NotificationURL].each do |param|
      it "raises DataError when #{param} is missing" do
        expect { api.refund_direct_debit(valid_options.except(param)) }.to raise_error(
          Trustly::Exception::DataError, "Option not valid '#{param}'"
        )
      end
    end

    it 'raises DataError when Amount is 0' do
      expect { api.refund_direct_debit(valid_options.merge('Amount' => '0')) }.to raise_error(
        Trustly::Exception::DataError, 'Amount is 0'
      )
    end

    context 'when API returns success' do
      before { stub_success('RefundDirectDebit') }

      it 'returns a successful JSONRPCResponse' do
        response = api.refund_direct_debit(valid_options)
        expect(response).to be_a(Trustly::Data::JSONRPCResponse)
        expect(response).to be_success
        expect(response.get_method).to eq('RefundDirectDebit')
      end
    end

    context 'when API returns error' do
      before { stub_error('RefundDirectDebit') }

      it 'returns a failed response' do
        response = api.refund_direct_debit(valid_options)
        expect(response).not_to be_success
        expect(response.error_code).to eq(620)
      end
    end
  end

  # ---- cancel_direct_debit (NEW) ----

  describe '#cancel_direct_debit' do
    let(:valid_options) do
      {
        'OrderID' => '12345',
        'MessageID' => SecureRandom.uuid,
        'NotificationURL' => 'https://example.com/notify'
      }
    end

    %w[OrderID MessageID NotificationURL].each do |param|
      it "raises DataError when #{param} is missing" do
        expect { api.cancel_direct_debit(valid_options.except(param)) }.to raise_error(
          Trustly::Exception::DataError, "Option not valid '#{param}'"
        )
      end
    end

    context 'when API returns success' do
      before { stub_success('CancelDirectDebit') }

      it 'returns a successful JSONRPCResponse' do
        response = api.cancel_direct_debit(valid_options)
        expect(response).to be_a(Trustly::Data::JSONRPCResponse)
        expect(response).to be_success
        expect(response.get_method).to eq('CancelDirectDebit')
      end
    end

    context 'when API returns error' do
      before { stub_error('CancelDirectDebit') }

      it 'returns a failed response' do
        response = api.cancel_direct_debit(valid_options)
        expect(response).not_to be_success
        expect(response.error_code).to eq(620)
      end
    end
  end

  # ---- Request signing ----

  describe '#sign_merchant_request' do
    it 'produces a Base64-encoded signature' do
      request = Trustly::Data::JSONRPCRequest.new('TestMethod', { 'Key' => 'Value' }, nil)
      request.set_uuid(uuid)
      signature = api.sign_merchant_request(request)
      expect(signature).to be_a(String)
      expect(Base64.decode64(signature).length).to be > 0
    end

    it 'raises SignatureError when no private key is loaded' do
      api.merchant_privatekey = nil
      request = Trustly::Data::JSONRPCRequest.new('TestMethod', { 'Key' => 'Value' }, nil)
      expect { api.sign_merchant_request(request) }.to raise_error(
        Trustly::Exception::SignatureError, 'No private key has been loaded'
      )
    end
  end

  # ---- Initialization errors ----

  describe '.new' do
    it 'raises AuthentificationError for missing username' do
      expect {
        described_class.new(
          username: nil, password: 'pass',
          private_pem: $test_certs[:private_pem],
          public_pem: $test_certs[:public_pem]
        )
      }.to raise_error(Trustly::Exception::AuthentificationError, 'Username not valid')
    end

    it 'raises AuthentificationError for missing password' do
      expect {
        described_class.new(
          username: 'user', password: nil,
          private_pem: $test_certs[:private_pem],
          public_pem: $test_certs[:public_pem]
        )
      }.to raise_error(Trustly::Exception::AuthentificationError, 'Password not valid')
    end

    it 'raises SignatureError for missing private pem file' do
      expect {
        described_class.new(
          username: 'user', password: 'pass',
          private_pem: '/nonexistent/private.pem',
          public_pem: $test_certs[:public_pem]
        )
      }.to raise_error(Trustly::Exception::SignatureError, /does not exist/)
    end

    it 'raises SignatureError for missing public pem file' do
      expect {
        described_class.new(
          username: 'user', password: 'pass',
          private_pem: $test_certs[:private_pem],
          public_pem: '/nonexistent/public.pem'
        )
      }.to raise_error(Trustly::Exception::SignatureError, /does not exist/)
    end
  end
end
