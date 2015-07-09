require 'fileutils'
require 'pathname'
require_relative 'downloader/config'
require_relative 'downloader/scraper'

class PinboardTabsDownloader

  attr_reader :scraper, :all_episodes
  def initialize
    @lib_root     = File.expand_path(File.join(File.dirname(__FILE__),'..'))
    @download_dir = File.join(lib_root, 'pinboard_tabs')
    @temp_dir     = File.join(lib_root, 'tmp')
    FileUtils.mkdir_p @download_dir
    FileUtils.mkdir_p @temp_dir
    STDOUT.sync = true
    set_credentials
    @scraper = RubyTapasDownloader::HtmlScraper.new(@username, @password)
    log "initialized"
  end

  def pinboard_url
    "https://pinboard.in/"
  end
  def tabs_url
    @tabs_url ||= "u:#{@username}/tabs/"
  end

  def sign_in_url
    pinboard_url
  end

  def get_tabs
    @scraper.sign_in(sign_in_url)
    tabs_page = @scraper.get(pinboard_url + tabs_url)
    @tabs_pages ||= tabs_page.search("#main_column td a").map {|a|
      [a.attribute('href').to_s, a.text]
    }.reject {|href, text|
      !href.include?(tabs_url)
    }
    self
  end

  def download
    @tabs_pages.each do |href, text|
      puts "Downloading #{href}: #{text}"
      tab_number = href.split('/')[-1]
      tab_description = text.gsub(/\s+/, '_').gsub('/', '-')
      file_name = File.join(@download_dir, "#{tab_number}-#{tab_description}.yaml")
      next if File.exists?(file_name)
      links = @scraper.get(href).search("table td a").each_with_object({}) {|a, result|
        result[a.attribute('href').to_s] = a.text
      }.reject {|href, text|
        !href.start_with?("http")
      }
      File.write(file_name, YAML.to_json(links))
    end
  end

  private

  def download_dir
    @download_dir
  end

  def temp_dir
    @temp_dir
  end

  def lib_root
    @lib_root
  end

  def set_credentials
    config = RubyTapasDownloader::Config.new(lib_root).config
    if config["pinboard"].size == 2
      @username = config["pinboard"]["username"]
      @password = config["pinboard"]["password"]
    else
      log "enter username"
      @username = gets.chomp
      log "enter password"
      @mpassword = gets.chomp
    end
  end

  def log(msg='')
    puts msg
  end
end
