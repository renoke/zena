class Version < ActiveRecord::Base
  include Zena::Use::AutoVersion
  include Zena::Use::Attachment
  include Zena::Use::MultiVersion::Version
  include Zena::Use::Workflow::Version
  include Dynamo::Attribute

  belongs_to            :user

  validates_presence_of :node_id

  attr_protected :node_id, :site_id, :content_id

  before_create :set_site_id


  def author
    user.contact
  end

  private
    def set_site_id
      self[:site_id] = current_site.id
    end
end
