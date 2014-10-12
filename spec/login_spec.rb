# encoding: utf-8
describe "登录", :type => :feature do
  before(:all, :gui => nil){ visit "/" } #启动driver，触发自动登录
  after(:all, :gui => nil){ auto_login }
  before(:each, :gui => nil){ visit @data.logout_path }

  describe "使用正确的密码登录" do
    before :all do
      login @data.login_name, @data.corret_pwd
    end

    it "跳转到首页" do
      debugger
      current_path.should == @data.home_path
      # page.has_content? "Guest，您好"
    end
  end

  describe "使用错误的密码登录", :gui do
    before :each do
      visit @data.logout_path
      login @data.login_name, @data.incorret_pwd
    end

    it "提示\"密码出错！\", 然后跳转回登录页" do
      popup.message.should include("密码出错")
      popup.confirm
      current_path.should_not == @data.home_path
    end

    after(:each){ auto_login }
  end

  describe "登录后台" do
    before do
      login @data.admin_name, @data.admin_pwd
    end

    it "跳转到后台" do
      current_path.should_not == @data.admin_home_path
    end
  end
end
