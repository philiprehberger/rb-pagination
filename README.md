# philiprehberger-pagination

[![Tests](https://github.com/philiprehberger/rb-pagination/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pagination/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pagination.svg)](https://rubygems.org/gems/philiprehberger-pagination)
[![License](https://img.shields.io/github/license/philiprehberger/rb-pagination)](LICENSE)
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

### Navigation Links

```ruby
page.links  # => { next: "cursor_value", prev: "cursor_value" }
```

## API

### `Pagination`

| Method | Description |
|--------|-------------|
| `.paginate(collection, strategy:, per_page:, cursor:, page:)` | Paginate a collection |

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

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
