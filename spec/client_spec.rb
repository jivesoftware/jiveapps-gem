require 'spec_helper'

describe Jiveapps::Client do

  before do
    @client = Jiveapps::Client.new(nil, nil)
  end

  describe "apps" do
    it "list -> get a list of this user's apps" do
      stub_api_request(:get, "/apps").to_return(:body => <<-EOJSON)
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
      EOJSON
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
      stub_api_request(:get, "/apps/myapp?extended=true").to_return(:body => <<-EOJSON)
        {"app":{"name":"myapp","created_at":"2010-10-15T23:59:10Z","updated_at":"2010-10-15T23:59:10Z","id":1}}
      EOJSON

      @client.info('myapp').should == {
        "name"       => "myapp",
        "created_at" => "2010-10-15T23:59:10Z",
        "updated_at" => "2010-10-15T23:59:10Z",
        "id"         => 1
      }
    end

    it "create -> should create a new app and return it's attributes" do
      stub_api_request(:post, "/apps").to_return(:body => <<-EOJSON)
        {"app":{"name":"myapp","created_at":"2010-10-15T23:59:10Z","updated_at":"2010-10-15T23:59:10Z","id":1}}
      EOJSON

      @client.create('myapp').should == {
        "name"       => "myapp",
        "created_at" => "2010-10-15T23:59:10Z",
        "updated_at" => "2010-10-15T23:59:10Z",
        "id"         => 1
      }
    end
  end

  describe "ssh keys" do
    it "fetches a list of the user's current keys" do
      stub_api_request(:get, "/ssh_keys").to_return(:body => <<-EOJSON)
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
      EOJSON
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
      stub_api_request(:post, "/ssh_keys").with(:body => "{\"ssh_key\":{\"key\":\"a key\"}}").to_return(:body => <<-EOJSON)
        {"ssh_key":{"key":"a key"}}
      EOJSON
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

  describe "collaborators" do
    it "list(app_name) -> list app collaborators" do
      stub_api_request(:get, "/apps/myapp/collaborators").to_return(:body => <<-EOJSON)
          [
              {
                  "collaborator": {
                      "created_at": "2011-02-04T11:16:55-08:00",
                      "updated_at": "2011-02-04T11:16:55-08:00",
                      "app_id": 135,
                      "id": 637,
                      "user_id": 120,
                      "user": {
                          "created_at": "2011-02-04T11:16:51-08:00",
                          "updated_at": "2011-02-04T11:16:51-08:00",
                          "username": "scott.becker",
                          "id": 120
                      }
                  }
              },
              {
                  "collaborator": {
                      "created_at": "2011-02-07T17:45:26-08:00",
                      "updated_at": "2011-02-07T17:45:26-08:00",
                      "app_id": 135,
                      "id": 657,
                      "user_id": 70,
                      "user": {
                          "created_at": "2011-02-04T11:16:51-08:00",
                          "updated_at": "2011-02-04T11:16:51-08:00",
                          "username": "aron.racho",
                          "id": 70
                      }
                  }
              }
          ]
      EOJSON
      @client.list_collaborators('myapp').should == [
        { :username => 'scott.becker' },
        { :username => 'aron.racho' }
      ]
    end

    it "add_collaborator(app_name, username) -> adds collaborator to app" do
      stub_api_request(:post, "/apps/myapp/collaborators").with(:body => "{\"collaborator\":{\"username\":\"joe@example.com\"}}")
      @client.add_collaborator('myapp', 'joe@example.com')
    end

    it "remove_collaborator(app_name, username) -> removes collaborator from app" do
      stub_api_request(:delete, "/apps/myapp/collaborators/joe%40example%2Ecom")
      stub_api_request(:delete, "/apps/myapp/collaborators/joe%2540example%252Ecom") # Stub double encoded version too
      @client.remove_collaborator('myapp', 'joe@example.com')
    end
  end

end
