# frozen_string_literal: true

module Philiprehberger
  module Pagination
    # Represents a page of results from pagination.
    #
    # @attr_reader items [Array] the items on this page
    # @attr_reader total [Integer, nil] total number of items
    # @attr_reader next_cursor [String, nil] cursor for the next page
    # @attr_reader prev_cursor [String, nil] cursor for the previous page
    # @attr_reader per_page [Integer, nil] items per page
    # @attr_reader current_page [Integer, nil] current page number (offset only)
    # @attr_reader offset [Integer, nil] current offset (offset only)
    class Page
      include Enumerable

      attr_reader :items, :total, :next_cursor, :prev_cursor, :per_page, :current_page, :offset

      # Create a new page result.
      #
      # @param items [Array] the items on this page
      # @param total [Integer, nil] total number of items
      # @param next_cursor [String, nil] cursor for the next page
      # @param prev_cursor [String, nil] cursor for the previous page
      # @param per_page [Integer, nil] items per page
      # @param current_page [Integer, nil] current page number
      # @param offset [Integer, nil] current offset
      def initialize(items:, total: nil, next_cursor: nil, prev_cursor: nil, per_page: nil, current_page: nil,
                     offset: nil)
        @items = items
        @total = total
        @next_cursor = next_cursor
        @prev_cursor = prev_cursor
        @per_page = per_page
        @current_page = current_page
        @offset = offset
      end

      # Whether there is a next page.
      #
      # @return [Boolean]
      def has_next?
        !@next_cursor.nil?
      end

      # Whether there is a previous page.
      #
      # @return [Boolean]
      def has_prev?
        !@prev_cursor.nil?
      end

      # Whether this is the first page.
      #
      # For offset strategy, returns true when current_page is 1. For cursor/keyset
      # strategies, returns true when there is no previous cursor.
      #
      # @return [Boolean]
      def first_page?
        return @current_page == 1 if @current_page

        !has_prev?
      end

      # Whether this is the last page.
      #
      # Returns true when there is no next cursor.
      #
      # @return [Boolean]
      def last_page?
        !has_next?
      end

      # Total number of pages when both total and per_page are known.
      #
      # @return [Integer, nil] total page count or nil if indeterminate
      def total_pages
        return nil unless @total && @per_page&.positive?

        (@total / @per_page.to_f).ceil
      end

      # Next page number for offset strategy.
      #
      # @return [Integer, nil] the next page number or nil if none
      def next_page
        return nil unless @current_page && has_next?

        @current_page + 1
      end

      # Previous page number for offset strategy.
      #
      # @return [Integer, nil] the previous page number or nil if none
      def prev_page
        return nil unless @current_page && has_prev?

        @current_page - 1
      end

      # Range of all page numbers for offset strategy.
      #
      # @return [Range, nil] 1..total_pages, or nil if total_pages is unknown
      def page_range
        pages = total_pages
        return nil unless pages

        1..pages
      end

      # Number of items on this page.
      #
      # @return [Integer]
      def size
        @items.length
      end
      alias length size
      alias count size

      # Whether this page has no items.
      #
      # @return [Boolean]
      def empty?
        @items.empty?
      end

      # Iterate over items on this page.
      #
      # @yield [item] each item on the page
      # @return [Enumerator] if no block given
      def each(&block)
        return @items.each unless block

        @items.each(&block)
        self
      end

      # Navigation links as a hash.
      #
      # @return [Hash<Symbol, String>] links with :next and :prev keys
      def links
        result = {}
        result[:next] = @next_cursor if @next_cursor
        result[:prev] = @prev_cursor if @prev_cursor
        result
      end

      # Page metadata as a hash.
      #
      # @return [Hash] metadata including current_page, per_page, total_pages, total_count, offset
      def metadata
        {
          current_page: @current_page,
          per_page: @per_page,
          total_pages: total_pages,
          total_count: @total,
          offset: @offset
        }
      end

      # Full page representation as a hash suitable for JSON serialization.
      #
      # Combines items, metadata, and navigation links in a single hash.
      #
      # @return [Hash] hash with :items, :metadata, and :links keys
      def to_h
        {
          items: @items,
          metadata: metadata,
          links: links
        }
      end

      # Serialize the page to a JSON string.
      #
      # Equivalent to calling `JSON.generate(page.to_h, *args)` — trailing
      # arguments are forwarded to `JSON.generate` for formatting options
      # (e.g. pretty-printing). Loading `json` is deferred until first use
      # so this gem remains zero-dependency.
      #
      # @return [String] JSON-encoded representation
      def to_json(*args)
        require 'json' unless defined?(::JSON)
        ::JSON.generate(to_h, *args)
      end
    end
  end
end
