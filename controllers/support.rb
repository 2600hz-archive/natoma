class Central
	get '/support' do
		@crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @active = Central.crumb("Support", "/support")
		haml "support/list"
	end

	get '/account_info' do
		haml 'support/account_info', :locals => { :session => session } 
	end

	post '/numbersearch' do
		@foo = Numsearch.new.lookup(params[:number])
		session[:foo1] = @foo
		@foo.each {|k,v| puts "#{k} **************************  #{v}"}
		redirect to('/account_info')
	end
end