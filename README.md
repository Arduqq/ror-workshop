# Creating a Simple RSS Feed Reader in Ruby on Rails

This tutorial walks you through how to build a simple RSS Feed Reader in Ruby on Rails.

## Prerequisites

Before we begin, make sure you have the following tools installed:

- Rails installed (`gem install rails`)
- SQLite (or PostgreSQL if preferred)
- Bundler (`gem install bundler`)

---

## Step 1: Create a New Rails Application

To start a new Rails application:

```sh
rails new rss_reader
cd rss_reader
```

---

## Step 2: Generate the Feed Model and Controller

We will create a `Feed` model to store the feed's title and URL, as well as a `FeedsController` to handle our feed logic.

Run the following commands:

```sh
rails generate model Feed title:string url:string
rails generate controller Feeds
rake db:migrate
```

This will generate the necessary database table (`feeds`) and controller.

---

## Step 3: Add Feed Parsing with `feedjira`

We need two gems to handle RSS feed parsing and fetching:

1. `feedjira` - A gem to parse the RSS feed data.
2. `httparty` - A gem for making HTTP requests to fetch feed data.

Add these gems to your `Gemfile`:

```ruby
gem 'feedjira'
gem 'httparty'
```

Then, install the gems by running:

```sh
bundle install
```

---

## Step 4: Create the Feeds Controller Actions

Next, we will define the actions in our `FeedsController` to add, view, and show RSS feeds.

Edit the `app/controllers/feeds_controller.rb` file:

```ruby
class FeedsController < ApplicationController
  require 'feedjira'  # Used to parse the RSS feed
  require 'httparty'   # Used to fetch feed data via HTTP
  
  # Fetch all feeds from the database to display on the index page
  def index
    @feeds = Feed.all
  end

  # Display a form for adding a new feed
  def new
    @feed = Feed.new
  end

  # Create a new feed from the form data and save it to the database
  def create
    @feed = Feed.new(feed_params)
    
    if @feed.save  # If the feed is saved successfully
      redirect_to feeds_path, notice: "Feed added successfully!"  # Redirect to the feed list
    else  # If the feed save fails (validation issues, etc.)
      render :new  # Render the 'new' form again for corrections
    end
  end

  # Display a specific feed and its entries
  def show
    @feed = Feed.find_by(id: params[:id])  # Find the feed by its ID
    if @feed.nil?  # If the feed is not found
      redirect_to feeds_path, alert: "Feed not found."  # Redirect to the feed list
    else
      # Fetch the entries from the feed URL
      @entries = fetch_feed_entries(@feed.url)
    end
  end

  private

  # Strong parameters for creating or updating a feed
  def feed_params
    params.require(:feed).permit(:title, :url)
  end

  # Fetch and parse the feed entries from the provided URL
  def fetch_feed_entries(url)
    response = HTTParty.get(url)  # Fetch the content of the RSS feed
    feed = Feedjira.parse(response.body)  # Parse the fetched content with Feedjira
    
    # Map each entry to a simplified hash containing essential details
    feed.entries.map do |entry|
      { 
        title: entry.title,  # Title of the entry
        url: entry.url,      # URL of the entry
        summary: entry.summary  # Summary of the entry
      }
    end
  end
end
```

### Explanation:

- `index` action: Retrieves all feeds and displays them in the index view.
- `new` action: Displays a form to add a new feed.
- `create` action: Handles the form submission, saves the new feed to the database, and redirects back to the feed list.
- `show` action: Displays a specific feed and its entries fetched from the feed URL.

---

## Step 5: Create the Views

Now, let’s create the views to display the feeds and their entries.

### `app/views/feeds/index.html.erb`

The index view will list all saved feeds:

```erb
<h1>RSS Feeds</h1>
<%= link_to 'Add Feed', new_feed_path %>  <!-- Link to add a new feed -->
<ul>
  <% @feeds.each do |feed| %>  <!-- Loop through each feed in the database -->
    <li><%= link_to feed.title, feed_path(feed) %></li>  <!-- Display feed title and link to its details -->
  <% end %>
</ul>
```

### `app/views/feeds/new.html.erb`

The `new` view provides a form to add a new feed:

```erb
<h1>Add a New Feed</h1>

<%= form_with model: (@feed || Feed.new), local: true do |f| %>  <!-- Form for adding a new feed -->
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>  <!-- Input field for feed title -->
  </p>
  <p>
    <%= f.label :url %><br>
    <%= f.text_field :url %>  <!-- Input field for feed URL -->
  </p>
  <p>
    <%= f.submit "Save" %>  <!-- Submit button -->
  </p>
<% end %>
```

### `app/views/feeds/show.html.erb`

The `show` view displays the details of a specific feed and its entries:

```erb
<h1><%= @feed&.title || "Feed Not Found" %></h1>  <!-- Display feed title or "Feed Not Found" -->
<% if @entries.present? %>  <!-- Check if there are entries in the feed -->
  <ul>
    <% @entries.each do |entry| %>  <!-- Loop through each entry of the feed -->
      <li>
        <a href="<%= entry[:url] %>"><%= entry[:title] %></a>  <!-- Display entry title as a link -->
        <p><%= entry[:summary] %></p>  <!-- Display entry summary -->
      </li>
    <% end %>
  </ul>
<% else %>
  <p>No entries found.</p>  <!-- If no entries are found in the feed -->
<% end %>

<%= link_to 'Back to Feeds', feeds_path %>  <!-- Link to return to the list of feeds -->
```

---

## Step 6: Define Routes

To define routes for accessing the feeds, edit the `config/routes.rb` file:

```ruby
Rails.application.routes.draw do
  resources :feeds  # Generates all necessary routes for the feeds
  root "feeds#index"  # Set the root path to the feeds index page
end
```

This ensures that you can perform CRUD actions (Create, Read, Update, Delete) on feeds.

---

## Step 7: Start the Server and Test

Now that everything is set up, start the Rails server:

```sh
rails server
```

Visit `http://localhost:3000` in your browser to:

- Add new RSS feeds
- View saved feeds
- Display entries from each RSS feed

---

## Done! Here's what your app can do.

1. Create a `Feed` model to store the feed title and URL.
2. Use `Feedjira` to parse the RSS feeds and fetch entries.
3. Display feed entries on a simple web interface.

You can expand this project further by:

- Adding background jobs to periodically fetch and update feed entries.
- Enhancing the user interface with a CSS framework like Bootstrap or Tailwind.
- Implementing search functionality to filter feed entries.

Happy coding!
