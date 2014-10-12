# encoding: utf-8
require 'rubygems'
require 'yarjuf'
require 'capybara_fix' #要放到引用capybara/rspec之前
require 'capybara/rspec'
require 'prickle/capybara' 
require 'rack'
require 'uri'
require 'fixture_loader'
require 'yaml'
require 'login_helper'

rspec_config = {}
#merge环境变量中的配置和config.yaml中的配置
Proc.new do
  config = YAML.load_file("config.yaml")
  puts config

  #merge config
  config.each do |k, v|
    key = k.to_s
    config[k] = ENV[key] unless ENV[key].nil? 
  end

  rspec_config = config
end.call

Capybara.default_driver = rspec_config["driver"].to_sym
require 'capybara/poltergeist'


Capybara.app_host = "http://"  + rspec_config["app"]

#配置测试服务器和测试浏览器
Capybara.register_driver :selenium do |app|
  config = rspec_config
  option = {
    :browser => :remote,
    :url => "http://#{config["server"]}:4444/wd/hub",
    :desired_capabilities => config["browser"].to_sym
  }

  if config["server"]
    option[:url] = "http://#{config["server"]}:4444/wd/hub"
    option[:browser] = :remote
    option[:desired_capabilities] = config["browser"].to_sym
  else
    option[:browser] = config["browser"].to_sym
  end

  #测试服务器是在本地
  unless option[:browser] == :remote
    option.delete :url
    option.delete :desired_capabilities
  end

  Capybara::Selenium::Driver.new(app, option)
end

Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app)
end

YewuHelper.config = rspec_config

#自动登录
Capybara.after_start[:selenium] = lambda { LoginHelper.auto_login }
Capybara.after_start[:poltergeist] = lambda { LoginHelper.auto_login }
Capybara.after_start[:webkit] = lambda { LoginHelper.auto_login }

if rspec_config["upload_dir"]
  UPLOAD_FILES_DIR = rspec_config["upload_dir"]
else
  UPLOAD_FILES_DIR = Dir.pwd + "/uploadfiles/"
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  #加载扩展
  c.include Prickle::Capybara, :type => :feature
  c.include YewuHelper, :type => :feature
  c.include FixtureLoader, :type => :feature

  #切换会话
  def switch_session session, rspec_config
    if Capybara.session_name.to_s != session.to_s
      Capybara.session_name = session.to_sym
      driver = rspec_config["sessions"][session.to_s]["driver"]
      Capybara.current_driver = (driver.nil? ? rspec_config["driver"] : driver).to_sym
      puts "  switching to #{session}[#{Capybara.current_driver}]"
    end
  end

  def test_app test, rspec_config
    app = (test.class.metadata[:app] || rspec_config["session"]).to_s
  end

  #如果测试项指定了:gui tag，切换到gui会话（会话名：当前会话名叫_gui）
  c.prepend_before(:each, :gui) do |test|
    unless test.class.metadata[:gui]
      switch_session  test_app(test, rspec_config) + "_gui", rspec_config
    end
  end

  c.append_after(:each, :gui) do |test|
    unless test.class.metadata[:gui]
      switch_session test_app(test, rspec_config), rspec_config
    end
  end

  c.prepend_before(:all, :gui) do |test|
    switch_session test_app(test, rspec_config) + "_gui", rspec_config
  end

  c.append_after(:all, :gui) do |test|
    switch_session test_app(test, rspec_config), rspec_config
  end

  #切换到用:app tag指定的会话
  c.prepend_before(:all, :app => lambda { |app| app }) do |test|
    switch_session test.class.metadata[:app], rspec_config
  end

  #切换到默认的会话
  c.prepend_before(:all) do |test|
    switch_session rspec_config["session"], rspec_config
  end

  #自动加载fixture
  c.before(:all) do |test|
    fixtures_dir  =  File.dirname(__FILE__) + "/../fixtures"
    test_file = File.basename test.class.file_path
    fixture_file = fixtures_dir + "/" + test_file.sub("_spec.rb","_fixture.yaml")
    if File.exists? fixture_file
      @data = FixtureLoader.require_fixtures fixture_file
    end
  end

  #自动加载helper，不要把断言和shared_examples写到helper文件中
  c.prepend_before(:all) do |test|
    helper_dir = File.dirname(__FILE__)
    test_file = File.basename(test.class.file_path).sub(/_spec.rb/,'')
    helper_file = test_file + "_helper.rb"
    if File.exists? helper_dir + "/" + helper_file
      require helper_file
      module_name = test_file.gsub('-','_').split("_").collect{|word| word.capitalize}.join('') + "Helper"
      test.class.class_eval("include #{module_name}")
    end
  end

  #每个测试后不reset设浏览器会话，避免每组测试都要登录
  c.after(:each) do
    # page.instance_variable_set(:@touched, false)  #每个测试后不reset设浏览器会话
    # Capybara.current_session.instance_variable_set(:@touched, false)
    pool = Capybara.instance_variable_get(:@session_pool)
    pool.each { |mode, session| 
      session.instance_variable_set(:@touched, false)
    }
  end

  #避免alert弹出未确定中断后续测试
  c.before(:all) do
    begin
      if Capybara.current_driver.eql? :selenium and page.driver.browser.switch_to.alert
        puts "!!!警告!!!异外的弹出框未关闭：" + popup.message
        popup.confirm
      elsif Capybara.current_driver.eql? :webkit
        page.driver.accept_js_prompts!
      end
    rescue
    end
  end
end


