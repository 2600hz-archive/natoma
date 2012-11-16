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
		@result = Nagios.new.set(params[:hostname], params[:starttime], params[:duration], params[:comment])
		haml 'support/nagios_info', :locals => { :result => @result}
	end

	get '/nagios_info' do
		haml 'support/nagios_info', :locals => { :session => session }
	end

	post '/nagiostest' do
		@result = Nagiostest.new.set(params[:hostname], params[:duration], params[:comment], params[:month], params[:day], params[:year], params[:hour], params[:minute])
		haml 'support/nagiostest_info', :locals => { :result => @result}
	end

	get '/nagiostest_info' do
		haml 'support/nagiostest_info', :locals => { :session => session }
	end
end
