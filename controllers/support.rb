class Central
	get '/support' do
		@crumbs = []
    	@crumbs << Central.crumb("Dashboard", "/")
    	@active = Central.crumb("Support", "/support")

		haml "support/list"
	end

	get '/account_info' do
		@foo
		haml 'support/account_info'
	end

	post '/numbersearch' do
		@foo = Numsearch.new(params[:number])
		redirect to('/account_info')
		puts @foo
	end

end