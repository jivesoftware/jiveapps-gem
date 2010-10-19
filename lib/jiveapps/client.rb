require 'rubygems'
require 'rest_client'
require 'json/pure'

class Jiveapps::Client

  def self.version
    '0.0.1'
  end

  def self.gem_version_string
    "jiveapps-gem/#{version}"
  end

  attr_reader :host, :user, :password

  def initialize(user, password, host='becker-mbp.jiveland.com')
    @user     = user
    @password = password
    @host     = host
  end

  def list
    doc = JSON.parse(get('/apps.json').to_s)
    doc.map do |item|
      item['app']
    end
  end

  def info(app_name)
    response = get("/apps/#{app_name}.json")
    if response == 'null'
      return nil
    else
      doc = JSON.parse(response.to_s)
      doc['app']
    end
  end

  def on_warning(&blk)
    @warning_callback = blk
  end

  def get(uri, extra_headers={})    # :nodoc:
    process(:get, uri, extra_headers)
  end

  def process(method, uri, extra_headers={}, payload=nil)
    headers  = jiveapps_headers.merge(extra_headers)
    args     = [method, payload, headers].compact
    response = resource(uri).send(*args)

    extract_warning(response)
    response
  end

  def jiveapps_headers   # :nodoc:
    {
      'X-Jiveapps-API-Version' => '1',
      'User-Agent'             => self.class.gem_version_string,
      'X-Ruby-Version'         => RUBY_VERSION,
      'X-Ruby-Platform'        => RUBY_PLATFORM
    }
  end

  def resource(uri)
    RestClient.proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
    if uri =~ /^https?/
      RestClient::Resource.new(uri, user, password)
    else
      RestClient::Resource.new("http://#{host}:3000", user, password)[uri]
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
