require 'rails_helper'

RSpec.describe Cached do
  include ActiveSupport::Testing::TimeHelpers

  let(:test_class) do
    Class.new do
      include Cached

      attr_reader :params, :call_count

      def initialize(params = {})
        @params = params
        @call_count = 0
      end

      def call
        @call_count += 1
        "result_#{params[:id]}_#{@call_count}"
      end

      def self.name
        'TestQuery'
      end
    end
  end

  let(:instance) { test_class.new(id: 123, name: 'test') }

  before do
    @original_cache_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear
  end

  after do
    Rails.cache = @original_cache_store
  end

  describe 'class attributes' do
    it 'sets default cache expiration time to 5 minutes' do
      expect(test_class._cache_expires_in).to eq(5.minutes)
    end

    it 'sets default cache versioner to nil' do
      expect(test_class._cache_versioner).to be_nil
    end
  end

  describe '.cached_model' do
    context 'with expires_in option' do
      before do
        test_class.cached_model(expires_in: 10.minutes)
      end

      it 'sets the cache expiration time' do
        expect(test_class._cache_expires_in).to eq(10.minutes)
      end
    end

    context 'with version_by option' do
      let(:version_proc) { -> { 'version_123' } }

      before do
        test_class.cached_model(version_by: version_proc)
      end

      it 'sets the cache versioner' do
        expect(test_class._cache_versioner).to eq(version_proc)
      end
    end

    context 'with both options' do
      let(:version_proc) { -> { 'version_456' } }

      before do
        test_class.cached_model(expires_in: 1.hour, version_by: version_proc)
      end

      it 'sets both cache expiration time and versioner' do
        expect(test_class._cache_expires_in).to eq(1.hour)
        expect(test_class._cache_versioner).to eq(version_proc)
      end
    end
  end

  describe '#cached_call' do
    it 'returns the result of call method' do
      result = instance.cached_call
      expect(result).to eq('result_123_1')
    end

    it 'caches the result on subsequent calls' do
      first_result = instance.cached_call
      second_result = instance.cached_call

      expect(first_result).to eq(second_result)
      expect(instance.call_count).to eq(1) # call should only be invoked once due to caching
    end

    it 'uses different cache keys for different instances' do
      instance1 = test_class.new(id: 1)
      instance2 = test_class.new(id: 2)

      result1 = instance1.cached_call
      result2 = instance2.cached_call

      expect(result1).to eq('result_1_1')
      expect(result2).to eq('result_2_1')
      expect(result1).not_to eq(result2)
    end

    it 'respects cache expiration time' do
      test_class.cached_model(expires_in: 1.second)

      first_result = instance.cached_call
      expect(instance.call_count).to eq(1)

      # Should still be cached
      second_result = instance.cached_call
      expect(second_result).to eq(first_result)
      expect(instance.call_count).to eq(1)

      # Wait for cache to expire
      travel_to(2.seconds.from_now) do
        third_result = instance.cached_call
        expect(instance.call_count).to eq(2)
        expect(third_result).to eq('result_123_2') # Different result due to cache miss
      end
    end

    context 'with version_by proc' do
      it 'includes version in cache key' do
        # Create a simple versioner that returns a fixed value
        test_class.cached_model(version_by: -> { 'v1' })

        first_result = instance.cached_call
        expect(instance.call_count).to eq(1)

        # Same version should use cache
        second_result = instance.cached_call
        expect(second_result).to eq(first_result)
        expect(instance.call_count).to eq(1)
      end

      it 'invalidates cache when version changes' do
        # Use instance variable to control version
        instance.instance_variable_set(:@version, 'v1')
        test_class.cached_model(version_by: -> { @version })

        # First call with version v1
        first_result = instance.cached_call
        expect(instance.call_count).to eq(1)

        # Second call with same version should use cache
        second_result = instance.cached_call
        expect(second_result).to eq(first_result)
        expect(instance.call_count).to eq(1)

        # Change version and verify cache is invalidated
        instance.instance_variable_set(:@version, 'v2')
        third_result = instance.cached_call
        expect(instance.call_count).to eq(2)
        expect(third_result).to eq('result_123_2') # Different result due to version change
      end
    end
  end

  describe '#cache_key' do
    it 'includes class name, params fingerprint, and version fingerprint' do
      cache_key = instance.send(:cache_key)

      expect(cache_key).to be_an(Array)
      expect(cache_key.size).to eq(3)
      expect(cache_key[0]).to eq('TestQuery')
      expect(cache_key[1]).to be_present # params_fingerprint
      expect(cache_key[2]).to be_nil     # version_fingerprint (no versioner set)
    end

    context 'with version_by proc' do
      before do
        test_class.cached_model(version_by: -> { 'test_version' })
      end

      it 'includes version fingerprint when versioner is set' do
        cache_key = instance.send(:cache_key)

        expect(cache_key.size).to eq(3)
        expect(cache_key[0]).to eq('TestQuery')
        expect(cache_key[1]).to be_present # params_fingerprint
        expect(cache_key[2]).to eq('test_version') # version_fingerprint
      end
    end
  end

  describe '#params_fingerprint' do
    context 'with hash-like params' do
      let(:instance) { test_class.new(id: 123, name: 'test', active: true) }

      it 'returns sorted array of key-value pairs' do
        fingerprint = instance.send(:params_fingerprint)

        expect(fingerprint).to be_an(Array)
        expect(fingerprint).to eq([ [ :active, true ], [ :id, 123 ], [ :name, 'test' ] ])
      end
    end

    context 'with ActionController::Parameters' do
      let(:params) { ActionController::Parameters.new(id: 456, filter: 'active').permit! }
      let(:instance) { test_class.new(params) }

      it 'converts to hash and returns sorted array' do
        fingerprint = instance.send(:params_fingerprint)

        expect(fingerprint).to be_an(Array)
        expect(fingerprint).to include([ 'filter', 'active' ], [ 'id', 456 ])
        expect(fingerprint.size).to eq(2)
      end
    end

    context 'with nil params' do
      let(:instance) do
        obj = test_class.new
        obj.instance_variable_set(:@params, nil)
        obj
      end

      it 'handles nil params gracefully' do
        fingerprint = instance.send(:params_fingerprint)

        expect(fingerprint).to eq([])
      end
    end

    context 'with non-hash params' do
      let(:instance) do
        obj = test_class.new
        obj.instance_variable_set(:@params, 'string_param')
        obj
      end

      it 'handles non-hash params gracefully' do
        fingerprint = instance.send(:params_fingerprint)

        expect(fingerprint).to eq([])
      end
    end
  end

  describe '#version_fingerprint' do
    context 'without versioner' do
      it 'returns nil when no versioner is set' do
        fingerprint = instance.send(:version_fingerprint)
        expect(fingerprint).to be_nil
      end
    end

    context 'with versioner' do
      before do
        test_class.cached_model(version_by: -> { 'version_123' })
      end

      it 'executes the versioner proc in instance context' do
        fingerprint = instance.send(:version_fingerprint)
        expect(fingerprint).to eq('version_123')
      end

      it 'has access to instance variables in versioner proc' do
        test_class.cached_model(version_by: -> { @params[:id] })

        fingerprint = instance.send(:version_fingerprint)
        expect(fingerprint).to eq(123)
      end
    end
  end

  describe 'integration with Rails.cache' do
    let(:cache_key) { [ 'TestQuery', [ [ :id, 123 ], [ :name, 'test' ] ], nil ] }

    it 'stores result in Rails cache with correct key and expiration' do
      expect(Rails.cache).to receive(:fetch)
        .with(cache_key, expires_in: 5.minutes)
        .and_call_original

      instance.cached_call
    end

    it 'retrieves result from Rails cache on subsequent calls' do
      # First call should store in cache
      first_result = instance.cached_call
      expect(instance.call_count).to eq(1)

      # Get the actual cache key that was generated
      actual_cache_key = instance.send(:cache_key)

      # Verify it's actually in the cache
      cached_value = Rails.cache.read(actual_cache_key)
      expect(cached_value).to eq(first_result)

      # Second call should retrieve from cache
      second_result = instance.cached_call
      expect(second_result).to eq(first_result)
      expect(instance.call_count).to eq(1)
    end

    it 'handles cache misses gracefully' do
      # Get the actual cache key and clear it
      actual_cache_key = instance.send(:cache_key)
      Rails.cache.delete(actual_cache_key)

      result = instance.cached_call
      expect(result).to eq('result_123_1')
      expect(instance.call_count).to eq(1)
    end
  end

  describe 'real-world usage with InvoiceQuery' do
    let!(:invoice) { create(:invoice, invoice_date: 1.day.ago, total: 1000.00) }
    let(:query) { InvoiceQuery.new(Invoice.all, page: 1, per_page: 10) }

    before do
      Rails.cache.clear
    end

    it 'caches InvoiceQuery results' do
      # First call should execute the query
      first_result = query.cached_call
      expect(first_result).to include(invoice)

      # Second call should use cached result
      # We can't easily test call count on InvoiceQuery, but we can verify
      # that the same object is returned from cache
      second_result = query.cached_call
      expect(second_result.to_a).to eq(first_result.to_a)
    end

    it 'uses version_by proc to invalidate cache when Invoice data changes' do
      # First call
      first_result = query.cached_call
      original_count = first_result.count

      # Create a new invoice (this should change the version)
      new_invoice = create(:invoice, invoice_date: Date.current, total: 2000.00)

      # Second call should get fresh data due to version change
      second_result = query.cached_call
      expect(second_result.count).to eq(original_count + 1)
      expect(second_result).to include(new_invoice)
    end

    it 'generates different cache keys for different query parameters' do
      query1 = InvoiceQuery.new(Invoice.all, page: 1, per_page: 10)
      query2 = InvoiceQuery.new(Invoice.all, page: 2, per_page: 10)

      key1 = query1.send(:cache_key)
      key2 = query2.send(:cache_key)

      expect(key1).not_to eq(key2)
      expect(key1[1]).not_to eq(key2[1]) # Different params fingerprint
    end
  end
end
