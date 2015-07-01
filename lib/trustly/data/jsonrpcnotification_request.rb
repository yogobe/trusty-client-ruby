class Trustly::JSONRPCNotificationRequest < Trustly::Data

  attr_accessor :notification_body, :payload

  def initialize(notification_body)
    super()
    self.notification_body = notification_body
    unless self.notification_body.is_a?(Hash)
      begin
        self.payload = JSON.parse(self.notification_body)
      rescue JSON::ParserError => e 
        raise Trustly::Exception::DataError, e.message
      end

      raise Trustly::Exception::JSONRPCVersionError, 'JSON RPC Version #{(self.get_version()} is not supported' if self.get_version() != '1.1'
    else
      self.payload = self.notification_body.deep_stringify_keys
    end
  end

  def get_version()
    return self.get('version')
  end

  def get_method()
    return self.get('method')
  end

  def get_uuid()
    return self.get_params('uuid')
  end

  def get_signature()
    return self.get_params('signature')
  end

  def get_params(name)
    raise KeyError,"#{name} is not present in params" if name.nil? || self.payload.try(:[],"params").nil? || self.payload["params"].try(:[],name).nil?
    return self.payload["params"][name]
  end

  def get_data(name=nil)
    if name.nil?
      raise KeyError,"Data not present" if self.payload.try(:[],"params").nil? || self.payload["params"].try(:[],"data").nil?
      return self.payload["params"]["data"]
    else
      raise KeyError,"#{name} is not present in data" if name.nil? || self.payload.try(:[],"params").nil? || self.payload["params"].try(:[],"data").nil? || self.payload["params"]["data"].try(:[],name).nil?
      return self.payload["params"]["data"][name]
    end
  end

end
