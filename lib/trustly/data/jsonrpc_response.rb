class Trustly::Data::JSONRPCResponse < Trustly::Data::Response

  def initialize(http_response)
    super(http_response)
    version = self.get("version")
    raise Trustly::Exception::JSONRPCVersionError, "JSON RPC Version is not supported" if version != '1.1'
  end

  def get_data(name=nil)
    return self.response_result.try(:[],"data") if name.nil?
    return Trustly::Exception::DataError, "Data not found or key is null" if self.response_result.try(:[],"data").nil? || name.nil?
    return self.response_result["data"][name]
  end

end