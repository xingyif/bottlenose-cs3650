#!/usr/bin/env ruby

key = ENV['BN_KEY']
sub = ENV['BN_SUB']
gra = ENV['BN_GRA']
ENV['BN_KEY'] = ''

def run(cmd)
  system(%{sudo -u student #{cmd}})
end

def unpack_to_home(file)
  Dir.chdir "/home/student"

  if (file =~ /\.tar\.gz$/i) || file =~ (/\.tgz$/i)
    run(%Q{tar xzf "#{file}"})
  elsif (file =~ /\.zip/i)
    run(%Q{unzip "#{file}"})
  else
    run(%Q{cp "#{file}" .})
  end
end

def unpack_submission
  if ENV["BN_SUB"]
    unpack_to_home(ENV["BN_SUB"])
  end
end

def unpack_grading
  if ENV["BN_GRADE"]
    unpack_to_home(ENV["BN_GRADE"])
    if File.directory?("grading")
      run(%Q{cp grading/* .})
    end
  end
end

unpack_grading
unpack_submission

def run_in_sub(cmd)
  count = `find . -name "Makefile" | wc -l`.chomp.to_i
  if count != 1
    raise Exception.new("Too many Makefiles: #{count}")
  end

  Dir.chdir "/home/student"
  dir = `dirname $(find . -name "Makefile" | head -1)`.chomp
  run(%Q{chown -R student:student "#{dir}"})
  Dir.chdir dir
  run(cmd)
end

run_in_sub("make")

unpack_grading

puts key
run_in_sub("make test")
puts key

