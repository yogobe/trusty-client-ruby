class Trustly::Data::JSONRPCRequest < Trustly::Data::Request

  def initialize(method=nil,data=nil,attributes=nil)

    if !data.nil? || !attributes.nil?
      self.payload = {"params"=>{}}
      unless data.nil?
        if !data.is_a?(Hash) && !attributes.nil?
          raise TypeError, "Data must be a Hash if attributes is provided"
        else
          self.payload["params"]["Data"] = data
        end
      else
        self.payload["params"]["Data"] = {}
      end

      self.payload["params"]["Data"]["Attributes"] = attributes unless attributes.nil?
    end

    self.payload['method']  = method unless method.nil?
    self.payload['params']  = {}     unless self.get('params')
    self.payload['version'] = '1.1'

  end


  def get_param(name)
    return self.payload['params'].try(:[],name)
  end

  def get_data(name=nil)
    data = self.get_param('Data')
    return data if name.nil?
    raise  KeyError, "Not found #{name} in data" if data.nil?
    return data.dup if name.nil?
    return data.try(:[],name)
  end

  def get_attribute(name)
    data        = self.get_param('Data')
    if data.nil?
      attributes  = nil
    else
      attributes  = data.try(:[],'Attributes')
    end
    raise KeyError, "Not found 'Attributes' in data" if attributes.nil?
    return attributes.dup if name.nil?
    return attributes.try(:[],name)
  end

  def set_param(name,value)
    self.payload['params'][name] = value
  end

  def set_data(name,value)
    unless name.nil?
      self.payload['params']['Data']       = {} if self.payload['params'].try(:[],'Data').nil?
      self.payload['params']['Data'][name] = value
    end
    return value
  end

  def set_attributes(name,value)
    unless name.nil?
      self.payload['params']['Data']                     = {} if self.payload['params'].try(:[],'Data').nil?
      self.payload['params']['Data']['Attributes']       = {} if self.payload['params']['Data'].try(:[],'Attributes').nil?
      self.payload['params']['Data']['Attributes'][name] = value
    end
    return value
  end

  def set_uuid(uuid)
    return self.set_param('UUID',uuid)
  end

  def get_uuid
    return self.get_param('UUID')
  rescue KeyError => e 
    return nil
  end 

  def set_method(method)
    return self.set('method',method)
  end

  def get_method()
    return self.get('method')
  rescue KeyError => e
    return nil
  end

end