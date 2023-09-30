# frozen_string_literal: true

require_relative 'lib/philiprehberger/pagination/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-pagination'
  spec.version = Philiprehberger::Pagination::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Framework-agnostic pagination with cursor, offset, and keyset strategies'
  spec.description = 'Pagination library supporting offset-based, cursor-based, and keyset ' \
                     'strategies. Returns page results with items, cursors, navigation links, ' \
                     'totals, and has_next/has_prev helpers. Works with any collection.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-pagination'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-pagination'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-pagination/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-pagination/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
