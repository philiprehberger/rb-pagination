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
        total_pages = if @total && @per_page && @per_page.positive?
                        (@total / @per_page.to_f).ceil
                      end

        {
          current_page: @current_page,
          per_page: @per_page,
          total_pages: total_pages,
          total_count: @total,
          offset: @offset
        }
      end
    end
  end
end
