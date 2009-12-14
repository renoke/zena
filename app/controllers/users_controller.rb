class UsersController < ApplicationController
  before_filter :find_user
  before_filter :check_is_admin,  :only => [:index, :create, :swap_dev]
  before_filter :restrict_access
  layout :admin_layout

  def show
    respond_to do |format|
      format.html { render :file => admin_layout, :layout => false } # render, content_for_layout = nil
      format.js
    end
  end

  # Show the list of users. Rendered in the admin layout.
  def index
    secure!(User) do
      @users = User.paginate(:all, :order => 'status DESC, login ASC', :page => params[:page], :per_page => 20)
    end

    get_groups_list
    @user   = User.new
    respond_to do |format|
      format.html
    end
  end

  def preferences
    respond_to do |format|
      format.html # preferences.html.erb
    end
  end

  def swap_dev
    if session[:dev]
      session[:dev] = nil
    else
      session[:dev] = true
    end
    if request.referer
      redirect_to request.referer
    else
      redirect_to :action => 'show'
    end
  end


  # TODO: test
  def create
    if params[:groups]
      params[:user][:group_ids] = params[:groups].values
    end
    get_groups_list
    @user = User.create(params[:user])
  end

  # TODO: test
  def edit
    @user.password = nil
    get_groups_list
    respond_to do |format|
      format.html { render :partial => 'users/form' }
      format.js   { render :partial => 'users/form', :layout => false }
    end
  end

  # TODO: test
  def update

    @update = params.delete(:update)

    # TODO: test
    unless params[:user][:password].blank?
      if params[:user][:password].strip.size < 6
        @user.errors.add('password', 'too short')
      end
      if !visitor.is_admin? || params[:user][:retype_password]
        if params[:user][:password] != params[:user][:retype_password]
          @user.errors.add('retype_password', 'does not match new password')
        end
      end
      unless visitor.is_admin?
        if !@user.password_is?(params[:user][:old_password])
          @user.errors.add('old_password', "not correct")
        end
      end
      if @user.errors.empty?
        @user.password = params[:user][:password]
        params[:user].delete(:password)
        params[:user].delete(:retype_password)
        params[:user].delete(:old_passowrd)
      end
    end

    if @user.errors.empty?
      @user.update_attributes(params[:user])
      if @user.errors.empty?
        flash[:notice] = _('information successfully updated')
      else
        flash[:error ] = _('could not update user')
      end
    end

    respond_to do |format|
      format.html # TODO
      format.js
    end
  end

  protected
    # Find the user or use the current visitor
    def find_user
      if params[:id]
        @user = secure!(User) { User.find(params[:id]) }
      else
        @user = visitor
      end
      @node = @user.contact
    end

    def get_groups_list
      @groups = secure!(Group) { Group.find(:all, :order=>'name') }
    end

    # Only allow if user is admin or the current user is the visitor
    # TODO: test
    def restrict_access
      if visitor.is_admin?
        @admin = true
      elsif @user[:id] == visitor[:id]
        if params[:user]
          # visitor changing his/her own info : restrict fields
          params[:user].keys.each do |k|
            params[:user].delete(k) unless [:login, :first_name, :name, :time_zone, :lang, :email, :password, :time_zone].include?(k.to_sym)
          end
        end
      else
        raise ActiveRecord::RecordNotFound
      end
    end
end
