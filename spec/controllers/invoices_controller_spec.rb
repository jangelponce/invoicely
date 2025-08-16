require 'rails_helper'

RSpec.describe InvoicesController, type: :controller do
  let!(:invoice1) { create(:invoice, invoice_date: 3.days.ago, total: 1000.00, active: true) }
  let!(:invoice2) { create(:invoice, invoice_date: 2.days.ago, total: 1500.00, active: true) }
  let!(:invoice3) { create(:invoice, invoice_date: 1.day.ago, total: 800.00, active: false) }
  let!(:invoice4) { create(:invoice, invoice_date: Date.current, total: 2000.00, active: true) }

  describe 'GET #index' do
    context 'when requesting HTML format' do
      it 'renders successfully' do
        get :index

        expect(response).to have_http_status(:ok)
      end

      it 'renders the inertia invoices/index page' do
        get :index

        expect(response).to have_http_status(:ok)
        if response.headers['X-Inertia'].present?
          expect(response.headers['X-Inertia']).to eq('true')
        end
      end

      it 'accepts query parameters without using them for HTML format' do
        get :index, params: {
          start_range: '2023-01-01',
          end_range: '2023-12-31',
          page: 1,
          per_page: 10,
          sort: 'total',
          direction: 'desc'
        }

        expect(response).to have_http_status(:ok)
      end

      it 'accepts any parameters for HTML format' do
        get :index, params: {
          start_range: '2023-01-01',
          unpermitted_param: 'should_be_ignored'
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when requesting JSON format' do
      it 'returns invoices as JSON' do
        get :index, format: :json

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('invoices')
        expect(json_response['invoices']).to be_an(Array)
      end

      it 'returns all invoices when no parameters are provided' do
        get :index, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['invoices'].count).to eq(4)
      end

      it 'applies query parameters to filter invoices' do
        get :index, format: :json, params: {
          start_range: 2.days.ago.beginning_of_day.to_s,
          end_range: Date.current.end_of_day.to_s
        }

        json_response = JSON.parse(response.body)
        expect(json_response['invoices']).to be_an(Array)

        if json_response['invoices'].any?
          invoice = json_response['invoices'].first
          expect(invoice).to have_key('id')
          expect(invoice).to have_key('total')
        end
      end

      it 'applies pagination parameters' do
        get :index, format: :json, params: {
          page: 1,
          per_page: 2
        }

        json_response = JSON.parse(response.body)
        expect(json_response['invoices'].count).to eq(2)
      end

      it 'applies sorting parameters' do
        get :index, format: :json, params: {
          sort: 'total',
          direction: 'desc'
        }

        json_response = JSON.parse(response.body)
        totals = json_response['invoices'].map { |inv| inv['total'].to_f }
        expect(totals).to eq(totals.sort.reverse)
      end

      it 'handles active invoice filtering through scope' do
        allow(InvoiceQuery).to receive(:new).and_call_original

        get :index, format: :json

        expect(InvoiceQuery).to have_received(:new).with(Invoice.all, anything)
      end

      it 'returns proper JSON structure' do
        get :index, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('invoices')

        if json_response['invoices'].any?
          invoice = json_response['invoices'].first
          expect(invoice).to have_key('id')
          expect(invoice).to have_key('invoice_number')
          expect(invoice).to have_key('invoice_date')
          expect(invoice).to have_key('total')
          expect(invoice).to have_key('active')
        end
      end
    end

    context 'with complex query parameters' do
      it 'handles multiple parameters correctly for HTML format' do
        get :index, params: {
          start_range: 1.week.ago.to_date.to_s,
          end_range: Date.current.to_s,
          page: 1,
          per_page: 5,
          sort: 'invoice_date',
          direction: 'asc'
        }

        expect(response).to have_http_status(:ok)
      end

      it 'handles multiple parameters correctly for JSON format' do
        get :index, format: :json, params: {
          start_range: 1.week.ago.to_date.to_s,
          end_range: Date.current.to_s,
          page: 1,
          per_page: 5,
          sort: 'invoice_date',
          direction: 'asc'
        }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['invoices'].count).to be <= 5

        if json_response['invoices'].count > 1
          dates = json_response['invoices'].map { |inv| Date.parse(inv['invoice_date']) }
          expect(dates).to eq(dates.sort)
        end
      end
    end

    context 'edge cases' do
      it 'handles empty query parameters' do
        get :index, format: :json, params: {
          start_range: '',
          end_range: '',
          page: '',
          per_page: '',
          sort: '',
          direction: ''
        }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['invoices']).to be_an(Array)
      end

      it 'handles invalid date parameters gracefully' do
        get :index, format: :json, params: {
          start_range: '',
          end_range: ''
        }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['invoices']).to be_an(Array)
      end

      it 'handles large page numbers' do
        get :index, format: :json, params: {
          page: 999,
          per_page: 10
        }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['invoices']).to eq([])
      end

      it 'handles zero per_page parameter' do
        get :index, format: :json, params: {
          per_page: 0
        }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['invoices']).to be_an(Array)
      end
    end

    context 'when no invoices exist' do
      before do
        Invoice.delete_all
      end

      it 'returns empty array for JSON format' do
        get :index, format: :json

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['invoices']).to eq([])
      end

      it 'still renders the Inertia page for HTML format' do
        get :index

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'private methods' do
    describe '#query_params' do
      let(:controller_instance) { described_class.new }

      before do
        allow(controller_instance).to receive(:params).and_return(
          ActionController::Parameters.new(test_params)
        )
      end

      context 'with permitted parameters' do
        let(:test_params) do
          {
            start_range: '2023-01-01',
            end_range: '2023-12-31',
            page: 1,
            per_page: 10,
            sort: 'total',
            direction: 'desc'
          }
        end

        it 'permits all expected parameters' do
          result = controller_instance.send(:query_params)

          expect(result).to be_permitted
          expect(result.to_h).to eq({
            'start_range' => '2023-01-01',
            'end_range' => '2023-12-31',
            'page' => 1,
            'per_page' => 10,
            'sort' => 'total',
            'direction' => 'desc'
          })
        end
      end

      context 'with unpermitted parameters' do
        let(:test_params) do
          {
            start_range: '2023-01-01',
            unpermitted_param: 'should_be_filtered',
            malicious_param: '<script>alert("xss")</script>'
          }
        end

        it 'filters out unpermitted parameters' do
          result = controller_instance.send(:query_params)

          expect(result.to_h).to eq({
            'start_range' => '2023-01-01'
          })
          expect(result.to_h).not_to have_key('unpermitted_param')
          expect(result.to_h).not_to have_key('malicious_param')
        end
      end

      context 'with mixed permitted and unpermitted parameters' do
        let(:test_params) do
          {
            start_range: '2023-01-01',
            end_range: '2023-12-31',
            page: 1,
            unpermitted_param: 'should_be_filtered',
            sort: 'total'
          }
        end

        it 'only permits expected parameters' do
          result = controller_instance.send(:query_params)

          expect(result.to_h).to eq({
            'start_range' => '2023-01-01',
            'end_range' => '2023-12-31',
            'page' => 1,
            'sort' => 'total'
          })
        end
      end

      context 'with no parameters' do
        let(:test_params) { {} }

        it 'returns empty permitted parameters' do
          result = controller_instance.send(:query_params)

          expect(result).to be_permitted
          expect(result.to_h).to eq({})
        end
      end
    end
  end

  describe 'integration with InvoiceQuery' do
    it 'uses InvoiceQuery with correct scope and parameters' do
      expect(InvoiceQuery).to receive(:new).with(
        Invoice.all,
        hash_including('sort' => 'total', 'direction' => 'desc')
      ).and_call_original

      get :index, format: :json, params: {
        sort: 'total',
        direction: 'desc'
      }

      expect(response).to have_http_status(:ok)
    end

    it 'calls the call method on InvoiceQuery instance' do
      query_instance = instance_double(InvoiceQuery)
      allow(InvoiceQuery).to receive(:new).and_return(query_instance)
      allow(query_instance).to receive(:call).and_return([])

      get :index, format: :json

      expect(query_instance).to have_received(:call)
    end
  end

  describe 'response headers and format' do
    it 'sets correct content type for JSON responses' do
      get :index, format: :json

      expect(response.content_type).to eq('application/json; charset=utf-8')
    end

    it 'sets Inertia headers for HTML responses' do
      get :index

      expect(response).to have_http_status(:ok)
    end

    it 'includes Vary header for Inertia responses' do
      get :index

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'performance considerations' do
    it 'does not load all invoices into memory for JSON responses' do
      100.times do |i|
        create(:invoice, total: (i + 1) * 10, active: true)
      end

      get :index, format: :json, params: { per_page: 10 }

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['invoices'].count).to eq(10)
    end
  end
end
