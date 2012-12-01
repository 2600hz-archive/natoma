class Central
  get '/clusters' do
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @active = Central.crumb("Clusters", "/clusters")
    @clusters = Cluster.list_all
    haml "clusters/list"
  end

  get '/clusters/create' do
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb("Clusters", "/clusters")
    @active = Central.crumb("Create")
    @environments = Environment.list_all
    haml "clusters/create"
  end

  get '/clusters/:id/create_zone' do |id|
    @cluster_id = id
    haml "zones/create_zone"
  end

  get '/clusters/:cluster' do |c_id|
    pass if c_id == "create"
    @cluster = Cluster.new(c_id)
    @zones = Zone.new(c_id)
    cluster_name = Central.redis.hget "clusters::#{c_id}", "name"
    env_id = Central.redis.hget "clusters::#{c_id}", "environment_id"
    env_name = Central.redis.hget "environments::#{env_id}", "name"
    acct_id = Central.redis.hget "environments::#{env_id}", "account_id"
    acct_name = Central.redis.hget "accounts::#{acct_id}", "name"
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb( "#{acct_name}", "/accounts/#{acct_id}")
    @crumbs << Central.crumb( "#{env_name}", "/environments/#{env_id}")
    @active = Central.crumb(@cluster.props["name"], request.path_info)
    @c_version = Central.redis.get "clusters::#{c_id}::version"
    @c_id = c_id
    haml "clusters/show"
  end

  post '/clusters' do
    id = counter
    c = Cluster.new(id)
    c.save(params)
    e = Environment.new(params["environment"])
    e.add_cluster(params["environment_id"],id)
    redirect to('/clusters')
  end

  post '/cluster_deploys' do
    n = Cluster.upgrade(params["version"],params["cluster_id"])
    cluster_id = params["cluster_id"]
    redirect to("/clusters/#{cluster_id}")
  end
end