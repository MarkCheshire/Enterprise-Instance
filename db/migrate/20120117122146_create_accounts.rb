class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.string :provider_key
      t.string :provider_name
      t.string :cover_code_digits
      t.string :developer_id
      t.string :cover_code
      t.string :provider_id
      t.string :password
      t.string :app_name
      t.string :app_id
      t.string :app_key
      t.timestamps
    end
  end

  def self.down
    drop_table :accounts
  end
end
