class Central
  class Nagiostest

    def set(hostname, duration, comment, month, day, year, hour, minute)
      puts "#{hostname}, #{duration}, #{comment}, #{month}, #{day}, #{year}, #{hour}, #{minute}"
      starttime = Date.new(year.to_i,month.to_i,day.to_i).to_time.to_i
      puts "STARTTIME: #{starttime}"
      puts hour.to_i*3600
      puts minute.to_i*60
      starttime = starttime+(hour.to_i*3600)+(minute.to_i*60)
      puts "MODIFIED STARTTIME: #{starttime}"
      time = Time.now
      dt_inc = Central.redis.hget "nagios_downtime", "field"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::hostname", "#{hostname}"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::starttime", "#{starttime}"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::duration", "#{duration}"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::comment", "#{comment}"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::time", "#{time}"
      Central.redis.hincrby "nagios_downtime", "field", 1


      rnagios = Hash.new
      commandfile = '/usr/local/nagios/var/rw/nagios.cmd'
      debug = "Setting host downtime for #{hostname}"
      now = Time.now
      $endtime = starttime.to_i+duration.to_i
      #cmd = '/usr/bin/printf "[%lu] SCHEDULE_HOST_DOWNTIME;#{hostname};#{starttime};#{$endtime};0;0;#{duration};RemoteSinatra;#{comment}" #{now} > #{commandfile}'
      cmd = "/root/test.sh #{hostname} #{starttime} #{duration} '#{comment}'"
      ip = "192.168.1.103"
      queue(debug, cmd, ip)
      return rnagios
    end

    def queue(debug, cmd, ip)
      Central.debug debug
      command = "ssh -p 22 root@#{ip} '#{cmd}'"
      log = Log.new object_id
      b_stdout = Log::Buffer.new object_id, "stdout"
      b_stderr = Log::Buffer.new object_id, "stderr"

      h = {}
      h["exit_status"] = 1
      h["started"] = Time.now.to_f
      h["finished"] = nil
      log.save h

      begin
        status = spawn command, 'stdout' => b_stdout, 'stderr' => b_stderr
      rescue => e
        h["error"] = e
      end
      h["finished"] = Time.now.to_f
      log.save h

      if DEBUG
        puts command
        puts status.to_i
        puts b_stdout
        puts b_stderr if b_stderr
      end
    end

  end
end
