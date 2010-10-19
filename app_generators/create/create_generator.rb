class CreateGenerator < RubiGen::Base

  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  default_options :author => nil

  attr_reader :name

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @destination_root = File.expand_path(args.shift)
    @name = base_name
    extract_options
  end

  def manifest
    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory ''
      BASEDIRS.each { |path| m.directory path }

      # Create stubs
      m.template "app.xml",  "app.xml"
      m.template "stylesheets/main.css", "stylesheets/main.css"
      m.template "javascripts/main.js", "javascripts/main.js"
      # m.template_copy_each ["template.rb", "template2.rb"]
      # m.file     "file",         "some_file_copied"
      # m.file_copy_each ["path/to/file", "path/to/file2"]

      # m.dependency "install_rubigen_scripts", [destination_root, 'create'],
      #   :shebang => options[:shebang], :collision => :force
    end
  end

  def after_generate
    create_local_repo
    create_remote_git_repo_and_push
    notify_user
  end

  def create_local_repo
    run("git init #{@destination_root}")
    run("cd #{@destination_root} && git add . && git commit -m 'initial commit'")
  end

  def create_remote_git_repo_and_push
    run("curl -u testuser:testpass -H 'Content-Type: application/json' -d '{\"app\": {\"name\":\"#{@name}\"}}' http://becker-mbp.jiveland.com:3000/apps.json")
    run("cd #{@destination_root} && git remote add jiveapps git://becker-mbp.jiveland.com/#{@name}.git")
    run("cd #{@destination_root} && git push jiveapps master")
  end

  def notify_user
    puts ""
    puts ""
    puts ""
    puts "Congratulations, you have created a new Jive App!"
    puts "================================================="
    puts "Git URL: git://becker-mbp.jiveland.com/#{@name}.git"
    puts "App URL: http://becker-mbp.jiveland.com:3000/apps/#{@name}/app.xml"
  end

  def run(command)
    # puts command
    `#{command} > /dev/null`
  end

  protected
    def banner
      <<-EOS
Creates a ...

USAGE: #{spec.name} name
EOS
    end

    def add_options!(opts)
      opts.separator ''
      opts.separator 'Options:'
      # For each option below, place the default
      # at the top of the file next to "default_options"
      # opts.on("-a", "--author=\"Your Name\"", String,
      #         "Some comment about this option",
      #         "Default: none") { |o| options[:author] = o }
      opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
    end

    def extract_options
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      # Templates can access these value via the attr_reader-generated methods, but not the
      # raw instance variable value.
      # @author = options[:author]
    end

    # Installation skeleton.  Intermediate directories are automatically
    # created so don't sweat their absence here.
    BASEDIRS = %w(
      javascripts
      stylesheets
    )
end