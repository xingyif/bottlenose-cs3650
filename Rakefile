#!/usr/bin/env rake
# -*- ruby -*-
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Bottlenose::Application.load_tasks

task :upgrade do
  system("bin/delayed_job stop")
  system("rake db:migrate")
  system("bundle exec rake assets:precompile")
  system("whenever -i")
  system("rake install")
  system("rake restart")
  system("bin/delayed_job start")
end  

task :restart do
  system("touch tmp/restart.txt")
end

task :install do
  system("cd sandbox/src && make")
  system("cd sandbox/src && make install")
end

task :start_delayed_job do
  system("cd #{Rails.root} && bin/delayed_job start > /dev/null")
end

task :reap do
  system("cd #{Rails.root} && script/sandbox-reaper")
end

task :backup do
  system("cd #{Rails.root} && script/remote-backup")
end

task :dump_sql do
  dbcfg = Rails.configuration.database_configuration
  dbname = dbcfg[Rails.env]["database"]
  dbuser = dbcfg[Rails.env]["username"]
  
  cmd = %Q{pg_dump -U "#{dbuser}" "#{dbname}" > db/dump.sql}
  puts cmd
  system(cmd)
  system(%Q{gzip -f db/dump.sql})
end

task :restore_sql do
  puts
  puts "This will replace the database with the latest dump!"
  puts
  puts "Ctrl+C to cancel, enter to continue."
  puts

  unless File.exists?("db/dump.sql.gz")
    puts "No db dump found, aborting."
    exit(0)
  end

  dbcfg = Rails.configuration.database_configuration
  dbname = dbcfg[Rails.env]["database"]
  dbuser = dbcfg[Rails.env]["username"]

  system("rake db:drop")
  system("rake db:create")

  cmd = %Q{zcat db/dump.sql.gz | psql -U "#{dbuser}" #{dbname}}
  system(cmd)
end

task :backup_and_reap do
  Rake::Task["backup"].execute
  Rake::Task["reap"].execute
end

namespace :db do
  task :nuke do
    puts
    puts "This will destroy the database!"
    puts
    puts "Press CTRL+C now if you're running this on the"
    puts "production server like Mark."
    puts
    puts "Otherwise, press enter to continue."
    $stdin.readline
    system("rake db:drop")
    system("rake nuke_uploads")
    system("rake db:create")
    system("rake db:migrate")
  end
end

task :nuke_uploads do
  puts
  puts "This will delete all student work."
  puts 
  puts "CTRL+C to cancel, or enter to continue"
  puts
  $stdin.readline
  system("rm -rf public/assignments")
  system("rm -rf public/submissions")
  system("rm -rf public/uploads")
  system("mkdir public/uploads")
  system("touch public/uploads/empty")
end


namespace :test do
  task :short do
    puts "\trake test:units"
    system("(rake test:units) 2>&1 | grep failures")

    puts "\trake test:functionals"
    system("(rake test:functionals) 2>&1 | grep failures")

    puts "\trake test:integration"
    system("(rake test:integration) 2>&1 | grep failures")
  end
end
