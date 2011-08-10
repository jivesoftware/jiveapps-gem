module Jiveapps::Command
  class Keys < Base

    SSH_KEY_REGEX = /^((?:[A-Za-z0-9-]+(?:="[^"]+")?,?)+ *)?(ssh-(?:dss|rsa)) *([^ ]*) *(.*)/

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
      silent = extract_option("--silent").present?
      keyfile = find_key(args.first)
      key = File.read(keyfile)
      validate_key(key, keyfile)

      display "Uploading ssh public key #{keyfile}" unless silent
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

      def validate_key(key, keyfile)
        if SSH_KEY_REGEX.match(key.strip).nil?
          fake_key = "ssh-rsa NAyG4kbVIZyokH/hMDkLbrFBktxPgsQKBgQDshif7w5RgOTK0eaNC6AJbjX0NTOgoTtbjQIX0s9fAUiakcxU3Qqna9ONXlL1mgf+WZ3KgOyUyNcgz2JPWinZseoTDNukRixqcLS9HO8qOWoLUHJZID1q1xf/btESt4UylEMiykEn712YGqCpVdFxX+q7z7b6Z5G/9n49hKWN22wKBgQCBDM1DUeqOX5Li2Hnj/EF/PfhGypAlhz/Klh40foNq7TziwFtkTZz06HpRNIhK2VcoLhU49f2v6CrcaEmll9Zs5Hw2VMrSeTNReO5gRfxlrId1imhfBkYUaZImEKSWAe3HgdyihCmXqf5SCQOtVmm5lxbgaSBjz== your.name@machine.name"

          raise CommandFailed, "Invalid SSH public key format found at \"#{keyfile}\":\n\n#{key}\n\nExample of correct format:\n\n#{fake_key}\n\nCheck and fix, or regenerate key with this command:\n$ ssh-keygen -t rsa"
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