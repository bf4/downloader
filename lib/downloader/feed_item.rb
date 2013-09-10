require_relative 'feed_link'
class RubyTapasDownloader
  FeedItem = Struct.new(:item) do
    def title
      item.at('title').inner_text
    end
    def episode_id
      @episode_id ||= [
       (title[/\d+/] || episode_id_from_video_link(video_links.first)),
       "post-#{post_id}"
      ].compact.uniq.
      join('_')
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
end
