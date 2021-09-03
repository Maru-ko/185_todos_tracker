require 'pg'


class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: "todos")
    end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end


  def find_list(id)
    sql =<<~SQL
      SELECT l.*,
        COUNT(t.id) AS todos_count,
        COUNT(NULLIF(t.completed, true)) AS todos_remaining_count
        FROM lists l
        LEFT OUTER JOIN todos t ON t.list_id = l.id
        WHERE l.id = $1
        GROUP BY l.id
        ORDER BY l.name;
    SQL
    result = query(sql, id)
    tuple = result.first#.find_todos_for_list
    # list_id = tuple["id"].to_i
    # todos = find_todos_for_list(list_id)
    { id: tuple["id"].to_i,
      name: tuple["name"], 
      todos_count: tuple["todos_count"].to_i,
      todos_remaining_count: tuple["todos_remaining_count"].to_i }
  end

  def all_lists
    sql = <<~SQL
      SELECT l.*,
        COUNT(t.id) AS todos_count,
        COUNT(NULLIF(t.completed, true)) AS todos_remaining_count
        FROM lists l
        LEFT OUTER JOIN todos t ON t.list_id = l.id
        GROUP BY l.id ORDER BY l.name
    SQL
    result = query(sql)

    result.map do |tuple|
     { id: tuple["id"].to_i,
       name: tuple["name"],
       todos_count: tuple["todos_count"].to_i,
       todos_remaining: tuple["todos_remaining"].to_i }
    end
  end

  def find_todos_for_list(list_id)
      todo_sql = "SELECT * FROM todos WHERE list_id = $1"
      todos_result = query(todo_sql, list_id)

      todos = todos_result.map do |todo_tuple|
        {id: todo_tuple["id"].to_i, 
         name: todo_tuple["name"], 
        completed: todo_tuple["completed"] == 't' ? true : false }
      end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1)"
    query(sql, list_name)
      # id = next_element_id(@session[:lists])
      # @session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = $1", id)
    query("DELETE FROM lists WHERE id = $1", id)
      # @session[:lists].reject! { |list| list[:id] == id }
  end

  def update_list_name(id, new_name)
      # list = find_list(id)
      # list[:name] = new_name
  end

  def create_new_todo(list_id, todo_name)
      sql = "INSERT INTO todos (list_id, name) VALUES ($1, $2)"
      query(sql, list_id, todo_name)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
    query(sql, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"
    query(sql, new_status, todo_id, list_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(sql, list_id)
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists(name) VALUES ($1)"
    query(sql, list_name)
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = $1", id)
    query("DELETE FROM lists WHERE id = $1", id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql, new_name, id)
  end

  #private :find_todos_for_list
end













