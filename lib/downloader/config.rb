require 'yaml'
class RubyTapasDownloader

  class Config
    attr_reader :config
    def initialize(lib_root)
      config_file = File.join(lib_root,'config.yml')
      if File.exists?(config_file)
        @config = YAML::load(File.read(config_file))
      end
    end
    def my_email
      config['my_email']
    end
    def my_password
      config['my_password']
    end
    def valid_config?
      if config
        ['my_email','my_password'].all? {|key| config[key].to_s.size > 2 }
        config
      else
        false
      end
    end
  end

end
