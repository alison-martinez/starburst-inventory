require "sinatra"
require "tilt/erubis"
require "yaml"
require "bcrypt"
require "titleize"
require "mongoid"

require_relative "database_persistence"

RESULTS_PER_PAGE = 5

configure do
  # enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

class User
  include Mongoid::Document

  field :username, type: String
  field :password, type: String
end


helpers do
  # Determine whether all items in a category have the needed number
  def category_complete?(category)
    category[:inventory_count] >= category[:needed_count]
  end

  # Determine whether the category has a class of completed
  def category_class(category)
    "completed" if category_complete?(category)
  end

  # Determine whether an individual item in a category has the needed number
  def item_complete?(item)
    item[:num_have] >= item[:num_need]
  end

  # Determine whether an individual item has a class of completed
  def item_class(item)
    "completed" if item_complete?(item)
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

# Return true if the user is signed in
def user_signed_in?
   session.key?(:username)
  # true
end

# Redirect user to the home page with an error message if
# they attempt to access a page without logging in.
def require_signed_in_user(path)
  unless user_signed_in?
    session[:error] = "You must be signed in to do that."
    session[:path] = path
    redirect "/users/signin"
  end
end

# Returns false if username and password are not valid
# (are not included in the users.yaml credential file)
def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

# Loads the username and password data from the users.yml credentials file
def load_user_credentials
  # credentials_path = File.expand_path('users.yml', __dir__)
  # YAML.load_file(credentials_path)
  credentials = {}
  User.all.each {|record| 
    credentials[record.username] = record.password
  }
  credentials
end

# Return id, name, and inventory data for a selected category id
# or provide error data to the session and redirect if id is invalid
def load_category(id)
  category = @storage.find_category(id.to_i)

  return category if category && id !~ /\D/

  session[:error] = "The specified category was not found."
  redirect "/categories"
end

# Return id, name, inventory, and category data for a selected item id
# or provide error data to the session and redirect if id is invalid
def load_item(item_id, id)
  item = @storage.find_item(item_id.to_i)

  return item if item && (item_id !~ /\D/) && (id !~ /\D/)

  session[:error] = "The specified item was not found."
  redirect "/categories/#{id.to_i}"
end

# Return an error if attempting to access a page that is beyond the
# pages of data for the group of categories or group of items in a category
# Also returns the error if the requested page is invalid
def error_for_page(page, total_elements)
  if total_elements == 0
    max_page = 0
  else
    max_page = (total_elements / RESULTS_PER_PAGE.to_f).ceil - 1
  end
  if (page =~ /\D/) || (!(0..max_page).cover? page.to_i )
    "The requested page is not valid."
  end
end

# Return an error message if new or updated category name is invalid.
# Return nil if values are valid.
# If an id is included, then this is an update rather than a new
# category, and validation differs
def error_for_category_name(name, id = nil)
  if !(1..100).cover? name.size
    "Category name must be between 1 and 100 characters."
  elsif id
    if @storage.list_of_other_categories(id).any? \
      { |category| category.downcase == name.downcase }
      "Updated category name must be unique."
    end
  elsif @storage.list_of_categories.any? \
    { |category| category.downcase == name.downcase }
    "New category name must be unique."
  end
end

# Return an error message if an item name or quantity is invalid.
# Return nil if values are valid
# If an id is included, then this is an update rather than a 
# new item, and validation differs
def error_for_item(item_name, num_need, num_have, item_id = nil)
  if !(1..100).cover? item_name.size
    "Item name must be between 1 and 100 characters."
  elsif num_need =~ /\D/ || num_have =~ /\D/
    "Quantities must be non-negative whole numbers."
  elsif num_have.to_i > num_need.to_i
    "The inventory of items cannot be greater than the number of items needed."
  elsif item_id
    if @storage.list_of_other_items(item_id).any? \
      { |item| item.downcase == item_name.downcase }
      "Updated item name must be unique."
    end
  elsif @storage.list_of_all_items.any? \
    { |item| item.downcase == item_name.downcase }
    "The name of the item must be unique."
  end
end

# Return an error if username or password is invalid
def error_for_credentials(username, password)
  credentials = load_user_credentials
  if !(1..30).cover? username.size
    "Username must be between 1 and 30 characters."
  elsif !(7..50).cover? password.size
    "Password must be between 7 and 50 characters."
  elsif credentials.key?(username)
    "Sorry, that username is already taken."
  end
end

# Write new credentials to yaml file
def write_credentials(username, password)
  # credentials_path = File.expand_path('users.yml', __dir__)
  # users = YAML.load_file(credentials_path)
  # users[username] = BCrypt::Password.create(password).to_s
  # File.open(credentials_path, "w") do |file|
  #   file.write users.to_yaml
  # end
  encryptedPassword = BCrypt::Password.create(password).to_s
  User.create!( username: username, password: encryptedPassword)
end

# Redirect to categories home page
get "/" do
  redirect "/categories"
end

# View a list of categories of items needed
get "/categories" do
  @page = params[:page] ? params[:page].to_i : 0
  @total_categories = @storage.list_of_categories.size

  error = error_for_page(params[:page], @total_categories)

  if error
    session[:error] = error
    redirect "/categories"
  else
    @categories = @storage.categories_by_page(@page)
    erb :categories, layout: :layout
  end
