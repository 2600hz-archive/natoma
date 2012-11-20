#TO-DO LIST
#Read email addresses from a file
class Central
  class Nagios

    def set(hostname, duration_hour, duration_minute, comment, month, day, year, hour, minute)
      #Translate month to month shorthand name
      if (month == "1")
        namemonth = "jan"
      elsif (month == "2")
        namemonth = "feb"
      elsif (month == "3")
        namemonth = "mar"
      elsif (month == "4")
        namemonth = "apr"
      elsif (month == "5")
        namemonth = "may"
      elsif (month == "6")
        namemonth = "jun"
      elsif (month == "7")
        namemonth = "jul"
      elsif (month == "8")
        namemonth = "aug"
      elsif (month == "9")
        namemonth = "sep"
      elsif (month == "10")
        namemonth = "oct"
      elsif (month == "11")
        namemonth = "nov"
      elsif (month == "12")
        namemonth = "dec"
      end
      #Convert duration from hours/minutes to seconds
      duration = (duration_hour.to_i*3600)+(duration_minute.to_i*60)
      #Set starttime to Unix Time
      starttime = Date.new(year.to_i,month.to_i,day.to_i).to_time.to_i
      starttime = starttime+(hour.to_i*3600)+(minute.to_i*60)
      #Set time to when downtime requested
      time = Time.now
      #Write downtime request info to a redis hash
      dt_inc = Central.redis.hget "nagios_downtime", "field"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::hostname", "#{hostname}"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::starttime", "#{starttime}"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::duration", "#{duration}"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::comment", "#{comment}"
      Central.redis.hset "nagios_downtime", "#{dt_inc}::time", "#{time}"
      Central.redis.hincrby "nagios_downtime", "field", 1

      #Add 0 in front of minute to allow at readable format
      if (minute.to_i < 10)
        modmin = "0#{minute}"
      else
        modmin = minute
      end
      #Set variables to emailing info
      emailsubject = "Host Downtime for: #{hostname}"
      emailbody = "\"#{hostname} is undergoing a scheduled downtime due to: #{comment}. This downtime will last for #{duration_hour} hour(s), #{duration_minute} minute(s).\""
      addresses = "***REMOVED***.ai@2600hz.com"
      #Run at command to set an email stak
      command = "echo 'echo #{emailbody} | mail -s \"#{emailsubject}\" #{addresses}' | at #{hour}:#{modmin} #{namemonth} #{day} #{year}"
      system(command)

      puts "*****************************\n#{command}\n************************************"
      #Create rnagios hash to return info (OBSOLETE)
      rnagios = Hash.new
      commandfile = '/usr/local/nagios/var/rw/nagios.cmd'
      debug = "Setting host downtime for #{hostname}"
      now = Time.now
      $endtime = starttime.to_i+duration.to_i
      #Set command to run /root/test.sh script, which writes to Nagios command file (This script is on nagios server)
      cmd = "/root/test.sh #{hostname} #{starttime} #{duration} '#{comment}'"
      #Set ip of nagios server
      ip = "192.168.1.103"
      queue(debug, cmd, ip)
      return rnagios
    end

    def queue(debug, cmd, ip)
      Central.debug debug
      command = "ssh -p 22 root@#{ip} '#{cmd}'"
      #Write to log
      log = Log.new object_id
      b_stdout = Log::Buffer.new object_id, "stdout"
      b_stderr = Log::Buffer.new object_id, "stderr"

      h = {}
      h["exit_status"] = 1
      h["started"] = Time.now.to_f
      h["finished"] = nil
      log.save h

      #SSH and run command
      begin
        status = spawn command, 'stdout' => b_stdout, 'stderr' => b_stderr
      rescue => e
        h["error"] = e
      end
      h["finished"] = Time.now.to_f
      log.save h

      #Debug
      if DEBUG
        puts command
        puts status.to_i
        puts b_stdout
        puts b_stderr if b_stderr
      end
    end

  end
end
