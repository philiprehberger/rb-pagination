# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
