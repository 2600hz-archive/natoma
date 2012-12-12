class Central
  get "/nodes" do
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @active = Central.crumb("Nodes", "/nodes")
    @nodes = Node.list_all
    haml "nodes/list"
  end

  get "/nodes/create" do
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb("Nodes", "/nodes")
    @active = Central.crumb("Create")
    @zones = Zone.list_all
    @commands = Command.list_all
    haml "nodes/create"
  end

  get '/nodes/:node' do |n_id|
    pass if n_id == "create"
    @node = Node.info(n_id)
    cluster_id = Central.redis.hget "zones::#{@node["zone_id"]}", "cluster_id"
    cluster_name = Central.redis.hget "clusters::#{cluster_id}", "name"
    z_name = Central.redis.hget "zones::#{@node["zone_id"]}", "name"
    env_id = Central.redis.hget "clusters::#{cluster_id}", "environment_id"
    env_name = Central.redis.hget "environments::#{env_id}", "name"
    acct_id = Central.redis.hget "environments::#{env_id}", "account_id"
    acct_name = Central.redis.hget "accounts::#{acct_id}", "name"
    @z_version = Central.redis.get "zones::#{@node["zone_id"]}::version"
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb( "#{acct_name}", "/accounts/#{acct_id}")
    @crumbs << Central.crumb( "#{env_name}", "/environments/#{env_id}")
    @crumbs << Central.crumb( "#{cluster_name}", "/clusters/#{cluster_id}")
    @crumbs << Central.crumb( "#{z_name}", "/zones/#{@node["zone_id"]}")
    @active = Central.crumb(@node["name"] + " node", request.path_info)
    @logs = Log.new n_id
    haml "nodes/show"
  end

  get '/nodes/edit/:node' do |n_id|
    @node = Node.info(n_id)
    @z_version = Central.redis.get "zones::#{@node["zone_id"]}::version"
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb( "Nodes", "/nodes")
    @active = Central.crumb(@node["name"] + " node", request.path_info)
    @logs = Log.new n_id
    haml "nodes/edit"
  end
  
  post '/nodes' do
    id = counter
    zone_id = params["zone_id"]
    @z_version = Central.redis.get "zones::#{zone_id}::version"
    @z = Zone.info(zone_id)
    n = Node.new(id)
    n.save(id, zone_id, params["ip"], params["name"], params["role"])
    n.add_node(params, id, @z_version, @z["erlang_cookie"])
    d = Node.deploy(params["ip"], id, params["name"])
    z = Zone.new(params["zone_id"])
    z.add_node(n.id)
    redirect to("/zones/#{zone_id}")
  end

  post '/node_upgrade' do
    id = counter
    node_id = params["node_id"]
    zone_id = params["zone_id"]
    @z = Zone.info(zone_id)
    n = Node.new(id)
    n.test(params, @z["erlang_cookie"])
    redirect to("/nodes/#{node_id}")
  end

  post '/node_edit' do
    node_id = params["node_id"]
    ip = params["ip"]
    Central.redis.hmset "nodes::#{node_id}", "name", params["name"], "ip", params["ip"], "role", params["role"]
    redirect to("/nodes/#{node_id}")
  end
end