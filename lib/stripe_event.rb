require "set"
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

  TYPE_LIST = Set[
    'account.updated',
    'account.application.deauthorized',
    'charge.succeeded',
    'charge.failed',
    'charge.refunded',
    'charge.dispute.created',
    'charge.dispute.updated',
    'charge.dispute.closed',
    'customer.created',
    'customer.updated',
    'customer.deleted',
    'customer.subscription.created',
    'customer.subscription.updated',
    'customer.subscription.deleted',
    'customer.subscription.trial_will_end',
    'customer.discount.created',
    'customer.discount.updated',
    'customer.discount.deleted',
    'invoice.created',
    'invoice.updated',
    'invoice.payment_succeeded',
    'invoice.payment_failed',
    'invoiceitem.created',
    'invoiceitem.updated',
    'invoiceitem.deleted',
    'plan.created',
    'plan.updated',
    'plan.deleted',
    'coupon.created',
    'coupon.deleted',
    'transfer.created',
    'transfer.updated',
    'transfer.failed',
    'ping'
  ].freeze
end
