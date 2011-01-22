require 'rubygems'
require 'rest_client'
require 'active_support'

class Jiveapps::Client

  def self.gem_version_string
    "jiveapps-gem/#{Jiveapps::VERSION}"
  end

  attr_reader :host, :user, :password

  def initialize(user, password, host=Jiveapps::WEBHOST)
    @user     = user
    @password = password
    @host     = host
  end

  ### Apps

  def list
    apps = get('/apps')

    if apps.class == Array
      apps.map { |item| item['app'] }
    else
      return apps
    end
  end

  def info(name)
    begin
      item = get("/apps/#{escape(name)}?extended=true")
      item.class == Hash && item['app'] ? item['app'] : item
    rescue RestClient::ResourceNotFound
      nil
    end
  end

  def post_app(path, obj)
    begin
      item = post(path, obj)
      if item.class == Hash && item['app']
        item['app']
      else
        item
      end
    rescue => e
      if e.response.body =~ /^\{/ # assume this is JSON if it starts with "{"
        errors = ActiveSupport::JSON.decode(e.response.body)
        return {"errors" => errors}
      else
        nil
      end
    end
  end

  def create(name)
    post_app("/apps", {:app => {:name => name}})
  end

  def delete_app(name)
    delete("/apps/#{escape(name)}").to_s
  end

  def register(name)
    post_app("/apps/#{escape(name)}/register", {})
  end

  def install(name)
    post_app("/apps/#{escape(name)}/install", {})
  end

  ### SSH Keys

  def keys
    ssh_keys = get('/ssh_keys')

    if ssh_keys.class == Array
      ssh_keys.map { |item| item['ssh_key'] }
    else
      return []
    end
  end

  def add_key(key)
    item = post("/ssh_keys", {:ssh_key => {:key => key}})

    if item.class == Hash && item['ssh_key']
      item['ssh_key']
    else
      nil
    end
  end

  def remove_key(name)
    delete("/ssh_keys/#{escape(name)}").to_s
  end

  ### OAuth Services

  def oauth_services(app_name)
    services = get("/apps/#{app_name}/oauth_services")

    if services.class == Array
      services.map { |item| item['oauth_service'] }
    else
      return []
    end
  end

  def add_oauth_service(app_name, name, key, secret)
    post("/apps/#{app_name}/oauth_services", {:oauth_service => {:name => name, :key => key, :secret => secret}})
  end

  def remove_oauth_service(app_name, name)
    delete("/apps/#{app_name}/oauth_services/#{name}")
  end

  ### General

  def version
    get("/gem_version").to_s
  end

  def on_warning(&blk)
    @warning_callback = blk
  end

  def get(uri, extra_headers={})    # :nodoc:
    process(:get, uri, extra_headers)
  end

  def post(uri, object, extra_headers={})    # :nodoc:
    process(:post, uri, extra_headers, ActiveSupport::JSON.encode(object))
  end

  def put(uri, object, extra_headers={})    # :nodoc:
    process(:put, uri, extra_headers, ActiveSupport::JSON.encode(object))
  end

  def delete(uri, extra_headers={})    # :nodoc:
    process(:delete, uri, extra_headers)
  end

  def process(method, uri, extra_headers={}, payload=nil)
    headers  = jiveapps_headers.merge(extra_headers)
    args     = [method, payload, headers].compact
    
    begin
      response = resource(uri).send(*args)
      extract_warning(response)
      parse_response(response.to_s)
    rescue RestClient::BadRequest => e
      puts e.response.body
      return nil
    end
  end

  def parse_response(response)
    return nil if response == 'null' || response.strip.length == 0
    response_text = response.strip

    if response_text =~ /^\{|^\[/
      return ActiveSupport::JSON.decode(response_text)
    else
      return response_text
    end
  end

  def jiveapps_headers   # :nodoc:
    {
      'X-Jiveapps-API-Version' => '1',
      'User-Agent'             => self.class.gem_version_string,
      'X-Ruby-Version'         => RUBY_VERSION,
      'X-Ruby-Platform'        => RUBY_PLATFORM,
      'Accept'                 => 'application/json',
      'Content-Type'           => 'application/json'
    }
  end

  def escape(value) # :nodoc:
    ### Ugly hack - nginx/passenger unescapes the name before it gets
    ### to rails, causing routes to fail. double encode in production
    if Jiveapps::MODE == 'production'
      _escape(_escape(value))
    else
      _escape(value)
    end
  end

  def _escape(value)  # :nodoc:
    escaped = URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    escaped.gsub('.', '%2E') # not covered by the previous URI.escape
  end

  def resource(uri)
    RestClient.proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
    if uri =~ /^http?/
      RestClient::Resource.new(uri, user, password)
    else
      RestClient::Resource.new(host, user, password)[uri]
    end
  end

  def extract_warning(response)
    return unless response
    if response.headers[:x_jiveapps_warning] && @warning_callback
      warning = response.headers[:x_jiveapps_warning]
      @displayed_warnings ||= {}
      unless @displayed_warnings[warning]
        @warning_callback.call(warning)
        @displayed_warnings[warning] = true
      end
    end
  end

  def git_host
    host.gsub(/^(http|https):\/\//, '')
  end

end
