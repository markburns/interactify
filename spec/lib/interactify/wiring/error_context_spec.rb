# frozen_string_literal: true

RSpec.describe Interactify::Wiring::ErrorContext do
  describe "#previously_defined_keys" do
    it "acts as a set" do
      expect(subject.previously_defined_keys).to be_a Set
      subject.append_previously_defined_keys(%w[foo bar baz])
      expect(subject.previously_defined_keys).to eq Set.new(%w[foo bar baz])

      subject.add_promised_keys(%w[foo bar baz])
      expect(subject.previously_defined_keys).to eq Set.new(%w[foo bar baz])

      subject.add_promised_keys(%w[foo boop baz])
      expect(subject.previously_defined_keys).to eq Set.new(%w[foo bar baz boop])
    end
  end

  describe "#missing_keys" do
    it "is a hash" do
      expect(subject.missing_keys).to eq({})

      subject.add_missing_keys("thing", %w[foo bar baz])
      subject.add_missing_keys("another", %w[beep boop bop])

      expect(subject.missing_keys).to eq(
        {
          "another" => Set.new(%w[beep boop bop]),
          "thing" => Set.new(%w[foo bar baz])
        }
      )
    end
  end

  describe "#infer_missing_keys" do
    it "adds missing keys" do
      callable = double(expected_keys: %w[foo bar baz boop])
      subject.append_previously_defined_keys(%w[foo bar baz])
      subject.infer_missing_keys(callable)

      expect(subject.missing_keys).to eq(
        {
          callable => Set.new(["boop"])
        }
      )
    end
  end
end
