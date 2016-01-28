module OpenFoodNetwork

  # When elements of the data model change, enqueue jobs to refresh the appropriate parts of
  # the products cache.
  class ProductsCache
    def self.variant_changed(variant)
      exchanges_featuring_variants(variant).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end


    def self.variant_destroyed(variant, &block)
      exchanges = exchanges_featuring_variants(variant).to_a

      block.call

      exchanges.each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end


    def self.product_changed(product)
      exchanges_featuring_variants(product.variants).each do |exchange|
        refresh_cache exchange.receiver, exchange.order_cycle
      end
    end


    private

    def self.exchanges_featuring_variants(variants)
      Exchange.
        outgoing.
        with_any_variant(variants).
        joins(:order_cycle).
        merge(OrderCycle.dated).
        merge(OrderCycle.not_closed)
    end


    def self.refresh_cache(distributor, order_cycle)
      Delayed::Job.enqueue RefreshProductsCacheJob.new distributor.id, order_cycle.id
    end
  end
end