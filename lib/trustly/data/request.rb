class Trustly::Data::Request < Trustly::Data

  attr_accessor :method

  def initialize(method=nil,payload=nil)
    super
    self.payload = self.vacuum(payload) unless payload.nil?
    unless method.nil?
      self.method  = method
    else
      self.method  = self.payload.get('method')
    end
  end

  def get_method
    return self.method
  end

  def set_method(method)
    self.method = method
    return method
  end

  def get_uuid
    return self.payload.get('uuid')
  end

  def set_uuid
    self.set('uuid',uuid)
    return uuid
  end

end