end

# Render the new category form
get "/categories/new" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  erb :new_category, layout: :layout
end

# Create a new category
post "/categories/new" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  category_name = params[:category].strip

  error = error_for_category_name(category_name)

  if error
    session[:error] = error
    erb :new_category, layout: :layout
  else
    @storage.create_new_category(category_name)
    session[:success] = "The new category has been created."
    redirect "/categories"
  end
end

# View an individual category with items
get "/categories/:id" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  id = params[:id].to_i

  @page = params[:page] ? params[:page].to_i : 0
  @total_items = @storage.list_of_items(id).size
  @category = load_category(params[:id])

  @categories = @storage.categories_by_page(@page)

  error = error_for_page(params[:page], @total_items)

  if error
    session[:error] = error
    redirect "/categories/#{id}"
  else
    @items = @storage.items_by_category_and_page(id, @page)
    erb :category, layout: :layout
  end
end

# Confirm category deletion page
post "/categories/:id/delete_confirm" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  @category_id = params[:id].to_i
  erb :confirm_delete_category, layout: :layout
end

# Delete a category
post "/categories/:id/destroy" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  id = params[:id].to_i
  choice = params[:optionsRadios]

  if choice == "delete"
    @storage.delete_category(id)
    session[:success] = "The category has been deleted."
  end
  redirect "/categories"
end

# Render a page to update the category name
get "/categories/:id/update" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  id = params[:id].to_i
  @category = load_category(params[:id])
  erb :update_category, layout: :layout
end

# Update the category name
post "/categories/:id/update" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  id = params[:id].to_i
  category_name = params[:category].strip
  @category = load_category(params[:id])

  error = error_for_category_name(category_name, id)

  if error
    session[:error] = error
    erb :update_category, layout: :layout
  else
    @storage.update_category_name(category_name, id)
    session[:success] = "The category name has been updated."
    redirect "/categories"
  end
end

# Render the page to add a new item to a category
get "/categories/:id/items/new" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  id = params[:id].to_i
  @category = load_category(params[:id])
  erb :new_item, layout: :layout
end

# Add a new item to a category
post "/categories/:id/items/new" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  id = params[:id].to_i
  item_name = params[:item].strip
  num_need = params[:num_need].strip.to_i
  num_have = params[:num_have].strip.to_i
  @category = load_category(params[:id])

  error = error_for_item(item_name, params[:num_need].strip, \
                         params[:num_have].strip)

  if error
    session[:error] = error
    erb :new_item, layout: :layout
  else
    @storage.add_item_to_category(id, item_name, num_need, num_have)
    session[:success] = "The new item has been created."
    redirect "/categories/#{id}"
  end
end

# Render the item editing page
get "/categories/:id/items/:item_id/update" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  @id = params[:id].to_i
  @item_id = params[:item_id].to_i
  @item = load_item(params[:item_id], params[:id])
  erb :update_item, layout: :layout
end

# Update an item in a category
post "/categories/:id/items/:item_id/update" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  @id = params[:id].to_i
  @item_id = params[:item_id].to_i
  @item = load_item(params[:item_id], params[:id])

  item_name = params[:item].strip
  num_need = params[:num_need].strip.to_i
  num_have = params[:num_have].strip.to_i

  error = error_for_item(item_name, params[:num_need].strip, \
                         params[:num_have].strip, @item_id)

  if error
    session[:error] = error
    erb :update_item, layout: :layout
  else
    @storage.update_item(@item_id, item_name, num_need, num_have)
    session[:success] = "The item has been updated."
    redirect "/categories/#{@id}"
  end
end

# Confirm item deletion page
post "/categories/:id/items/:item_id/delete_confirm" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  @category_id = params[:id].to_i
  @item_id = params[:item_id].to_i
  @item = load_item(params[:item_id], params[:id])
  erb :confirm_delete_item, layout: :layout
end

# Delete an item in a category
post "/categories/:id/items/:item_id/destroy" do
  full_path = request.fullpath
  require_signed_in_user(full_path)

  id = params[:id].to_i
  item_id = params[:item_id].to_i
  choice = params[:optionsRadios]

  if choice == "delete"
    @storage.delete_item(item_id)
    session[:success] = "The item has been deleted."
  end
  redirect "/categories/#{id}"
end

# Render the sign-in page
get "/users/signin" do
  erb :signin
end

# Sign-in to app
post "/users/signin" do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:success] = "Welcome!"
    if session[:path]
      path = session[:path]
      session.delete(:path)
      redirect path
    else
      redirect "/"
    end
  else
    session[:error] = "Invalid credentials"
    erb :signin
  end
end

# Sign-out of app
post "/users/signout" do
  session.delete(:username)
  session[:success] = "You have been signed out."
  redirect "/"
end

# Render the page to create a new account
get "/users/create" do
  erb :create_account
end

# Create a new account
post "/users/create" do
  username = params[:username]
  password = params[:password]

  error = error_for_credentials(username, password)

  if error
    session[:error] = error
    erb :create_account, layout: :layout
  else
    write_credentials(username, password)
    session[:success] = "Your account has been created!  Please sign in."
    redirect "/users/signin"
  end
end

not_found do
  session[:error] = "Sorry, that page was not found."
  redirect "/"
end

after do
  @storage.disconnect
end
