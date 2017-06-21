class AddAccessToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :access_token, :string
    add_column :users, :firstname, :string
    add_column :users, :lastname, :string
    add_column :users, :profile, :string
    add_column :users, :dob, :date
    add_column :users, :reporting_email, :string
  end
end
