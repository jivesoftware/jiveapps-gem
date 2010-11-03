require 'rubygems'
require 'rest_client'
require 'json'

class Jiveapps::Client

  def self.version
    '0.0.1'
  end

  def self.gem_version_string
    "jiveapps-gem/#{version}"
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
      return []
    end
  end

  def info(name)
    begin
      item = get("/apps/#{name}")
      item['app']
    rescue RestClient::ResourceNotFound
      nil
    end
  end

  def create(name)
    item = post("/apps", {:app => {:name => name}})

    if item.class == Hash && item['app']
      item['app']
    else
      nil
    end
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
    ### Ugly hack - nginx/passenger unescapes the name before it gets to rails, causing routes to fail. double encode in production
    if Jiveapps::WEBHOST =~ /^becker/ # in dev mode
      delete("/ssh_keys/#{escape(name)}").to_s
    else # in production mode
      delete("/ssh_keys/#{escape(escape(name))}").to_s
    end
  end

  ### General

  def on_warning(&blk)
    @warning_callback = blk
  end

  def get(uri, extra_headers={})    # :nodoc:
    process(:get, uri, extra_headers)
  end

  def post(uri, object, extra_headers={})    # :nodoc:
    process(:post, uri, extra_headers, JSON.dump(object))
  end

  def put(uri, object, extra_headers={})    # :nodoc:
    process(:put, uri, extra_headers, JSON.dump(object))
  end

  def delete(uri, extra_headers={})    # :nodoc:
    process(:delete, uri, extra_headers)
  end

  def process(method, uri, extra_headers={}, payload=nil)
    headers  = jiveapps_headers.merge(extra_headers)
    args     = [method, payload, headers].compact
    response = resource(uri).send(*args)

    extract_warning(response)
    parse_response(response.to_s)
  end

  def parse_response(response)
    if response == 'null' || response.strip.length == 0
      return nil
    else
      return JSON.parse(response.strip)
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

  def escape(value)  # :nodoc:
    escaped = URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    escaped.gsub('.', '%2E') # not covered by the previous URI.escape
  end

  def resource(uri)
    RestClient.proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
    if uri =~ /^https?/
      RestClient::Resource.new(uri, user, password)
    else
      RestClient::Resource.new("http://#{host}", user, password)[uri]
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

end
