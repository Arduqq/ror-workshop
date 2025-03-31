class FeedsController < ApplicationController
  require "feedjira"

  def index
    @feeds = Feed.all
    @entries = fetch_feed_entries_global
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
      @entries = fetch_feed_entries(@feed.url)
    end
  end

  def destroy
    @feed = Feed.find(params[:id])
    @feed.destroy
    redirect_to feeds_path, notice: "Feed was successfully deleted."
  end

  private

  def feed_params
    params.require(:feed).permit(:title, :url)
  end

  def fetch_feed_entries_global
    all_entries = []

    @feeds.each do |feed|
      parsed_feed = fetch_feed_entries(feed.url)
      all_entries.concat(parsed_feed) if parsed_feed
    end

    # Sort all entries by published date, if available
    all_entries.sort_by { |entry| entry[:published] || Time.zone.now }.reverse
  end

  def fetch_feed_entries(url)
    response = HTTParty.get(url)
    parsed_feed = Feedjira.parse(response.body)

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
    []
  end
end
