class Central
  class Node
    attr_reader :id, :props, :cluster, :key, :commands

    def initialize(id)
      @id = id
      @key = "nodes"
      @props = Central.redis.hgetall "nodes::#{@id}" || {}
    end

    def save(props={})
      props_v = props.reject {|k,v| not ["name", "ip", "zone_id", "command_id", "role"].include? k}

      Central.redis.sadd "nodes", @id
      Central.redis.set "nodes::#{props_v[:name]}", @id
      Central.redis.hmset "nodes::#{@id}", "id", @id, "name", props_v[:name], "ip", props_v[:ip], "zone_id", props_v[:zone_id], "command_id", props_v[:command_id], "role", props_v[:role]

      Resque.enqueue(Deploy, @key, @id, props_v[:command_id])
    end

    def cluster
      @cluster ||= Cluster.new(nodes["cluster_id"])
    end

    def self.info(id)
      @id = id
      info = Central.redis.hgetall "nodes::#{@id}" || {}
    end
    
    ## class methods
    def self.list_all
      nodes = []
      Central.redis.smembers("nodes").each do |n_id|
        nodes << Node.info(n_id)
      end
      nodes
    end

    def self.list(ids)
      nodes = []
      ids.each do |n_id|
        nodes << Node.info(n_id)
      end
      nodes
    end

  end
end