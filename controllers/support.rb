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
		#session[:foo1] = @foo
		#@foo.each {|k,v| puts "KEY:#{k}\nVALUE:#{v}\n\n\n"}
		#@bar.each{|k,v| puts "KEY:#{k}\nVALUE:#{v}\n\n\n"}
		#@meow.each{|k,v| puts "KEY:#{k}\nVALUE:#{v}\n\n\n"}
		#@mix.each{|k,v| puts "KEY:#{k}\nVALUE:#{v}\n\n\n"}
		#redirect to('/account_info')
		haml 'support/account_info', :locals => { :raccount => @raccount , :rparent => @rparent , :rsugar => @rsugar , :rsugarcontact => @rsugarcontact , :rticket => @rticket}
	end

	post '/nagios' do
		@result = Nagios.new.set(params[:hostname], params[:starttime], params[:duration], params[:comment])
		haml 'support/nagios_info', :locals => { :result => @result}
	end

	get '/nagios_info' do
		haml 'support/nagios_info', :locals => { :session => session }
	end
end
