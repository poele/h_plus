require 'sinatra/base'
require 'rack-flash'

module Transhumanity
  class Server < Sinatra::Base

    configure do
      set :sessions, true
      use Rack::Flash
    end

    configure :development do
        register Sinatra::Reloader
        $db = PG.connect dbname: "transhumanity", host: "localhost"
    end

    configure :production do
      require 'uri'
      uri = URI.parse ENV["DATABASE_URL"]
      $db = PG.connect dbname: uri.path[1..-1],
                         host: uri.host,
                         port: uri.port,
                         user: uri.user,
                     password: uri.password
    end

    # is true if someone is logged in

    def logged_in?
      current_user != nil
    end

# uses sessions to store the current user
    def current_user
      session[:user_id]
    end

# allows commenting in markdown
 		def markdown(text)
  		markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :hard_wrap => true, :space_after_headers => true )
  		markdown.render(text)
		end

		# MAIN PAGE

    get "/" do
    	# DO NOT FORGET TO PUT vvvvvv IN EVERY ROUTE WITH THE SIDEBAR
    	# 
    	# these will be the flash messages that show up after an error
    	# or just need to notify the user
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

# logs a user in by storing their data in a session
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

# logs a user out by deleting their session
    delete('/logout') do
      session[:user_id] = nil
      redirect '/'
    end

    # USER SIGN UP SECTION

# displays the sign up page
    get '/signup' do
 		  user_id = session[:user_id]
    	erb :signup
    end

# allows users to create an account if the name isn't registered to someone else
    post '/signup' do
    	name = params[:name]
    	password = params[:password]
    	email = params[:email]
    	$db.exec_params("INSERT INTO users (name, email, password, created_at) VALUES ($1, $2, $3, current_timestamp);", [name, email, password])
    	flash[:success] = "You successfully created an account."
    	redirect "/"
    end

    # POSTS SECTION (topics/:id just displays posts for that topic)


# ports page by posts from most popular to least
    get '/topics/:id' do
    	@id = params[:id]
    	@user = session[:user_id]
    	@posts = $db.exec_params("SELECT * FROM posts WHERE topic = $1 ORDER BY popularity DESC;", [params[:id]])
    	@username = $db.exec_params("SELECT * FROM users JOIN posts ON posts.user_id = users.id WHERE posts.id = $1", [params[:id]])
    	erb :topic, :layout => :layout
    end

    # sorts page by posts from most comments to least

    get '/topicsbycomments/:id' do
    	@id = params[:id]
    	@user = session[:user_id]
    	@posts = $db.exec_params("SELECT posts.id, posts.subject, posts.content, posts.popularity, posts.user_id, posts.topic, count(*) FROM posts, comments WHERE posts.id = comments.post GROUP BY posts.id ORDER BY count DESC;")
    	erb :mostcomments, :layout => :layout
    end

# allows logged in users to make posts
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

    # allows users to upvote posts

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

    # shows the post and its comments

    get '/posts/:id' do
  
    	@user = session[:user_id]
    	@post = $db.exec_params("SELECT * FROM users JOIN posts ON posts.user_id = users.id WHERE posts.id = $1", [params[:id]]).first
    	@comments = $db.exec_params("SELECT * FROM users JOIN comments ON comments.user_id = users.id WHERE post = $1 ORDER BY comments.id ASC;", [params[:id]])
    	erb :post, :layout => :layout
    end

# allows users to delete posts IF THEY ARE THE OP

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

		# allows users to edit the post if they are the op

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

# allows logged in users to post comments
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

    # allows users to delete comments IF THEY ARE LOGGED IN AS THE POSTER

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

    # allows user to edit comment IF THEY ARE LOGGED IN AS THE POSTER

    get '/editcomment/:id' do
    	@user = session[:user_id]
    	@comment = $db.exec_params("SELECT * FROM comments WHERE id = $1", [params[:id]]).first
    	@username = $db.exec_params("SELECT * FROM comments JOIN users ON users.id = comments.user_id WHERE comments.id = $1", [params[:id]]).first
    	erb :editcomment, :layout => :layout
    end

    # updates comment data in sql

    post '/editcomment' do
    	@user = session[:user_id]
    	@comment = $db.exec_params("SELECT * FROM comments WHERE comments.id = $1", [params[:id]]).first
    	$db.exec_params("UPDATE comments SET content = $1 WHERE id = $2", [params[:content], params[:id]])
    	redirect "/posts/#{@comment['post']}"
    end

    # PROFILE SECTION

# shows individual profile
    get '/profiles/:id' do
    	@updated = flash[:updated]
    	@error = flash[:error]
    	@user = session[:user_id]
    	@id = params[:id]
    	@username = $db.exec_params("SELECT * FROM users WHERE id = $1", [params[:id]]).first
    	erb :profile, :layout => :layout
    end

# allows user to edit profile IF THEY ARE LOGGED IN AS THAT USER
    get '/editprofile/:id' do
    	@user = session[:user_id]
    	@username = $db.exec_params("SELECT * FROM users WHERE id = $1", [params[:id]]).first
    	erb :editprofile, :layout => :layout
 		end

# updates profile data in sql
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

# shows a user's posts. allows for editing if user is logged in as that user
 		get '/userposts/:id' do
 			@user = session[:user_id]
 			@posts = $db.exec_params("SELECT * FROM posts WHERE user_id = $1", [params[:id]])
 			@username = $db.exec_params("SELECT * FROM posts JOIN users ON users.id = posts.user_id WHERE users.id = $1", [params[:id]]).first
 			erb :userposts, :layout => :layout
 		end

# shows a users comments. allows for editing if user is logged in as that users
 		get '/usercomments/:id' do
 			@user = session[:user_id]
 			@comments = $db.exec_params("SELECT * FROM comments WHERE user_id = $1", [params[:id]])
 			@username = $db.exec_params("SELECT * FROM comments JOIN users ON users.id = comments.user_id WHERE users.id = $1", [params[:id]]).first
 			erb :usercomments, :layout => :layout 
 		end

 	end

end