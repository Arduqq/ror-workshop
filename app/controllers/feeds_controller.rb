class FeedsController < ApplicationController
  # Feedjira is a library that helps parse RSS feeds
  require "feedjira"

  # Action for displaying all feeds
  def index
    # Fetches all the feed entries globally from all feeds stored in the database
    @feeds = Feed.all
    @entries = fetch_feed_entries_global
  end

  # Action to initialize a new feed object for the form
  def new
    # Creates an empty instance of Feed
    @feed = Feed.new
  end

  # Action to create a new feed
  def create
    # Creates a new feed object from the parameters submitted via the form
    @feed = Feed.new(feed_params)
    
    # Attempts to save the feed object to the database
    if @feed.save
      # If the feed is saved successfully, redirect to the feeds index page with a success message
      redirect_to feeds_path, notice: "Feed added successfully!"
    else
      # If save fails, re-render the new feed form
      render :new
    end
  end

  # Action to display a specific feed's details
  def show
    # Attempts to find a feed from the database using the provided feed ID
    @feed = Feed.find_by(id: params[:id])

    if @feed.nil?
      # If the feed is not found, redirect to the feed index page with an error message
      redirect_to feeds_path, alert: "Feed not found."
    else
      # If the feed is found, fetch all the entries from the feed URL
      @entries = fetch_feed_entries(@feed.url)
    end
  end

  # Action to delete a specific feed
  def destroy
    # Finds the feed to be deleted by its ID
    @feed = Feed.find(params[:id])
    
    # Deletes the feed from the database
    @feed.destroy
    
    # Redirects to the feed index page with a success message
    redirect_to feeds_path, notice: "Feed was successfully deleted."
  end

  private

  # Strong parameters for feed creation (only title and url are allowed)
  def feed_params
    params.require(:feed).permit(:title, :url)
  end

  # Fetches entries for all the feeds globally (combining entries from multiple feeds)
  def fetch_feed_entries_global
    # Initialize an empty array to store entries
    all_entries = []

    # Iterate over each feed stored in the database
    @feeds.each do |feed|
      # Fetch entries for each feed using its URL
      parsed_feed = fetch_feed_entries(feed.url)

      # Add the fetched entries to the all_entries array if any are returned
      all_entries.concat(parsed_feed) if parsed_feed
    end

    # Sort the collected entries by their published date, most recent first
    all_entries.sort_by { |entry| entry[:published] || Time.zone.now }.reverse
  end

  # Fetches entries from a single feed URL
  def fetch_feed_entries(url)
    # Fetches the feed content using HTTP request
    response = HTTParty.get(url)
    
    # Parses the feed content using Feedjira
    parsed_feed = Feedjira.parse(response.body)

    # Maps the parsed feed entries to a more structured format
    parsed_feed.entries.map do |entry|
      {
        title: entry.title,       # Title of the entry
        url: entry.url,           # URL of the entry
        summary: entry.summary,   # Summary of the entry
        published: entry.published || Time.zone.now # Published date, fallback to current time
      }
    end
  rescue => e
    # If there is an error in fetching or parsing, log the error and return an empty array
    Rails.logger.error "Failed to fetch feed from #{url}: #{e.message}"
    []
  end
end
