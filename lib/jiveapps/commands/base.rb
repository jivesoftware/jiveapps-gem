module Jiveapps::Command
  class Base
    include Jiveapps::Helpers

    attr_accessor :args
    attr_reader :autodetected_app
    def initialize(args, jiveapps=nil)
      @args = args
      @jiveapps = jiveapps
      @autodetected_app = false
    end

    def jiveapps
      @jiveapps ||= Jiveapps::Command.run_internal('auth:client', args)
    end

    def extract_app(force=true)
      app = extract_option('--app', false)
      raise(CommandFailed, "You must specify an app name after --app") if app == false
      unless app
        app = extract_app_in_dir(Dir.pwd) ||
        raise(CommandFailed, "No app specified.\nRun this command from app folder or set it adding --app <app name>") if force
        @autodetected_app = true
      end
      app
    end

    def extract_app_in_dir(dir)
      return unless remotes = git_remotes(dir)

      if remote = extract_option('--remote')
        remotes[remote]
      elsif remote = extract_app_from_git_config
        remotes[remote]
      else
        apps = remotes.values.uniq
        case apps.size
          when 0; return nil
          when 1; return apps.first
          else
            current_dir_name = dir.split('/').last.downcase
            apps.select { |a| a.downcase == current_dir_name }.first
        end
      end
    end

    def extract_app_from_git_config
      remote = %x{ git config jiveapps.remote }.strip
      remote == "" ? nil : remote
    end

    def git_remotes(base_dir)
      git_config = "#{base_dir}/.git/config"
      unless File.exists?(git_config)
        parent = base_dir.split('/')[0..-2].join('/')
        return git_remotes(parent) unless parent.empty?
      else
        remotes = {}
        current_remote = nil
        File.read(git_config).split(/\n/).each do |l|
          current_remote = $1 if l.match(/\[remote \"([\w\d-]+)\"\]/)
          app = (l.match(/url = git@#{jiveapps.git_host}:([\w\d-]+)\.git/) || [])[1]
          if current_remote && app
            remotes[current_remote.downcase] = app
            current_remote = nil
          end
        end
        return remotes
      end
    end

    def extract_option(options, default=true)
      values = options.is_a?(Array) ? options : [options]
      return unless opt_index = args.select { |a| values.include? a }.first
      opt_position = args.index(opt_index) + 1
      if args.size > opt_position && opt_value = args[opt_position]
        if opt_value.include?('--')
          opt_value = nil
        else
          args.delete_at(opt_position)
        end
      end
      opt_value ||= default
      args.delete(opt_index)
      block_given? ? yield(opt_value) : opt_value
    end

  end
end