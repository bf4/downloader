require_relative 'lib/pinboard_tabs_downloader'

if __FILE__ == $0
  rt = PinboardTabsDownloader.new
  rt.get_tabs.download
end
