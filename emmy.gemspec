# coding: utf-8
version = File.read(File.expand_path('../EMMY_VERSION', __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name          = "emmy"
  spec.version       = version
  spec.summary       = %q{Emmy is EventMachine-based framework}
  spec.license       = "MIT"

  spec.authors       = ["inre"]
  spec.email         = ["inre.storm@gmail.com"]
  spec.homepage      = "https://github.com/emmygems"

  spec.files         = ["README.md"]

  spec.required_ruby_version     = '>= 2.2.2'
  spec.required_rubygems_version = '>= 2.3.0'

  spec.add_dependency "eventmachine", "~> 1.0"
  spec.add_dependency "emmy-engine",  "~> 0.2"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rspec",   "~> 3.0"
  spec.add_development_dependency "rake",    "~> 10.0"
end
