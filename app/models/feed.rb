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
end
