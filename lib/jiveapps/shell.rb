# Originally taken (and modified) from GitHub-Gem: https://github.com/defunkt/github-gem/blob/master/lib/github/command.rb

require 'systemu'

module Jiveapps
class Shell < String
  attr_reader :error
  attr_reader :out
  attr_reader :exit_status

  def initialize(command)
    @command = command
  end

  def run
    out = err = nil

    begin
      status, out, err = systemu(@command)
    rescue => e
      puts e.inspect
    end

    @exit_status = status.exitstatus

    replace @error = err unless err.empty?
    replace @out   = out unless out.empty?

    self
  end

  def command
    @command.join(' ')
  end

  def error?
    @exit_status != 0
  end

  def out?
    !!@out
  end

end
end
