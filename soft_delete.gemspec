require_relative 'lib/soft_delete/version'

Gem::Specification.new do |spec|
  spec.name          = 'ar_soft_delete'
  spec.version       = SoftDelete::VERSION
  spec.authors       = ['Stephen Philp']
  spec.email         = ['swelltrain@gmail.com']

  spec.summary       = 'Soft delete active_record models.'
  spec.description   = 'This gem takes an open approach and lets you decide
    how little or how much your project will be using the soft delete pattern.
    It can be configured on a per-model level to use whichever features
    are appropriate at the time.  This makes it especially easy to introduce
    soft delete into existing projects.'
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['source_code_uri'] = 'https://github.com/swelltrain/soft_delete'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.exist?('.git') ? `git ls-files`.split("\n") : Dir.glob('{lib}/**/*')
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'with_model'
end
