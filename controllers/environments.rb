class Central
  get "/environments" do
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @active = Central.crumb("Environments", "/environments")
    @environments = Environment.list_all
    haml "environments/list"
  end

  get '/environments/create' do
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb("Environment", "/environments")
    @accounts = Account.list_all
    @active = Central.crumb("Create", request.path_info)
    haml "environments/create"
  end

  get '/environments/:id' do |id|
    pass if id == "create"
    @environment = Environment.new(id)
    env_name = Central.redis.hget "environments::#{id}", "name"
    acct_id = Central.redis.hget "environments::#{id}", "account_id"
    acct_name = Central.redis.hget "accounts::#{acct_id}", "name"
    @crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @crumbs << Central.crumb( "#{acct_name}", "/accounts/#{acct_id}")
    @active = Central.crumb(@environment.props["name"], request.path_info)
    haml "environments/show"
  end

  post '/environments' do
    id = counter 
    e = Environment.new(id)
    e.save(params)
    a = Account.new(id)
    a.add_env(params["account_id"],id)
    redirect to('/environments')
  end
end