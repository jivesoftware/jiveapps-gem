require 'spec_helper'

describe Jiveapps::Client do

  before do
    @client = Jiveapps::Client.new(nil, nil)
  end

  it "list -> get a list of this user's apps" do
    stub_api_request(:get, "/apps").to_return(:body => <<-EOXML)
      [
        {
          "app": {
            "name"       : "foo",
            "created_at" : "2010-10-15T23:59:10Z",
            "updated_at" : "2010-10-15T23:59:10Z",
            "id"         : 1
          }
        },
        {
          "app": {
            "name"       : "bar",
            "created_at" : "2010-10-16T01:12:16Z",
            "updated_at" : "2010-10-16T01:12:16Z",
            "id"         : 2
          }
        }
      ]
    EOXML
    @client.list.should == [
      {
        "name"       => "foo",
        "created_at" => "2010-10-15T23:59:10Z",
        "updated_at" => "2010-10-15T23:59:10Z",
        "id"         => 1
      },
      {
        "name"       => "bar",
        "created_at" => "2010-10-16T01:12:16Z",
        "updated_at" => "2010-10-16T01:12:16Z",
        "id"         => 2
      }
    ]
  end

  it "info -> get app attributes" do
    stub_api_request(:get, "/apps/myapp").to_return(:body => <<-EOXML)
      {"app":{"name":"myapp","created_at":"2010-10-15T23:59:10Z","updated_at":"2010-10-15T23:59:10Z","id":1}}
    EOXML

    @client.info('myapp').should == {
      "name"       => "myapp",
      "created_at" => "2010-10-15T23:59:10Z",
      "updated_at" => "2010-10-15T23:59:10Z",
      "id"         => 1
    }
  end

end
