# frozen_string_literal: true

require 'tmpdir'

module ApiHelper
  def self.generate_test_certs
    key = OpenSSL::PKey::RSA.new(2048)
    dir = Dir.mktmpdir('trustly_test')
    private_pem = File.join(dir, 'test.merchant.private.pem')
    public_pem = File.join(dir, 'test.trustly.public.pem')
    File.write(private_pem, key.to_pem)
    File.write(public_pem, key.public_key.to_pem)
    { dir: dir, private_pem: private_pem, public_pem: public_pem }
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    certs = ApiHelper.generate_test_certs
    $test_certs = certs
  end

  config.after(:suite) do
    FileUtils.rm_rf($test_certs[:dir]) if $test_certs
  end
end
