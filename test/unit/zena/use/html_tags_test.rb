require 'test_helper'

class HtmlTagsTest < Zena::View::TestCase
  include Zena::Use::HtmlTags::ViewMethods
  include Zena::Use::Refactor::ViewMethods # fquote
  include Zena::Use::I18n::ViewMethods # _
  include Zena::Use::Urls::ViewMethods # data_path
  
  def test_img_tag
    login(:ant)
    img = secure!(Node) { nodes(:bird_jpg) }
    assert_equal "<img src='/en/image30.jpg' width='660' height='600' alt='bird' class='full'/>", img_tag(img)
    assert_equal "<img src='/en/image30_pv.jpg' width='70' height='70' alt='bird' class='pv'/>", img_tag(img, :mode=>'pv')
  end
  
  def test_img_tag_document
    login(:ant)
    doc = secure!(Node) { nodes(:water_pdf) }
    assert_equal "<img src='/images/ext/pdf.png' width='32' height='32' alt='pdf document' class='doc'/>", img_tag(doc)
    assert_equal "<img src='/images/ext/pdf_pv.png' width='70' height='70' alt='pdf document' class='doc'/>",  img_tag(doc, :mode=>'pv')
  end
  
  def test_img_tag_other_classes
    login(:ant)
    # contact  project       post     tag
    [:lake, :cleanWater, :opening, :art].each do |sym|
      obj   = secure!(Node) { nodes(sym) }
      klass = obj.klass
      assert_equal "<img src='/images/ext/#{klass.underscore}.png' width='32' height='32' alt='#{klass} node' class='node'/>", img_tag(obj)
      assert_equal "<img src='/images/ext/#{klass.underscore}_pv.png' width='70' height='70' alt='#{klass} node' class='node'/>",  img_tag(obj, :mode=>'pv')
    end
    
    obj   = Node.new
    assert_equal "<img src='/images/ext/other.png' width='32' height='32' alt='Node node' class='node'/>", img_tag(obj)
  end
  
  def test_img_tag_opts
    login(:anon)
    img = secure!(Node) { nodes(:bird_jpg) }
    assert_equal "<img src='/en/image30.jpg' width='660' height='600' alt='bird' id='yo' class='full'/>",
                  img_tag(img, :mode=>nil, :id=>'yo')
    assert_equal "<img src='/en/image30_pv.jpg' width='70' height='70' alt='bird' id='yo' class='super'/>",
                  img_tag(img, :mode=>'pv', :id=>'yo', :class=>'super')
    assert_equal "<img src='/en/image30_med.jpg' width='220' height='200' alt='super man' class='med'/>",
                  img_tag(img, :mode=>'med', :alt=>'super man')
  end
  
  def test_img_tag_other
    login(:tiger)
    doc = secure!(Node) { nodes(:water_pdf) }
    doc.c_ext = 'bin'
    assert_equal 'bin', doc.c_ext
    assert_equal "<img src='/images/ext/other.png' width='32' height='32' alt='bin document' class='doc'/>", img_tag(doc)
    assert_equal "<img src='/images/ext/other_pv.png' width='70' height='70' alt='bin document' class='doc'/>", img_tag(doc, :mode=>'pv')
    assert_equal "<img src='/images/ext/other.png' width='32' height='32' alt='bin document' class='doc'/>", img_tag(doc, :mode=>'std')
  end
  
  def test_alt_with_apos
    doc = secure!(Node) { nodes(:lake_jpg) }
    assert_equal "<img src='/en/projects/cleanWater/image24.jpg' width='600' height='440' alt='it&apos;s a lake' class='full'/>", img_tag(doc)
  end
  
  def test_select_id
    @node = secure!(Node) { nodes(:status) }
    select = select_id('node', :parent_id, :class=>'Project')
    assert_no_match %r{select.*node\[parent_id\].*21.*19.*29.*11}m, select
    assert_match %r{select.*node\[parent_id\].*29}, select
    login(:tiger)
    @node = secure!(Node) { nodes(:status) }
    assert_match %r{select.*node\[parent_id\].*21.*19.*29.*11}m, select_id('node', :parent_id, :class=>'Project')
    assert_match %r{input type='text'.*name.*node\[icon_id\]}m, select_id('node', :icon_id)
  end
  
  def test_uses_datebox_with_lang
    res = uses_datebox
    assert_match %r{/calendar/lang/calendar-en-utf8.js}, res
  end
  
  def test_uses_datebox_without_lang
    visitor.lang = 'io'
    res = uses_datebox
    assert_no_match %r{/calendar/lang/calendar-io-utf8.js}, res
    assert_match %r{/calendar/lang/calendar-en-utf8.js}, res
  end
  
  def test_date_box
    @node = secure!(Node) { nodes(:status) }
    assert_match %r{span class="date_box".*img src="\/calendar\/iconCalendar.gif".*input id='datef.*' name='node\[updated_at\]' type='text' value='2006-04-11 00:00'}m, date_box('node', 'updated_at')
  end
  
  def test_visitor_link
    assert_equal '', visitor_link
    login(:ant)
    assert_match %r{users/#{users_id(:ant)}.*Solenopsis Invicta}, visitor_link
  end
  
  def test_flash_messages
    login(:ant)
    assert_equal "<div id='messages'></div>", flash_messages(:show=>'both')
    flash[:notice] = 'yoba'
    assert_match /notice.*yoba/, flash_messages(:show=>'both')
    assert_no_match /error/, flash_messages(:show=>'both')
    flash[:error] = 'taio'
    assert_match /notice.*yoba/, flash_messages(:show=>'both')
    assert_match /error.*taio/, flash_messages(:show=>'both')
    flash[:notice] = nil
    assert_no_match /notice/, flash_messages(:show=>'both')
    assert_match /error/, flash_messages(:show=>'both')
  end
  
  def test_node_actions_for_public
    @node = secure!(Node) { nodes(:cleanWater) }
    assert !@node.can_edit?, "Node cannot be edited by the public"
    res = node_actions(:actions=>:all)
    assert_equal '', res
  end
  
  def test_node_actions_wiki_public
    Participation.connection.execute "UPDATE participations SET status = #{User::Status[:user]} WHERE site_id = #{sites_id(:zena)} AND user_id=#{users_id(:anon)}"
    @node = secure!(Node) { nodes(:wiki) }
    assert @node.can_edit?, "Node can be edited by the public"
    res = node_actions(:actions=>:all)
    assert_match %r{/nodes/29/versions/0/edit}, res
    assert_match %r{/nodes/29/edit}, res
  end
  
  def test_node_actions_for_ant
    login(:ant)
    @node = secure!(Node) { Node.find(nodes_id(:cleanWater)) }
    res = node_actions(:actions=>:all)
    assert_match    %r{/nodes/21/versions/0/edit}, res
    assert_no_match %r{/nodes/21/edit}, res
  end
  
  def test_node_actions_for_tiger
    login(:tiger)
    @node = secure!(Node) { Node.find(nodes_id(:cleanWater)) }
    res = node_actions(:actions=>:all)
    assert_match %r{/nodes/21/versions/0/edit}, res
    assert_match %r{/nodes/21/edit}, res
    @node.edit!
    assert @node.save
    res = node_actions(:actions=>:all)
    assert_match %r{/nodes/21/versions/0/edit}, res
    assert_match %r{/nodes/21/versions/0/propose}, res
    assert_match %r{/nodes/21/versions/0/publish}, res
    assert_match %r{/nodes/21/edit}, res
  end
  
  def test_node_actions_on_new_node
    login(:ant)
    @node = secure!(Page) { Page.new(:name => 'hello', :parent_id => nodes_id(:zena)) }
    assert @node.new_record?
    assert_equal '', node_actions(:actions=>:all)
  end
  
  def test_login_link
    assert_equal "<a href='/login'>login</a>", login_link
    login(:ant)
    assert_equal "<a href='/logout'>logout</a>", login_link
  end
  
  def test_show_path_root
    @node = secure!(Node) { Node.find(nodes_id(:zena))}
    assert_equal "<li><a href='/en' class='current'>zena</a></li>", show_path
    @node = secure!(Node) { Node.find(nodes_id(:status))}
    assert_match %r{.*zena.*projects.*cleanWater.*li.*page22\.html' class='current'>status}m, show_path
  end
  
  def test_show_path_root_with_login
    login(:ant)
    @node = secure!(Node) { Node.find(nodes_id(:zena))}
    assert_equal "<li><a href='/#{AUTHENTICATED_PREFIX}' class='current'>zena</a></li>", show_path
  end
  
  def test_lang_links
    login(:lion)
    @controller.set_params(:controller=>'nodes', :action=>'show', :path=>'projects/cleanWater', :prefix=>AUTHENTICATED_PREFIX)
    assert_match %r{<em>en</em>.*href=.*/oo/projects/cleanWater\?lang=.*fr.*}, lang_links
  end
  
  def test_lang_links_no_login
    login(:anon)
    @controller.set_params(:controller=>'nodes', :action=>'show', :path=>'projects/cleanWater', :prefix=>'en')
    assert_match %r{<em>en</em>.*href=.*/fr/projects/cleanWater.*fr.*}, lang_links
  end
end