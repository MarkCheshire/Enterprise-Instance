class Account < ActiveRecord::Base

  # == Schema Information
  #
  # Table name: accounts
  #
  #  id            :integer         not null, primary key
  #  provider_key  :string(255)
  #  provider_name :string(255)
  #  site_url      :string(255)
  #  developer_id  :string(255)
  #  cover_code    :string(255)
  #  provider_id   :string(255)
  #  password      :string(255)
  #  app_name      :string(255)
  #  app_id        :string(255)
  #  app_key       :string(255)
  #  created_at    :datetime
  #  updated_at    :datetime
  #

  attr_accessible :site_url, :developer_id, :provider_name, :provider_key

  def initialize(*params)

    super(*params)

    if self.site_url  # if initialized without setting site_url skip this setup

      # parse "https://cheshapi.3scale.net/access_code?access_code=426aa22220" into "cheshapi" and "426aa22220"
      if self.site_url =~ /https:\/\/([^.]*).*access_code=(\w.*)/
        @provider_id = $1
        @cover_code = $2
      end

      three_digit_random_number = Array.new(3){rand 10}.join
      @pwd = @provider_id + three_digit_random_number

      # setup the details of the provider account itself
      AccountMgmtApi.new(self.provider_id, self.provider_key)
      provider_new_credentials

      sample_new_credentials

      # setup the details of the buyer test account
      buyer = BuyerAccount.signup(
                        :username => 'buyer',
                        :org_name => '3scale Test',
                        :email => 'mark@3scale.net',
                        :password => 'buyer123',
                        :password_confirmation=> 'buyer123')

      unless buyer.account_id  then @provider_id = "BUYER SIGNUP ERROR" end

    end

  end

  def provider_new_credentials     # looks for admin acount "provider" and changes to new id and pwd
    users = Nokogiri::XML(Provider.admin_users(:format => 'xml'))
    userid = users.xpath('//user[username="provider"]/id').text

    response = Provider.set_fields(userid,
                        :username => self.provider_id,
                        :password=>self.password,
                        :password_confirmation=>self.password)

    if response.code != 200 then @provider_id = "PROVIDER_NEW_CREDENTIALS ERROR" end

  end

  def sample_new_credentials     # gets the appid and appkey for the sample app with org_name "sample1"
    accounts = Nokogiri::XML(Provider.accounts(:format => 'xml'))
    id = accounts.xpath('//account[org_name="sample1"]/id').text

    # get the application keys for the app in the sample1 account
    buyer = BuyerAccount.new(id)
    buyerapps = buyer.applications
    buyerappid = buyerapps['applications']['application']['id']  # assumes there is only one app and takes that
    app = Application.new(buyer.account_id, buyerappid)
    response = app.show

    if response.code != 200 then
      @app_id = @app_key = @app_name = "SAMPLE_NEW_CREDENTIALS ERROR"
    else
      @app_id = app.app_id
      @app_key = app.app_key
      @app_name = response["application"]["name"]
      @buyer_name = "sample1"
    end
    # change the credentials for the sample1 account
    buyer_account = buyer.show_account
    buyer_userid = buyer_account['account']['users']['user']['id']  # assumes only one user
    buyer.set_fields( buyer_userid,
                      :username => self.developer_id,
                      :password => self.password,
                      :password_confirmation => self.password )

  end

  def cover_code
    @cover_code
  end

  def provider_id
    @provider_id
  end

  def password
    @pwd.downcase
  end

  def app_name
    @app_name
  end

  def app_id
    @app_id
  end

  def app_key
    @app_key
  end

  def buyer_name
    @buyer_name
  end
end