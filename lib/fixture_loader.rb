# encoding: utf-8
require "yaml"

module FixtureLoader
  class ObjectHash
    def initialize(hash)
      @hash = hash
      hash.each do |k,v|
        if v.class == Hash
          self.instance_variable_set("@#{k}", self.class.new(v))
        else
          self.instance_variable_set("@#{k}", v)
        end
        self.define_singleton_method(k, proc{self.instance_variable_get("@#{k}")})
        # self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
      end
    end

    def [] key
      @hash[key]
    end

    def to_hash
      @hash
      # h = {}
      # self.instance_variables.each do |x|
      #   name = x[1..-1]
      #   h[name] = self.instance_variable_get(name)
      # end
      # return h
    end
  end

  def self.require_fixtures file
    hash = YAML.load_file(file)
    return FixtureLoader::ObjectHash.new hash
  end

  #加载fixture，可省略扩展名.yaml
  #@example 
  # @data = require_fixtures("login_fixture") 
  def require_fixtures file
    file << ".yaml" if File.extname(file).empty?
    fixtures_dir  =  Dir.pwd + "/fixtures"
    path = fixtures_dir + "/" + file
    if File.exists? path
      FixtureLoader.require_fixtures path
    else
      raise "#{path}不存在"
    end
  end
end

class Hash
  def to_obj
    FixtureLoader::HashObject.new self
  end
end

