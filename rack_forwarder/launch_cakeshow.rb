PIDFILE = '/home1/cakecuba/.cakeshow_pid'

def launch_process
  child = Process.fork {
    Process.exec 'cd ~/cakeshow && source ./set_app_env.sh && coffee cakeshow.coffee 2>&1 1 > ~/cakeshow_out'
  }
  
  Process.detach(child)
  File.open(PIDFILE, 'w') {|f| f.write(child)}

  return child
end

def ensure_process_running
  if File.exists? PIDFILE
    begin
      pid = IO.read(PIDFILE).to_i
      Process.getpgid(pid)
      return pid
    rescue
    end
  end

  puts 'Launching process'
  return launch_process()
end

if __FILE__ == $PROGRAM_NAME
  ensure_process_running()
end
