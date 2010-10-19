module Jiveapps::Command
  class Base
    include Jiveapps::Helpers

    attr_accessor :args
    def initialize(args)
      @args = args
    end

    def ask
      gets.strip
    end

    def jiveapps
      @jiveapps ||= Jiveapps::Command.run_internal('auth:client', args)
    end

  end
end