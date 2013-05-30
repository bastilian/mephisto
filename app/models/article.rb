class Article < Content
  class CommentNotAllowed < StandardError; end
  extend Unscoped
  validates_presence_of :title, :user_id, :site_id

  before_validation { |record| record.set_default_filter! }
  after_validation :convert_to_utc
  has_permalink :title, :scope => :site_id
  after_save    :save_assigned_sections
  after_update  :reset_comment_attributes

  liquify

  acts_as_versioned :if_changed => [:title, :body, :excerpt], :limit => 5 do
    def self.included(base)
      base.send :include, Mephisto::TaggableMethods
      base.belongs_to :updater, :class_name => '::User', :foreign_key => 'updater_id'
      [:year, :month, :day].each { |m| base.delegate m, :to => :published_at }
    end

    def published?
      !new_record? && !published_at.nil?
    end

    def pending?
      !published? || Time.now.utc < published_at
    end
    
    def status
      pending? ? :pending : :published
    end
  end

  has_many :assigned_sections, :dependent => :destroy
  has_many :sections, :through => :assigned_sections, :order => 'sections.name'

  has_many :events,   :order => 'created_at desc', :dependent => :delete_all

  has_many :comments, :dependent => :delete_all

  has_many :assigned_assets, :order => 'position', :dependent => :destroy
  has_many :assets, :through => :assigned_assets, :conditions => ['assigned_assets.active = ?', true], :select => 'assets.*, assigned_assets.label' do
    def add(asset, label = nil)
      AssignedAsset.find_or_create_by_article_id_and_asset_id(proxy_owner.id, asset.id).tap do |aa|
        aa.label  = label
        aa.active = true
        aa.save!
      end
    end
    
    def remove(asset)
      AssignedAsset.update_all ['active = ?', false], ['article_id = ? AND asset_id = ?', proxy_owner.id, asset.id]
    end
  end

  belongs_to :user
  unscope    :user

  named_scope :with_permalink, lambda {|options| { :conditions => ['(contents.permalink = ?)', options[:permalink]] } }
  named_scope :in_timeframe,   lambda {|options| { :conditions => ['(contents.published_at BETWEEN ? AND ?)', Time.delta(options[:year], options[:month], options[:day])].flatten } }
  named_scope :published,      lambda { { :conditions => ["(contents.published_at IS NOT NULL AND contents.published_at <= ?)", Time.now.utc], :order => 'published_at desc' } }
  named_scope :tagged,         lambda {|tags| {:conditions => ["tags.name IN (?)", tags], :include => [:user, :tags]} }
  named_scope :in_section,     lambda {|section| { :conditions => ['assigned_sections.section_id = ?', section.id], 
                                                   :joins => 'inner join assigned_sections on contents.id = assigned_sections.article_id' }}

  class << self

    def find_by_permalink(options)
      result = if options.is_a?(String)
        published.with_permalink(:permalink => options)
      elsif options[:id]
        published.find_by_id(options[:id])
      elsif options[:permalink] && !(options[:year] || options[:month] || options[:day])
        published.with_permalink(options)
      elsif options[:year] || options[:month] || options[:day]
        published.with_permalink(options).in_timeframe(options)
      else
        nil
      end
      result.is_a?(Array) ? result.first : result
    end

    def with_published(&block)
      with_scope({:find => { :conditions => ['contents.published_at <= ? AND contents.published_at IS NOT NULL', Time.now.utc] } }, &block)
    end

    def find_by_date(options = {})
      with_published do
        find :all, {:order => 'contents.published_at desc'}.update(options)
      end
    end
    
    def find_all_in_month(year, month, options = {})
      published.in_timeframe({:year => year, :month => month}).find(:all, options)
    end
    
    def find_all_by_tags(tag_names, limit = 15)
      published.tagged(tag_names).find(:all, {:limit => limit})
    end
    
    def permalink_for(str)
      PermalinkFu.escape(str)
    end
  end

  # AX
  def full_permalink
    published? && ['', published_at.year, published_at.month, published_at.day, permalink] * '/'
  end

  def has_section?(section)
    return @new_sections.include?(section.id.to_s) if !@new_sections.blank?
    (new_record? && section.home?) || sections.include?(section)
  end

  def section_ids=(new_sections)
    @new_sections = new_sections
  end

  def published_at=(value)
    @recently_published = published_at.nil? && value
    write_attribute :published_at, value
  end
  
  def recently_published?
    @recently_published
  end

  def filter=(new_filter)
    return if new_filter == read_attribute(:filter)
    @old_filter ||= read_attribute(:filter)
    write_attribute :filter, new_filter
  end

  # AX
  def hash_for_permalink(options = {})
    [:year, :month, :day, :permalink].inject(options) { |o, a| o.update a => send(a) }
  end

  def accept_comments?
    status == :published && (comment_age > -1) && (comment_age == 0 || comments_expired_at > Time.now.utc)
  end

  def comments_expired_at
    (published_at || Time.now.utc) + comment_age.days
  end

  def set_filter_from(filtered_object)
    self.filter = filtered_object.filter
  end

  def set_default_filter_from(filtered_object)
    set_filter_from(filtered_object) if filter.nil?
  end

  def set_default_filter!
    set_default_filter_from user
  end

  def add_xml(builder)
    add_podcast_xml(builder)
  end

  def next(section=nil)
    return nil if section && !sections.include?(section)
    section = sections[0] if (section.nil?)
    if section.paged?
      articles_in_section = section.articles.published
      index = articles_in_section.index(self)
      (index <= articles_in_section.length-1) ? articles_in_section[index+1] : nil
    else
      site.articles.published.in_section(section).first
    end
  end

  def previous(section=nil)
    return nil if section && !sections.include?(section)
    section = sections[0] if (section.nil?)
    self.class.with_published do
      if section
        if section.paged?
          index = section.articles.index(self)
          (index > 0) ? section.articles[index-1] : nil
          # article = section.articles.detect {|article| article.id == id }
        else
          site.articles.find :first, :conditions => ['published_at < ? and assigned_sections.section_id = ?', published_at, section.id], 
            :joins => 'inner join assigned_sections on contents.id = assigned_sections.article_id',
            :order => 'published_at desc'
        end
      else
        site.articles.find :first, :conditions => ['published_at < ?', published_at], :order => 'published_at desc'
      end
    end
  end


  protected
    def convert_to_utc
      self.published_at = published_at.utc if published_at
    end
    
    def save_assigned_sections
      return if @new_sections.nil?
      assigned_sections.each do |assigned_section|
        @new_sections.delete(assigned_section.section_id.to_s) || assigned_section.destroy
      end
      
      if !@new_sections.blank?
        Section.find(:all, :conditions => ['id in (?)', @new_sections]).each { |section| assigned_sections.create :section => section }
        sections.reset
      end
    
      @new_sections = nil
    end
    
    def reset_comment_attributes
      Content.update_all ['title = ?, published_at = ?, permalink = ?', title, published_at, permalink], ['article_id = ?', id]
    end
    
    def add_podcast_xml(builder)
      if asset = assets.find(:first, :conditions => ['label = ?', 'podcast'], :select => 'assets.*')
        builder.link :rel => :enclosure, :type => asset.content_type, :length => asset.size, :href => asset.public_filename
      end
    end
end