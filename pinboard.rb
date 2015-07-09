require_relative "lib/pinboard_downloader"

client = GetPinboard.new
client.download_all
# links.each do |link|
#   begin
#     GetPinboard.get_link(link)
#   ensure
#     GetPinboard.save_links
#   end
# end
GetPinboard.print_download_errors
