#######################################################################
#                  Licensing Information                              #
#                                                                     #
#  The following code is a derivative work of the code from the       #
#  Mercurial project, which is licensed GPLv2. This code therefore    #
#  is also licensed under the terms of the GNU Public License,        #
#  verison 2.                                                         #
#                                                                     #
#  For information on the license of this code when distributed       #
#  with and used in conjunction with the other modules in the         #
#  Amp project, please see the root-level LICENSE file.               #
#                                                                     #
#  © Michael J. Edgar and Ari Brown, 2009-2010                        #
#                                                                     #
#######################################################################

command :bisect do |c|
  c.workflow :hg
  
  c.desc "subdivision search of changesets"
  c.help <<-EOS
amp bisect [-gbsr] [-c CMD] [REV]
  
  This command helps to find changesets which introduce problems.
  To use, mark the earliest changeset you know exhibits the problem
  as bad, then mark the latest changeset which is free from the
  problem as good. Bisect will update your working directory to a
  revision for testing (unless the --noupdate option is specified).
  Once you have performed tests, mark the working directory as bad
  or good and bisect will either update to another candidate changeset
  or announce that it has found the bad revision.
  
  As a shortcut, you can also use the revision argument to mark a
  revision as good or bad without checking it out first.
  
  If you supply a command it will be used for automatic bisection. Its exit
  status will be used as flag to mark revision as bad or good. In case exit
  status is 0 the revision is marked as good, 125 - skipped, 127 (command not
  found) - bisection will be aborted and any other status bigger than 0 will
  mark revision as bad."
  
  Where options are:
EOS
  
  c.opt :command, "The command to run to test", :short => '-c', :type => :string, :default => 'ruby'
  c.opt :"dirty-room", "Eval the ruby code in -f in the context of this amp binary (faster than shelling out)", :short => '-d'
  c.opt :file, "The file to run with --command (which defaults to ruby) for testing", :short => '-f', :type => :string
  c.opt :"no-update", "Don't update the working directory during tests", :short => '-U'
  c.opt :revs, "The revision range to search in", :short => '-r', :type => :string, :default => '0'
  
  c.before do |opts, args|
    # Set the command to be the command and the file joined together in
    # perfect harmony. If file isn't set, command will still work.
    # If command isn't set, it defaults to 'ruby' up in the command parsing
    # so actually it's always set unless there's a problem between the keyboard
    # and chair. I'm sorry this isn't cross platform. Find room in your heart
    # to forgive me.
    opts[:command] = "#{opts[:command]} #{opts[:file]} 1>/dev/null 2>/dev/null"
    
    if opts[:"dirty-room"]
      raise "The --dirty-room option needs --file as well" unless opts[:file]
    end
    
    # If we have to preserve the working directory, then copy
    # it to a super secret location and do the work there
    if opts[:"no-update"]
      require 'fileutils'
      
      opts[:testing_repo] = "../.amp_bisect_#{Time.now}"
      FileUtils.cp_r repo.path, opts[:testing_repo]
    end
    
    true
  end
  
  c.after do |opts, args|
    if opts[:"no-update"]
      FileUtils.rm_rf opts[:testing_repo]
    end
  end
  
  c.on_run do |opts, args|
    #################################
    # VARIABLE PREP
    #################################
    # Set up some variables and make
    # $display be set to false.
    # Also set up what the proc is to
    # test each revision. Assign a cute
    # phrase to tell the user what's going
    # on.
    # 
    
    repo = opts[:repository]
    old  = $display
    $display = false # so revert won't be so chatty!
    
    # This is the sample to run. The proc needs to return true
    # or false
    if opts[:command]
      using = "use `#{opts[:command].red}`"
      run_sample = proc { system opts[:command] }
    elsif opts[:"dirty-room"]
      using = "evaluate #{opts[:file]} in this Ruby interpreter"
      run_sample = proc { eval File.read(opts[:file]) }
    else
      raise "Must have the --command or --dirty-room option set!"
    end
    
    last_good, last_bad = *c.parse_revision_range(opts[:revs])
    last_bad ||= repo.size - 1
    history = [last_bad]  # KILLME
    
    test_rev  = last_bad
    is_good   = {} # {revision :: integer => good? :: boolean}
    last_good.upto(last_bad) {|i| is_good[i] = nil }
    
    ########################################
    # COMPLIMENT WHOEVER IS READING THE CODE
    ########################################
    
    # Hey! That's a really nice shirt. Where'd you get it?
    Amp::UI.say "Sweet computer, btw. I'm really digging this hardware.\n"
    
    
    ########################################
    # EXPLICITLY SAY WHAT WE'RE DOING
    ########################################
    Amp::UI.say <<-EOS
OK! Terve! Today we're going to be bisecting your repository find a bug.
Let's see... We're set to #{using} to do some bug hunting between revisions
#{last_good.to_s.red} and #{last_bad.to_s.red}.

Enough talk, let's go Orkin-Man on this bug!
========
EOS
    
    
    #############################################
    # BINARY SEARCH
    #############################################
    # Here's where we actually do the work. We're
    # just going through in a standard binary
    # search method. I haven't actually written
    # a BS method in a long time so I don't know
    # if this is official, but it works.
    # 
    
    until (last_good - last_bad).abs < 1
      repo.clean test_rev
      
      # keep the user updated
      pretty_print is_good 
      
      # if the code sample works
      if run_sample[]
        is_good[test_rev] = true # then it's a success and mark it as such
        break if test_rev == last_good
        last_good = test_rev
      else
        is_good[test_rev] = false
        last_bad = test_rev
      end
      
      test_rev = (last_good + last_bad) / 2
      history << test_rev
    end
    puts # clear the progress bar business
    
    ############################################
    # CLEANING UP
    ############################################
    # Restore the working directory to its proper
    # state and restore the $display variable.
    # Report on the results of the binary search
    # and say whether there is a bug, and if there
    # is a bug, say where it starts.
    # 
    
    repo.clean(repo.size - 1)
    $display = old # and put things as they were
    
    if is_good[last_bad]
      Amp::UI.say "The selected range of history passes the test. No bug found."
    else
      Amp::UI.say "Revision #{last_bad} has the bug!"
    end
  end
  
  def pretty_print(hash)
    print("\b" * hash.size * 3)
    print "\r"
    print '['
    hash.keys.sort[0..-2].each do |key|
      case hash[key]
      when true
        print 'o, '
      when false
        print 'x, '
      when nil
        print '_, '
      end
    end
    case hash[hash.keys.sort.last]
    when true
      print 'o'
    when false
      print 'x'
    when nil
      print '_'
    end
    print ']'
  end
end

# Now for some helpers!
module Kernel
  def bisect_command(name, opts={})
    command name.to_sym do |c|
      
      # set the default options as passed in
      opts.each do |k, v|
        c.default k, v
      end
      
      yield self if block_given?
    end
  end
end