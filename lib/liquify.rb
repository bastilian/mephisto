module Liquify  
  module ClassMethods
    def liquify
      self.send :include, InstanceMethods
    end
  end

  module InstanceMethods
    def to_liquid(options=nil)
      "#{self.class}Drop".constantize.new(self, options)
    end
  end   

  ActiveRecord::Base.extend ClassMethods
end

ActiveRecord::Base.extend Liquify