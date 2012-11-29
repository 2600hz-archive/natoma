class Central
	get '/support' do
		@crumbs = []
    @crumbs << Central.crumb("Dashboard", "/")
    @active = Central.crumb("Support", "/support")
		haml "support/list"
	end

	post '/nagios' do
		@result = Nagios.new.set(params[:hostname], params[:duration_hour], params[:duration_minute], params[:comment], params[:month], params[:day], params[:year], params[:hour], params[:minute])
		haml 'support/nagios_info', :locals => { :result => @result}
	end

	get '/nagios_info' do
		haml 'support/nagios_info', :locals => { :session => session }
	end
	
	post '/support/bc_search' do
	  @search_results = Accountsearch.new.bigcouch_search(params[:query])
	  haml 'support/bcsearch_results', :locals => { :search_results => @search_results }
	end
	
	get '/support/bcsearch_results' do
	  haml 'support/bcsearch_results', :locals => { :session => session }
	end
	
	get '/support/bigcouch/:id' do
		@raccount, @rparent, @rsugar, @rsugarcontact, @rticket = Accountsearch.new.bigcouch_info(params[:id])
		haml 'support/bigcouch_info', :locals => { :raccount => @raccount , :rparent => @rparent , :rsugar => @rsugar , :rsugarcontact => @rsugarcontact , :rticket => @rticket }
	end
	
	get '/support/bigcouch_info' do
		 haml 'support/bigcouch_info', :locals => { :session => session }
	end


	get '/support/Sugar_Zendesk/:query' do
		@rsugar, @rsugarcontact = Accountsearch.new.sugar_search(params[:query])
		@rticket = Accountsearch.new.zendesk_search(params[:query])
		haml 'support/sugarzendesk_info', :locals => { :rsugar => @rsugar , :rsugarcontact => @rsugarcontact , :rticket => @rticket }
	end

	get '/support/sugarzendesk_info' do
		haml 'support/sugarzendesk_info', :locals => { :session => session }
	end
end
