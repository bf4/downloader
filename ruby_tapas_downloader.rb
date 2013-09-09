require 'fileutils'
require_relative 'config'
require_relative 'scraper'
require_relative 'feed_item'
class RubyTapasDownloader

  attr_reader :scraper, :all_episodes
  def initialize
    STDOUT.sync = true
    @current_dir = File.expand_path(File.dirname(__FILE__))
    set_credentials
    @scraper = XmlScraper.new(@my_email, @my_password)
    puts "initialized"
  end

  def feed_url
    "https://rubytapas.dpdcart.com/feed"
  end

  def content_url
    'https://rubytapas.dpdcart.com/subscriber/content'
  end

  def get_episode_list
    puts "signing in"
    # @current_page = Nokogiri::XML(File.read('./feed.xml')).
    scraper.with_basic_auth(feed_url) do |page|
      page.save!('feed.xml')
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
    @second_sign_in =  scraper.sign_in(content_url)

    puts "downloading files"
    download_episodes
  end

  private

  def download_episodes
    existing_episodes = Dir['*/']
    puts existing_episodes.inspect
    old_episodes, new_episodes  = all_episodes.partition do |episode|
      existing_episodes.include?(episode.episode_id + '/')
    end
    if new_episodes.size.zero?
      puts "everything is downloaded"
    else
      puts "already downloaded \n\t#{old_episodes.map(&:episode_id).join("\n\t")}"
      puts "downloading \n\t#{new_episodes.map(&:episode_id).join("\n\t")}"
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
        puts "getting link #{link.inspect}"
        download_file(link)
      end
    end
  end
  def download_file(link)
    puts
    name = link.text
    href = link.href
    print "downloading #{name} from #{href}... "
    file = scraper.get(href)
    print "saving #{name}...(#{file.filename}) "
    file.save!(file.filename)
    puts "success"
  end

  def in_episode_dir(episode_number, &block)
    puts "****** #{episode_number}"
    episode_dir = File.join(current_dir,episode_number)
    FileUtils.mkdir_p(episode_dir)
    Dir.chdir(episode_dir) do
      yield
    end
  end

  def current_dir
    @current_dir
  end

  def set_credentials

    config = Config.new
    if config.valid_config?
      @my_email = config.my_email
      @my_password = config.my_password
    else
      puts "enter email"
      @my_email = gets.chomp
      puts "enter password"
      @my_password = gets.chomp
    end

  end
end
