class CreateRuns < ActiveRecord::Migration[5.0]
  def change
    create_table :runs do |t|
      t.belongs_to :day, index: true
      t.belongs_to :user, index: true
      t.string :distance
      t.string :time
      t.string :link
      t.timestamps
    end
  end
end
