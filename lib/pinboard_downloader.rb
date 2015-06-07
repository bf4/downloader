require_relative "downloader/http"
require 'readability'
require 'fileutils'
require 'set'
require 'yaml'
%w{open-uri rss/0.9 rss/1.0 rss/2.0 rss/parser}.each do |lib|
  require(lib)
end
class GetPinboard
  def initialize(config = get_config)
    @user = config.fetch(:user)
    @rss_base = config.fetch(:rss_base)
    @secret_base_url = config.fetch(:secret_base_url)
    @private_tags = config.fetch(:private_tags)
    @public_tags = config.fetch(:public_tags)
  end

  def download_all
    private_feeds.each do |feed_url|
      GetPinboard.get_feed(feed_url)
    end
  end

  def private_feeds
    @private_tags.map {|tag|
      url = "#{@rss_base}#{@secret_base_url}#{@user}#{tag}/"
      build_url(url)
    }
  end

  def public_feeds
    @public_tags.map {|tag|
      url = "#{@rss_base}#{@user}#{tag}"
      build_url(url)
    }
  end

  private

  def get_config
    config = File.read("./pinboard_config.rb")
    opts = eval config, binding, __FILE__, __LINE__
    p opts
  end

  def build_url(base_url)
    "#{base_url}?count=400"
  end

  def self.get_feed(url)
    init
    @url = url
    puts
    puts "getting feed from #{@url}"
    puts

    begin
      response = @client.get(@url, timeout: 5)
      @feed = RSS::Parser.parse(response.body, false)
    rescue RSS::NotWellFormedError, Errors::ConnectionError => e
      puts "#{e.class}\t#{e.message}\t#{@url}\t#{e.backtrace.inspect}"
      # null object
      @feed = RSS::Rss.new('1.0')
    end


    @feed.items.each do |item|
      link = item.link
      get_link(link)
    end
    save_links
  end
  def self.get_link(link)
    init
    add_link(link)
    begin
      uri = URI.parse(link)
    rescue URI::InvalidURIError => e
      add_page_download_error(link)
      puts "ERROR: #{e.class}: #{e.message}: #{link}"
      # File.open(File.join(@output_dir,build_filename(link)), 'w') {|file| file.write(link) }
      return
    end
    filename = build_filename("#{uri.host}_#{uri.path}_#{uri.query}.html")
    # uri.scheme # e.g. http
    # uri.fragment # the part after #
    if File.exists?(File.join(@output_dir,filename))
      #puts "file exists for #{link}"
    else
      output_file = "#{@output_dir}/#{filename}"
      puts "downloading #{link}"
      begin
        page = @client.get(@url, timeout: 5).body
        readable_page = Readability::Document.new(page).content
      rescue SocketError, URI::InvalidURIError => e
        add_page_download_error(output_file)
        puts "ERROR: #{e.class}: #{e.message}: #{link} : #{filename}"
        page = link
        readable_page = link
      rescue Timeout::Error, Errno::ETIMEDOUT, Errors::ConnectionError => e
        add_page_download_error(output_file)
        puts "ERROR: #{e.class}: #{e.message}: #{link} : #{filename}"
      # File.open(File.join(@output_dir,build_filename(link)), 'w') {|file| file.write(link) }
        return
      end
      File.open(File.join(@output_dir,filename), 'w') {|file| file.write(readable_page) }
      File.open(File.join(@original_dir,filename), 'w') {|file| file.write(page) }
    end

  end

  def self.print_download_errors
    puts "download errors"
    puts Array(@download_errors).join("\n")
  end

  def self.save_links
    # puts "writing links"
    File.open(@links_file,'w+') do |file|
      file.write(Set.new(@links.map).sort.to_yaml)
    end
  end

  private

  def self.init
    return if defined?(@output_dir)
    @client = Http
    @output_dir = 'pages'
    FileUtils.mkdir_p(@output_dir)
    @original_dir = 'original'
    FileUtils.mkdir_p(@original_dir)
    @links_file = "links.yaml"
    @links = read_links
  end
  def self.build_filename(text)
    text =   text.to_s.strip.gsub(/\.html?_*?\.html/,'.html').gsub(/[^a-zA-Z0-9_\-.]/,'_').gsub(/_+/,'_').gsub(/_*\./,'.')
    text = text[0..50] + '.html' if text.size > 55
    text
  end
  def self.add_page_download_error(text)
    @download_errors = (Array(@download_errors) << text ).compact.uniq
  end
  def self.add_link(link)
    @links << link
  end
  def self.read_links
    `touch #{@links_file}`
    @all_links = YAML::load(File.read(@links_file)) || Set.new
  end
end
