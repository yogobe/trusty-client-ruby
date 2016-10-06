class Trustly::Api::Signed < Trustly::Api

  attr_accessor :url_path,:api_username, :api_password, :merchant_privatekey, :is_https


  def initialize(_options)
    options = {
      :host        => 'test.trustly.com',
      :port        => 443,
      :is_https    => true,
      :private_pem => "#{Rails.root}/certs/trustly/test.merchant.private.pem",
      :public_pem  => "#{Rails.root}/certs/trustly/test.trustly.public.pem"
    }.merge(_options)


    raise Trustly::Exception::SignatureError, "File '#{options[:private_pem]}' does not exist" unless File.file?(options[:private_pem])
    raise Trustly::Exception::SignatureError, "File '#{options[:public_pem]}' does not exist"  unless File.file?(options[:public_pem])

    super(options[:host],options[:port],options[:is_https],options[:public_pem])

    self.api_username = options.try(:[],:username)
    self.api_password = options.try(:[],:password)
    self.is_https     = options.try(:[],:is_https)
    self.url_path     = '/api/1'

    raise Trustly::Exception::AuthentificationError, "Username not valid" if self.api_username.nil?
    raise Trustly::Exception::AuthentificationError, "Password not valid" if self.api_password.nil?

    self.load_merchant_privatekey(options[:private_pem])

  end

  def load_merchant_privatekey(filename)
    self.merchant_privatekey = OpenSSL::PKey::RSA.new(File.read(filename))
  end

  def handle_response(request,httpcall)
    response = Trustly::Data::JSONRPCResponse.new(httpcall)
    raise   Trustly::Exception::SignatureError,'Incoming message signature is not valid' unless self.verify_trustly_signed_response(response)
    raise   Trustly::Exception::DataError,     'Incoming response is not related to request. UUID mismatch.' if response.get_uuid() != request.get_uuid()
    return  response
  end

  def insert_credentials(request)
    request.set_data( 'Username' , self.api_username)
    request.set_data( 'Password' , self.api_password)
    request.set_param('Signature', self.sign_merchant_request(request))
  end

  def sign_merchant_request(data)
    raise Trustly::Exception::SignatureError, 'No private key has been loaded' if self.merchant_privatekey.nil?
    method      = data.get_method()
    method      = '' if method.nil?
    uuid        = data.get_uuid()
    uuid        = '' if uuid.nil?
    data        = data.get_data()
    data        = {} if data.nil?

    serial_data = "#{method}#{uuid}#{self.serialize_data(data)}"
    sha1hash    = OpenSSL::Digest::SHA1.new
    signature   = self.merchant_privatekey.sign(sha1hash,serial_data)
    return Base64.encode64(signature).chop #removes \n
  end

  def url_path(request=nil)
    return '/api/1'
  end

  def call_rpc(request)
    request.set_uuid(SecureRandom.uuid) if request.get_uuid().nil?
    return super(request)
  end

  def void(orderid)
    request = Trustly::Data::JSONRPCRequest.new('Void',{"OrderID"=>orderid},nil)
    return self.call_rpc(request)
  end

  def deposit(_options)
    options = {
      "Locale"            => "es_ES",
      "Country"           => "ES",
      "Currency"          => "EUR",
      "SuccessURL"        => "https://www.trustly.com/success",
      "FailURL"           => "https://www.trustly.com/fail",
      "NotificationURL"   => "https://test.trustly.com/demo/notifyd_test",
      "Amount"            => 0
    }.merge(_options)

    ["Locale","Country","Currency","SuccessURL","FailURL","Amount","NotificationURL","EndUserID","MessageID"].each do |req_attr|
      raise Trustly::Exception::DataError, "Option not valid '#{req_attr}'" if options.try(:[],req_attr).nil?
    end

    raise Trustly::Exception::DataError, "Amount is 0" if options["Amount"].nil? || options["Amount"].to_f <= 0.0

    attributes = options.slice(
      "Locale","Country","Currency",
      "SuggestedMinAmount","SuggestedMaxAmount","Amount",
      "Currency","Country","IP",
      "SuccessURL","FailURL","TemplateURL","URLTarget",
      "MobilePhone","Firstname","Lastname","NationalIdentificationNumber",
      "Email", "ShopperStatement"
    )

    data       = options.slice("NotificationURL","EndUserID","MessageID")

    # check required fields
    request = Trustly::Data::JSONRPCRequest.new('Deposit',data,attributes)
    return self.call_rpc(request)
    #options["HoldNotifications"] = "1" unless
  end

  def refund(_options)
    options = {
      "Currency" => "EUR"
    }.merge(_options)

    # check for required options
    ["OrderID","Amount","Currency"].each{|req_attr| raise Trustly::Exception::DataError, "Option not valid '#{req_attr}'" if options.try(:[],req_attr).nil? }

    request = Trustly::Data::JSONRPCRequest.new('Refund',options,nil)
    return self.call_rpc(request)
  end

  def notification_response(notification,success=true)
    response = Trustly::JSONRPCNotificationResponse.new(notification,success)
    response.set_signature(self.sign_merchant_request(response))
    return response
  end

  def withdraw(_options)

  end

end
