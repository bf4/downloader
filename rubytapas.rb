require 'fileutils'
require 'yaml'
require 'mechanize'
require 'forwardable'
class RubyTapasDownloader

  class XmlParser < Mechanize::File
    attr_reader :xml
    def initialize(uri = nil, response = nil, body = nil, code = nil)
      @xml = Nokogiri::XML(body)
      super uri, response, body, code
    end
    extend Forwardable
    def_delegators  :@xml, :search, :/, :at
  end
  attr_reader :agent, :current_page, :my_email, :my_password, :config
  def initialize
    STDOUT.sync = true
    @current_dir = File.expand_path(File.dirname(__FILE__))
    initialize_xml_agent
    puts "initialized"
  end
  def url
    "https://rubytapas.dpdcart.com/feed"
  end

  FeedLink = Struct.new(:href, :text)
  FeedItem = Struct.new(:item) do
      def title
        item.at('title').inner_text
      end
      def episode_id
        title[/\d+/] ||
         episode_id_from_video_link(video_links.first) ||
         "post-#{post_id}"
      end
      def episode_id_from_video_link(video_link)
         video_link && video_link.text[/[^-]+/]
      end
      def post_id
        episode_link.text.match(/post\?id=(\d+)/)[1]
      end
      def episode_link
       item.at('link')
      end
      def description
        item.at('description').inner_text
      end
      def parsed_description
        Nokogiri::HTML(description)
      end
      def links
        # parsed_description.xpath('//a/@href').map(&:value)
        parsed_description.search('a').map {|a| FeedLink.new(a.attribute('href').value, a.text) }
      end
      def download_links
        links.reject {|link| link.text =~ /mp4/i }.select {|link| link.href =~ /dpdcart/ }
      end
      def video_links
        links.select {|link| link.text =~ /mp4/i }.select {|link| link.href =~ /dpdcart/ }
      end
      def pubdate
        item.at('pubDate')
      end
      def guid
        item.at('guid')
      end
  end
  def sign_in
    puts "signing in"
    # @current_page = Nokogiri::XML(File.read('./feed.xml')).
    set_credentials
    agent.add_auth(url,my_email,my_password)
    signin_url = "https://rubytapas.dpdcart.com/feed"
    page = agent.get(signin_url)
    page.save!('feed.xml')
    @current_page = page.
      search('item').map do |item|
      FeedItem.new(item)
    end

    self
  end
  def download
    # sign in again
    initialize_html_agent
    signin_url = 'https://rubytapas.dpdcart.com/subscriber/content'
    page = agent.get(signin_url)
    page.save!('index.html')
    form = page.form
    set_credentials
    form.field_with('username').value = my_email
    form.field_with('password').value = my_password
    form.checkbox_with('remember_me').check
    @second_sign_in =  agent.submit(form, form.buttons.first)


    puts "downloading files"
    download_episodes
  end

  private

  def initialize_xml_agent
    # Mechanize.html_parser = Nokogiri::XML
    @agent = Mechanize.new
    # puts @agent.html_parser
    agent.user_agent = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6' # not sure what user_agent_alias I can set
    # agent.pluggable_parser.default = Mechanize::Page
    agent.pluggable_parser['application/xml'] = XmlParser
    agent.pluggable_parser['application/rss+xml'] = XmlParser
  end
  def initialize_html_agent
    # Mechanize.html_parser = Nokogiri::XML
    @agent = Mechanize.new
    puts @agent.html_parser
    agent.user_agent = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6' # not sure what user_agent_alias I can set
  end
  def get_url(url, parameters=[], headers={}, referer=nil)
    referer ||= url
    agent.get(url, parameters, referer, headers) # weird api, made explicit here
  end
  def all_episodes
    @all_episodes ||= current_page
  end
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
    file = agent.get(href)
    print "saving #{name}...(#{file.filename}) "
    file.save!(file.filename)
    puts "success"
  end

  def set_credentials
    if valid_config?
      @my_email = config['my_email']
      @my_password = config['my_password']
    else
      puts "enter email"
      @my_email = gets.chomp
      puts "enter password"
      @my_password = gets.chomp
    end
  end
  def valid_config?
    config_file = File.join(File.dirname(__FILE__),'config.yml')
    if File.exists?(config_file)
      @config = YAML::load(File.read(config_file))
      ['my_email','my_password'].all? {|key| config[key].to_s.size > 2 }
    else
      false
    end
  end
  def in_episode_dir(episode_number, &block)
    puts "****** #{episode_number}"
    episode_dir = File.join(current_dir,episode_number)
    FileUtils.mkdir_p(episode_dir)
    Dir.chdir(episode_dir)
    yield
    Dir.chdir(current_dir)
  end

  def current_dir
    @current_dir
  end
end
if __FILE__ == $0
  rt = RubyTapasDownloader.new
  rt.sign_in.download
end
