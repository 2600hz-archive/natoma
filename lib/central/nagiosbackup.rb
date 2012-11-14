#class Central
#  class Nagios

#    def set(hostname, starttime, duration, comment)
#    rnagios = Hash.new
#    commandfile = '/usr/local/nagios/var/rw/nagios.cmd'
#    $endtime = starttime.to_i+duration.to_i
#    File.open(commandfile, 'w') do |f2|
#      f2.puts "[%lu] SCHEDULE_HOST_DOWNTIME;#{hostname};#{starttime};#{$endtime};0;0;#{duration};Sinatra;#{comment}\n"
#    end

#    return rnagios
#    end

#end

#end
