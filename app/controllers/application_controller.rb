class ApplicationController < ActionController::Base
	before_filter :set_access_control_headers
	before_filter :set_instant_account_flash

	protect_from_forgery

	def set_access_control_headers
	  headers['Access-Control-Allow-Origin'] = "*"
	  # headers['Access-Control-Allow-Credentials'] = 'true'
	  # this and the  Origin = * are incompatible
	  # ,Set-Cookie
    headers['Access-Control-Allow-Headers'] = '*,X-CSRF-Token,x-requested-with,Content-Type,If-Modified-Since,If-None-Match'
	  headers['Access-Control-Request-Method'] = 'POST, OPTIONS'
    headers['Access-Control-Expose-Headers'] = 'ETag'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PATCH, PUT, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Max-Age'] = '86400'
	end
	
  helper_method :current_user
	def current_user
	  @current_user ||= User.find_by_remember_token(session[:remember_token]) if session[:remember_token]
	end

	def call_rake(task, options ={})
		options[:rails_env] = Rails.env
		args = options.map {|n,v| "#{n.to_s.upcase}='{v}'"}
		system "bundle exec rake #{task} #{args.join(' ')} --trace >> #{Rails.root}/log/#{task.to_s}.log"
	end

	helper_method :username_path
	def username_path(user)
		return '/'+user.username
	end

	private

		def set_instant_account_flash
			if flash[:instant_account]
				if flash[:instant_account] == 'new'
					flash[:instant_account] = 'home'
				elsif flash[:instant_account] == 'home'
					flash[:instant_account] = 'first-action'
				elsif flash[:instant_account] == 'first-action'
					flash[:instant_account] = 'second-action'
				elsif flash[:instant_account] == 'second-action'
					flash[:instant_account] = nil
				end
			end
		end
		# def authorize
		#   redirect_to login_url, alert: "Not authorized" if current_user.nil?
		# end
end
