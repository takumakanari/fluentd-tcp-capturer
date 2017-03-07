# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluentd-tcp-capturer"
  spec.version       = "0.2.0"
  spec.authors       = ["takumakanari"]
  spec.email         = ["chemtrails.t@gmail.com"]

  spec.summary       = %q{Fluentd message capturer}
  spec.description   = %q{A tool to inspect/dump/handle message to Fluentd TCP input.}
  spec.homepage      = "https://github.com/takumakanari/fluentd-tcp-capturer"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ruby-pcap"
  spec.add_runtime_dependency "threadpool"
  spec.add_runtime_dependency "fluentd", [">= 0.12", "< 2"]
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
end
