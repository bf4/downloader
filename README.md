# [RubyTapas file downloader](https://gist.github.com/bf4/5303227)

## About

This script will download all *non-video* files in the current directory.

It will check for already downloaded files in the current directory.

It can work interactively or with a config.yml (copy from config.yml.template)

deps: mechanize

## Usage

```ruby
    rt = RubyTapasDownloader.new
    rt.get_episode_list.download
```

## Other RubyTapas scripts

- [tapas-bar](https://github.com/mislav/tapas-bar) Tiny webapp that Mislav uses for watching RubyTapas from his iPad across home network. deps: nokogiri, sinatra, sass
- [tapas](https://github.com/ebarendt/tapas) WIP script for automatically downloading RubyTapas episodes and supporting files.  deps: faraday
- [download_rubytapas](https://gist.github.com/xpepper/5872399) Downloads all attachments. deps: wget
- [Andy Lindmans's tweet](https://twitter.com/alindeman/status/364027827269537792) downloads the first 1_052 episodes.  `for i in {1..1052}; do wget --content-disposition --header "Cookie: ..." "https://rubytapas.dpdcart.com/subscriber/download?file_id=$i"; done`

## History etc.

This script adapted from my earlier script [Download All Software ios movie clips](https://gist.github.com/bf4/4070991)

Any idea how to TDD this?

Other comments?

by Benjamin Fleischer

## License

MIT license
