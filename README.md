[RubyTapas file downloader](https://gist.github.com/bf4/5303227)

This script will download all non-video files in the current directory.

It will check for already downloaded files in the current directory.

It can work interactively or with a config.yml (copy from config.yml.template)

usage

```ruby
    rt = RubyTapasDownloader.new
    rt.get_episode_list.download
```

adapted from my earlier script [Download All Software ios movie clips](https://gist.github.com/bf4/4070991)

Any idea how to TDD this?

Other comments?

Benjamin Fleischer
Do what you want with this code
