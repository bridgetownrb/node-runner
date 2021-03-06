# frozen_string_literal: true

require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name          = "node-runner"
  spec.version       = NodeRunner::VERSION
  spec.author        = "Bridgetown Team"
  spec.email         = "maintainers@bridgetownrb.com"
  spec.summary       = "A simple way to execute Javascript in a Ruby context via Node"
  spec.homepage      = "https://github.com/bridgetownrb/node-runner"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.5"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|script|spec|features)/!) }
  spec.require_paths = ["lib"]
end

