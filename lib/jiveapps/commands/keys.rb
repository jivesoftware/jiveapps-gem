module Jiveapps::Command
  class Keys < Base

    # Lists uploaded SSH keys
    def list
      long = args.any? { |a| a == '--long' }
      ssh_keys = jiveapps.keys
      if ssh_keys.empty?
        display "No keys for #{jiveapps.user}"
      else
        display "=== #{ssh_keys.size} key#{'s' if ssh_keys.size > 1} for #{jiveapps.user}"
        ssh_keys.each do |ssh_key|
          display long ? ssh_key['key'].strip : format_key_for_display(ssh_key['key'])
        end
      end
    end
    alias :index :list

    # Uploads an SSH Key
    # - args.first can either be a path to a key file or be nil. if nil, looks in default paths
    def add
      keyfile = find_key(args.first)
      key = File.read(keyfile)

      display "Uploading ssh public key #{keyfile}"
      jiveapps.add_key(key)
    end

    # Remove an SSH key
    # - args.first must be the name of the key
    def remove
      if args.first == nil
        display "No key specified. Please specify key to remove, for example:\n$ jiveapps keys:remove name@host"
        return
      end
      begin
        jiveapps.remove_key(args.first)
        display "Key #{args.first} removed."
      rescue RestClient::ResourceNotFound
        display "Key #{args.first} not found."
      end
    end

    # Check to see if this machine's SSH key (or the key passed in) has been registered with Jiveapps
    def check
      keyfile = find_key(args.first)
      key = File.read(keyfile)
      key_name = key.strip.split(/\s+/).last

      uploaded_key_names = jiveapps.keys.map{|key| key['name']}

      if uploaded_key_names.include?(key_name)
        display "This machine's SSH key \"#{key_name}\" has been registered with Jive Apps."
      else
        display "This machine's SSH key \"#{key_name}\" has not been registered with Jive Apps."
      end
    end

    private
      # Finds a key in the specified path or in the default locations (~/.ssh/id_(r|d)sa.pub)
      def find_key(path=nil)
        if !path.nil? && path.length > 0
          return path if File.exists? path
          raise CommandFailed, "No ssh public key found in #{path}."
        else
          %w(rsa dsa).each do |key_type|
            keyfile = "#{home_directory}/.ssh/id_#{key_type}.pub"
            return keyfile if File.exists? keyfile
          end
          raise CommandFailed, "No ssh public key found in #{home_directory}/.ssh/id_[rd]sa.pub.  You may want to specify the full path to the keyfile or generate it with this command: ssh-keygen -t rsa"
        end
      end

      # Formats an SSH key for display by trimming out the middle
      # Example Output:
      # ssh-rsa AAAAB3NzaC...Fyoke4MQ== pablo@jive
      def format_key_for_display(key)
        type, hex, local = key.strip.split(/\s/)
        [type, hex[0,10] + '...' + hex[-10,10], local].join(' ')
      end

  end
end