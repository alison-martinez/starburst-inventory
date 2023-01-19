require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "inventory")
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  # Return id, name, and inventory data for a category
  # Return nil if the id is not associated with a category
  def find_category(id)
    sql = <<~SQL
      SELECT categories.id, categories.name, SUM(items.num_need) AS total_needed,
      SUM(items.num_have) AS total_inventory FROM categories
      LEFT OUTER JOIN items ON categories.id = items.category_id
      WHERE categories.id = $1
      GROUP BY categories.id, categories.name
    SQL

    result = query(sql, id)

    result.first ? (tuple_to_list_hash(result.first)) : nil
  end

  # Return id, name, and inventory data for a range of categories,
  # returning only the data for a specified page
  def categories_by_page(page)
    sql = <<~SQL
      SELECT categories.id, categories.name, SUM(items.num_need) AS total_needed,
      SUM(items.num_have) AS total_inventory FROM categories
      LEFT OUTER JOIN items ON categories.id = items.category_id
      GROUP BY categories.id, categories.name
      ORDER BY LOWER(categories.name)
      LIMIT #{RESULTS_PER_PAGE} OFFSET #{page * RESULTS_PER_PAGE}
    SQL

    result = query(sql)

    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  # Return a list of the category name values
  def list_of_categories
    result = query("SELECT name FROM categories")
    result.values.flatten
  end

  # Return a list of categories besides the one being renamed
  def list_of_other_categories(id)
    result = query("SELECT name FROM categories WHERE id <> $1", id)
    result.values.flatten
  end

  def create_new_category(name)
    sql = "INSERT INTO categories (name) VALUES ($1)"
    query(sql, name)
  end

  # Return a list of item data for a specific category,
  # returning only the data for a specified page
  def items_by_category_and_page(category_id, page)
    items_sql = <<~SQL
    SELECT * FROM items WHERE category_id = $1 
    ORDER BY LOWER(name) 
    LIMIT #{RESULTS_PER_PAGE} 
    OFFSET #{page * RESULTS_PER_PAGE}
    SQL

    items_result = query(items_sql, category_id)

    items_result.map do |item_tuple|
      { id: item_tuple["id"].to_i,
        name: item_tuple["name"],
        num_need: item_tuple["num_need"].to_i,
        num_have: item_tuple["num_have"].to_i }
    end
  end

  # Return a list of item name values for a category, for counting
  def list_of_items(category_id)
    result = query("SELECT name FROM items WHERE category_id = $1", category_id)
    result.values.flatten
  end

  # Return a list of all item names
  # to check for uniqueness of new items
  def list_of_all_items
    result = query("SELECT name FROM items")
    result.values.flatten
  end

  # Return a list of all item names
  # except the current item
  def list_of_other_items(id)
    result = query("SELECT name FROM items WHERE id <> $1", id)
    result.values.flatten
  end

  # Return id, name, category, and inventory data for an item
  # If no item exists with that id, return nil
  def find_item(item_id)
    item_sql = "SELECT * FROM items WHERE id = $1"
    item_result = query(item_sql, item_id)

    item_result.first ? (tuple_to_list_hash_item(item_result.first)) : nil
  end

  def delete_category(id)
    sql = "DELETE FROM categories WHERE id = $1"
    query(sql, id)
  end

  def add_item_to_category(id, item_name, num_need, num_have)
    sql = <<~SQL
    INSERT INTO items (name, num_need, num_have, category_id) 
    VALUES ($1, $2, $3, $4)
    SQL

    query(sql, item_name, num_need, num_have, id)
  end

  def update_item(item_id, item_name, num_need, num_have)
    sql = <<~SQL
    UPDATE items 
    SET name = $1, num_need = $2, num_have = $3 
    WHERE id = $4
    SQL

    query(sql, item_name, num_need, num_have, item_id)
  end

  def delete_item(item_id)
    sql = "DELETE FROM items WHERE id = $1"
    query(sql, item_id)
  end

  def update_category_name(category_name, id)
    sql = "UPDATE categories SET name = $1 WHERE id = $2"
    query(sql, category_name, id)
  end

  private

  def tuple_to_list_hash(tuple)
    { id: tuple["id"].to_i,
      category: tuple["name"],
      needed_count: tuple["total_needed"].to_i,
      inventory_count: tuple["total_inventory"].to_i }
  end

  def tuple_to_list_hash_item(tuple)
    { id: tuple["id"].to_i,
      name: tuple["name"],
      num_need: tuple["num_need"].to_i,
      num_have: tuple["num_have"].to_i }
  end
end
