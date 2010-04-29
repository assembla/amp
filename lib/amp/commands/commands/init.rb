command :init do |c|
  c.workflow :all
  
  c.desc "Initializes a new repository in the current directory."
  c.opt :type, "Which type of repository (git, hg)", :short => '-t', :type => :string, :default => 'hg'
  
  c.on_run do |options, args|
    path = args.first ? args.first : '.'
    
    case options[:type]
    when 'hg'
      Amp::Repositories::Mercurial::LocalRepository.new(path, true, options[:global_config])
    when 'git'
      Amp::Repositories::Git::LocalRepository.new(path, true, options[:global_config])
    else
      raise "Unknown repository type #{options[:type].inspect}"
    end
    
    puts "New #{options[:type]} repository initialized."
  end
end