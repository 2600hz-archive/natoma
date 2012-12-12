class Central
  get "/zones" do
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @active = Central.crumb("Zones", "/zones")
    @zones = Zone.list_all
    haml "zones/list"
  end

  get '/zones/create' do
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb("Environment", "/zones")
    @active = Central.crumb("Create", request.path_info)
    @clusters = Cluster.list_all
    haml "zones/create"
  end

  get '/zones/:id' do |id|
    pass if id == "create"
    @zone = Zone.new(id)
    @z_id = id
    @z_version = Central.redis.get "zones::#{id}::version"
    cluster_id = Central.redis.hget "zones::#{@z_id}", "cluster_id"
    cluster_name = Central.redis.hget "clusters::#{cluster_id}", "name"
    env_id = Central.redis.hget "clusters::#{cluster_id}", "environment_id"
    env_name = Central.redis.hget "environments::#{env_id}", "name"
    acct_id = Central.redis.hget "environments::#{env_id}", "account_id"
    acct_name = Central.redis.hget "accounts::#{acct_id}", "name"
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb( "#{acct_name}", "/accounts/#{acct_id}")
    @crumbs << Central.crumb( "#{env_name}", "/environments/#{env_id}")
    @crumbs << Central.crumb( "#{cluster_name}", "/clusters/#{cluster_id}")
    @active = Central.crumb(@zone.props["name"], request.path_info)
    haml "zones/show"
  end

  get '/zones/edit/:node' do |z_id|
    @zone = Zone.new(z_id)
    puts @zone.props["name"]
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb( "Nodes", "/nodes")
    @active = Central.crumb(@zode["name"] + " zone", request.path_info)
    haml "zones/edit"
  end

  post '/zones' do
    id = counter
    z = Zone.new(id)
    z.save(params)
    c = Cluster.new(params["cluster_id"])
    c.add_zone(params["cluster_id"], id)
    redirect to('/zones')
  end

  post '/zone_create' do
    id = counter
    zone_id = id
    @z = Zone.info(zone_id)
    n = Node.new(id)
    z = Zone.new(id)
    z.save(params)
    c = Cluster.new(params["cluster_id"])
    c.add_zone(params["cluster_id"], id)
    params['server'].each do |k,v|
      n_id = counter
      #puts v['ip'], v['name'], v['role'], params['version']
      n.save(n_id, zone_id, v['ip'], v['name'], v['role'])
      n.add_zone_node(n_id, v['name'], v['role'], params['version'], params['erlang_cookie'] )
      z.add_node(n_id)
      d = Node.deploy(v['ip'], n_id, v['name'])
    end
    z.zone_json(params['server'], zone_id)
    redirect to('/zones')
  end

  post '/zone_deploys' do
    n = Zone.upgrade(params["version"],params["zone_id"])
    zone_id = params["zone_id"]
    redirect to("/zones/#{zone_id}")
  end
end