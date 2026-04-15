# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-04-15

### Changed
- Verify full compliance with Ruby package guides (gemspec metadata, README structure, CHANGELOG format, CI workflow)

## [0.3.0] - 2026-04-15

### Added
- `Page#to_h` serializes a page as a hash with `:items`, `:metadata`, and `:links` keys (JSON-ready)
- `Page#page_range` returns the range of page numbers (e.g. `1..5`) for offset pagination
- `Page#next_page` and `Page#prev_page` expose the neighboring page numbers for offset pagination
- `Page#first_page?` and `Page#last_page?` boolean navigation helpers
- `Page#total_pages` public accessor for the computed total page count
- `Page` now includes `Enumerable` with `#each`, `#size`, `#length`, `#count`, and `#empty?`

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-29

### Added
- Page metadata via `page.metadata` returning current_page, per_page, total_pages, total_count, offset
- Page size limits with `min_per_page` and `max_per_page` options raising `InvalidPageSizeError`
- Cursor encryption with HMAC-SHA256 signing via `secret` option raising `InvalidCursorError`

## [0.1.3] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.2] - 2026-03-24

### Fixed
- Fix Installation section quote style to double quotes
- Remove inline comments from Development section to match template

## [0.1.1] - 2026-03-22

### Changed
- Expand test coverage from 21 to 34 examples

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Offset-based pagination with page numbers
- Cursor-based pagination with Base64-encoded cursors
- Keyset-based pagination for sorted collections
- Page result object with items, total, cursors, and links
- Navigation helpers: has_next?, has_prev?, links
- Configurable per_page with minimum of 1

[0.3.1]: https://github.com/philiprehberger/rb-pagination/releases/tag/v0.3.1
[0.3.0]: https://github.com/philiprehberger/rb-pagination/releases/tag/v0.3.0
[0.2.1]: https://github.com/philiprehberger/rb-pagination/releases/tag/v0.2.1
[0.2.0]: https://github.com/philiprehberger/rb-pagination/releases/tag/v0.2.0
[0.1.3]: https://github.com/philiprehberger/rb-pagination/releases/tag/v0.1.3
[0.1.2]: https://github.com/philiprehberger/rb-pagination/releases/tag/v0.1.2
[0.1.1]: https://github.com/philiprehberger/rb-pagination/releases/tag/v0.1.1
[0.1.0]: https://github.com/philiprehberger/rb-pagination/releases/tag/v0.1.0
