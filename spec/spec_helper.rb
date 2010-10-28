require 'rspec'
require 'webmock/rspec'

Rspec.configure do |c|
  c.mock_with :rspec
  c.include WebMock::API
end

require 'jiveapps'
require 'jiveapps/command'
require 'jiveapps/commands/base'
Dir["#{File.dirname(__FILE__)}/../lib/jiveapps/commands/*"].each { |c| require c }
require 'jiveapps/client'

def stub_api_request(method, path)
  stub_request(method, "http://#{Jiveapps::WEBHOST}#{path}.json")
end

def prepare_command(klass)
  command = klass.new(['--app', 'myapp'])
  command.stub!(:args).and_return([])
  command.stub!(:display)
  command.stub!(:jiveapps).and_return(mock('jiveapps client', :host => 'jiveapps.com'))
  command.stub!(:extract_app).and_return('myapp')
  command
end
