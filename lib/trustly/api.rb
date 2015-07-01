
class Trustly::Api 

  attr_accessor :api_host, :api_port, :api_is_https,:last_request,:trustly_publickey,:trustly_verifyer

  def serialize_data(object)
    serialized  = ""
    if object.is_a?(Array)
      # Its an array 
      object.each do |obj|
        serialized.concat(obj.is_a?(Hash) ? serialize_data(obj) : obj.to_s)
      end
    elsif object.is_a?(Hash)
      # Its a Hash
      object.sort.to_h.each do |key,value|
        serialized.concat(key.to_s).concat(serialize_data(value))
      end
    else
      # Anything else: numbers, symbols, values
      serialized.concat object.to_s
    end
    return serialized
  end

  def initialize(host,port,is_https,pem_file)
    self.api_host     = host
    self.api_port     = port
    self.api_is_https = is_https

    self.load_trustly_publickey(pem_file)
  end

  def load_trustly_publickey(file)
    self.trustly_publickey = OpenSSL::PKey::RSA.new(File.read(file)) #.public_key
  end

  def url_path(request=nil)
    raise NotImplementedError
  end

  def handle_response(request,httpcall)
    raise NotImplementedError
  end

  def insert_credentials(request)
    raise NotImplementedError
  end

  def verify_trustly_signed_notification(response)
    method    = response.get_method()
    uuid      = response.get_uuid()
    signature = response.get_signature()
    data      = response.get_data()
    return self._verify_trustly_signed_data(method, uuid, signature, data)
  end

  protected

  def _verify_trustly_signed_data(method, uuid, signature, data)
    method        = '' if method.nil?
    uuid          = '' if uuid.nil?
    serial_data   = "#{method}#{uuid}#{self.serialize_data(data)}"
    raw_signature = Base64.decode64(signature)
    return self.trustly_publickey.public_key.verify(OpenSSL::Digest::SHA1.new, raw_signature, serial_data)
  end

  def verify_trustly_signed_response(response)
    method    = response.get_method()
    uuid      = response.get_uuid()
    signature = response.get_signature()
    data      = response.get_data()
    return self._verify_trustly_signed_data(method, uuid, signature, data)
  end


  def set_host(host=nil,port=nil,is_https=nil)
    self.api_host = host          unless host.nil?
    self.load_trustly_publickey() unless host.nil?
    self.api_port = port          unless port.nil?
    self.is_https = is_https      unless is_https.nil?
  end

  def base_url
    if self.api_is_https
      return (self.api_port == 443) ? "https://#{self.api_host}" : "https://#{self.api_host}:#{self.api_port}"
    else
      return (self.api_port == 80)  ? "http://#{self.api_host}"  : "http://#{self.api_host}:#{self.api_port}"
    end
  end

  def uri(request)
    return URI("#{self.base_url}#{self.url_path(request)}")
  end

  def call_rpc(request)
    self.insert_credentials(request)
    self.last_request    = request
    uri                  = self.uri(request)
    http_req             = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    http_req.body        = request.json()
    http_res             = Net::HTTP.start(uri.hostname, uri.port,{use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE}) { |http| http.request(http_req) }
    return self.handle_response(request,http_res)
  end



end
  

