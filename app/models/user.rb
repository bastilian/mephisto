require 'digest/sha1'
class User < ActiveRecord::Base
  @@admin_scope = {:find => { :conditions => ['admin = ?', true] } }
  @@membership_options = {:select => 'distinct users.*, memberships.admin as site_admin', :order => 'users.login',
    :joins => 'left outer join memberships on users.id = memberships.user_id'}

  default_scope :conditions => {:deleted_at => nil}

  # Virtual attribute for the unencrypted password
  attr_accessor :password
  
  #Only these can be modified through bulk-setters like update_attributes, new, create
  attr_accessible :login, :email, :password, :password_confirmation, :filter
  
  validates_presence_of     :login, :email
  validates_format_of       :email, :with => Format::EMAIL
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 5..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login, :email, :case_sensitve => false
  before_save :encrypt_password

  has_many :articles

  has_many :memberships, :dependent => :destroy
  has_many :sites, :through => :memberships, :order => 'title, host'

  def self.find_admins(*args)
    with_scope(@@admin_scope) { find *args }
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate_for(site, login, password)
    return nil if site.nil? || login.nil? || login.blank? || password.nil? || password.blank?
    u = find(:first, @@membership_options.merge(
      :conditions => ['users.login = ? and (memberships.site_id = ? or users.admin = ?)', login, site.id, true]))
    u && u.authenticated?(password) ? u : nil
  end

  def self.find_by_site(site, id)
    self.find_by_site_with_deleted(site, id)
  end

  def self.find_by_site_with_deleted(site, id, with_deleted=nil)
    if with_deleted
      self.with_exclusive_scope { self.find(:first, @@membership_options.merge(
            :conditions => ['users.id = ? and (memberships.site_id = ? or users.admin = ?)', id, site.id, true])) }
    else
      self.find_by_site_without_deleted(site, id)
    end
  end

  def self.find_by_site_without_deleted(site, id)
    self.find(:first, @@membership_options.merge(
          :conditions => ['users.id = ? and (memberships.site_id = ? or users.admin = ?)', id, site.id, true]))
  end

  def self.find_with_deleted(id)
    self.with_exclusive_scope { User.find(id) }
  end

  def self.count_with_deleted
    self.with_exclusive_scope { User.count(:all) }
  end

  def self.find_all_by_site(site, options = {})
    find(:all, @@membership_options.merge(options.reverse_merge(:conditions => ['memberships.site_id = ? or users.admin = ?', site.id, true]))).uniq
  end

  def self.find_all_by_site_with_deleted(site, options = {})
    self.with_exclusive_scope { self.find_all_by_site(site, options) }
  end

  def self.find_by_token(site, token)
    return nil if site.nil? || token.nil? || token.blank?
    find(:first, @@membership_options.merge(:conditions => ['token = ? and token_expires_at > ? and (memberships.site_id = ? or users.admin = ?)', token, Time.now.utc, site.id, true]))
  end
  
  def self.find_by_email(site, email)
    find(:first, @@membership_options.merge(:conditions => ['email = ? and (memberships.site_id = ? or users.admin = ?)', email, site.id, true]))
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def token?
    token_expires_at && Time.now.utc < token_expires_at 
  end

  # The site admin property is brought in from memberships.admin, when joined with the sites table.
  def site_admin?
    ActiveRecord::ConnectionAdapters::Column.value_to_boolean read_attribute(:site_admin)
  end

  def reset_token!
    (self.token = rand_key).tap do |t|
      self.token_expires_at = 2.weeks.from_now.utc
      save!
    end
  end

  def to_liquid
    UserDrop.new self
  end

  def destroy
    self.update_attribute(:deleted_at, Time.now)
  end

  protected
    def encrypt_password
      return if password.blank?
      self.salt = rand_key if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.nil? || !password.blank?
    end
    
    def rand_key
      Digest::SHA1.hexdigest("--#{Time.now.to_s.split(//).sort_by {rand}.join}--#{login}--")
    end
end
