=begin
  180 SQL and Relational Database > Database-backed Web Applications > Assignments   
=end
require "pry"
require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, "secret"
  set :erb, escape_html: true
end             


configure(:development) do          #Allows to only use the following configurations when in a dev env
  require "sinatra/reloader"
  also_reload "database_persistence.rb" #Whenever a new request comes in this file will reload as well keeping you from needing to kill the program everytime a change is made
end                            

helpers do
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
   list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end



def load_list(id)
  list = @storage.find_list(id)
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
  halt
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif @storage.all_lists.any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
  end
end

before do
  @storage = DatabasePersistence.new(logger) #Sinatra provides a logging helper which can be used in any of the routes or anywhere in your application 
                                             #Passing in the Sinatra provided logger object which has a bunch of methods that can be used 
end                                          #The logger is then passed inbto the initialize method within the database_persistence.rb file 

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View a single todo list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = load_list(id)

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(id, list_name)
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

# Delete a todo list
post "/lists/:id/destroy" do
  id = params[:id].to_i

  @storage.delete_list(id)

  session[:success] = "The list has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    redirect "/lists"
  end
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @storage.create_new_todo(@list_id, text)

    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  @storage.delete_todo_from_list(@list_id, todo_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# Update the status of a todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @storage.update_todo_status(@list_id, todo_id, is_completed)

  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a list
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  @storage.mark_all_todos_as_completed(@list_id)

  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end

=begin 
Purpose of Exercise: #4 Extracting Session Manipulation Code 
  1) Look through the rest of the code in the .rb file in the different routes and methods 
     make sure that any references to the :session are moved to the session persistance class
     and then replaced with the appropriate method call to the storage instance variable that 
     are creating in the before block.  

  2) In this Exercise we extracted all of the session code where we're interacting with values within the 
     session out of our Sinatra application and into the new Class Session Persistence. 
     And in doing so we have donw a few things 1) We've moved all of that code into one place so if we wanted
     to replace the use of the session with a different data store which is out intention in this
     case it's much easier to do because the code that we need to change is in one place. 
     2) The other benefit that we get from doing this is we get to see this API that starts to 
     emerge on the session persistance class and doing that we can get an idea of what kind of 
     operations we will be performing and this gives us a really good idea of what the core funtionality
     of the API is able to do and our application is providing.   


Purpose of Exercise: #5 Designing a Schema (Work found in the Schema.sql file)
  1) We're going to need to design a database schema that will hold the data for our todo lists 
  and items. The following tables describe the attributes of these entities that we'll need to 
  store:
    List
      - Has a unique name
    Todo
      - Has a name
      - Belongs to a list
      - Can be completed, but should default to not be completed

Purpose of Exercise: #6 Setting up a Database Connection
  1) Take the DB created in the last assignment and connect through it from the Ruby process
  in the Sinatra application, we're also going to be doing a littel bit of project cleanup. 
  We're going to move the Session Persistence Class into its own file and then copy that 
  file into a new file called database_persistence and once inside there we will craft the 
  DB Persistence class that we will eventually use.  

Purpose of Exercise: #7 Executing and Logging Database Queries 



=end










