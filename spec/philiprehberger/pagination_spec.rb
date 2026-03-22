# frozen_string_literal: true

require 'spec_helper'
require 'base64'

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
  end
end
