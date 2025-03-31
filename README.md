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

## Step 4: Create a Feed Model

Here you will make clear what the functionality and structure of a feed is. A feed has a title and a url, as well as its overall entries. In general, you will want to have a feed fetch all of its entries, as well as show the entirety of your feed (your global feed).

Edit the `app/models/feed.rb` file:

```ruby
class Feed < ApplicationRecord
  # Associations
  has_many :entries, dependent: :destroy  # Each feed can have many entries

  # Validations
  validates :title, presence: true         # Ensure the feed has a title
  validates :url, presence: true, uniqueness: true  # Ensure the feed URL is unique and present

  # Fetch feed entries for a specific feed URL
  def self.fetch_feed_entries(url)
    response = HTTParty.get(url)
    parsed_feed = Feedjira.parse(response.body)

    # Map parsed entries into a standardized format
    parsed_feed.entries.map do |entry|
      {
        title: entry.title,
        url: entry.url,
        summary: entry.summary,
        published: entry.published || Time.zone.now
      }
    end
  rescue => e
    Rails.logger.error "Failed to fetch feed from #{url}: #{e.message}"
    []  # Return an empty array if fetching the feed fails
  end

  # Fetch feed entries for all saved feeds
  def self.fetch_feed_entries_global
    all_entries = []

    Feed.all.each do |feed|
      entries = fetch_feed_entries(feed.url)
      all_entries.concat(entries) if entries
    end

    # Sort the entries by publication date in descending order
    all_entries.sort_by { |entry| entry[:published] || Time.zone.now }.reverse
  end

private

  def feed_params
     params.require(:feed).permit(:title, :url)
   end
end

```

## Step 5: Create the Feeds Controller Actions

Next, we will define the actions in our `FeedsController` to add, view, and show RSS feeds. It's where we define what happens when we ask the server to do things for us.

Edit the `app/controllers/feeds_controller.rb` file:

```ruby
class FeedsController < ApplicationController
  def index
    @feeds = Feed.all
    @entries = Feed.fetch_feed_entries_global  # Call the method from the Feed model
  end

  def new
    @feed = Feed.new
  end

  def create
    @feed = Feed.new(feed_params)
    if @feed.save
      redirect_to feeds_path, notice: "Feed added successfully!"
    else
      render :new
    end
  end

  def show
    @feed = Feed.find_by(id: params[:id])
    if @feed.nil?
      redirect_to feeds_path, alert: "Feed not found."
    else
      @entries = Feed.fetch_feed_entries(@feed.url)  # Call the method from the Feed model
    end
  end

  def destroy
    @feed = Feed.find(params[:id])
    @feed.destroy
    redirect_to feeds_path, notice: "Feed was successfully deleted."
  end
end

```

### Explanation:

- `index` action: Retrieves all feeds and displays them in the index view.
- `new` action: Displays a form to add a new feed.
- `create` action: Handles the form submission, saves the new feed to the database, and redirects back to the feed list.
- `show` action: Displays a specific feed and its entries fetched from the feed URL.

---

## Step 6: Create the Views

Now, let’s create the views to display the feeds and their entries. This is the place where you structure all that data that you request from your server. 

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
