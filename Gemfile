# A sample Gemfile
source "https://rubygems.org"

gem "mechanize", "~> 2.6"

# make your own local changes if you want
local_gemfile = File.expand_path("Gemfile.local", File.dirname(__FILE__))
eval_gemfile(local_gemfile) if File.exists?(local_gemfile)
