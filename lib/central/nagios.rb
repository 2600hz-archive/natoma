class Central
  class Nagios

    def set(hostname, starttime, duration, comment)
    #ARGV[0] IS HOSTNAME
    #ARGV[1] IS START TIME IN UNIX TIME
    #ARGV[2] IS DURATION IN SECONDS
    #ARGV[3] IS COMMENT
    rnagios = Hash.new
    commandfile = '/usr/local/nagios/var/rw/nagios.cmd'
    $endtime = starttime.to_i+duration.to_i
    File.open(commandfile, 'w') do |f2|
      f2.puts "[%lu] SCHEDULE_HOST_DOWNTIME;#{hostname};#{starttime};#{$endtime};0;0;#{duration};Sinatra;#{comment}\n"
    end

    return rnagios
    end

end

end
