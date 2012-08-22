class AccountMgmtApi
  include HTTParty

  def initialize (provider_name, key)
    uri= "https://" + provider_name.downcase + "-admin.3scale.net/admin/api"
    self.class.base_uri uri
    self.class.default_params :provider_key => key
    # debug_output $stderr
  end
end

class Provider < AccountMgmtApi

  def self.accounts (custom=nil)
    if custom
      get("/accounts.xml", custom)
    else
      get("/accounts.xml")
    end
  end

  def self.user (accountid, userid)
    get("/accounts/#{accountid}/users/#{userid}.xml")
  end

  def self.applications
    get("/applications.xml")
  end

  def self.applications_for_account(accountid)
    get("/accounts/#{accountid}/applications.xml")
  end

  def self.admin_users (custom=nil)
    if custom
      get("/users.xml", custom)
    else
      get("/users.xml")
    end
  end

  def self.app_plans
    get("/application_plans.xml")
  end

  def self.set_fields (adminuserid, params)
    # =====================================
    # = params fields e.g. :username, :password, :password_confirmation         =
    # =====================================
    put("/users/#{adminuserid}.xml", :query => params)
  end

end

class Application < AccountMgmtApi

  attr_accessor :account_id, :application_id, :app_id, :app_key

  # use app_id in place of user_key where appropriate

  def initialize(accountid=nil, applicationid=nil, appid=nil, appkey=nil)
    self.account_id = accountid
    self.application_id = applicationid
    self.app_id = appid
    self.app_key = app_key
  end

  def show
    response = self.class.get("/accounts/#{@account_id}/applications/#{@application_id}.xml")
    if response.code != 200 then
      self.app_id = self.app_key = "XXX"
    else
      self.app_id = response['application']['application_id']
      self.app_key = response['application']['keys']['key']
    end
    return response
  end

  def self.create ( accountid, planid, params )
    params[:plan_id]=planid.to_s
    response = post("/accounts/#{accountid}/applications.xml", :body => params)
    if response.code != 200
      self.new( nil, nil, nil, nil )
    else
      # assumes appid authmode
      applicationid = response["application"]["id"]
      appid = response["application"]["application_id"]
      appkey = response["application"]["keys"]["key"]
      self.new( accountid, applicationid, appid, appkey )
    end
  end

  def accept
    self.class.put("/accounts/#{@account_id}/applications/#{@application_id}/accept.xml")
  end

  def change_plan(planid)
    self.class.put("/accounts/#{@account_id}/applications/#{@application_id}/change_plan.xml", :query => {:plan_id => planid})
  end

  def set_fields (params)
    # =====================================
    # = params fields :name, :description =
    # =====================================
    self.class.put("/accounts/#{@account_id}/applications/#{@application_id}.xml", :query => params)
  end

end


class BuyerAccount < AccountMgmtApi

  attr_accessor :account_id, :application_id

  def initialize (account_id, application_id=nil)
    self.account_id = account_id
    self.application_id = application_id
  end

  def self.signup (params)

    # =============================================
    # = mandatory parameters :org_name, :username =
    # =============================================

    response = post('/signup.xml', :body => params )
    if response.code != 201
      self.new( nil, nil )        # this could be improved to return a nil object on errors
    else
      account = response['account']['id']
      if response['account']['applications']
        app = response['account']['applications']['application']['id']
      else
        app = nil
      end
      self.new( account, app )
    end
  end

  def show_account
    self.class.get("/accounts/#{@account_id}.xml")
  end

  def delete_account
    self.class.delete("/accounts/#{@account_id}.xml")
  end

  def account_id
    @account_id
  end

  def application_id
    @application_id
  end

  def activate_user (userid)
    self.class.put("/accounts/#{@account_id}/users/#{userid}/activate.xml")
  end

  def approve
    self.class.put("/accounts/#{@account_id}/approve.xml")
  end

  def set_fields (userid, params)
    # =====================================
    # = params fields :org_name, :username =
    # =====================================
    self.class.put("/accounts/#{@account_id}/users/#{userid}.xml", :query => params)
  end

  def applications
    self.class.get("/accounts/#{@account_id}/applications.xml")
  end

end

# ==================
# = Usage Examples =
# ==================

# ===========
# = Provider =
# ===========
# puts Provider.user(36, 36)
# puts Provider.accounts
# puts Provider.accounts['accounts']['account'].each { |item| puts item['id'] }
# puts Provider.admin_users
# Provider.set_fields("76", :password=>"123456", :password_confirmation=>"123456")

# ===========
# = BuyerAccount =
# ===========
# buyer=BuyerAccount.new("23")
# buyer = BuyerAccount.signup(
                        # :username => 'DevAdmin',
                        # :org_name => 'Org Test'
                        # :password => '123456',
                        # :password_confirmation=> '123456')

# ==============
# = Application =
# ==============
# app=Application.new(a.account_id, a.app_id)
# app=Application.create(accountid, planid, name:"appname", description:"appdescription")   # returns Application object
# app.change_plan("46")
