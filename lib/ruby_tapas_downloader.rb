require 'fileutils'
require 'pathname'
require_relative 'downloader/config'
require_relative 'downloader/scraper'
require_relative 'downloader/feed_item'
class RubyTapasDownloader

  attr_reader :scraper, :all_episodes
  def initialize
    @lib_root     = File.expand_path(File.join(File.dirname(__FILE__),'..'))
    @download_dir = File.join(lib_root, 'downloads')
    @temp_dir     = File.join(lib_root, 'tmp')
    STDOUT.sync = true
    set_credentials
    @scraper = XmlScraper.new(@my_email, @my_password)
    log "initialized"
  end

  def feed_url
    "https://rubytapas.dpdcart.com/feed"
  end

  def content_url
    'https://rubytapas.dpdcart.com/subscriber/content'
  end

  def get_episode_list
    log "signing in"
    # @current_page = Nokogiri::XML(File.read('./feed.xml')).
    scraper.with_basic_auth(feed_url) do |page|
      page.save!(File.join(temp_dir,'feed.xml'))
      @all_episodes = page.
        search('item').map do |item|
        FeedItem.new(item)
      end
    end

    self
  end

  def download
    # sign in again
    @scraper = HtmlScraper.new(@my_email, @my_password)
    @second_sign_in =  scraper.sign_in(content_url) do |page|
      page.save!(File.join(temp_dir,'index.html'))
    end

    log "downloading files"
    download_episodes
  end

  private

  def download_episodes
    existing_episodes = Pathname.glob(File.join(download_dir,'*/')).map(&:basename).map(&:to_s)
    old_episodes, new_episodes  = all_episodes.partition do |episode|
      existing_episodes.include?(episode.episode_id)
    end
    if new_episodes.size.zero?
      log "everything is downloaded"
    else
      log "already downloaded \n\t#{old_episodes.map(&:episode_id).join("\n\t")}"
      log "downloading \n\t#{new_episodes.map(&:episode_id).join("\n\t")}"
    end
    new_episodes.each do |episode|
      download_episode(episode)
    end
  end
  def download_episode(episode)
    episode_number = episode.episode_id

    in_episode_dir(episode_number) do
      File.open("description.html","w+") {|file| file.write(episode.description) }
      File.open("item.html","w+") {|file| file.write(episode.item.text) }
      episode.download_links.each do |link|
        log "getting link #{link.inspect}"
        download_file(link)
      end
    end
  end
  def download_file(link)
    log
    name = link.text
    href = link.href
    print "downloading #{name} from #{href}... "
    file = scraper.get(href)
    print "saving #{name}...(#{file.filename}) "
    file.save!(file.filename)
    log "success"
  end

  def in_episode_dir(episode_number, &block)
    log "****** #{episode_number}"
    episode_dir = File.join(download_dir,episode_number)
    FileUtils.mkdir_p(episode_dir)
    Dir.chdir(episode_dir) do
      yield
    end
  end

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

    config = Config.new(lib_root)
    if config.valid_config?
      @my_email = config.my_email
      @my_password = config.my_password
    else
      log "enter email"
      @my_email = gets.chomp
      log "enter password"
      @my_password = gets.chomp
    end

  end
  def log(msg='')
    puts msg
  end
end
