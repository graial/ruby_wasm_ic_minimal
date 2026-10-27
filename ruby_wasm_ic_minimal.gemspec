require File.expand_path('lib/ruby_wasm_ic_minimal/version', __dir__)

Gem::Specification.new do |spec|
  spec.name                  = 'ruby_wasm_ic_minimal'
  spec.version               = RubyWasmIcMinimal::VERSION
  spec.authors               = ['graial']
  spec.email                 = ['graial@paglalayag.net']
  spec.summary               = 'Four carried files required for running rack and roda on the minimal ruby.wasm build'
  spec.description           = 'This gem contains the four carried files required for running rack and roda on the minimal ruby.wasm build.'
  spec.homepage              = 'https://github.com/graial/ruby_wasm_ic_minimal'
  spec.license               = 'MIT'
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 3.3.3'
  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md"]
end