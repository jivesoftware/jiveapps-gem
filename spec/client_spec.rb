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

  it "create -> should create a new app and return it's attributes" do
    stub_api_request(:post, "/apps").to_return(:body => <<-EOXML)
      {"app":{"name":"myapp","created_at":"2010-10-15T23:59:10Z","updated_at":"2010-10-15T23:59:10Z","id":1}}
    EOXML

    @client.create('myapp').should == {
      "name"       => "myapp",
      "created_at" => "2010-10-15T23:59:10Z",
      "updated_at" => "2010-10-15T23:59:10Z",
      "id"         => 1
    }
  end

  describe "ssh keys" do
    it "fetches a list of the user's current keys" do
      stub_api_request(:get, "/ssh_keys").to_return(:body => <<-EOXML)
        [
            {
                "ssh_key": {
                    "name": "foobar",
                    "created_at": "2010-11-01T18:31:04Z",
                    "updated_at": "2010-11-01T18:31:04Z",
                    "username": "testuser",
                    "id": 3,
                    "key": "a b foobar"
                }
            }
        ]
      EOXML
      @client.keys.should == [
        {
          "name"       => "foobar",
          "created_at" => "2010-11-01T18:31:04Z",
          "updated_at" => "2010-11-01T18:31:04Z",
          "username"   => "testuser",
          "id"         => 3,
          "key"        => "a b foobar"
        }
      ]
    end

    it "add_key(key) -> add an ssh key (e.g., the contents of id_rsa.pub) to the user" do
      stub_api_request(:post, "/ssh_keys").to_return(:body => <<-EOXML)
        {"ssh_key":{"key":"a key"}}
      EOXML
      @client.add_key('a key')
    end

    it "remove_key(key) -> remove an ssh key by name (user@box)" do
      ### Ugly hack - nginx/passenger unescapes the name before it gets to rails, causing routes to fail. double encode in production
      stub_api_request(:delete, "/ssh_keys/joe%40workstation")
      stub_api_request(:delete, "/ssh_keys/joe%2540workstation") # stub the double-encoded version too.
      @client.remove_key('joe@workstation')
    end

    # it "remove_all_keys -> removes all ssh keys for the user" do
    #   stub_api_request(:delete, "/ssh_keys")
    #   @client.remove_all_keys
    # end
  end


end
