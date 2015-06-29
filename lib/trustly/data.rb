class Trustly::Data
    
  attr_accessor :payload

  def initialize
    self.payload = {}
  end
  # Vacuum out all keys being set to Nil in the data to be communicated
  def vacumm(data)
    if data.is_a? Array
      ret = []
      data.each do |elem|
        unless elem.nil?
          v = self.vacumm elem
          ret.append(v) unless v.nil?
        end
      end
      return nil if ret.length == 0
      return ret
    elsif data.is_a? Hash
      ret = {}
      data.each do |key,elem|
        unless elem.nil?
          v = self.vacumm elem
          ret[key.to_s] = elem unless v.nil?
        end
      end
      return nil if ret.length == 0
      return ret
    else
      return data
    end
  end

  def get(name=nil)
    return name.nil? ? self.payload.dup : self.payload.try(:[],name) 
  end

  def get_from(sub,name)
    return nil if sub.nil? || name.nil? || self.payload.try(:[],sub).nil? || self.payload[sub].try(:[],name).nil?
    return self.payload[sub][name]
  end

  def set(name,value)
    self.payload[name] = value
    return value
  end

  def set_in(sub,name,value,parent=nil)
    return nil if sub.nil? || name.nil?
    self.payload[sub]       = {}      if self.payload.try(:[],sub).nil?
    self.payload[sub][name] = value
  end

  def pop(name)
    v = self.payload.try(:[],name)
    delete self.payload[name] unless v.nil?
    return v
  end

  def json()
    self.payload.to_json
  end
  
end