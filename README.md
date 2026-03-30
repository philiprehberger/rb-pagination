# philiprehberger-pagination

[![Tests](https://github.com/philiprehberger/rb-pagination/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pagination/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pagination.svg)](https://rubygems.org/gems/philiprehberger-pagination)
[![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-pagination)](https://github.com/philiprehberger/rb-pagination/releases)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-pagination)](https://github.com/philiprehberger/rb-pagination/commits/main)
[![License](https://img.shields.io/github/license/philiprehberger/rb-pagination)](LICENSE)
[![Bug Reports](https://img.shields.io/github/issues/philiprehberger/rb-pagination/bug)](https://github.com/philiprehberger/rb-pagination/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![Feature Requests](https://img.shields.io/github/issues/philiprehberger/rb-pagination/enhancement)](https://github.com/philiprehberger/rb-pagination/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Framework-agnostic pagination with cursor, offset, and keyset strategies

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-pagination"
```

Or install directly:

```bash
gem install philiprehberger-pagination
```

## Usage

```ruby
require "philiprehberger/pagination"

page = Philiprehberger::Pagination.paginate(users,
  strategy: :offset,
  per_page: 25,
  page: 2
)

page.items       # => [user_26, user_27, ...]
page.total       # => 100
page.has_next?   # => true
page.has_prev?   # => true
```

### Offset Pagination

```ruby
page = Philiprehberger::Pagination.paginate(items, strategy: :offset, per_page: 10, page: 3)
page.next_cursor  # => "4" (next page number)
page.prev_cursor  # => "2" (previous page number)
```

### Cursor Pagination

```ruby
page = Philiprehberger::Pagination.paginate(items, strategy: :cursor, per_page: 10)
next_page = Philiprehberger::Pagination.paginate(items,
  strategy: :cursor,
  per_page: 10,
  cursor: page.next_cursor
)
```

### Keyset Pagination

```ruby
# Items must be sorted; cursor is based on the last item's value
page = Philiprehberger::Pagination.paginate(sorted_items, strategy: :keyset, per_page: 10)
```

### Page Metadata

```ruby
page = Philiprehberger::Pagination.paginate(items, strategy: :offset, per_page: 10, page: 2)
page.metadata
# => { current_page: 2, per_page: 10, total_pages: 5, total_count: 50, offset: 10 }
```

### Page Size Limits

```ruby
page = Philiprehberger::Pagination.paginate(items,
  per_page: 25,
  max_per_page: 100,
  min_per_page: 1
)
# Raises InvalidPageSizeError if per_page is out of bounds
```

### Cursor Encryption

```ruby
page = Philiprehberger::Pagination.paginate(items,
  strategy: :cursor,
  per_page: 10,
  secret: "my-secret-key"
)
# Cursors are signed with HMAC-SHA256
# Tampered cursors raise InvalidCursorError
```

## API

### `Pagination`

| Method | Description |
|--------|-------------|
| `.paginate(collection, strategy:, per_page:, cursor:, page:, max_per_page:, min_per_page:, secret:)` | Paginate a collection |

### `Page`

| Method | Description |
|--------|-------------|
| `#items` | Items on the current page |
| `#total` | Total number of items in the collection |
| `#next_cursor` | Cursor for the next page |
| `#prev_cursor` | Cursor for the previous page |
| `#has_next?` | Whether there is a next page |
| `#has_prev?` | Whether there is a previous page |
| `#links` | Hash of navigation cursors |
| `#metadata` | Hash with current_page, per_page, total_pages, total_count, offset |
| `#per_page` | Items per page |
| `#current_page` | Current page number (offset only) |
| `#offset` | Current offset (offset only) |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this package useful, consider giving it a star on GitHub — it helps motivate continued maintenance and development.

[![LinkedIn](https://img.shields.io/badge/Philip%20Rehberger-LinkedIn-0A66C2?logo=linkedin)](https://www.linkedin.com/in/philiprehberger)
[![More packages](https://img.shields.io/badge/more-open%20source%20packages-blue)](https://philiprehberger.com/open-source-packages)

## License

[MIT](LICENSE)
