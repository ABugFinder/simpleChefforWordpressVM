# InSpec test for recipe wp-cb::php

# The InSpec reference, with examples and extensive documentation, can be
# found at https://www.inspec.io/docs/reference/resources/

unless os[:name] == 'ubuntu'
  # This is an example test, replace with your own test.
  describe user('php') do
    it { should exist }
  end
end

# This is an example test, replace it with your own test.
describe port(80) do
  it { should_not be_listening }
end
