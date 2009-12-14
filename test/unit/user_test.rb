require 'test_helper'

class UserTest < Zena::Unit::TestCase

  def test_find_allowed_user_by_login
    assert_equal 'su', User.find_allowed_user_by_login('su').login
  end

  def test_deleted_user_should_not_be_allowed
    User.connection.execute "UPDATE users SET status = #{User::Status[:deleted]} WHERE id = #{users_id(:tiger)} AND site_id = #{sites_id(:zena)}"
    assert_nil User.find_allowed_user_by_login('tiger')
  end

  def test_user_from_other_site_should_not_be_allowed
    # default login zena site
    # whale is user form ocean site
    assert_nil User.find_allowed_user_by_login('whale')
  end

  def test_visited_node_ids
    login(:tiger)
    secure!(Node) { nodes(:status) }
    secure!(Node) { nodes(:bird_jpg) }
    assert_equal [nodes_id(:status), nodes_id(:bird_jpg)], visitor.visited_node_ids
    login(:anon)
    secure!(Node) { nodes(:status) }
    secure!(Node) { nodes(:bird_jpg) }
    assert_equal [nodes_id(:status), nodes_id(:bird_jpg)], visitor.visited_node_ids
    with_caching do
      login(:tiger)
      secure!(Node) { nodes(:status) }
      secure!(Node) { nodes(:bird_jpg) }
      assert_equal [nodes_id(:status), nodes_id(:bird_jpg)], visitor.visited_node_ids
      login(:anon)
      secure!(Node) { nodes(:status) }
      secure!(Node) { nodes(:bird_jpg) }
      assert_equal [nodes_id(:status), nodes_id(:bird_jpg)], visitor.visited_node_ids
    end
  end

  def test_cannot_destroy_su
    login(:su)
    su = users(:su)
    assert_raise(Zena::AccessViolation){ su.destroy }
  end

  def test_cannot_destroy_anon
    login(:su)
    anon = users(:anon)
    assert_raise(Zena::AccessViolation){ anon.destroy }
  end

  def test_can_destroy_ant
    login(:lion)
    ant = users(:ant)
    assert_nothing_raised( Zena::AccessViolation ) { ant.destroy }
  end

  def test_create
    User.connection.execute "UPDATE users SET lang='ru' WHERE id IN (#{users_id(:incognito)},#{users_id(:whale)})"
    User.connection.execute "UPDATE sites SET languages='fr,ru' WHERE id=#{sites_id(:ocean)}"
    User.connection.execute "UPDATE users SET time_zone='US/Hawaii' WHERE id=#{users_id(:incognito)}"
    login(:whale)

    user = secure!(User) { User.create("login"=>"john", "password"=>"isjjna78a9h") }

    assert !user.new_record?, "Not a new record"
    assert !user.contact.new_record?, "Users's contact node is not a new record"

    user = secure!(User) { User.find(user[:id]) } # reload
    assert_equal sites_id(:ocean), user.site_id
    assert_equal 2, user.groups.size
    assert user.groups.map{|g| g.name}.include?('public'), "Is in the public group"
    assert user.groups.map{|g| g.name}.include?('aqua'), "Is in the 'site' group"
    assert_equal User::Status[:moderated], user.status
    assert_equal 'ru', user.lang
    assert_equal 'US/Hawaii', user[:time_zone]
    assert !user.user?, "Not a real user yet"
    assert visitor.user?, "Whale is a user"

    contact = user.contact
    assert_equal "john", contact.version.title
  end

  def test_only_admin_can_create
    login(:tiger)
    user = secure!(User) { User.create("name"=>"Shakespeare", "status"=>"50", "group_ids"=>[""], "lang"=>"fr", "time_zone"=>"Bern", "first_name"=>"William", "login"=>"bob", "password"=>"jsahjks894", "email"=>"") }
    assert user.new_record?, "Not saved"
    assert_equal 'Not found', user.errors[:site]
    assert user.errors[:base] #.any?
    login(:lion)
    user = secure!(User) { User.create("name"=>"Shakespeare", "status"=>"50", "group_ids"=>[""], "lang"=>"fr", "time_zone"=>"Bern", "first_name"=>"William", "login"=>"bob", "password"=>"jsahjks894", "email"=>"") }
    assert !user.new_record?, "Saved"
    assert !user.contact.new_record?, "Contact saved"
    assert_equal sites_id(:zena), user.contact.site_id
  end

  def test_create_with_auto_publish
    Site.connection.execute "UPDATE sites SET auto_publish = 1 WHERE id = #{sites_id(:zena)}"
    login(:lion)
    user = secure!(User) { User.create("name"=>"Shakespeare", "status"=>"50", "group_ids"=>[""], "lang"=>"fr", "time_zone"=>"Europe/Zurich", "first_name"=>"William", "login"=>"bob", "password"=>"jsahjks894", "email"=>"") }
    assert !user.new_record?, "Saved"
    assert !user.contact.new_record?, "Contact saved"
    assert_equal sites_id(:zena), user.contact.site_id
  end

  def test_create_admin_with_groups
    login(:lion)
    user = secure!(User) { User.new("login"=>"john", "password"=>"isjjna78a9h", "group_ids"=>[1329663069]) }
    assert user.save
    user = secure!(User) { User.find(user[:id])}
    assert_equal 3, user.groups.size
  end

  def test_update_keep_password
    login(:tiger)
    user = secure!(User) { users(:tiger) }
    pass = user[:password]
    assert pass != "", "Password not empty"
    assert user.update_attributes(:login=>'bigme', :password=>'')
    assert_equal 'bigme', user.login
    assert_equal pass, user[:password]
  end

  def test_only_self_or_admin_can_update
    login(:tiger)
    user = secure!(User) { users(:ant) }
    user.email = "eat@spam.com"
    assert !user.save
    assert user.errors[:base] #.any?
    user = secure!(User) { users(:tiger) }
    user.email = "socr@isa.man"
    assert user.save
    assert_equal "socr@isa.man", user.email
  end

  def test_only_admin_can_create
    login(:tiger)
    user = secure!(User) { User.create(:login=>'joe', :password=>'whatever') }
    assert user.new_record?
    assert user.errors[:base] #.any?
    login(:lion)
    user = secure!(User) { User.create(:login=>'joe', :password=>'whatever') }
    assert !user.new_record?
  end

  def test_cannot_remove_self_from_admin_status
    login(:lion)
    user = secure!(User) { users(:lion) }
    assert !user.update_attributes(:status => User::Status[:user])
    assert_equal 'You do not have the rights to do this.', user.errors[:status]
    user = secure!(User) { users(:lion) }
    assert user.update_attributes('status' => User::Status[:admin].to_s, 'time_zone' => 'Europe/Berlin')
  end

  def test_can_update_pass_admin_status
    login(:lion)
    user = users(:ant)
    assert user.update_attributes(:status => User::Status[:admin])
    user.reload
    assert_equal User::Status[:admin], user.status
    assert user.is_admin?
    login(:ant) # admin
    assert visitor.is_admin?
    user = users(:lion)
    assert user.update_attributes(:status => User::Status[:user])
    user.reload
    assert_equal User::Status[:user], user.status
    assert !user.is_admin?
  end

  def test_empty_password
    login(:lion)
    bob = secure!(User) { User.new }
    bob.login = 'bob'
    bob.save
    assert ! bob.save
    assert bob.errors[:password] #.any?
  end

  def test_update_public
    login(:lion)
    pub = secure!(User) { users(:anon) }
    assert_equal 'en', pub.lang
    assert_nil pub.login
    assert_nil pub[:password]

    pub.login = "hello"
    pub.password = 'heyjoe'
    pub.lang = 'es'
    assert pub.save
    assert_equal 'es', pub.lang
    assert_equal nil, pub.login
    assert_equal nil, pub[:password]
  end

  def test_comments_to_publish
    login(:tiger)
    # status dgroup = managers
    node = nodes(:status)
    assert_equal groups_id(:managers), node.dgroup_id
    # tiger in managers
    to_publish = visitor.comments_to_publish
    assert_equal 1, to_publish.size
    assert_equal 'Nice site', to_publish[0][:title]

    # ant not in managers
    login(:ant)
    to_publish = visitor.comments_to_publish
    assert_nil to_publish
  end

  def test_is_admin
    login(:ant)
    user = secure!(User) { users(:lion) }
    assert user.is_admin?
  end

  def test_group_ids
    login(:ant)
    user = secure!(User) { users(:tiger) }
    assert_equal [groups_id(:managers), groups_id(:public), groups_id(:workers)], user.group_ids
    user = secure!(User) { users(:lion) }
    assert_equal [groups_id(:admin), groups_id(:managers), groups_id(:public), groups_id(:workers)], user.group_ids
  end

  def test_status_name
    login(:lion)
    user = secure!(User) { users(:lion) }
    assert_equal "admin", user.status_name
    user = secure!(User) { users(:ant) }
    assert_equal "user", user.status_name
    user = secure!(User) { users(:anon) }
    assert_equal "moderated", user.status_name
  end

  def test_invalid_time_zone
    login(:lion)
    user = secure!(User) { User.create("login"=>"john", "password"=>"isjjna78a9h", 'time_zone' => 'Zurich') }
    assert user.new_record?
    assert_not_nil user.errors['time_zone']

    user = secure!(User) { User.create("login"=>"john", "password"=>"isjjna78a9h", 'time_zone' => 'Mexico/General') }
    assert !user.new_record?

    user = secure!(User) { User.create("login"=>"jim", "password"=>"isjjna78a9h", 'time_zone' => '') }
    assert !user.new_record?
    assert_nil user[:time_zone]
  end

  def test_new_defaults
    login(:lion)
    User.connection.execute "UPDATE users SET lang='fr' WHERE id = #{users_id(:anon)}"
    User.connection.execute "UPDATE users SET time_zone = 'Europe/Berlin' WHERE id = #{users_id(:anon)}"

    user = secure!(User) { User.create("login"=>"john", "password"=>"isjjna78a9h") }
    assert !user.new_record?
    assert_equal 'fr', user.lang
    assert_equal 'Europe/Berlin', user[:time_zone]
    assert_equal User::Status[:moderated], user.status
  end

  def test_tz
    login(:ant)
    assert_equal TZInfo::Timezone.get('Europe/Zurich'), visitor.tz
    login(:lion)
    assert_equal TZInfo::Timezone.get('UTC'), visitor.tz
  end

  def test_redactions
    login(:tiger)
    assert_equal ['opening'], visitor.redactions.map {|r| r.node.name}
    node = secure(Page) { Page.create(:v_title => 'hello', :parent_id => nodes_id(:projects)) }
    node.propose
    assert_equal ['hello'], visitor.to_publish.map {|r| r.node.name}
    assert_equal ['hello'], visitor.proposed.map {|r| r.node.name}

    login(:lion)
    assert_equal ['hello'], visitor.to_publish.map {|r| r.node.name}
  end
end
