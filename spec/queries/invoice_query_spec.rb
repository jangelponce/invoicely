require 'rails_helper'

RSpec.describe InvoiceQuery do
  let(:base_scope) { Invoice.all }

  let!(:invoice1) { create(:invoice, invoice_date: 3.days.ago.beginning_of_day, total: 1000.00, active: true) }
  let!(:invoice2) { create(:invoice, invoice_date: 2.days.ago.beginning_of_day, total: 1500.00, active: true) }
  let!(:invoice3) { create(:invoice, invoice_date: 1.day.ago.beginning_of_day, total: 800.00, active: false) }
  let!(:invoice4) { create(:invoice, invoice_date: Date.current.beginning_of_day, total: 2000.00, active: true) }
  let!(:invoice5) { create(:invoice, invoice_date: 1.day.from_now.beginning_of_day, total: 500.00, active: true) }

  describe '#initialize' do
    it 'accepts a scope and params' do
      query = described_class.new(Invoice.active, { page: 2 })
      expect(query.instance_variable_get(:@scope)).to eq(Invoice.active)
      expect(query.instance_variable_get(:@params)).to include(page: 2)
    end

    it 'uses Invoice.all as default scope' do
      query = described_class.new
      expect(query.instance_variable_get(:@scope)).to eq(Invoice.all)
    end

    it 'uses empty hash as default params' do
      query = described_class.new
      params = query.instance_variable_get(:@params)
      expect(params).to include(
        page: InvoiceQuery::DEFAULT_PAGE,
        per_page: InvoiceQuery::DEFAULT_PER_PAGE,
        sort: InvoiceQuery::DEFAULT_SORT_FIELD,
        direction: InvoiceQuery::DEFAULT_SORT_DIRECTION
      )
    end
  end

  describe '#call' do
    context 'with default parameters' do
      it 'returns all invoices with default sorting' do
        query = described_class.new
        result = query.call

        expect(result.count).to eq(5)
        expect(result.first).to eq(invoice5)
        expect(result.last).to eq(invoice1)
      end
    end

    context 'with date range filtering' do
      it 'filters by date range using date strings' do
        start_date = 2.days.ago.to_date.to_s
        end_date = Date.current.to_s

        query = described_class.new(base_scope, {
          start_range: start_date,
          end_range: end_date
        })
        result = query.call

        expect(result.count).to be >= 2
        expect(result).to include(invoice2)
        expect(result).not_to include(invoice1, invoice5)

        result_dates = result.map(&:invoice_date).map(&:to_date)
        expect(result_dates.all? { |date| date >= Date.parse(start_date) && date <= Date.parse(end_date) }).to be true
      end

      it 'filters by datetime range using datetime strings' do
        start_datetime = 2.days.ago.beginning_of_day.to_s
        end_datetime = 1.day.ago.end_of_day.to_s

        query = described_class.new(base_scope, {
          start_range: start_datetime,
          end_range: end_datetime
        })
        result = query.call

        expect(result.count).to eq(2)
        expect(result).to include(invoice2, invoice3)
        expect(result).not_to include(invoice1, invoice4, invoice5)
      end

      it 'handles single date filtering using datetime strings' do
        test_datetime = Date.parse('2023-06-15').beginning_of_day
        test_invoice = create(:invoice, invoice_date: test_datetime, total: 999.99, active: true)

        query = described_class.new(base_scope, {
          start_range: test_datetime.to_s,
          end_range: test_datetime.end_of_day.to_s
        })
        result = query.call

        expect(result).to include(test_invoice)

        result_dates = result.map(&:invoice_date).map(&:to_date).uniq
        expect(result_dates).to all(eq(test_datetime.to_date))
      end

      it 'returns all records when no date range is provided' do
        query = described_class.new(base_scope, {})
        result = query.call

        expect(result.count).to eq(5)
      end

      it 'returns all records when date range params are blank' do
        query = described_class.new(base_scope, {
          start_range: '',
          end_range: nil
        })
        result = query.call

        expect(result.count).to eq(5)
      end
    end

    context 'with pagination' do
      it 'paginates results with default per_page' do
        query = described_class.new(base_scope, { page: 1, per_page: 2 })
        result = query.call

        expect(result.count).to eq(2)
      end

      it 'handles different pages' do
        query_page1 = described_class.new(base_scope, { page: 1, per_page: 2 })
        query_page2 = described_class.new(base_scope, { page: 2, per_page: 2 })

        result_page1 = query_page1.call
        result_page2 = query_page2.call

        expect(result_page1.count).to eq(2)
        expect(result_page2.count).to eq(2)
        expect(result_page1.first).not_to eq(result_page2.first)
      end

      it 'uses default pagination when not specified' do
        query = described_class.new(base_scope)
        result = query.call

        expect(result.count).to eq(5)
      end

      it 'handles page beyond available records' do
        query = described_class.new(base_scope, { page: 10, per_page: 2 })
        result = query.call

        expect(result.count).to eq(0)
      end
    end

    context 'with sorting' do
      it 'sorts by total amount ascending' do
        query = described_class.new(base_scope, {
          sort: 'total',
          direction: 'asc'
        })
        result = query.call

        totals = result.map(&:total)
        expect(totals).to eq(totals.sort)
        expect(result.first).to eq(invoice5)
        expect(result.last).to eq(invoice4)
      end

      it 'sorts by total amount descending' do
        query = described_class.new(base_scope, {
          sort: 'total',
          direction: 'desc'
        })
        result = query.call

        totals = result.map(&:total)
        expect(totals).to eq(totals.sort.reverse)
        expect(result.first).to eq(invoice4)
        expect(result.last).to eq(invoice5)
      end

      it 'sorts by invoice_date ascending' do
        query = described_class.new(base_scope, {
          sort: 'invoice_date',
          direction: 'asc'
        })
        result = query.call

        dates = result.map(&:invoice_date)
        expect(dates).to eq(dates.sort)
        expect(result.first).to eq(invoice1)
        expect(result.last).to eq(invoice5)
      end

      it 'uses default sort when not specified' do
        query = described_class.new(base_scope)
        result = query.call

        dates = result.map(&:invoice_date)
        expect(dates).to eq(dates.sort.reverse)
      end
    end

    context 'with combined parameters' do
      it 'applies filtering, pagination, and sorting together' do
        test_datetime = Date.parse('2023-07-20').beginning_of_day
        additional_invoices = []
        10.times do |i|
          additional_invoices << create(:invoice,
            invoice_date: test_datetime + i.hours,
            total: (i + 1) * 100,
            active: true
          )
        end

        query = described_class.new(Invoice.active, {
          start_range: test_datetime.to_s,
          end_range: test_datetime.end_of_day.to_s,
          page: 1,
          per_page: 5,
          sort: 'total',
          direction: 'desc'
        })
        result = query.call

        expect(result.count).to eq(5)

        totals = result.map(&:total)
        expect(totals).to eq(totals.sort.reverse)
        expect(result.first.total).to eq(1000.0)
        expect(result.last.total).to eq(600.0)
        expect(result.all?(&:active)).to be true
        expect(result.all? { |inv| inv.invoice_date.to_date == test_datetime.to_date }).to be true
      end
    end

    context 'with scoped input' do
      it 'respects the initial scope' do
        active_scope = Invoice.active
        query = described_class.new(active_scope)
        result = query.call

        expect(result.all?(&:active)).to be true
        expect(result).not_to include(invoice3)
      end

      it 'works with complex scopes' do
        high_value_scope = Invoice.where('total > ?', 1200)
        query = described_class.new(high_value_scope, {
          sort: 'total',
          direction: 'asc'
        })
        result = query.call

        expect(result.count).to eq(2)
        expect(result.all? { |inv| inv.total > 1200 }).to be true
        expect(result.first.total).to be < result.last.total
      end
    end
  end

  describe 'private methods' do
    let(:query) { described_class.new }

    describe '#sanitize_params' do
      it 'sets default values for missing params' do
        result = query.send(:sanitize_params, {})

        expect(result).to include(
          page: InvoiceQuery::DEFAULT_PAGE,
          per_page: InvoiceQuery::DEFAULT_PER_PAGE,
          sort: InvoiceQuery::DEFAULT_SORT_FIELD,
          direction: InvoiceQuery::DEFAULT_SORT_DIRECTION
        )
      end

      it 'preserves provided params' do
        params = {
          page: 2,
          per_page: 5,
          sort: 'total',
          direction: 'asc'
        }
        result = query.send(:sanitize_params, params)

        expect(result).to include(params)
      end

      it 'parses date strings' do
        params = {
          start_range: '2023-01-01',
          end_range: '2023-12-31'
        }
        result = query.send(:sanitize_params, params)

        expect(result[:start_range]).to be_a(Date)
        expect(result[:end_range]).to be_a(Date)
        expect(result[:start_range]).to eq(Date.parse('2023-01-01'))
        expect(result[:end_range]).to eq(Date.parse('2023-12-31'))
      end

      it 'parses datetime strings' do
        params = {
          start_range: '2023-01-01 10:30:00',
          end_range: '2023-12-31 23:59:59'
        }
        result = query.send(:sanitize_params, params)

        expect(result[:start_range]).to be_a(DateTime)
        expect(result[:end_range]).to be_a(DateTime)
        expect(result[:start_range]).to eq(DateTime.parse('2023-01-01 10:30:00'))
        expect(result[:end_range]).to eq(DateTime.parse('2023-12-31 23:59:59'))
      end

      it 'handles nil date values' do
        params = {
          start_range: nil,
          end_range: nil
        }
        result = query.send(:sanitize_params, params)

        expect(result[:start_range]).to be_nil
        expect(result[:end_range]).to be_nil
      end
    end

    describe '#parse_date_or_datetime' do
      it 'parses date strings as Date objects' do
        result = query.send(:parse_date_or_datetime, '2023-01-01')
        expect(result).to be_a(Date)
        expect(result).to eq(Date.parse('2023-01-01'))
      end

      it 'parses datetime strings as DateTime objects' do
        result = query.send(:parse_date_or_datetime, '2023-01-01 10:30:00')
        expect(result).to be_a(DateTime)
        expect(result).to eq(DateTime.parse('2023-01-01 10:30:00'))
      end

      it 'detects time information by presence of colon' do
        date_only = query.send(:parse_date_or_datetime, '2023-01-01')
        datetime_with_time = query.send(:parse_date_or_datetime, '2023-01-01 10:30:00')
        datetime_with_seconds = query.send(:parse_date_or_datetime, '2023-01-01 10:30:45')

        expect(date_only).to be_a(Date)
        expect(datetime_with_time).to be_a(DateTime)
        expect(datetime_with_seconds).to be_a(DateTime)
      end
    end

    describe '#filter_by_range' do
      let(:scope) { Invoice.all }

      it 'returns original scope when both ranges are blank' do
        result = query.send(:filter_by_range, scope, start_range: nil, end_range: nil)
        expect(result).to eq(scope)
      end

      it 'returns original scope when both ranges are empty strings' do
        result = query.send(:filter_by_range, scope, start_range: '', end_range: '')
        expect(result).to eq(scope)
      end

      it 'filters by date range' do
        start_date = 2.days.ago.to_date
        end_date = Date.current

        result = query.send(:filter_by_range, scope, start_range: start_date, end_range: end_date)

        expect(result.count).to be >= 2
        expect(result).to include(invoice2)
        expect(result).not_to include(invoice1, invoice5)

        result_dates = result.map(&:invoice_date).map(&:to_date)
        expect(result_dates.all? { |date| date >= start_date && date <= end_date }).to be true
      end

      it 'filters by datetime range' do
        start_datetime = 2.days.ago.beginning_of_day
        end_datetime = 1.day.ago.end_of_day

        result = query.send(:filter_by_range, scope, start_range: start_datetime, end_range: end_datetime)

        expect(result.count).to eq(2)
        expect(result).to include(invoice2, invoice3)
      end
    end

    describe '#paginate' do
      let(:scope) { Invoice.all }

      it 'paginates correctly for first page' do
        result = query.send(:paginate, scope, page: 1, per_page: 2)
        expect(result.count).to eq(2)
      end

      it 'paginates correctly for second page' do
        result = query.send(:paginate, scope, page: 2, per_page: 2)
        expect(result.count).to eq(2)
      end

      it 'handles last page with fewer items' do
        result = query.send(:paginate, scope, page: 3, per_page: 2)
        expect(result.count).to eq(1)
      end

      it 'returns empty result for page beyond available records' do
        result = query.send(:paginate, scope, page: 10, per_page: 2)
        expect(result.count).to eq(0)
      end
    end

    describe '#order' do
      let(:scope) { Invoice.all }

      it 'orders by specified field and direction' do
        result = query.send(:order, scope, sort: 'total', direction: 'asc')
        totals = result.map(&:total)
        expect(totals).to eq(totals.sort)
      end

      it 'handles descending order' do
        result = query.send(:order, scope, sort: 'total', direction: 'desc')
        totals = result.map(&:total)
        expect(totals).to eq(totals.sort.reverse)
      end

      it 'orders by invoice_date' do
        result = query.send(:order, scope, sort: 'invoice_date', direction: 'asc')
        dates = result.map(&:invoice_date)
        expect(dates).to eq(dates.sort)
      end
    end
  end

  describe 'constants' do
    it 'defines expected default values' do
      expect(InvoiceQuery::DEFAULT_PAGE).to eq(1)
      expect(InvoiceQuery::DEFAULT_PER_PAGE).to eq(10)
      expect(InvoiceQuery::DEFAULT_SORT_FIELD).to eq("invoice_date")
      expect(InvoiceQuery::DEFAULT_SORT_DIRECTION).to eq("desc")
    end
  end

  describe 'edge cases' do
    it 'handles invalid date strings gracefully' do
      expect {
        described_class.new(base_scope, {
          start_range: 'invalid-date',
          end_range: 'also-invalid'
        }).call
      }.to raise_error(Date::Error)
    end

    it 'handles very large page numbers' do
      query = described_class.new(base_scope, { page: 999999, per_page: 10 })
      result = query.call
      expect(result.count).to eq(0)
    end

    it 'handles zero per_page' do
      query = described_class.new(base_scope, { per_page: 0 })
      result = query.call
      expect(result.count).to eq(0)
    end

    it 'handles negative page numbers' do
      query = described_class.new(base_scope, { page: -1, per_page: 2 })
      result = query.call
      expect(result.count).to be >= 0
    end
  end
end
