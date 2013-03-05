require 'spec_helper'

describe StripeEvent do
  let(:event_type) { StripeEvent::TYPE_LIST.sample }

  it "backend defaults to AS::Notifications" do
    expect(described_class.backend).to eq ActiveSupport::Notifications
  end

  describe ".pattern" do
    context "given no arguments" do
      let(:regexp) { described_class.pattern }

      it "matches event types in the namespace" do
        expect(regexp).to match described_class.namespace(event_type)
      end

      it "does not match event types outside the namespace" do
        expect(regexp).to_not match event_type
      end
    end

    context "given a list of event types" do
      let(:regexp) { described_class.pattern(event_type) }

      it "matches given event types in the namespace" do
        expect(regexp).to match described_class.namespace(event_type)
      end

      it "does not match other namespaced event types" do
        expect(regexp).to_not match described_class.namespace('customer.discount.created')
      end
    end
  end

  it "registers a subscriber" do
    subscriber = described_class.subscribe(event_type) { |e| }
    subscribers = subscribers_for_type(event_type)
    expect(subscribers).to eq [subscriber]
  end

  it "registers subscribers within a parent block" do
    described_class.setup do
      subscribe('invoice.payment_succeeded') { |e| }
    end
    subscribers = subscribers_for_type('invoice.payment_succeeded')
    expect(subscribers).to_not be_empty
  end

  it "passes only the event object to the subscribed block" do
    event = { :type => event_type }

    expect { |block|
      described_class.subscribe(event_type, &block)
      described_class.publish(event)
    }.to yield_with_args(event)
  end

  it "uses Stripe::Event as the default event retriever" do
    Stripe::Event.should_receive(:retrieve).with('1')
    described_class.event_retriever.call(:id => '1')
  end

  it "allows setting an event_retriever" do
    params = { :id => '1' }

    described_class.event_retriever = Proc.new { |arg| arg }
    event = described_class.event_retriever.call(params)
    expect(event).to eq params
  end
end
