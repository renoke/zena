require 'test_helper'



class ZenaTagsTest < Zena::Controller::TestCase


  yamltest :directories => [:default, "#{Zena::ROOT}/bricks/**/test/zafu"]
  Section # make sure we load Section links before trying relations

  class ZafuDummy
    include RubyLess::SafeClass
    safe_method [:hello, {:lang => String}] => String

    def hello(opts)
      case opts[:lang]
      when 'en'
        'Hi there!'
      when 'fr'
        'Salut poilu!'
      when 'de'
        'Grützi!'
      else
        "Sorry, I don't speak #{opts[:lang]}..."
      end
    end
  end

  class ::Node
    def dummy
      ZafuDummy.new
    end
  end

  RubyLess::SafeClass.safe_method_for Node, [:dummy] => ZafuDummy

  def setup
    @controller = Zena::TestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    super
  end

  def yt_do_test(file, test)
    src = yt_get('src', file, test) if @@test_strings[file][test].keys.include?('src') # we do not want src built from title
    tem = yt_get('tem', file, test)
    res = yt_get('res', file, test)
    compiled_files = {}
    @@test_strings[file][test].each do |k,v|
      next if ['src','tem','res','context'].include?(k)
      compiled_files[k] = v
    end
    context = yt_get('context', file, test)
    site = sites(context.delete('site') || 'zena')
    $_test_site = site.name
    @request.host = site.host
    # set context
    params = {}
    #params[:user_id] = users_id(context.delete('visitor').to_sym)
    params[:user] = context.delete 'visitor'
    params[:node_id] = nodes_id(context.delete('node').to_sym)
    params[:prefix]  = context.delete('lang')
    params[:date]    = context['ref_date'] ? context.delete('ref_date').to_s : nil
    params[:url] = "/#{test.to_s.gsub('_', '/')}"
    params.merge!(context) # merge the rest of the context as query parameters
    Zena::TestController.templates = @@test_strings[file]
    if src
      post 'test_compile', params
      template = @response.body
      if tem
        yt_assert tem, template
      end
    else
      template = tem
    end

    compiled_files.each do |path,value|
      fullpath = File.join(SITES_ROOT,'test.host','zafu',path)
      assert File.exist?(fullpath), "Saved template #{path} should exist."
      yt_assert value, File.read(fullpath)
    end

    if res
      params[:text] = template
      post 'test_render', params
      result = @response.body
      yt_assert res, result
    end
  end

  alias o_yt_assert yt_assert

  def yt_assert(test_val, result)
    test_val.gsub!(/_ID\(([^\)]+)\)/) do
      Zena::FoxyParser::id($_test_site, $1)
    end
    o_yt_assert test_val, result
  end

  def test_basic_cache_part
    with_caching do
      Node.connection.execute "UPDATE nodes SET name = 'first' WHERE id = #{nodes_id(:status)}"
      caches = Cache.find(:all)
      assert_equal [], caches
      yt_do_test('basic', 'cache_part')

      cont = {
        :user_id => users_id(:anon),
        :user => 'anon',
        :node_id => nodes_id(:status),
        :prefix  => 'en',
        :url  => '/cache/part',
        :text => @response.body
      }.freeze

      post 'test_render', cont
      assert_equal 'first', @response.body

      cache  = Cache.find(:first)
      assert_kind_of Cache, cache
      assert_equal "first", cache.content
      Node.connection.execute "UPDATE nodes SET name = 'second' WHERE id = #{nodes_id(:status)}"

      post 'test_render', cont
      assert_equal 'first', @response.body

      Node.connection.execute "DELETE FROM #{Cache.table_name};"

      post 'test_render', cont
      assert_equal 'second', @response.body
    end
  end

  def test_relations_updated_today
    Node.connection.execute "UPDATE nodes SET updated_at = #{Zena::Db::NOW} WHERE id IN (#{nodes_id(:status)}, #{nodes_id(:art)});"
    yt_do_test('relations', 'updated_today')
  end

  def test_relations_upcoming_events
    set_date(:people, :days => 7)
    yt_do_test('relations', 'upcoming_events')
  end

  def test_relations_in_7_days
    set_date(:art)
    set_date([:projects, :cleanWater], :days => 6)
    set_date([:people],                :days => 10)
    yt_do_test('relations', 'in_7_days')
  end

  def test_relations_logged_7_days_ago
    set_date([:art, :status], :minutes => 2)
    set_date([:projects, :cleanWater], :days => -6)
    set_date([:people],                :days => -10)
    yt_do_test('relations', 'logged_7_days_ago')
  end

  def test_relations_around_7_days
    set_date(:status)
    set_date(:art,                     :days => 5)
    set_date([:projects, :cleanWater], :days => -6)
    set_date([:people],                :days => -10)
    yt_do_test('relations', 'around_7_days')
  end

  def test_relations_in_37_hours
    set_date(:art, :minutes => 2)
    set_date(:cleanWater,          :hours => 36)
    set_date([:projects, :people], :hours => 38)
    yt_do_test('relations', 'in_37_hours')
  end

  def test_relations_this_week
    if Time.now.strftime('%u').to_i < 3
      # not in this week
      set_date(:people,   :days => -5, :fld => 'event_at')
      # in this week
      set_date(:art,      :days =>  2, :fld => 'event_at')
      set_date(:projects, :days =>  1, :fld => 'event_at')
    else
      # not in this week
      set_date(:people,   :days =>  5, :fld => 'event_at')
      # in this week
      set_date(:art,      :days => -2, :fld => 'event_at')
      set_date(:projects, :days => -1, :fld => 'event_at')
    end
    yt_do_test('relations', 'this_week')
  end

  def test_relations_this_month
    if Time.now.strftime('%d').to_i < 15
      # not in this month
      set_date(:people,   :days => -20, :fld => 'event_at')
      # in this month
      set_date(:art,      :days =>  12, :fld => 'event_at')
      set_date(:projects, :days =>   5, :fld => 'event_at')
    else
      # not in this month
      set_date(:people,   :days =>  20, :fld => 'event_at')
      # in this month
      set_date(:art,      :days => -12, :fld => 'event_at')
      set_date(:projects, :days =>  -5, :fld => 'event_at')
    end
    yt_do_test('relations', 'this_month')
  end

  def test_relations_this_year
    if Time.now.strftime('%m').to_i < 6
      # not in this year
      set_date(:people,   :months => -8, :fld => 'event_at')
      # in this year
      set_date(:art,      :months =>  2, :fld => 'event_at')
      set_date(:projects, :months =>  1, :fld => 'event_at')
    else
      # not in this year
      set_date(:people,   :months =>  8, :fld => 'event_at')
      # in this year
      set_date(:art,      :months => -2, :fld => 'event_at')
      set_date(:projects, :months => -1, :fld => 'event_at')
    end
    yt_do_test('relations', 'this_year')
  end

  def test_relations_direction_both
    art, projects, status = nodes_id(:art), nodes_id(:projects), nodes_id(:status)
    values = [
      [art,    status,   relations_id(:node_has_references)],
      [status, projects, relations_id(:node_has_references)]
      ]
    Zena::Db.insert_many('links', %W{source_id target_id relation_id}, values)
    yt_do_test('relations', 'direction_both')
  end

  def test_relations_direction_both_self_auto_ref
    art, projects, status = nodes_id(:art), nodes_id(:projects), nodes_id(:status)
    values = [
      [art,    status,   relations_id(:node_has_references)],
      [status, status,   relations_id(:node_has_references)],
      [status, projects, relations_id(:node_has_references)]
      ]
    Zena::Db.insert_many('links', %W{source_id target_id relation_id}, values)
    yt_do_test('relations', 'direction_both_self_auto_ref')
  end

  def test_basic_recursion_in_each
    login(:tiger)
    node = secure!(Node) { nodes(:status) }
    node.unpublish
    yt_do_test('basic', 'recursion_in_each')
  end

  def test_zazen_swf_button_player
    DocumentContent.connection.execute "UPDATE document_contents SET ext = 'mp3' WHERE id = #{document_contents_id(:water_pdf)}"
    yt_do_test('zazen', 'swf_button_player')
  end

  def test_basic_captcha
    values = [
      ["'recaptcha_pub'", "'pubkey'", sites_id(:zena)],
      ["'recaptcha_priv'", "'privkey'", sites_id(:zena)]
    ]
    Zena::Db.insert_many('site_attributes', %W{key value owner_id}, values)
    yt_do_test('basic', 'captcha')
  end

  yt_make
end