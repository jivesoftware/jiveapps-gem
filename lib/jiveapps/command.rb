require 'jiveapps/helpers'
require 'jiveapps/commands/base'

Dir["#{File.dirname(__FILE__)}/commands/*.rb"].each { |c| require c }

module Jiveapps
  module Command
    class InvalidCommand < RuntimeError; end
    class CommandFailed  < RuntimeError; end

    extend Jiveapps::Helpers

    class << self

      def run(command, args)
        # puts "command: #{command.inspect}"
        # puts "args: #{args.inspect}"
        
        begin
          run_internal(command, args.dup)
        rescue InvalidCommand
          puts "command: #{command}, args.dup: #{args.dup}"
          error "Unknown command. Run 'jiveapps help' for usage information."
        end
      end

      def run_internal(command, args)
        klass, method = parse(command)
        # puts "klass: #{klass.inspect}"
        runner = klass.new(args)
        raise InvalidCommand unless runner.respond_to?(method)
        runner.send(method)
      end

      def parse(command)
        parts = command.split(':')
        case parts.size
          when 1
            begin
              return eval("Jiveapps::Command::#{command.capitalize}"), :index
            rescue NameError, NoMethodError
              return Jiveapps::Command::App, command
            end
          when 2
            begin
              return Jiveapps::Command.const_get(parts[0].capitalize), parts[1]
            rescue NameError
              raise InvalidCommand
            end
          else
            raise InvalidCommand
        end
      end


      ### Helpers

      def error(msg)
        STDERR.puts(msg)
        exit 1
      end

    end
  end
end
