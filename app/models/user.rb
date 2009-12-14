require 'digest/sha1'
require 'tzinfo'
require 'authlogic/crypto_providers/bcrypt'

=begin rdoc
There are two special users in each site :
[anon] Anonymous user. Used to set defaults for newly created users.
[su] This user has full access to all the content in zena. He/she can read/write/destroy
      about anything. Even private content can be read/edited/removed by su. <em>This user should
      only be used for emergency purpose</em>. This is why an ugly warning is shown on all pages when
      logged in as su.

If you want to give administrative rights to a user, simply put him/her into the _admin_ group.

Users have access rights defined by the groups they belong to. They also have a 'status' indicating the kind of
things they can/cannot do :
+:user+::        (60): can read/write/publish
+:commentator+:: (40): can write comments
+:moderated+::   (30): can write moderated comments
+:reader+::      (20): can only read
+:deleted+::     ( 0): cannot login

TODO: when a user is 'destroyed', pass everything he owns to another user or just mark the user as 'deleted'...
=end
class User < ActiveRecord::Base

  acts_as_authentic do |c|
    #c.transition_from_crypto_providers = Zena::InitialCryptoProvider
    #c.crypto_provider = Authlogic::CryptoProviders::BCrypt
    c.crypto_provider = Zena::CryptoProvider::Initial
    c.validate_email_field = false
    c.validate_login_field = false
    c.require_password_confirmation = false
    c.validate_password_field = false
  end

  include RubyLess::SafeClass

  safe_attribute          :login, :name, :first_name, :email, :time_zone, :created_at, :updated_at
  safe_method             :initials => String, :fullname => String, :status => Number, :status_name => String

  safe_context            :contact => 'Contact'
  attr_accessible         :login, :lang, :first_name, :name, :email, :time_zone, :status, :group_ids, :site_ids, :crypted_password, :password
  attr_accessor           :visited_node_ids
  attr_accessor           :ip

  belongs_to              :site
  belongs_to              :contact, :dependent => :destroy
  has_and_belongs_to_many :groups
  has_many                :nodes
  has_many                :versions

  before_validation       :user_before_validation
  validate                :valid_groups
  validate                :valid_user
  validates_uniqueness_of :login, :scope => :site_id

  before_destroy          :dont_destroy_protected_users
  validates_presence_of   :site_id
  before_create           :create_contact

  Status = {
    :su          => 80,
    :admin       => 60,  # can create other users, manage site, etc
    :user        => 50,  # can write articles + publish (depends on access rights)
    :commentator => 40,  # can write comments
    :moderated   => 30,  # can write comments (moderated)
    :reader      => 20,  # can read
    :deleted     => 0,
  }.freeze
  Num_to_status = Hash[*Status.map{|k,v| [v,k]}.flatten].freeze


  class << self

    def find_allowed_user_by_login(login)
      User.find(:first, :conditions=>["login = ? and status > 0 and site_id = ?", login, current_site.id])
    end

    # Creates a new user without setting the defaults (used to create the first users of the site). Use
    # new instead.
    alias new_no_defaults new

    # Creates a new user with the defaults set from the anonymous user.
    def new(attrs={})
      new_attrs = attrs.dup
      anon = visitor.site.anon

      # Set new user defaults based on the anonymous user.
      [:lang, :time_zone, :status].each do |sym|
        new_attrs[sym] = anon.send(sym) if attrs[sym].blank? && attrs[sym.to_s].blank?
      end
      super(new_attrs)
    end

  end


  def contact_with_secure
    @contact ||= secure(Contact) { contact_without_secure }
  end
  alias_method_chain :contact, :secure


  # Each time a node is found using secure (Zena::Acts::Secure or Zena::Acts::SecureNode), this method is
  # called to set the visitor in the found object. This is also used to keep track of the opened nodes
  # when rendering a page for the cache so we can know when to expire the cache.
  def visit(obj, opts={})
    if obj.kind_of? Node
      obj.visitor = self #explicit visit
      # keep track of the nodes connected to this visit to build the 'expire_with' list
      visited_node_ids << obj[:id]
    end
  end

  def visited_node_ids
    @visited_node_ids ||= []
  end

  def fullname
    (first_name ? (first_name + " ") : '') + name.to_s
  end

  def initials
    fullname.split(" ").map {|w| w[0..0].capitalize}.join("")
  end

  def email
    self[:email] || ""
  end

  # Store the password, using SHA1. You should change the default value of PASSWORD_SALT (in Zena::ROOT/lib/zena.rb). This makes it harder to use
  # rainbow tables to find clear passwords from hashed values.
  # def password=(string)
  #   if string.blank?
  #     self[:password] = nil
  #   elsif string && string.length > 4
  #     self[:password] = User.hash_password(string)
  #   else
  #     @password_too_short = true
  #   end
  # end
  #
  # # Test password
  # def password_is?(str)
  #   self[:password] == User.hash_password(str)
  # end

  def status_name
    Num_to_status[status].to_s
  end

  # Return true if the user is in the admin group or if the user is the super user.
  def is_admin?
    is_su? || status.to_i >= User::Status[:admin]
  end

  # Return true if the user is the anonymous user for the current visited site
  def is_anon?
    # tested in site_test
    current_site.anon_id == self[:id] && (!new_record? || self[:login].nil?) # (when creating a new site, anon_id == nil)
  end

  # Return true if the user is the super user for the current visited site
  def is_su?
    # tested in site_test
    current_site.su_id == self[:id]
  end

  # Return true if the user's status is high enough to start editing nodes.
  def user?
    status >= User::Status[:user]
  end

  # Return true if the user's status is high enough to write comments.
  def commentator?
    status >= User::Status[:moderated]
  end

  # Return true if the user's comments should be moderated.
  def moderated?
    status < User::Status[:commentator]
  end

  # Return true if the user's status is high enough to read. This is basically the same as
  # not deleted?.
  # TODO: test
  def reader?
    status >= User::Status[:reader]
  end

  # Return true if the user is deleted and should not be allowed to login.
  # TODO: test
  def deleted?
    status == User::Status[:deleted]
  end

  # Returns a list of the group ids separated by commas for the user (this is used mainly in SQL clauses).
  def group_ids
    @group_ids ||= if is_admin?
      current_site.groups.map{|g| g[:id]}
    else
      groups.find(:all, :order=>'name').map{ |g| g[:id] }
    end
  end

  # Define the groups the user belongs to.
  def group_ids=(list)
    # We have to do our own method to avoid rails loading groups which will not be secured.
    @defined_group_ids = list
  end

  def time_zone=(tz)
    self[:time_zone] = tz.blank? ? nil : tz
    @tz = nil
  end

  #TODO: test
  # return only the ids of the groups really set (not all groups for admin or the like)
  def group_set_ids
    @group_set_ids ||= groups.map{|g| g[:id]}
  end

  # TODO: test
  def tz
    @tz ||= TZInfo::Timezone.get(self[:time_zone] || "UTC")
  rescue TZInfo::InvalidTimezoneIdentifier
    @tz = TZInfo::Timezone.get("UTC")
  end

  def comments_to_publish
    if is_su?
      # su can view all
      secure(Comment) { Comment.find(:all, :conditions => ['status = ?', Zena::Status[:prop]]) }
    else
      secure(Comment) { Comment.find(:all, :select=>'comments.*, nodes.name', :from=>'comments, nodes, discussions',
                   :conditions => ['comments.status = ? AND discussions.node_id = nodes.id AND comments.discussion_id = discussions.id AND nodes.dgroup_id IN (?)', Zena::Status[:prop], visitor.group_ids]) }
    end
  end

  # List all versions proposed for publication that the user has the right to publish.
  def to_publish
    secure(Version) { Version.find(:all, :conditions => ['status = ? AND nodes.dgroup_id IN (?)', Zena::Status[:prop], visitor.group_ids]) }
  end

  # List all versions owned that are currently being written (status= +red+)
  def redactions
    secure(Version) { Version.find(:all, :conditions => ['status = ? AND versions.user_id = ?', Zena::Status[:red], self.id]) }
  end

  # List all versions owned that are currently being proposed (status= +prop+)
  def proposed
    secure(Version) { Version.find(:all, :conditions => ['status = ? AND versions.user_id = ?', Zena::Status[:prop], self.id]) }
  end

  private
    def create_contact
      return unless visitor.site[:root_id] # do not try to create a contact if the root node is not created yet

      @contact = secure!(Contact) { Contact.new(
        # owner is the user except for anonymous and super user.
        # TODO: not sure this is a good idea...
        :user_id       => (self[:id] == current_site[:anon_id] || self[:id] == current_site[:su_id]) ? visitor[:id] : self[:id],
        :v_title       => (name.blank? || first_name.blank?) ? login : fullname,
        :c_first_name  => first_name,
        :c_name        => (name || login ),
        :c_email       => email,
        :v_status      => Zena::Status[:pub]
      )}
      @contact[:parent_id] = current_site[:root_id]

      unless @contact.save
        # What do we do with this error ?
        raise Zena::InvalidRecord, "Could not create contact node for user #{self.id} in site #{site_id} (#{@contact.errors.map{|k,v| [k,v]}.join(', ')})"
      end

      unless @contact.publish_from
        raise Zena::InvalidRecord, "Could not publish contact node for user #{user_id} in site #{site_id} (#{@contact.errors.map{|k,v| [k,v]}.join(', ')})"
      end

      self[:contact_id] = @contact[:id]
    end

    # Set user defaults.
    def user_before_validation
      return true if current_site.being_created?

      self[:site_id] = visitor.site[:id]

      if new_record?
        self.status = current_site.anon.status if status.blank?
        self.lang   = current_site.anon.lang   if lang.blank?
      elsif status.blank?
        self.status   = current_site.anon.status
      end

      if login.blank? && !is_anon?
        self.login = name
      end
    end

    # Returns the current site (self = visitor) or the visitor's site
    # FIXME: remove and use 'site'
    def current_site
      self.site || visitor.site
    end

    # Validates that anon user does not have a login, that other users have a password
    # and that the login is unique for the sites the user belongs to.
    def valid_user
      self[:site_id] = visitor.site[:id]

      if !current_site.being_created? && !visitor.is_admin? && visitor[:id] != self[:id]
        errors.add('base', 'You do not have the rights to do this.')
        return false
      end

      errors.add('lang', 'not available') unless current_site.lang_list.include?(lang)

      if is_anon?
        # Anonymous user *must* have an empty login
        self[:login]    = nil
        self[:crypted_password] = nil
      else
        if new_record?
          # Refuse to add a user in a site if already a user with same login.
          errors.add(:password, "can't be blank") if self[:crypted_password].nil? || self[:crypted_password] == ""
        else
          # get old password
          old = User.find(self[:id])
          self[:crypted_password] = old[:crypted_password] if self[:crypted_password].nil? || self[:crypted_password] == ""
          errors.add(:login, "can't be blank") if self[:login].blank?
          errors.add(:status, 'You do not have the rights to do this.') if self[:id] == visitor[:id] && old.is_admin? && self.status.to_i != old.status
        end
      end

      if self[:time_zone]
        begin
          TZInfo::Timezone.get(self[:time_zone])
        rescue
          errors.add(:time_zone, 'invalid')
        end
      end

      if @password_too_short
        errors.add(:password, 'too short')
        remove_instance_variable :@password_too_short
      end
    end

    # Make sure all users are in the _public_ and _site_ groups. Make sure
    # the user only belongs to groups in the same site.
    def valid_groups #:doc:
      g_ids = @defined_group_ids || (new_record? ? [] : group_set_ids)
      g_ids.reject! { |g| g.blank? }
      g_ids << current_site.public_group_id
      g_ids << current_site.site_group_id unless is_anon?
      g_ids.uniq!
      g_ids.compact!
      self.groups = []
      g_ids.each do |id|
        group = Group.find(id)
        unless current_site.being_created? || group.site_id == self.site_id
          errors.add('group', 'not found')
          next
        end
        self.groups << group
      end
    end

    # Do not allow destruction of the site's special users.
    def dont_destroy_protected_users #:doc:
      raise Zena::AccessViolation, "su and Anonymous users cannot be destroyed !" if current_site.protected_user_ids.include?(id)
    end

    def old
      @old ||= self.class.find(self[:id])
    end
end
