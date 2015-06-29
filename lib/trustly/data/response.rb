class Trustly::Data::Response < Trustly::Data
  attr_accessor :response_status, :response_reason, :response_body, :response_result

  def initialize(http_response) #called from Net::HTTP.get_response("trustly.com","/api_path") -> returns Net::HTTPResponse 
    super()
    self.response_status = http_response.code
    self.response_reason = http_response.class.name
    self.response_body   = http_response.body
    begin
      self.payload       = JSON.parse(self.response_body)
    rescue JSON::ParserError => e 
      if self.response_status != 200
        raise Trustly::Exception::ConnectionError, "#{self.response_status}: #{self.response_reason} [#{self.response_body}]"
      else
        raise Trustly::Exception::DataError, e.message
      end
    end

    begin
      self.response_result = self.get('result')
    rescue IndexError::KeyError => e
      self.response_result = nil
    end

    if self.response_result.nil?
      begin
        self.response_result = self.payload["error"]["error"]
      rescue IndexError::KeyError => e
      end
    end
    raise Trustly::Exception::DataError, "No result or error in response #{self.payload}" if self.response_result.nil?
  end

  def error?
    return !self.get('error').nil?
  rescue IndexError::KeyError => e
    return false
  end

  def error_code
    return nil unless self.error?
    return self.response_result["data"].try(:[],'code')
  end

  def error_msg
    return nil unless self.error?
    return self.response_result["data"].try(:[],'message')
  end

  def success?
    return !self.get('result').nil?
  rescue IndexError::KeyError => e
    return false
  end

  def get_uuid
    return self.response_result.try(:[],'uuid')
  end

  def get_method
    return self.response_result.try(:[],'method')
  end

  def get_signature
    return self.response_result.try(:[],"signature")
  end

  def get_result
    unless name.nil?
      if self.response_result.is_a?(Hash)
        return self.response_result.try(:[],name)
      else
        raise StandardError::TypeError, "Result is not a Hash"
      end
    else
      return self.response_result.dup
    end
  end

end