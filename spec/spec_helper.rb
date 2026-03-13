# frozen_string_literal: true

require 'json'
require 'net/http'
require 'openssl'
require 'base64'
require 'securerandom'
require 'webmock/rspec'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/slice'
require 'active_support/string_inquirer'

# Stub Rails.root since the gem references it in default options
unless defined?(Rails)
  module Rails
    def self.root
      File.expand_path('..', __dir__)
    end

    def self.env
      ActiveSupport::StringInquirer.new('test')
    end
  end
end

require 'trustly'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus
  config.order = :random
end
