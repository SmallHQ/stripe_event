require 'spec_helper'

describe StripeEvent do
  let(:event_type) { 'charge.succeeded' }

  describe ".backend" do
    it "AS::Notifications is the default backend" do
      expect(described_class.backend).to be ActiveSupport::Notifications
    end
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

  describe ".subscribe" do
    context "given no event types" do
      it "registers a subscriber to all event types" do
        described_class.backend.should_receive(:subscribe).with(
          described_class.pattern
        ).and_yield

        described_class.subscribe { |e| }
      end
    end

    context "given list of event types" do
      it "registers a subscriber to the given event types" do
        described_class.backend.should_receive(:subscribe).with(
          described_class.pattern(event_type)
        ).and_yield

        described_class.subscribe(event_type) { |e| }
      end
    end
  end

  describe ".publish" do
    it "yields the event object to the subscribed block" do
      event = double("event")
      event.should_receive(:[]).with(:type).and_return(event_type)

      expect { |block|
        described_class.subscribe(event_type, &block)
        described_class.publish(event)
      }.to yield_with_args(event)
    end
  end

  describe ".event_retriever" do
    it "Stripe::Event is the default event retriever" do
      Stripe::Event.should_receive(:retrieve).with('1')
      described_class.event_retriever.call(:id => '1')
    end
  end
end
