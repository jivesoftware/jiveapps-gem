require 'jiveapps/helpers'
require 'jiveapps/commands/base'

Dir["#{File.dirname(__FILE__)}/commands/*.rb"].each { |c| require c }

module Jiveapps
  module Command
    class InvalidCommand < RuntimeError; end
    class CommandFailed  < RuntimeError; end

    extend Jiveapps::Helpers

    class << self

      def run(command, args, retries=0)
        begin
          run_internal 'auth:reauthorize', args.dup if retries > 0
          run_internal(command, args.dup)
        rescue InvalidCommand
          error "Unknown command. Run 'jiveapps help' for usage information."
        rescue RestClient::Unauthorized
          if retries < 3
            STDERR.puts "Authentication failure"
            run(command, args, retries+1)
          else
            error "Authentication failure"
          end
        rescue RestClient::ResourceNotFound => e
          error extract_not_found(e.http_body)
        rescue RestClient::RequestFailed => e
          error extract_error(e.http_body) unless e.http_code == 402
        rescue RestClient::RequestTimeout
          error "API request timed out. Please try again, or contact Jive via the community at https://developers.jivesoftware.com if this issue persists."
        rescue CommandFailed => e
          error e.message
        rescue Interrupt => e
          error "\n[canceled]"
        end
      end

      def run_internal(command, args)
        klass, method = parse(command)
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

      def extract_not_found(body)
        body =~ /^[\w\s]+ not found$/ ? body : "Resource not found"
      end

      def extract_error(body)
        msg = parse_error_xml(body) || parse_error_json(body) || 'Internal server error'
        msg.split("\n").map { |line| ' !   ' + line }.join("\n")
      end

      def parse_error_xml(body)
        xml_errors = REXML::Document.new(body).elements.to_a("//errors/error")
        msg = xml_errors.map { |a| a.text }.join(" / ")
        return msg unless msg.empty?
      rescue Exception
      end

      def parse_error_json(body)
        json = JSON.parse(body.to_s)
        json['error']
      rescue JSON::ParserError
      end

    end
  end
end
