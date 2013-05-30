require 'rubypants'
require 'base64'

require 'mephisto'
require 'mephisto/theme_root'

class ActionController::Dispatcher
  def self.register_liquid_tags
    Mephisto.liquid_filters.each { |mod| Liquid::Template.register_filter mod }
    Mephisto.liquid_tags.each { |name, klass| Liquid::Template.register_tag name, klass }
  end
end

ActionController::Dispatcher.register_liquid_tags

ActiveSupport::Inflector.inflections do |inflect|
  #inflect.plural /^(ox)$/i, '\1en'
  #inflect.singular /^(ox)en/i, '\1'
  #inflect.irregular 'person', 'people'
  inflect.uncountable %w( audio )
end