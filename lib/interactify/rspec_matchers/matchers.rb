# frozen_string_literal: true

require "interactify/wiring"

module Interactify
  module RSpecMatchers
    class ContractMatcher
      attr_reader :actual, :expected_values, :actual_values, :type

      def initialize(actual, expected_values, actual_values, type)
        @actual = actual
        @expected_values = expected_values
        @actual_values = actual_values
        @type = type
      end

      def failure_message
        message = "expected #{actual} to #{type} #{expected_values.inspect}"
        message += "\n\tmissing: #{missing}" if missing.any?
        message += "\n\textra: #{extra}" if extra.any?
        message
      end

      def valid?
        missing.empty? && extra.empty?
      end

      def missing
        expected_values - actual_values
      end

      def extra
        actual_values - expected_values
      end
    end
  end
end

# Custom matchers that implement expect_inputs, promise_outputs, organize_interactors
# e.g. expect(described_class).to expect_inputs(:connection, :order)
# e.g. expect(described_class).to promise_outputs(:request_logger)
# e.g. expect(described_class).to organize_interactors(SeparateIntoPackages, SendPackagesToSeko)
[
  %i[expect_inputs expected_keys],
  %i[promise_outputs promised_keys],
  %i[organize_interactors organized]
].each do |type, meth|
  RSpec::Matchers.define type do |*expected_values|
    match do |actual|
      next false unless actual.respond_to?(meth)

      actual_values = Array(actual.send(meth))

      @contract_matcher = Interactify::RSpecMatchers::ContractMatcher.new(
        actual,
        expected_values,
        actual_values,
        type.to_s.gsub("_", " ")
      )

      @contract_matcher.valid?
    end

    failure_message do
      @contract_matcher.failure_message
    end
  end
end
