# frozen_string_literal: true

require_relative 'pagination/version'
require_relative 'pagination/page'
require 'base64'
require 'openssl'

module Philiprehberger
  module Pagination
    class Error < StandardError; end
    class InvalidPageSizeError < Error; end
    class InvalidCursorError < Error; end

    DEFAULT_PER_PAGE = 25

    # Paginate a collection using the specified strategy.
    #
    # @param collection [Array, #to_a] the collection to paginate
    # @param strategy [Symbol] :offset, :cursor, or :keyset
    # @param per_page [Integer] items per page
    # @param cursor [String, nil] cursor for cursor-based pagination
    # @param page [Integer, nil] page number for offset-based pagination
    # @param max_per_page [Integer, nil] maximum allowed per_page value
    # @param min_per_page [Integer, nil] minimum allowed per_page value
    # @param secret [String, nil] HMAC secret for cursor signing (cursor/keyset strategies)
    # @return [Page] the paginated result
    # @raise [Error] if strategy is invalid
    # @raise [InvalidPageSizeError] if per_page is out of bounds
    # @raise [InvalidCursorError] if cursor signature is invalid
    def self.paginate(collection, strategy: :offset, per_page: DEFAULT_PER_PAGE, cursor: nil, page: nil,
                      max_per_page: nil, min_per_page: nil, secret: nil)
      per_page = per_page.to_i
      validate_page_size!(per_page, min_per_page: min_per_page, max_per_page: max_per_page)
      per_page = [per_page, 1].max

      items = collection.to_a

      case strategy.to_sym
      when :offset
        paginate_offset(items, per_page: per_page, page: page)
      when :cursor
        paginate_cursor(items, per_page: per_page, cursor: cursor, secret: secret)
      when :keyset
        paginate_keyset(items, per_page: per_page, cursor: cursor, secret: secret)
      else
        raise Error, "unknown strategy: #{strategy}"
      end
    end

    # Iterate every page of a collection in order, yielding each {Page}.
    #
    # Drives {.paginate} repeatedly using the previous page's `next_cursor`
    # (or next page number for offset strategy) until there are no further
    # pages. Returns an Enumerator if no block is given. Useful for
    # batch-processing idioms (export, ETL, slow report generation) where
    # callers would otherwise have to thread cursors by hand.
    #
    # @param collection [Array, #to_a] the collection to paginate
    # @param strategy [Symbol] :offset, :cursor, or :keyset
    # @param per_page [Integer] items per page
    # @param opts [Hash] additional keyword args forwarded to {.paginate}
    # @yield [page] each {Page} in order
    # @return [Enumerator, nil]
    def self.each_page(collection, strategy: :offset, per_page: DEFAULT_PER_PAGE, **opts)
      unless block_given?
        return to_enum(:each_page, collection, strategy: strategy, per_page: per_page, **opts)
      end

      first_args = opts.dup
      page = paginate(collection, strategy: strategy, per_page: per_page, **first_args)
      yield page

      while page.has_next?
        loop_args = opts.dup
        if strategy.to_sym == :offset
          loop_args[:page] = page.current_page + 1
        else
          loop_args[:cursor] = page.next_cursor
        end
        page = paginate(collection, strategy: strategy, per_page: per_page, **loop_args)
        yield page
      end

      nil
    end

    # Validate per_page against min/max bounds.
    #
    # @param per_page [Integer] the requested page size
    # @param min_per_page [Integer, nil] minimum bound
    # @param max_per_page [Integer, nil] maximum bound
    # @raise [InvalidPageSizeError] if out of bounds
    def self.validate_page_size!(per_page, min_per_page:, max_per_page:)
      if min_per_page && per_page < min_per_page
        raise InvalidPageSizeError, "per_page #{per_page} is below minimum #{min_per_page}"
      end

      return unless max_per_page && per_page > max_per_page

      raise InvalidPageSizeError, "per_page #{per_page} exceeds maximum #{max_per_page}"
    end
    private_class_method :validate_page_size!

    # Sign a cursor value with HMAC-SHA256.
    #
    # @param data [String] the cursor data
    # @param secret [String] the HMAC secret
    # @return [String] signed cursor in format "Base64(data)--HMAC(data)"
    def self.sign_cursor(data, secret)
      encoded = Base64.strict_encode64(data)
      hmac = OpenSSL::HMAC.hexdigest('SHA256', secret, encoded)
      "#{encoded}--#{hmac}"
    end
    private_class_method :sign_cursor

    # Verify and decode a signed cursor.
    #
    # @param cursor [String] the signed cursor
    # @param secret [String] the HMAC secret
    # @return [String] the decoded cursor data
    # @raise [InvalidCursorError] if the cursor is invalid or tampered
    def self.verify_cursor(cursor, secret)
      parts = cursor.split('--', 2)
      raise InvalidCursorError, 'invalid cursor format' unless parts.length == 2

      encoded, hmac = parts
      expected_hmac = OpenSSL::HMAC.hexdigest('SHA256', secret, encoded)

      unless secure_compare(expected_hmac, hmac)
        raise InvalidCursorError, 'invalid cursor signature'
      end

      Base64.strict_decode64(encoded)
    rescue ArgumentError
      raise InvalidCursorError, 'invalid cursor encoding'
    end
    private_class_method :verify_cursor

    # Constant-time string comparison to prevent timing attacks.
    #
    # @param a [String] first string
    # @param b [String] second string
    # @return [Boolean] whether the strings are equal
    def self.secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      OpenSSL.fixed_length_secure_compare(a, b)
    end
    private_class_method :secure_compare

    # Encode a cursor, optionally signing it.
    #
    # @param value [String] the value to encode
    # @param secret [String, nil] optional HMAC secret
    # @return [String] the encoded (and optionally signed) cursor
    def self.encode_cursor(value, secret)
      if secret
        sign_cursor(value, secret)
      else
        Base64.strict_encode64(value)
      end
    end
    private_class_method :encode_cursor

    # Decode a cursor, optionally verifying its signature.
    #
    # @param cursor [String] the cursor to decode
    # @param secret [String, nil] optional HMAC secret
    # @return [String] the decoded value
    # @raise [InvalidCursorError] if signed cursor is invalid
    def self.decode_cursor(cursor, secret)
      if secret
        verify_cursor(cursor, secret)
      else
        Base64.strict_decode64(cursor)
      end
    rescue ArgumentError
      raise InvalidCursorError, 'invalid cursor encoding'
    end
    private_class_method :decode_cursor

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
        prev_cursor: has_prev ? (current_page - 1).to_s : nil,
        per_page: per_page,
        current_page: current_page,
        offset: offset
      )
    end
    private_class_method :paginate_offset

    # Cursor-based pagination using Base64-encoded index.
    #
    # @param items [Array] all items
    # @param per_page [Integer] items per page
    # @param cursor [String, nil] Base64-encoded cursor
    # @param secret [String, nil] HMAC secret for cursor signing
    # @return [Page]
    def self.paginate_cursor(items, per_page:, cursor:, secret: nil)
      start_index = if cursor
                      decode_cursor(cursor, secret).to_i
                    else
                      0
                    end
      start_index = [start_index, 0].max
      total = items.length
      page_items = items[start_index, per_page] || []

      end_index = start_index + page_items.length
      has_next = end_index < total
      has_prev = start_index.positive?

      Page.new(
        items: page_items,
        total: total,
        next_cursor: has_next ? encode_cursor(end_index.to_s, secret) : nil,
        prev_cursor: has_prev ? encode_cursor([start_index - per_page, 0].max.to_s, secret) : nil,
        per_page: per_page
      )
    end
    private_class_method :paginate_cursor

    # Keyset-based pagination (assumes items are sorted, uses last item as cursor).
    #
    # @param items [Array] all items (must be sorted)
    # @param per_page [Integer] items per page
    # @param cursor [String, nil] Base64-encoded cursor value
    # @param secret [String, nil] HMAC secret for cursor signing
    # @return [Page]
    def self.paginate_keyset(items, per_page:, cursor:, secret: nil)
      if cursor
        decoded = decode_cursor(cursor, secret).to_i
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
                      encode_cursor(val.to_s, secret)
                    end

      prev_cursor = cursor

      Page.new(
        items: page_items,
        total: total,
        next_cursor: next_cursor,
        prev_cursor: prev_cursor,
        per_page: per_page
      )
    end
    private_class_method :paginate_keyset
  end
end
