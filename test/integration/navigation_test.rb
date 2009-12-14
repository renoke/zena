require "#{File.dirname(__FILE__)}/../test_helper"

class NavigationTest < ActionController::IntegrationTest
  #include Zena::Test::Base

  def test_authorize
    get 'http://test.host/'
    assert_redirected_to 'http://test.host/en'
    follow_redirect!
    assert_response :success

    # 1. site forces authentication
    Site.connection.execute "UPDATE sites SET authentication = 1 WHERE id = #{sites_id(:zena)}"
    get 'http://test.host/'
    assert_redirected_to 'http://test.host/login'

    reset!
    post 'http://test.host/session', :login=>'tiger', :password=>'tiger'
    assert_redirected_to "http://test.host/users/#{users_id(:tiger)}"

    # 2. navigating out of '/oo' but logged in and format is not data
    get 'http://test.host/fr'
    assert_redirected_to 'http://test.host/oo'
    follow_redirect!
    assert_response :success
    get 'http://test.host/fr/textdocument53.css' # data
    assert_response :success
  end

  def test_authorize_http_auth
    Site.connection.execute "UPDATE sites SET http_auth = 1 WHERE id = #{sites_id(:zena)}"
    get 'http://test.host/'
    assert_redirected_to 'http://test.host/en'
    follow_redirect!
    assert_response :success

    # 1. site forces authentication
    Site.connection.execute "UPDATE sites SET authentication = 1 WHERE id = #{sites_id(:zena)}"
    get 'http://test.host/'
    assert_response 401 # http_auth

    reset!
    post 'http://test.host/session', :login=>'tiger', :password=>'tiger'
    assert_redirected_to "http://test.host/users/#{users_id(:tiger)}"

    # 2. navigating out of '/oo' but logged in and format is not data
    get 'http://test.host/fr'
    assert_redirected_to 'http://test.host/oo'
    follow_redirect!
    assert_response :success
    assert_equal 'fr', session[:lang]
    get 'http://test.host/en/textdocument53.css' # data
    assert_response :success
    assert_equal 'fr', session[:lang]
  end

  def test_out_of_oo_custom_base_set_lang
    post 'http://test.host/session', :login=>'tiger', :password=>'tiger'
    assert_redirected_to "http://test.host/users/#{users_id(:tiger)}"
    # 2. navigating out of '/oo' but logged in and format is not data, custom_base url (format not in path)
    assert_equal 'en', session[:lang]
    get 'http://test.host/fr/projects/cleanWater'
    assert_redirected_to 'http://test.host/oo/projects/cleanWater'
    assert_equal 'fr', session[:lang]
    follow_redirect!
    assert_response :success
  end

  def test_set_lang
    Site.connection.execute "UPDATE sites SET languages = 'fr,en,es' WHERE id = #{sites_id(:zena)}"
    get 'http://test.host/', {}, {'HTTP_ACCEPT_LANGUAGE' => 'de-DE,fr-FR;q=0.8,es;q=0.9'}
    assert_redirected_to 'http://test.host/es'
    follow_redirect!
    assert_response :success
    get 'http://test.host/', {}, {'HTTP_ACCEPT_LANGUAGE' => 'de-DE,fr-FR;q=0.8,es;q=0.9'}
    assert_redirected_to 'http://test.host/es'
    reset!
    get 'http://test.host/', {}, {'HTTP_ACCEPT_LANGUAGE' => 'de-DE,fr-FR;q=0.8,es;q=0.3'}
    assert_redirected_to 'http://test.host/fr'

    Site.connection.execute "UPDATE sites SET languages = 'fr,de,en,es' WHERE id = #{sites_id(:zena)}"
    reset!
    get 'http://test.host/', {}, {'HTTP_ACCEPT_LANGUAGE' => 'de-DE,fr-FR;q=0.8,es;q=0.3'}
    assert_redirected_to 'http://test.host/de'
    follow_redirect!
    assert_response :success
    get 'http://test.host/es'
    assert_response :success
    assert_equal 'es', session[:lang]
    get 'http://test.host/en'
    assert_response :success
    assert_equal 'en', session[:lang]
    get 'http://test.host/en?lang=es'
    assert_redirected_to 'http://test.host/es'
    follow_redirect!
    assert_response :success
    assert_equal 'es', session[:lang]
    get 'http://test.host/nodes/29/edit'
    assert_response :success
    get 'http://test.host/oo'
    assert_redirected_to 'http://test.host/login'
    get 'http://test.host/oo/nodes/13' # private entry 'ant' in bad url format
    assert_redirected_to 'http://test.host/login'
    get 'http://test.host/nodes/13' # private entry 'ant'
    assert_response :missing
  end

  def test_set_lang_authenticated
    post 'http://test.host/session', :login=>'lion', :password=>'lion'
    get 'http://test.host/oo/page32.html?lang=fr'
    assert_redirected_to 'http://test.host/oo/page32.html'
    assert_equal 'fr', visitor.lang
  end

  def test_set_lang_out_of_nodes
    post 'http://test.host/session', :login=>'lion', :password=>'lion'
    get 'http://test.host/users?lang=fr'
    assert_redirected_to 'http://test.host/users'
    assert_equal 'fr', visitor.lang
  end


  def test_set_lang_with_login
    post 'http://test.host/session', :login=>'tiger', :password=>'tiger'
    assert_redirected_to "http://test.host/users/#{users_id(:tiger)}"
    follow_redirect!
    assert_response :success
    assert_equal 'en', session[:lang]
    get 'http://test.host/oo?lang=fr'
    assert_redirected_to 'http://test.host/oo'
    follow_redirect!
    assert_response :success
    assert_equal 'fr', session[:lang]
  end

  def test_nodes_redirect
    get 'http://test.host/nodes/30'
    assert_redirected_to 'http://test.host/en/image30.html'
    follow_redirect!
    assert_response :success
  end

  def test_url_without_lang_redirect
    get 'http://test.host/project29.html'
    assert_redirected_to 'http://test.host/en/project29.html'
    follow_redirect!
    assert_response :success
  end

  def test_url_without_lang_redirect_keeps_url_params
    get 'http://test.host/project29.html?page=2'
    assert_redirected_to 'http://test.host/en/project29.html?page=2'
    follow_redirect!
    assert_response :success
  end

  def test_url_bad_class_redirect_keeps_url_params
    get 'http://test.host/en/page29.html?page=2'
    assert_redirected_to 'http://test.host/en/project29.html?page=2'
    follow_redirect!
    assert_response :success
  end

  def test_url_by_zip_without_lang_redirect
    get 'http://test.host/29'
    assert_redirected_to 'http://test.host/en/29'
    follow_redirect!
    assert_redirected_to 'http://test.host/en/project29.html'
    follow_redirect!
    assert_response :success
  end

  def test_url_by_path_without_lang_redirect
    get 'http://test.host/projects/wiki'
    assert_redirected_to 'http://test.host/en/projects/wiki'
    follow_redirect!
    assert_redirected_to 'http://test.host/en/project29.html'
    follow_redirect!
    assert_response :success
  end

  def test_bad_url
    get 'http://test.host/en/node1.html'
    assert_response :missing
  end

  def test_bad_zip
    get 'http://test.host/1'
    assert_redirected_to 'http://test.host/en/1'
    follow_redirect!
    assert_response :missing
  end

  def test_change_session_lang_on_login
    get 'http://test.host/'
    assert_redirected_to 'http://test.host/en'
    assert_equal 'en', session[:lang]
    get 'http://test.host/oo'
    assert_redirected_to 'http://test.host/login'
    post 'http://test.host/session', :login=>'ant', :password=>'ant'
    assert_redirected_to 'http://test.host/oo'
    assert_equal 'fr', session[:lang]

    # update visitor lang (as if changed through preferences)
    User.connection.execute "UPDATE users SET lang = 'en' WHERE id = #{users_id(:ant)} and site_id = #{sites_id(:zena)}"
    get 'http://test.host/oo'
    assert_equal 'en', session[:lang]

    get 'http://test.host/fr'
    assert_redirected_to 'http://test.host/oo'
    assert_equal 'fr', session[:lang]
    assert_equal 'fr', User.find(users_id(:ant)).lang
  end

  def test_show_with_mode
    get "http://test.host/en/section12_changes.html"
    assert_response :missing # people is not rendered with 'wiki' mode where 'changes' is defined.
    get "http://test.host/en/project29_changes.html"
    assert_response :success
    get 'http://test.host/en/section12_index.html'
    assert_response :missing
    get 'http://test.host/en/section12_+index.html'
    assert_response :missing
  end

  def test_show_bad_mode
    get 'http://test.host/en/section12_std.html'
    assert_response :missing
  end

  def test_show_with_internal_mode
    get 'http://test.host/en/section12_+index.html'
    assert_response :missing
  end

  private

    module CustomAssertions
      include Zena::Test::Integration

      def get_node(node_sym=:status, opts={})
        @node = nodes(node_sym)
        host = opts[:host] || 'test.host'
        opts.delete(:host)

        @site = Site.find_by_host(host)
        if @node[:id] == @site.root_id
          path = []
        else
          path = @node.basepath.split('/')
          unless @node[:custom_base]
            path += ["#{@node.class.to_s.downcase}#{@node[:id]}.html"]
          end
        end
        prefix = (!request || session[:user] == @site.anon_id) ? 'en' : AUTHENTICATED_PREFIX
        url = "http://#{host}/#{prefix}/#{path.join('/')}"
        puts "get #{url}"
        get url
      end
    end

    def login(user = nil)
      open_session do |sess|
        sess.extend(CustomAssertions)
        if user
          sess.post 'http://test.host/session', :login=>user.to_s, :password=>user.to_s
          sess.follow_redirect!
        end
      end
    end

    def anon
      @anon ||= open_session do |sess|
        sess.extend(CustomAssertions)
      end
    end

    def sites_id(key)
      ZenaTest::multi_site_id(key)
    end

    alias users_id sites_id
end