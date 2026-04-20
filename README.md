# philiprehberger-pagination

[![Tests](https://github.com/philiprehberger/rb-pagination/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pagination/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pagination.svg)](https://rubygems.org/gems/philiprehberger-pagination)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-pagination)](https://github.com/philiprehberger/rb-pagination/commits/main)

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
page.next_page    # => 4
page.prev_page    # => 2
page.page_range   # => 1..5
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
page.total_pages   # => 5
page.first_page?   # => false
page.last_page?    # => false
```

### Hash & JSON Serialization

```ruby
page = Philiprehberger::Pagination.paginate(items, strategy: :offset, per_page: 10, page: 2)
page.to_h
# => {
#   items: [...],
#   metadata: { current_page: 2, per_page: 10, total_pages: 5, total_count: 50, offset: 10 },
#   links: { next: "3", prev: "1" }
# }

page.to_json
# => '{"items":[...],"metadata":{...},"links":{...}}'

# Formatting options are forwarded to JSON.generate
page.to_json(indent: "  ", space: " ", object_nl: "\n")
```

### Iteration

```ruby
page = Philiprehberger::Pagination.paginate(items, strategy: :offset, per_page: 10)
page.size              # => 10
page.empty?            # => false
page.each { |item| puts item }
page.map { |item| item.name }  # Enumerable methods work directly on the page
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
| `#first_page?` | Whether this is the first page |
| `#last_page?` | Whether this is the last page |
| `#next_page` | Next page number (offset only) |
| `#prev_page` | Previous page number (offset only) |
| `#page_range` | Range of all page numbers, e.g. `1..5` |
| `#total_pages` | Ceiling division of total by per_page |
| `#links` | Hash of navigation cursors |
| `#metadata` | Hash with current_page, per_page, total_pages, total_count, offset |
| `#to_h` | Hash with items, metadata, and links (JSON-ready) |
| `#to_json(*args)` | JSON string of the page; extra args forwarded to `JSON.generate` |
| `#size` / `#length` / `#count` | Number of items on this page |
| `#empty?` | Whether the page has no items |
| `#each` | Iterate over items (includes `Enumerable`) |
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

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-pagination)

🐛 [Report issues](https://github.com/philiprehberger/rb-pagination/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-pagination/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
