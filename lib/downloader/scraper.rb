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

  class Scraper

    attr_reader :agent
    def initialize(username, password)
      @username = username
      @password = password
      initialize_parser
    end

    def with_basic_auth(auth_url)
      agent.add_auth(auth_url,@username,@password)
      page = agent.get(auth_url)
      yield page
    end

    def sign_in(signin_url)
      page = agent.get(signin_url)
      yield page if block_given?
      form = page.form
      form.field_with('username').value = @username
      form.field_with('password').value = @password
      form.checkbox_with('remember_me').check
      agent.submit(form, form.buttons.first)
    end

    def get(url)
      agent.get(url)
    end

    # currently unused
    def get_url(url, parameters=[], headers={}, referer=nil)
      referer ||= url
      agent.get(url, parameters, referer, headers) # weird api, made explicit here
    end

  end

  class HtmlScraper < Scraper

    def initialize_parser
      # Mechanize.html_parser = Nokogiri::XML
      @agent = Mechanize.new
      puts agent.html_parser
      agent.user_agent = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6' # not sure what user_agent_alias I can set
      agent
    end

  end

  class XmlScraper < Scraper

    def initialize_parser
      # Mechanize.html_parser = Nokogiri::XML
      @agent = Mechanize.new
      # puts @agent.html_parser
      agent.user_agent = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6' # not sure what user_agent_alias I can set
      # agent.pluggable_parser.default = Mechanize::Page
      agent.pluggable_parser['application/xml'] = XmlParser
      agent.pluggable_parser['application/rss+xml'] = XmlParser
      agent
    end

  end
end
