class CreateGenerator < RubiGen::Base

  include Jiveapps::Helpers

  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  default_options :author => nil

  attr_reader :name

  attr_reader :title,
              :description,
              :author_name,
              :author_affiliation,
              :author_email

  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @destination_root = File.expand_path(args.first)
    @name = base_name
    extract_options
  end

  def manifest
    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory ''
      BASEDIRS.each { |path| m.directory path }

      # Create stubs
      m.template "app.xml",                  "app.xml"
      m.template "canvas.html",              "canvas.html"
      m.template "home.html",                "home.html"
      m.template "hello.html",               "hello.html"
      m.template "stylesheets/main.css",     "stylesheets/main.css"
      m.template "javascripts/main.js",      "javascripts/main.js"
      m.file     "images/icon16.png",        "images/icon16.png"
      m.file     "images/icon48.png",        "images/icon48.png"
      m.file     "images/icon128.png",       "images/icon128.png"

      # Samples
      # m.template_copy_each ["template.rb", "template2.rb"]
      # m.file     "file",         "some_file_copied"
      # m.file_copy_each ["path/to/file", "path/to/file2"]

      # m.dependency "install_rubigen_scripts", [destination_root, 'create'],
      #   :shebang => options[:shebang], :collision => :force
    end
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

      @title              = get_app_prop_with_default('App Title',           name)
      @description        = get_app_prop_with_default('App Description',     'Description of ' + name)
      @author_name        = get_or_set_git_prop('--global user.name',        'Author Name')
      @author_affiliation = get_or_set_git_prop('--global user.affiliation', 'Author Affiliation / Company Name')
      @author_email       = get_or_set_git_prop('--global user.email',       'Author Email')
    end

    # Installation skeleton.  Intermediate directories are automatically
    # created so don't sweat their absence here.
    BASEDIRS = %w(
      javascripts
      stylesheets
      images
    )
end