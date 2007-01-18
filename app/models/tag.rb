=begin rdoc
=== Read/Write for a tag
Users can add nodes to a tag collection, if they have *write access* to the #Tag. It is exactly the same as adding a
sub page or a document. See #Link for more details.
=end
class Tag < Page
  link :tag_for, :class_name=>'Node', :as=>'tag', :collector=>true
  alias o_pages pages
  def pages
    @pages ||= (o_pages + tag_for(:conditions=>"kpath NOT LIKE 'NPD%'")).sort {|a,b| a.name <=> b.name}
  end
  
  alias o_documents documents
  def documents
    @documents ||= (o_documents + tag_for(:conditions=>"kpath LIKE 'NPD%'")).sort {|a,b| a.name <=> b.name}
  end
end