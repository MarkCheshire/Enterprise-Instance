class ChangetoSiteUrl < ActiveRecord::Migration
  def self.up
    rename_column :accounts, :cover_code_digits, :site_url
  end

  def self.down
  end
end
