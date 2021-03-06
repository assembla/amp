# -*- ruby -*-
##################################################################
#                  Licensing Information                         #
#                                                                #
#  The following code is licensed, as standalone code, under     #
#  the Ruby License, unless otherwise directed within the code.  #
#                                                                #
#  For information on the license of this code when distributed  #
#  with and used in conjunction with the other modules in the    #
#  Amp project, please see the root-level LICENSE file.          #
#                                                                #
#  © Michael J. Edgar and Ari Brown, 2009-2010                   #
#                                                                #
##################################################################

require 'rake'
require 'rake/tasklib'
require 'rake/testtask'
require 'yard'
require 'hoe'

Rake::TaskManager.class_eval do
  def remove_task(*task_names)
    task_names.each do |task_name|
      @tasks.delete(task_name.to_s)
    end
  end
end

def remove_task(*task_names)
  task_names.each do |task_name|
    Rake.application.remove_task(task_name)
  end
end
 
#Hoe.plugin :minitest
Hoe.spec "amp" do
  developer "Michael Edgar", "adgar@carboni.ca"
  developer "Ari Brown", "seydar@carboni.ca"
  self.url = "http://amp.carboni.ca/"
  self.spec_extras = {:extensions => ["ext/amp/mercurial_patch/extconf.rb",
                                 "ext/amp/priority_queue/extconf.rb",
                                 "ext/amp/support/extconf.rb",
                                 "ext/amp/bz2/extconf.rb"]}
  self.need_rdoc = false
  self.summary = "Version Control in Ruby. Mercurial Compatible. Big Ideas."
  extra_dev_deps << ["rtfm", ">= 0.5.1"] << ["yard", ">= 0.4.0"] << ["minitest", ">= 1.5.0"]
end
 
# Hoe.spec "amp-pure" do
#   developer "Michael Edgar", "adgar@carboni.ca"
#   developer "Ari Brown", "seydar@carboni.ca"
#   self.url = "http://amp.carboni.ca/"
#   
#   self.need_rdoc = false
#   self.flog_threshold = 50000
#   self.summary = "Version Control in Ruby. Mercurial Compatible. Big Ideas. (Pure-Ruby version)"
# end

remove_task 'test_deps', 'publish_docs', 'post_blog', 
            'deps:fetch', 'deps:list', 'deps:email', 'flay', 'clean', 'flog'

load 'tasks/yard.rake'
load 'tasks/stats.rake'
load 'tasks/man.rake'

desc 'Rebuild the manifest'
task :manifest do
  sh "hg manifest > Manifest.txt"
end

task :release => [:manifest]

desc "Build the C extensions"
task :build do
  curdir = File.expand_path(File.dirname(__FILE__))
  ruby_exe = RUBY_VERSION < "1.9" ? "ruby" : "ruby1.9"
  Dir['ext/amp/*'].each do |target|
    sh "cd #{File.join(curdir, target)}; #{ruby_exe} #{File.join(curdir, target, "extconf.rb")}" # this is necessary because ruby will build the Makefile in '.'
    sh "cd #{File.join(curdir, target)}; make"
  end
end

desc "Clean out the compiled code"
task :clean do
  sh "rm -rf ext/amp/**/*.o"
  sh "rm -rf ext/amp/**/Makefile"
  sh "rm -rf ext/amp/**/*.bundle"
  sh "rm -rf ext/amp/**/*.so"
end

desc "Clean and buld the C-extensions"
task :rebuild => [:clean, :build]

desc "Prepares for testing"
task :prepare do
  `tar -C test/store_tests/ -xzf test/store_tests/store.tar.gz`
  `tar -C test/localrepo_tests/ -xzf test/localrepo_tests/testrepo.tar.gz`
end

desc "Compile Site"
task :"build-website" do
  require 'site/src/helpers.rb'
  load 'lib/amp.rb' # get the version
  missing_gems = []
  requirements = ['haml', 'uv']
  requirements_install = ['haml', 'ultraviolet']
  requirements.each do |requirement|
    begin
      require requirement
    rescue LoadError => e
      puts "The following gems are required to build the amp website: #{requirements.join(", ")}"
      puts "Install them as follows: gem install #{requirements_install.join(" ")}"
      puts "You will need oniguruma. Here's a helpful explanation of how to install it if"
      puts "you need some help: http://snippets.aktagon.com/snippets/61-Installing-Ultraviolet-and-Onigurama"
      exit
    end
  end
  
  Dir["site/src/**/*.haml"].reject {|item| item.split("/").last =~ /^_/}.each do |haml|
    file_path = haml[8..-6]
    FileUtils.makedirs(File.dirname("site/build" + file_path + ".html"))
    File.open("site/build" + file_path + ".html","w") do |out|
      puts "Building #{file_path}"
      out.write render(haml)
    end
  end
  %w(css images scripts docs).each do |dir|
    src = "site/src/#{dir}/"
    if File.exist? src
      sh "cp -r #{src} site/build/#{dir}/"
    end
  end
end

# vim: syntax=Ruby
