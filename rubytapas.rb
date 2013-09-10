require_relative 'lib/ruby_tapas_downloader'

if __FILE__ == $0
  rt = RubyTapasDownloader.new
  rt.get_episode_list.download
end
