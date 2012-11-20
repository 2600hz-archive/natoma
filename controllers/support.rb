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
		@raccount, @rparent, @rsugar, @rsugarcontact, @rticket = Numsearch.new.lookup(params[:number])
		haml 'support/account_info', :locals => { :raccount => @raccount , :rparent => @rparent , :rsugar => @rsugar , :rsugarcontact => @rsugarcontact , :rticket => @rticket}
	end

	post '/nagios' do
		@result = Nagios.new.set(params[:hostname], params[:duration_hour], params[:duration_minute], params[:comment], params[:month], params[:day], params[:year], params[:hour], params[:minute])
		haml 'support/nagios_info', :locals => { :result => @result}
	end

	get '/nagios_info' do
		haml 'support/nagios_info', :locals => { :session => session }
	end
end
