require "sinatra/base"
require "sinatra/reloader"
require "pry"
require "rack-flash"
require "rest-client"
require 'httparty'
require 'json'
require 'redcarpet'

require_relative "db/connection"

module Transhumanity
  class Server < Sinatra::Base

    configure do
      register Sinatra::Reloader
      set :sessions, true
      use Rack::Flash
    end

    def logged_in?
      current_user != nil
    end

    def current_user
      session[:user_id]
    end

 		def markdown(text)
  		markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :hard_wrap => true, :space_after_headers => true )
  		markdown.render(text)
		end

		# MAIN PAGE

    get "/" do
    	# DO NOT FORGET TO PUT vvvvvv IN EVERY ROUTE WITH THE SIDEBAR
    	@user = session[:user_id]
    	@success = flash[:success]
    	@incorrect = flash[:incorrect]
    	@notpop = flash[:notpop]
    	@notin = flash[:notin]
    	@topics = $db.exec_params("SELECT * FROM topics;")
    	@image = $db.exec_params("SELECT * FROM posts INNER JOIN users ON users.id = posts.user_id;")
    	erb :home, :layout => :layout
    end

    # SIDEBAR

    post('/login') do
      name = params[:name]
      password = params[:password]
      query = "SELECT * FROM users WHERE name = $1;"
      results = $db.exec_params(query, [name])
      user = results.first
      if user && user['password'] == password
        session[:user_id] = user['id']
        user_id = session[:user_id]
        redirect '/'
      else
        flash[:incorrect] = "Incorrect username or password."
        redirect '/'
        erb :home
      end
    end

    delete('/logout') do
      session[:user_id] = nil
      redirect '/'
    end

    # USER SIGN UP SECTION

    get '/signup' do
 		  user_id = session[:user_id]
    	erb :signup
    end

    post '/signup' do
    	name = params[:name]
    	password = params[:password]
    	email = params[:email]
    	$db.exec_params("INSERT INTO users (name, email, password, created_at) VALUES ($1, $2, $3, current_timestamp);", [name, email, password])
    	flash[:success] = "You successfully created an account."
    	redirect "/"
    end

    # POSTS SECTION (topics/:id just displays posts for that topic)

    get '/topics/:id' do
    	@id = params[:id]
    	@user = session[:user_id]
    	@posts = $db.exec_params("SELECT * FROM posts WHERE topic = $1 ORDER BY popularity DESC;", [params[:id]])
    	@username = $db.exec_params("SELECT * FROM users JOIN posts ON posts.user_id = users.id WHERE posts.id = $1", [params[:id]])
    	erb :topic, :layout => :layout
    end

    get '/topicsbycomments/:id' do
    	@id = params[:id]
    	@user = session[:user_id]
    	@posts = $db.exec_params("SELECT posts.id, posts.subject, posts.content, posts.popularity, posts.user_id, posts.topic, count(*) FROM posts, comments WHERE posts.id = comments.post GROUP BY posts.id ORDER BY count DESC;")
    	erb :mostcomments, :layout => :layout
    end


    post '/posts' do
    	if logged_in?
      	result = params[:topic]
      	$db.exec_params("INSERT INTO posts (subject, content, topic, user_id, created_at) VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)", [params[:subject], params[:content], params[:topic], current_user])
        redirect "/topics/#{result}"
      else 
      	flash[:notin] = "You must log in to post a topic."
        redirect "/"
      end
    end

    post '/popularity' do
    	@user = session[:user_id]
    	if logged_in?
    		result = params[:id]
    		$db.exec_params("UPDATE posts SET popularity = popularity + 1 WHERE id = $1", [params[:postid]])
    		redirect "/topics/#{result}"
    	else
    		flash[:notpop] = "Please log in to continue."
    		redirect '/'
    	end
    end

    get '/posts/:id' do
  
    	@user = session[:user_id]
    	@post = $db.exec_params("SELECT * FROM users JOIN posts ON posts.user_id = users.id WHERE posts.id = $1", [params[:id]]).first
    	@comments = $db.exec_params("SELECT * FROM users JOIN comments ON comments.user_id = users.id WHERE post = $1 ORDER BY comments.id ASC;", [params[:id]])
    	erb :post, :layout => :layout
    end

    post '/deletepost/:id' do
    	@user = session[:user_id]
    	@post = $db.exec_params("SELECT * FROM posts WHERE id = $1", [params[:id]]).first
    	if @user == @post['user_id']
    		delete = $db.exec_params("DELETE FROM posts WHERE id = $1", [params[:id]]).first
    		redirect "/topics/#{@post['topic']}"
    	else 
    		flash[:error] = "You must be logged in to delete this post."
    		redirect "/topics/#{@post['topic']}"
    	end
    end

    get '/editpost/:id' do
    	@user = session[:user_id]
    	@post = $db.exec_params("SELECT * FROM posts WHERE id = $1", [params[:id]]).first
    	@username = $db.exec_params("SELECT * FROM posts JOIN users ON users.id = posts.user_id WHERE posts.id = $1", [params[:id]]).first
    	erb :editpost, :layout => :layout
    end

    post '/editpost' do
    	@user = session[:user_id]
    	@post = $db.exec_params("SELECT * FROM posts WHERE id = $1", [params[:id]]).first
    	$db.exec_params("UPDATE posts SET subject = $1, content = $2 WHERE id = $3", [params[:subject], params[:content], params[:id]])
    	    	binding.pry
    	redirect "/posts/#{@post['id']}"
    end

    # COMMENT SECTION

    get '/comments/:id' do
    	@comment = $db.exec_params("SELECT * FROM comments JOIN users ON users.id = comments.user_id WHERE comments.id = $1", [params[:id]]).first
    	erb :comment, :layout => :layout
    end


    post '/comments' do
    	ip = request.ip
    	url = "http://ipinfo.io/#{ip}/json"
    	response = RestClient.get (url)
    	json = JSON.parse(response.body)
    	location = "#{json['city']}, #{json['region']}, #{json['country']}"
    	if logged_in?
      	result = params["post"]
      	$db.exec_params("INSERT INTO comments (content, post, user_id, location, created_at) VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)", [params[:message], params[:post], current_user, location])
        redirect "/posts/#{result}"
      else 
      	flash[:notin] = "You must log in to post a comment."
        redirect "/"
      end
    end

    post '/deletecomment/:id' do
    	@user = session[:user_id]
    	@comment = $db.exec_params("SELECT * FROM comments WHERE id = $1", [params[:id]]).first
    	if @user == @comment['user_id']
    		delete = $db.exec_params("DELETE FROM comments WHERE id = $1", [params[:id]]).first
    		redirect "/posts/#{@comment['post']}"
    	else 
    		flash[:error] = "You must be logged in to delete this comment."
    		redirect "/posts/#{@comment['post']}"
    	end
    end

    get '/editcomment/:id' do
    	@user = session[:user_id]
    	@comment = $db.exec_params("SELECT * FROM comments WHERE id = $1", [params[:id]]).first
    	@username = $db.exec_params("SELECT * FROM comments JOIN users ON users.id = comments.user_id WHERE comments.id = $1", [params[:id]]).first
    	erb :editcomment, :layout => :layout
    end

    post '/editcomment' do
    	@user = session[:user_id]
    	@comment = $db.exec_params("SELECT * FROM comments WHERE comments.id = $1", [params[:id]]).first
    	$db.exec_params("UPDATE comments SET content = $1 WHERE id = $2", [params[:content], params[:id]])
    	redirect "/posts/#{@comment['post']}"
    end

    # PROFILE SECTION

    get '/profiles/:id' do
    	@updated = flash[:updated]
    	@error = flash[:error]
    	@user = session[:user_id]
    	@id = params[:id]
    	@username = $db.exec_params("SELECT * FROM users WHERE id = $1", [params[:id]]).first
    	erb :profile, :layout => :layout
    end

    get '/editprofile/:id' do
    	@user = session[:user_id]
    	@username = $db.exec_params("SELECT * FROM users WHERE id = $1", [params[:id]]).first
    	erb :editprofile, :layout => :layout
 		end

 		post '/editprofile' do
 			@user = session[:user_id]
 		
 		 	if params[:name] != "" && params[:email] != ""
 				name = $db.exec_params("UPDATE users SET name = $1 WHERE id = $2", [params[:name], session[:user_id]])
 				email = $db.exec_params("UPDATE users SET email = $1 WHERE id = $2", [params[:email], session[:user_id]])
 				bio = $db.exec_params("UPDATE users SET bio = $1 WHERE id = $2", [params[:bio], session[:user_id]])
 				image = $db.exec_params("UPDATE users SET image = $1 WHERE id = $2", [params[:avatar], session[:user_id]])
 				flash[:updated] = "Your profile was successfully updated."
 				redirect "/profiles/#{@user}"
 			else 
 				flash[:error] = "Error: required field missing."
 				redirect "/profiles/#{@user}"
 			end
 		end

 		# nav bar sw$g

 		get '/userposts/:id' do
 			@user = session[:user_id]
 			@posts = $db.exec_params("SELECT * FROM posts WHERE user_id = $1", [params[:id]])
 			@username = $db.exec_params("SELECT * FROM posts JOIN users ON users.id = posts.user_id WHERE users.id = $1", [params[:id]]).first
 			erb :userposts, :layout => :layout
 		end

 		get '/usercomments/:id' do
 			@user = session[:user_id]
 			@comments = $db.exec_params("SELECT * FROM comments WHERE user_id = $1", [params[:id]])
 			@username = $db.exec_params("SELECT * FROM comments JOIN users ON users.id = comments.user_id WHERE users.id = $1", [params[:id]]).first
 			erb :usercomments, :layout => :layout 
 		end

 	end

end