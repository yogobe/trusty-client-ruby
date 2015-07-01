require "bundler/gem_tasks"

task :console do
  exec "irb -r trustly -r 'active_support/core_ext/object/try' -r 'active_support/core_ext/hash/keys' -r 'JSON' -I ./lib"
end
