class Site < ActiveRecord::Base
  has_many  :assets, :as => :attachable
  serialize :filters, Array

  def filters=(value)
    write_attribute :filters, [value].flatten.collect(&:to_sym)
  end
end