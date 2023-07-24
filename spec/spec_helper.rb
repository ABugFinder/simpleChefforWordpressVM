require 'chefspec'
require 'chefspec/policyfile'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.log_level = :error
end

at_exit { ChefSpec::Coverage.report! }