%w(
  .ruby-version
  .rbenv-vars
  tmp/restart.txt
  tmp/caching-dev.txt
  /Users/wuminzhe/Projects/huaxin/etherscanio-rb
).each { |path| Spring.watch(path) }
