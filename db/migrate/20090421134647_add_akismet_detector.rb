class AddAkismetDetector < ActiveRecord::Migration
  def self.up
    add_column :sites, :akismet_detector, :string
  end
  
  def self.down
    remove_column :sites, :akisment_detector
  end
end