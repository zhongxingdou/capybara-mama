require 'capybara'
#!!!引用此文件时，要放到引用capybara/rspec之前

=begin
class Capybara::Selenium::Driver < Capybara::Driver::Base
  def within_frame(frame_id)
    #old_window = browser.window_handle
    #browser.switch_to.frame(frame_id)
    frame_handle = frame_id
    #puts "hello" if frame_handle.is_a?(Capybara::Node::Base)
    frame_handle = frame_handle.native if frame_handle.is_a?(Capybara::Node::Base)
    old_window = browser.window_handle
    browser.switch_to.frame(frame_handle)
    yield
  ensure
    browser.switch_to.window old_window
    browser.switch_to.default_content
  end
end
=end

class Capybara::Node::Base
  def attach_file(locator, path, options={})
    unless base.class == Capybara::Selenium::Driver and base.options[:browser] == :remote
      Array(path).each do |p|
        raise Capybara::FileNotFound, "cannot attach file, #{p} does not exist" unless File.exist?(p.to_s)
      end
    end
    find(:file_field, locator, options).set(path)
  end
end

class Capybara::Session
  alias old_driver driver
  def driver
    unless @driver
      old_driver
      Capybara.after_start[mode].call
    end
    @driver
  end
end

module Capybara
  class << self
    attr_accessor :after_start

    def using_session(name)
      previous_session = self.session_name
      self.session_name = name
      yield
    ensure
      self.session_name = previous_session
    end
  end
  Capybara.after_start = {}
end

