# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'symian/version'

Gem::Specification.new do |spec|
  spec.name          = 'symian'
  spec.version       = Symian::VERSION
  spec.authors       = ['Mauro Tortonesi']
  spec.email         = ['mauro.tortonesi@unife.it']
  spec.description   = %q{A Decision Support Tool for the Performance Optimization of IT Support Organizations}
  spec.summary       = %q{A support tool for strategic and business-driven decision making in the performance optimization of the IT incident management process}
  spec.homepage      = 'https://github.com/mtortonesi/symian'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/).reject{|x| x == '.gitignore' }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 4.0.0'
  spec.add_dependency 'awesome_print', '~> 1.2.0'
  spec.add_dependency 'erv', '~> 0.0.2'

  spec.add_development_dependency 'bundler', '~> 1.6.2'
  spec.add_development_dependency 'rake', '~> 10.1.1'
  spec.add_development_dependency 'minitest-spec-context', '~> 0.0.3'
end
