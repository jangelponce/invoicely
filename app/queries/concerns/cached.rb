module Cached
  extend ActiveSupport::Concern

  included do
    class_attribute :_cache_expires_in, instance_accessor: false, default: 5.minutes
    class_attribute :_cache_versioner, instance_accessor: false, default: nil
  end

  class_methods do
    def cached_model(expires_in: nil, version_by: nil)
      self._cache_expires_in = expires_in
      self._cache_versioner  = version_by
    end
  end

  def cached_call
    Rails.cache.fetch(cache_key, expires_in: self.class._cache_expires_in) { call }
  end

  private

  def cache_key
    [
      self.class.name,
      params_fingerprint,
      version_fingerprint
    ]
  end

  def params_fingerprint
    h = @params.respond_to?(:to_h) ? @params.to_h : (@params || {})
    return [] unless h.respond_to?(:to_a)
    h.to_a.sort
  end

  def version_fingerprint
    return unless (v = self.class._cache_versioner)
    instance_exec(&v)
  end
end
