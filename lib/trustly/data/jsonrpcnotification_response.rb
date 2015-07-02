class Trustly::JSONRPCNotificationResponse < Trustly::Data
  
  def initialize(request,success=nil)
    super()
    uuid   = request.get_uuid()
    method = request.get_method()

    self.set('version')
    self.set_result('uuid',uuid)     unless uuid.nil?
    self.set_result('method',method) unless method.nil?
    self.set_data('success', (!success.nil? && !success ? 'FAILED' : 'OK' ))
  end

  def set_result(name,value)
    return nil if name.nil? || value.nil?
    self.payload["result"]                = {} if self.payload.try(:[],"result").nil?
    self.payload["result"][name]          = value
  end

  def set_data(name,value)
    return nil if name.nil? || value.nil?
    self.payload["result"]               = {} if self.payload.try(:[],"result").nil?
    self.payload["result"]["data"]       = {} if self.payload["result"].try(:[],"data").nil?
    self.payload["result"]["data"][name] = value
  end

  def get_result(name)
    raise KeyError,"#{name} is not present in result" if name.nil? || self.payload.try(:[],"result").nil? || self.payload["result"].try(:[],name).nil?
    return self.payload["result"][name]
  end

  def get_data(name=nil)
    raise KeyError,"#{name} is not present in data" if name.nil? || self.payload.try(:[],"result").nil? || self.payload["result"].try(:[],"data").nil? || self.payload["result"]["data"].try(:[],name).nil?
    return self.payload["result"]["data"][name]
  end

  def get_data(name=nil)
    if name.nil?
      raise KeyError,"Data not present" if self.payload.try(:[],"result").nil? || self.payload["result"].try(:[],"data").nil?
      return self.payload["result"]["data"]
    else
      raise KeyError,"#{name} is not present in data" if name.nil? || self.payload.try(:[],"result").nil? || self.payload["result"].try(:[],"data").nil? || self.payload["result"]["data"].try(:[],name).nil?
      return self.payload["result"]["data"][name]
    end
  end

  def get_method
    return self.get_result('method')
  end

  def get_uuid
    return self.get_result('uuid')
  end

  def get_signature
    return self.get_result('signature')
  end

end