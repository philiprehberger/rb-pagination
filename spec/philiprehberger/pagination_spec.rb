# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'openssl'

RSpec.describe Philiprehberger::Pagination do
  let(:items) { (1..50).to_a }

  describe 'VERSION' do
    it 'has a version number' do
      expect(Philiprehberger::Pagination::VERSION).not_to be_nil
    end
  end

  describe '.paginate' do
    it 'raises on unknown strategy' do
      expect { described_class.paginate(items, strategy: :unknown) }.to raise_error(Philiprehberger::Pagination::Error)
    end
  end

  describe 'offset strategy' do
    it 'returns the first page by default' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10)
      expect(page.items).to eq((1..10).to_a)
      expect(page.total).to eq(50)
    end

    it 'returns a specific page' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10, page: 3)
      expect(page.items).to eq((21..30).to_a)
    end

    it 'reports has_next? correctly' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10, page: 1)
      expect(page.has_next?).to be true

      last_page = described_class.paginate(items, strategy: :offset, per_page: 10, page: 5)
      expect(last_page.has_next?).to be false
    end

    it 'reports has_prev? correctly' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10, page: 1)
      expect(page.has_prev?).to be false

      page2 = described_class.paginate(items, strategy: :offset, per_page: 10, page: 2)
      expect(page2.has_prev?).to be true
    end

    it 'provides next and prev cursors as page numbers' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10, page: 3)
      expect(page.next_cursor).to eq('4')
      expect(page.prev_cursor).to eq('2')
    end

    it 'returns empty items for out-of-range page' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10, page: 100)
      expect(page.items).to eq([])
    end

    it 'provides links hash' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10, page: 3)
      expect(page.links).to eq({ next: '4', prev: '2' })
    end

    it 'handles per_page of zero' do
      page = described_class.paginate(items, strategy: :offset, per_page: 0)
      expect(page.items.length).to eq(1)
    end

    it 'sets current_page and offset on the page' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10, page: 3)
      expect(page.current_page).to eq(3)
      expect(page.offset).to eq(20)
      expect(page.per_page).to eq(10)
    end
  end

  describe 'cursor strategy' do
    it 'returns the first page without cursor' do
      page = described_class.paginate(items, strategy: :cursor, per_page: 10)
      expect(page.items).to eq((1..10).to_a)
      expect(page.has_next?).to be true
      expect(page.has_prev?).to be false
    end

    it 'paginates with cursor' do
      cursor = Base64.strict_encode64('10')
      page = described_class.paginate(items, strategy: :cursor, per_page: 10, cursor: cursor)
      expect(page.items).to eq((11..20).to_a)
      expect(page.has_next?).to be true
      expect(page.has_prev?).to be true
    end

    it 'returns empty on exhausted cursor' do
      cursor = Base64.strict_encode64('50')
      page = described_class.paginate(items, strategy: :cursor, per_page: 10, cursor: cursor)
      expect(page.items).to eq([])
      expect(page.has_next?).to be false
    end

    it 'includes total count' do
      page = described_class.paginate(items, strategy: :cursor, per_page: 10)
      expect(page.total).to eq(50)
    end

    it 'does not set current_page or offset for cursor strategy' do
      page = described_class.paginate(items, strategy: :cursor, per_page: 10)
      expect(page.current_page).to be_nil
      expect(page.offset).to be_nil
      expect(page.per_page).to eq(10)
    end
  end

  describe 'keyset strategy' do
    it 'returns the first page without cursor' do
      page = described_class.paginate(items, strategy: :keyset, per_page: 10)
      expect(page.items).to eq((1..10).to_a)
      expect(page.has_next?).to be true
    end

    it 'paginates with cursor' do
      cursor = Base64.strict_encode64('10')
      page = described_class.paginate(items, strategy: :keyset, per_page: 10, cursor: cursor)
      expect(page.items).to eq((11..20).to_a)
    end

    it 'returns last page correctly' do
      cursor = Base64.strict_encode64('40')
      page = described_class.paginate(items, strategy: :keyset, per_page: 10, cursor: cursor)
      expect(page.items).to eq((41..50).to_a)
      expect(page.has_next?).to be false
    end

    it 'does not set current_page or offset for keyset strategy' do
      page = described_class.paginate(items, strategy: :keyset, per_page: 10)
      expect(page.current_page).to be_nil
      expect(page.offset).to be_nil
      expect(page.per_page).to eq(10)
    end
  end

  describe 'page edge cases' do
    it 'handles negative page number as page 1' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10, page: -5)
      expect(page.items).to eq((1..10).to_a)
    end
  end

  describe 'total pages calculation' do
    it 'calculates total pages for exact division' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10)
      total_pages = (page.total.to_f / 10).ceil
      expect(total_pages).to eq(5)
    end

    it 'calculates total pages for non-exact division' do
      page = described_class.paginate(items, strategy: :offset, per_page: 7)
      total_pages = (page.total.to_f / 7).ceil
      expect(total_pages).to eq(8)
    end
  end

  describe 'offset calculation' do
    it 'returns correct offset items for page 2 with per_page 5' do
      page = described_class.paginate(items, strategy: :offset, per_page: 5, page: 2)
      expect(page.items).to eq([6, 7, 8, 9, 10])
    end

    it 'returns correct offset items for last partial page' do
      small = (1..13).to_a
      page = described_class.paginate(small, strategy: :offset, per_page: 5, page: 3)
      expect(page.items).to eq([11, 12, 13])
    end
  end

  describe 'per_page edge cases' do
    it 'treats per_page of 1 as single-item pages' do
      page = described_class.paginate(items, strategy: :offset, per_page: 1, page: 1)
      expect(page.items).to eq([1])
      expect(page.has_next?).to be true
    end

    it 'treats very large per_page as single page' do
      page = described_class.paginate(items, strategy: :offset, per_page: 1000)
      expect(page.items).to eq(items)
      expect(page.has_next?).to be false
    end
  end

  describe 'empty collection' do
    it 'returns empty page for empty collection' do
      page = described_class.paginate([], strategy: :offset, per_page: 10)
      expect(page.items).to eq([])
      expect(page.total).to eq(0)
      expect(page.has_next?).to be false
      expect(page.has_prev?).to be false
    end

    it 'returns empty page for empty collection with cursor strategy' do
      page = described_class.paginate([], strategy: :cursor, per_page: 10)
      expect(page.items).to eq([])
      expect(page.total).to eq(0)
    end
  end

  describe 'single item collection' do
    it 'paginates a single item' do
      page = described_class.paginate([42], strategy: :offset, per_page: 10)
      expect(page.items).to eq([42])
      expect(page.total).to eq(1)
      expect(page.has_next?).to be false
      expect(page.has_prev?).to be false
    end
  end

  describe 'page metadata' do
    it 'returns metadata hash for offset pagination' do
      page = described_class.paginate(items, strategy: :offset, per_page: 10, page: 2)
      meta = page.metadata
      expect(meta[:current_page]).to eq(2)
      expect(meta[:per_page]).to eq(10)
      expect(meta[:total_pages]).to eq(5)
      expect(meta[:total_count]).to eq(50)
      expect(meta[:offset]).to eq(10)
    end

    it 'returns nil current_page and offset for cursor pagination' do
      page = described_class.paginate(items, strategy: :cursor, per_page: 10)
      meta = page.metadata
      expect(meta[:current_page]).to be_nil
      expect(meta[:per_page]).to eq(10)
      expect(meta[:total_pages]).to eq(5)
      expect(meta[:total_count]).to eq(50)
      expect(meta[:offset]).to be_nil
    end

    it 'returns nil current_page and offset for keyset pagination' do
      page = described_class.paginate(items, strategy: :keyset, per_page: 10)
      meta = page.metadata
      expect(meta[:current_page]).to be_nil
      expect(meta[:offset]).to be_nil
      expect(meta[:total_pages]).to eq(5)
    end

    it 'calculates total_pages with ceiling division' do
      page = described_class.paginate((1..13).to_a, strategy: :offset, per_page: 5)
      expect(page.metadata[:total_pages]).to eq(3)
    end

    it 'returns total_pages as nil when total is nil' do
      page = Philiprehberger::Pagination::Page.new(items: [1, 2], per_page: 10)
      expect(page.metadata[:total_pages]).to be_nil
    end

    it 'returns total_pages as nil when per_page is nil' do
      page = Philiprehberger::Pagination::Page.new(items: [1, 2], total: 10)
      expect(page.metadata[:total_pages]).to be_nil
    end
  end

  describe 'page size limits' do
    it 'allows per_page within bounds' do
      page = described_class.paginate(items, per_page: 10, min_per_page: 1, max_per_page: 100)
      expect(page.items.length).to eq(10)
    end

    it 'raises InvalidPageSizeError when per_page exceeds max' do
      expect do
        described_class.paginate(items, per_page: 200, max_per_page: 100)
      end.to raise_error(Philiprehberger::Pagination::InvalidPageSizeError, /exceeds maximum 100/)
    end

    it 'raises InvalidPageSizeError when per_page is below min' do
      expect do
        described_class.paginate(items, per_page: 0, min_per_page: 1)
      end.to raise_error(Philiprehberger::Pagination::InvalidPageSizeError, /below minimum 1/)
    end

    it 'does not enforce limits when max_per_page is nil' do
      page = described_class.paginate(items, per_page: 1000)
      expect(page.items).to eq(items)
    end

    it 'does not enforce limits when min_per_page is nil' do
      page = described_class.paginate(items, per_page: 0)
      expect(page.items.length).to eq(1)
    end

    it 'inherits from Error' do
      expect(Philiprehberger::Pagination::InvalidPageSizeError).to be < Philiprehberger::Pagination::Error
    end

    it 'raises when per_page equals max boundary' do
      page = described_class.paginate(items, per_page: 100, max_per_page: 100)
      expect(page.per_page).to eq(100)
    end

    it 'raises when per_page equals min boundary' do
      page = described_class.paginate(items, per_page: 5, min_per_page: 5)
      expect(page.per_page).to eq(5)
    end

    it 'works with both min and max set' do
      expect do
        described_class.paginate(items, per_page: 200, min_per_page: 5, max_per_page: 100)
      end.to raise_error(Philiprehberger::Pagination::InvalidPageSizeError)

      expect do
        described_class.paginate(items, per_page: 2, min_per_page: 5, max_per_page: 100)
      end.to raise_error(Philiprehberger::Pagination::InvalidPageSizeError)
    end
  end

  describe 'cursor encryption' do
    let(:secret) { 'my-secret-key' }

    context 'with cursor strategy' do
      it 'returns signed cursors when secret is provided' do
        page = described_class.paginate(items, strategy: :cursor, per_page: 10, secret: secret)
        expect(page.next_cursor).to include('--')
      end

      it 'paginates correctly with signed cursors' do
        page1 = described_class.paginate(items, strategy: :cursor, per_page: 10, secret: secret)
        page2 = described_class.paginate(items, strategy: :cursor, per_page: 10, cursor: page1.next_cursor,
                                                secret: secret)
        expect(page2.items).to eq((11..20).to_a)
      end

      it 'raises InvalidCursorError for tampered cursor' do
        page = described_class.paginate(items, strategy: :cursor, per_page: 10, secret: secret)
        tampered = "#{page.next_cursor}tampered"
        expect do
          described_class.paginate(items, strategy: :cursor, per_page: 10, cursor: tampered, secret: secret)
        end.to raise_error(Philiprehberger::Pagination::InvalidCursorError)
      end

      it 'raises InvalidCursorError for cursor signed with different secret' do
        page = described_class.paginate(items, strategy: :cursor, per_page: 10, secret: 'key-a')
        expect do
          described_class.paginate(items, strategy: :cursor, per_page: 10, cursor: page.next_cursor, secret: 'key-b')
        end.to raise_error(Philiprehberger::Pagination::InvalidCursorError)
      end

      it 'raises InvalidCursorError for malformed cursor' do
        expect do
          described_class.paginate(items, strategy: :cursor, per_page: 10, cursor: 'not-valid', secret: secret)
        end.to raise_error(Philiprehberger::Pagination::InvalidCursorError)
      end

      it 'works without secret (backward compatible)' do
        page = described_class.paginate(items, strategy: :cursor, per_page: 10)
        expect(page.next_cursor).not_to include('--')
        page2 = described_class.paginate(items, strategy: :cursor, per_page: 10, cursor: page.next_cursor)
        expect(page2.items).to eq((11..20).to_a)
      end

      it 'can traverse all pages with signed cursors' do
        all_items = []
        cursor = nil
        loop do
          page = described_class.paginate(items, strategy: :cursor, per_page: 10, cursor: cursor, secret: secret)
          all_items.concat(page.items)
          break unless page.has_next?

          cursor = page.next_cursor
        end
        expect(all_items).to eq(items)
      end
    end

    context 'with keyset strategy' do
      it 'returns signed cursors when secret is provided' do
        page = described_class.paginate(items, strategy: :keyset, per_page: 10, secret: secret)
        expect(page.next_cursor).to include('--')
      end

      it 'paginates correctly with signed cursors' do
        page1 = described_class.paginate(items, strategy: :keyset, per_page: 10, secret: secret)
        page2 = described_class.paginate(items, strategy: :keyset, per_page: 10, cursor: page1.next_cursor,
                                                secret: secret)
        expect(page2.items).to eq((11..20).to_a)
      end

      it 'raises InvalidCursorError for tampered keyset cursor' do
        page = described_class.paginate(items, strategy: :keyset, per_page: 10, secret: secret)
        tampered = page.next_cursor.sub(/--.*$/, '--badhash')
        expect do
          described_class.paginate(items, strategy: :keyset, per_page: 10, cursor: tampered, secret: secret)
        end.to raise_error(Philiprehberger::Pagination::InvalidCursorError)
      end
    end

    it 'InvalidCursorError inherits from Error' do
      expect(Philiprehberger::Pagination::InvalidCursorError).to be < Philiprehberger::Pagination::Error
    end

    it 'raises InvalidCursorError for cursor without separator when secret given' do
      expect do
        described_class.paginate(items, strategy: :cursor, per_page: 10,
                                        cursor: Base64.strict_encode64('10'), secret: secret)
      end.to raise_error(Philiprehberger::Pagination::InvalidCursorError)
    end
  end

  describe Philiprehberger::Pagination::Page do
    it 'stores items and metadata' do
      page = described_class.new(items: [1, 2, 3], total: 10, next_cursor: 'abc', prev_cursor: 'def')
      expect(page.items).to eq([1, 2, 3])
      expect(page.total).to eq(10)
      expect(page.next_cursor).to eq('abc')
      expect(page.prev_cursor).to eq('def')
    end

    it 'has_next? returns false when no next cursor' do
      page = described_class.new(items: [1], total: 1)
      expect(page.has_next?).to be false
    end

    it 'has_prev? returns false when no prev cursor' do
      page = described_class.new(items: [1], total: 1)
      expect(page.has_prev?).to be false
    end

    it 'returns empty links when no cursors' do
      page = described_class.new(items: [1], total: 1)
      expect(page.links).to eq({})
    end

    it 'returns only next link on first page' do
      page = described_class.new(items: [1], total: 10, next_cursor: '2')
      expect(page.links).to eq({ next: '2' })
    end

    it 'returns only prev link on last page' do
      page = described_class.new(items: [1], total: 10, prev_cursor: '4')
      expect(page.links).to eq({ prev: '4' })
    end

    it 'defaults total to nil' do
      page = described_class.new(items: [1])
      expect(page.total).to be_nil
    end

    it 'stores per_page, current_page, and offset' do
      page = described_class.new(items: [1], total: 10, per_page: 5, current_page: 2, offset: 5)
      expect(page.per_page).to eq(5)
      expect(page.current_page).to eq(2)
      expect(page.offset).to eq(5)
    end

    it 'returns complete metadata hash' do
      page = described_class.new(items: [1], total: 50, per_page: 10, current_page: 3, offset: 20)
      expect(page.metadata).to eq({
                                    current_page: 3,
                                    per_page: 10,
                                    total_pages: 5,
                                    total_count: 50,
                                    offset: 20
                                  })
    end

    it 'returns metadata with nil total_pages when total is nil' do
      page = described_class.new(items: [1], per_page: 10)
      expect(page.metadata[:total_pages]).to be_nil
    end

    describe '#to_h' do
      it 'returns a hash with items, metadata, and links' do
        page = described_class.new(items: [1, 2, 3], total: 50, per_page: 10, current_page: 2,
                                   offset: 10, next_cursor: '3', prev_cursor: '1')
        hash = page.to_h
        expect(hash[:items]).to eq([1, 2, 3])
        expect(hash[:metadata][:current_page]).to eq(2)
        expect(hash[:metadata][:total_pages]).to eq(5)
        expect(hash[:links]).to eq({ next: '3', prev: '1' })
      end

      it 'returns empty links hash when no cursors present' do
        page = described_class.new(items: [1], total: 1)
        expect(page.to_h[:links]).to eq({})
      end
    end

    describe '#total_pages' do
      it 'returns ceiling division of total by per_page' do
        page = described_class.new(items: [1], total: 50, per_page: 10)
        expect(page.total_pages).to eq(5)
      end

      it 'returns nil when total is nil' do
        page = described_class.new(items: [1], per_page: 10)
        expect(page.total_pages).to be_nil
      end

      it 'returns nil when per_page is nil' do
        page = described_class.new(items: [1], total: 10)
        expect(page.total_pages).to be_nil
      end

      it 'returns nil when per_page is zero' do
        page = described_class.new(items: [1], total: 10, per_page: 0)
        expect(page.total_pages).to be_nil
      end
    end

    describe '#next_page / #prev_page' do
      it 'returns the next page number for offset strategy' do
        page = described_class.new(items: [1], total: 50, per_page: 10, current_page: 2, next_cursor: '3',
                                   prev_cursor: '1')
        expect(page.next_page).to eq(3)
        expect(page.prev_page).to eq(1)
      end

      it 'returns nil for next_page when there is no next' do
        page = described_class.new(items: [1], total: 10, per_page: 10, current_page: 1)
        expect(page.next_page).to be_nil
      end

      it 'returns nil for prev_page on the first page' do
        page = described_class.new(items: [1], total: 50, per_page: 10, current_page: 1, next_cursor: '2')
        expect(page.prev_page).to be_nil
      end

      it 'returns nil for cursor-strategy pages (no current_page)' do
        page = described_class.new(items: [1], next_cursor: 'abc')
        expect(page.next_page).to be_nil
        expect(page.prev_page).to be_nil
      end
    end

    describe '#page_range' do
      it 'returns 1..total_pages for offset strategy' do
        page = described_class.new(items: [1], total: 50, per_page: 10)
        expect(page.page_range).to eq(1..5)
      end

      it 'returns nil when total_pages is unknown' do
        page = described_class.new(items: [1])
        expect(page.page_range).to be_nil
      end

      it 'returns 1..1 when total equals per_page' do
        page = described_class.new(items: [1], total: 10, per_page: 10)
        expect(page.page_range).to eq(1..1)
      end
    end

    describe '#first_page? / #last_page?' do
      it 'identifies the first page by current_page' do
        page = described_class.new(items: [1], total: 50, per_page: 10, current_page: 1, next_cursor: '2')
        expect(page.first_page?).to be true
        expect(page.last_page?).to be false
      end

      it 'identifies the last page by absence of next_cursor' do
        page = described_class.new(items: [1], total: 50, per_page: 10, current_page: 5, prev_cursor: '4')
        expect(page.first_page?).to be false
        expect(page.last_page?).to be true
      end

      it 'treats cursor strategy without prev_cursor as first page' do
        page = described_class.new(items: [1], next_cursor: 'abc')
        expect(page.first_page?).to be true
        expect(page.last_page?).to be false
      end

      it 'reports last page for lone page with no cursors' do
        page = described_class.new(items: [1], total: 1)
        expect(page.first_page?).to be true
        expect(page.last_page?).to be true
      end
    end

    describe 'Enumerable behavior' do
      it 'exposes size, length, and count' do
        page = described_class.new(items: [1, 2, 3])
        expect(page.size).to eq(3)
        expect(page.length).to eq(3)
        expect(page.count).to eq(3)
      end

      it 'reports empty? correctly' do
        expect(described_class.new(items: []).empty?).to be true
        expect(described_class.new(items: [1]).empty?).to be false
      end

      it 'iterates items with each' do
        seen = described_class.new(items: [1, 2, 3]).map { |item| item }
        expect(seen).to eq([1, 2, 3])
      end

      it 'supports Enumerable methods like map and select' do
        page = described_class.new(items: [1, 2, 3, 4])
        expect(page.map { |item| item * 2 }).to eq([2, 4, 6, 8])
        expect(page.select(&:even?)).to eq([2, 4])
      end

      it 'returns an Enumerator from each when no block given' do
        page = described_class.new(items: [1, 2, 3])
        expect(page.each).to be_a(Enumerator)
        expect(page.each.to_a).to eq([1, 2, 3])
      end
    end
  end
end
