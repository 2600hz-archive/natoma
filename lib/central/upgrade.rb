class Central
  module Upgrade
    @queue = "upgrade"

    def self.perform(ip, node_id, node_name, version)
      Central.debug "Upgrading Cluster Node #{ip} to version #{version}"

      copy_node_json(ip, node_id, node_name)
      curl_repo(ip)
      setup_deps(ip)
      env_reset(ip)
      #copy_databag(ip)
      chef_solo(ip, node_id, node_name)
    end

    def self.perform_old(ip, node_id, node_name, version)
      Central.debug "Upgrading Cluster Node #{ip} to version #{version}"
      h = {}
      h['started'] = Time.now.to_f
      log = Log.new object_id
      b_stdout = Log::Buffer.new object_id, "stdout"
      b_stderr = Log::Buffer.new object_id, "stderr"
      command = "ssh -p 22 root@#{ip} 'cat /etc/issue'"

      begin
        status = spawn command, 'stdout' => b_stdout, 'stderr' => b_stderr
      rescue => e
        h["error"] = e
      end
      h['finished'] = Time.now.to_f
      log.save h

      if DEBUG
        puts command
        puts status.to_i
        puts b_stdout
        puts b_stderr if b_stderr
      end
    end

    def self.copy_node_json(ip, node_id, node_name)
      debug = "Copying node json file to Node #{ip}"
      command = "scp /tmp/#{node_id}-#{node_name}.json root@#{ip}:/root"
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