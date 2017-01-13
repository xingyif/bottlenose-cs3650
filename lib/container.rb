
require 'open3'

class Container
  def initialize(name)
    @name = name
  end

  def start!
    run(
      %Q{lxc launch bn-base "#{@name}" -e \
           -c "limits.cpu.allowance=20ms/60ms" \
           -c "limits.memory=512MB" \
           -c "limits.processes=128"}
    )
   
    loop do
      sleep(1)
      state = `(lxc exec #{@name} -- runlevel) 2>&1`
      break if state =~ /^N/;
    end

    run("lxc exec #{@name} -- hostname #{@name}")
  end

  def mkdir(path, mode = 0755)
    run(%Q{lxc exec #{@name} -- mkdir -m 0#{mode.to_s(8)} -p "#{path}"})

    puts "container.mkdir(#{path})"
    run(%Q{lxc exec #{@name} -- ls -l "#{path}"})
  end

  def push(src, dst)
    run(%Q{lxc file push "#{src}" "#{@name}/#{dst}"})
  end

  def push_dir(src, dst)
    src_parent = File.dirname(src)
    src_name   = File.basename(src)
    run(%Q{(cd "#{src_parent}" && tar cf - "#{src_name}") | \
        lxc exec #{@name} -- bash -c '(cd "#{dst}" && tar xf -)'})
  end

  def pull(src, dst)
    raise Exception.new("TODO")
  end

  def chmod(path, mode)
    run(%Q{lxc exec #{@name} -- chmod 0#{mode.to_s(8)} "#{path}"})
  end

  def chmod_r(path, mode)
    run(%Q{lxc exec #{@name} -- chmod -R 0#{mode.to_s(8)} "#{path}"})
  end

  def exec_driver(path, secret, sub, gra)
    push(path, "/root/bn_driver.rb")
    command = %Q{lxc exec "#{@name}" -- bash -c \
                   '(cd && BN_KEY="#{secret}" BN_SUB="#{sub}" BN_GRA="#{gra}" \
                   ruby -I /tmp/bn/lib bn_driver.rb)'}
    puts "Run driver: #{command}"
    Open3.capture3(command)
  end

  def stop!
    run(%Q{lxc stop #{@name} --timeout 5})
    sleep(1)
    force_stop!
  end
  
  def force_stop!
    system(%Q{(lxc stop "#{@name}" --force 2>&1) > /dev/null})
  end

  private

  def run(cmd)
    puts "Run: #{cmd}"
    system(cmd) or begin
      puts "Error running command: #{cmd}"
      force_stop!
      raise Exception.new("Error running command: #{cmd}")
    end
  end
end

