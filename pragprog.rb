require 'fileutils'
require 'pathname'
require 'open-uri'
require 'net/http'

if __FILE__ == $0

  redirect_range = (300..399)
  base_url = "http://pragprog.com/magazines/download/ISSUE.FORMAT"
  # should check for most recent release
  #   http://pragprog.com/magazines.opds
  issues = (1..49).map(&:to_s)
  formats = %w(HTML PDF epub mobi)
  root = File.expand_path('..', __FILE__)
  output_dir = File.join(root, 'pragprog')
  FileUtils.mkdir_p(output_dir)
  html_dir = File.join(output_dir, 'html')
  FileUtils.mkdir_p(html_dir)
  html_wget_options = "-B http://pragprog.com/magazines/ --convert-links" <<
   " --recursive --level=2 --continue"  <<
   " --no-host-directories" <<
   " --force-directories" <<
   " --adjust-extension" <<
   " --no-parent" <<
   " -p"
  issues.each do |issue|
    issue_dir = File.join(output_dir, issue)
    FileUtils.mkdir_p(issue_dir)
    formats.each do |format|
      output_path = File.join(issue_dir, "#{issue}.#{format}")
      if File.exists?(output_path)
        puts "#{output_path} already downloaded"
      else
        url = base_url.sub('ISSUE', issue).sub('FORMAT',format)
        output_options = if (format == 'HTML')
                           uri = URI(url)
                           response = Net::HTTP.get_response(uri)
                           url = response['location'] if redirect_range.cover?(response.code.to_i)
                           url << '/' unless url.end_with?('/')
                           html_wget_options <<
                             " --default-page=#{issue}.HTML" <<
                             " --directory-prefix=#{html_dir}"
                         else
                           "-O #{output_path}" <<
                             " --directory-prefix=#{output_dir}"
                         end

        p cmd = "wget #{url} #{output_options}"
        system(cmd)
      end
    end
  end

end
