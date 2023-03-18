### Welcome to my **Franciscan Starburst Inventory** App!

This app was designed to solve a very simple problem.  I collect a unique set of dinnerware that was manufactured in the 1950's by the Franciscan Ware company.  The pattern is called Starburst, and it is sought after for its mid-century modern aesthetic.  Although the dishes are no longer manufactured, you can still find them on ebay, Etsy, yard sales, and flea markets (if you're lucky!).

My mom and aunts are prolific yard sale divas, and they are always asking what I have and what I need.  I used to just give them some general information, and at one point I moved to an Excel spreadsheet where I could keep track of my inventory and what I'm still looking for.  However, there was not an easy way to keep it updated without emailing an updated spreadsheet every time I made changes.  I thought this would be an ideal topic for this project, as the dinnerware pieces fall into some larger category groups, and each group contains a number of individual items that are on my list.  

With this app, I have provided some starter data in the `schema.sql` file.  The app allows you to view, add, delete, and rename categories as well as view, add, delete, and update individual items within those categories.

There are a few restrictions on the data that can be entered into the database in this app:
* Category names and item names need to have a value (names must be between 1 and 100 characters)
* Category names and item names must be unique (although if you are updating, you can keep the same name)
* The quantity of items needed can not be less than 0
* The quantity of items in inventory can not be less than 0
* The quantity of items in inventory can not be greater than the number of items needed
* Item names are required, but the default values for item quantities is 0

In keeping with the general project requirements:
* The application uses Sinatra
* The application uses ERB view templates
* The application uses PostgreSQL to store dta and uses the `pg` gem
* The application uses MongoDB to store user authentication data
* The application does not use additional Rubygems for the purposes of fulfulling the project requirements.  

With regards to the application-specific requirements:
* The application contains two kinds of related data -- categories and items.  Categories are collections of items.  There is a one-to-many relationship between categories and items.  
* The application provides create-read-update-delete capabilities for both categories and items, and the pages used to update the categories and items have unique URLs
* Output on the categories page (list of categories) and the individual category pages (lists of items) is limited to 5 items per page, and an error message is generated if you try to access an invalid page number
* Categories and items are sorted alphabetically
* Input data is validated as described above. 
* URL parameters such as ID numbers and query strings are validated, with error messages generated and redirection upon errors.  All error and success messages appear as flash messages at the top of the screen
* The app requires login authentication for accessing anything besides the categories page.


Details on running this application:
1. This application was developed with Ruby 3.0.0
2. Required gems are listed in the Gemfile.  Run `bundle install` to fetch all remote sources, resolve dependencies, and install any needed gems
3. I used Google Chrome Version 103.0.5060.66 (Official Build) (64-bit) to test this app
4. Databases were created with PostgreSQL 12.11 for Ubuntu
5. Create the `inventory` database by running `createdb inventory` from your command line. 
6. Import the tables and test data into the `inventory` database by using `psql -d inventory < schema.sql` from the command line
7. Run the app by running `ruby ./inventory.rb` from your command line, and then direct your browser to `http://127.0.0.1:4567` to view the app.
8.  You must be signed in to access most of the features of the app.  Usernames and encrypted passwords are stored in a MongoDB database.    

