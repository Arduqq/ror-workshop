class Feed < ApplicationRecord
  has_many :entries, dependent: :destroy  # Each feed can have many entries
  validates :title, presence: true         # Ensure the feed has a title
  validates :url, presence: true, uniqueness: true  # Ensure the feed URL is unique and present
end
