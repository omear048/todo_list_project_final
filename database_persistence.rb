require "pg"

class DatabasePersistence
  def initialize(logger)               #The logger is passed in from the "before" method found in the todo.rb file; look there for more details on its purpose  
    @db = if Sinatra::Base.production? #Create new connections to DB and store in the @db instance variable; other lines added when setting up program for use with Heroku
        PG.connect(ENV['DATABASE_URL'])
      else
        PG.connect(dbname: "todos")
      end
    @logger = logger 
  end

  #Method for the purpose of anytime using a query we are automatically printing it to the terminal d-bug console 
  def query(statement, *params) #Use of splat(*) parameter used with methods where you don't know how many arguements it will take 
    @logger.info "#{statement}: #{params}" #Funtionailty for the ability to see in the local host terminal d-bug output from sinatra showing all of the requests it's accepting; this will alow us to see the SQL queries that are being executed in the db to help troubleshoot 
    @db.exec_params(statement, params) #The use of this .exec_params is replacing the .exec_params that would have been called in each of the methods 
  end

  def find_list(id)
    #@session[:lists].find { |l| l[:id] == id }
    sql = "Select * FROM lists WHERE id = $1" #The .exec_params that pass the id into this statement can be found in the "def query method" above 
    result = query(sql, id)  

    #Convert DB result array object into a hash that can properly be used by the .rb code 
    tuple = result.first 

    list_id = tuple["id"].to_i 
    todos = find_todos_for_list(list_id)
    {id: list_id, name: tuple["name"], todos: todos}
  end

  def all_lists           #allows us to load the list page in the application 
    sql = "SELECT * FROM lists"
    result = query(sql) #The query method will pass back the .exec_params so the SQL code works above 

    result.map do |tuple|
      list_id = tuple["id"].to_i        #Teh values returned from queries will always be strings so they will need to be returned to the wanted state 
      todos = find_todos_for_list(list_id)
      {id: list_id, name: tuple["name"], todos: todos}  #Converting the array result of the db sql statement into a hash that can be used within the system 
    end
  end



  #Inserts a new row into the db
  def create_new_list(list_name) 
    sql = "INSERT INTO lists (name) VALUES ($1)"
    result = query(sql, list_name)
  end

  #Write a new implementation of DatabasePersistence#delete_list that removes the correct row from the lists table.
  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = $1", id)
    query("DELETE FROM lists WHERE id = $1", id)
  end

  #Write a new implementation of DatabasePersistence#update_list_name that updates a row in the database.
  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql, new_name, id)
  end

  #Write a new implementation of DatabasePersistence#create_new_todo that inserts new rows into the database.
  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2)"
    query(sql, todo_name, list_id)
  end

  #Write a new implementation of DatabasePersistence#delete_todo_from_list that removes the correct row from the todos table.
  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
    query(sql, todo_id, list_id)
  end

  #Write a new implementation of DatabasePersistence#update_todo_status that updates a row in the database.
  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"
    query(sql, new_status, todo_id, list_id)
  end

  #Write a new implementation of DatabasePersistence#mark_all_todos_as_completed that updates all rows in the database.
  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(sql, list_id)
  end

  private 

  def find_todos_for_list(list_id)
    todo_sql = "SELECT * FROM todos WHERE list_id = $1"
    todos_result = query(todo_sql, list_id)

    todos_result.map do |todo_tuple|   #I really do not understand how this piece works; If the query returns an array or arrays how can you add it to a hash using the column header name? 
      {id: todo_tuple["id"].to_i,                    #I guess the result of a Query eventhough in array of arrays format can be treated as a hash with the column header = the hash key 
       name: todo_tuple["name"],
       completed: todo_tuple["completed"] == "t"}
    end
  end


end