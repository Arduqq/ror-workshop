class CreateFeeds < ActiveRecord::Migration[8.0]
  def change
    create_table :feeds do |t|
      t.string :title
      t.string :url

      t.timestamps
    end
  end
end
