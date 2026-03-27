# frozen_string_literal: true

require_relative 'pagination/version'
require_relative 'pagination/page'
require 'base64'

module Philiprehberger
  module Pagination
    class Error < StandardError; end

    DEFAULT_PER_PAGE = 25

    # Paginate a collection using the specified strategy.
    #
    # @param collection [Array, #to_a] the collection to paginate
    # @param strategy [Symbol] :offset, :cursor, or :keyset
    # @param per_page [Integer] items per page
    # @param cursor [String, nil] cursor for cursor-based pagination
    # @param page [Integer, nil] page number for offset-based pagination
    # @return [Page] the paginated result
    # @raise [Error] if strategy is invalid
    def self.paginate(collection, strategy: :offset, per_page: DEFAULT_PER_PAGE, cursor: nil, page: nil)
      items = collection.to_a
      per_page = [per_page.to_i, 1].max

      case strategy.to_sym
      when :offset
        paginate_offset(items, per_page: per_page, page: page)
      when :cursor
        paginate_cursor(items, per_page: per_page, cursor: cursor)
      when :keyset
        paginate_keyset(items, per_page: per_page, cursor: cursor)
      else
        raise Error, "unknown strategy: #{strategy}"
      end
    end

    # Offset-based pagination.
    #
    # @param items [Array] all items
    # @param per_page [Integer] items per page
    # @param page [Integer, nil] page number (1-based)
    # @return [Page]
    def self.paginate_offset(items, per_page:, page:)
      current_page = [page.to_i, 1].max
      offset = (current_page - 1) * per_page
      total = items.length
      page_items = items[offset, per_page] || []

      has_next = (offset + per_page) < total
      has_prev = current_page > 1

      Page.new(
        items: page_items,
        total: total,
        next_cursor: has_next ? (current_page + 1).to_s : nil,
        prev_cursor: has_prev ? (current_page - 1).to_s : nil
      )
    end
    private_class_method :paginate_offset

    # Cursor-based pagination using Base64-encoded index.
    #
    # @param items [Array] all items
    # @param per_page [Integer] items per page
    # @param cursor [String, nil] Base64-encoded cursor
    # @return [Page]
    def self.paginate_cursor(items, per_page:, cursor:)
      start_index = cursor ? Base64.strict_decode64(cursor).to_i : 0
      start_index = [start_index, 0].max
      total = items.length
      page_items = items[start_index, per_page] || []

      end_index = start_index + page_items.length
      has_next = end_index < total
      has_prev = start_index.positive?

      Page.new(
        items: page_items,
        total: total,
        next_cursor: has_next ? Base64.strict_encode64(end_index.to_s) : nil,
        prev_cursor: has_prev ? Base64.strict_encode64([start_index - per_page, 0].max.to_s) : nil
      )
    end
    private_class_method :paginate_cursor

    # Keyset-based pagination (assumes items are sorted, uses last item as cursor).
    #
    # @param items [Array] all items (must be sorted)
    # @param per_page [Integer] items per page
    # @param cursor [String, nil] Base64-encoded cursor value
    # @return [Page]
    def self.paginate_keyset(items, per_page:, cursor:)
      if cursor
        decoded = Base64.strict_decode64(cursor).to_i
        start_index = items.index { |item| item.respond_to?(:id) ? item.id > decoded : item > decoded } || items.length
      else
        start_index = 0
      end

      total = items.length
      page_items = items[start_index, per_page] || []
      end_index = start_index + page_items.length
      has_next = end_index < total

      last_item = page_items.last
      next_cursor = if has_next && last_item
                      val = last_item.respond_to?(:id) ? last_item.id : last_item
                      Base64.strict_encode64(val.to_s)
                    end

      prev_cursor = cursor

      Page.new(
        items: page_items,
        total: total,
        next_cursor: next_cursor,
        prev_cursor: prev_cursor
      )
    end
    private_class_method :paginate_keyset
  end
end
