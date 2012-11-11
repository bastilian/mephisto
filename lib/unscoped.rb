# Provides the ability to unscope associations, this solves problems described in
# http://stackoverflow.com/questions/1540645/how-to-disable-default-scope-for-a-belongs-to/11012633#11012633
#
# Examples
#
#    class Document < ActiveRecord::Base
#      default_scope where(deleted: false)
#    end
#
#    class Comment < ActiveRecord::Base
#      extend Unscoped
#
#      belongs_to :document
#      unscope :document
#    end
#
module Unscoped

  # Public: Ensure a previously defined association is not scoped by a default_scope.
  #
  # associations - The Symbol with the name(s) of the associations to unscope.
  #
  # Examples
  #
  #    # Unscope a single assoication
  #    unscope :document
  #
  #    # Unscope multiple in one way.
  #    unscope :document, :comments
  #
  # Raises ArgumentError if the named association does not exist on the model, so ensure
  # the association is defined _before_ calling `unscope`.
  #
  # Returns nothing.
  def unscope(*associations)
    associations.flatten.each do |association|
      raise ArgumentError, "no association named #{association} exists on this model" unless self.reflect_on_association(*association)
  
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{association}
          self.class.reflect_on_association(#{association.inspect}).klass.send(:with_exclusive_scope) { super }
        end
      RUBY
    end
  end
end