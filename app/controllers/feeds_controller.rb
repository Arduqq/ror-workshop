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
