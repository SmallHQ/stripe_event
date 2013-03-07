require "stripe"
require "stripe_event/engine"

module StripeEvent
  class << self
    attr_accessor :backend, :event_retriever, :prefix

    def setup(&block)
      instance_eval(&block)
    end

    def instrument(params)
      publish event_retriever.call(params)
    end

    def publish(event)
      backend.publish namespace(event[:type]), event
    end

    def subscribe(*names, &block)
      backend.subscribe pattern(*names) do |*args|
        payload = args.last
        block.call payload
      end
    end

    def pattern(*list)
      list << "\.*" if list.empty?
      Regexp.union list.map { |name| Regexp.new namespace(name) }
    end

    def namespace(name)
      "#{prefix}.#{name}"
    end
  end

  self.backend = ActiveSupport::Notifications
  self.event_retriever = lambda { |params| Stripe::Event.retrieve(params[:id]) }
  self.prefix = 'stripe_event'
end
