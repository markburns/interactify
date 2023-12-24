require 'interactify/interactor_wiring'

# Custom matcher that implements expect_inputs
# e.g.
# expect(described_class).to expect_inputs(:connection, :order)

RSpec::Matchers.define :expect_inputs do |*expected_inputs|
  match do |actual|
    actual_inputs = expected_keys(actual)
    @missing_inputs = expected_inputs - actual_inputs
    @extra_inputs = actual_inputs - expected_inputs

    @missing_inputs.empty? && @extra_inputs.empty?
  end

  failure_message do |actual|
    message = "expected #{actual} to expect inputs #{expected_inputs.inspect}"
    message += "\n\tmissing inputs: #{@missing_inputs}" if @missing_inputs
    message += "\n\textra inputs: #{@extra_inputs}" if @extra_inputs
    message
  end

  def expected_keys(klass)
    Array(klass.contract.expectations.instance_eval { @terms }.json&.rules&.keys)
  end
end

# Custom matcher that implements promise_outputs
# e.g. expect(described_class).to promise_outputs(:request_logger)
RSpec::Matchers.define :promise_outputs do |*expected_outputs|
  match do |actual|
    actual_outputs = promised_keys(actual)
    @missing_outputs = expected_outputs - actual_outputs
    @extra_outputs = actual_outputs - expected_outputs

    @missing_outputs.empty? && @extra_outputs.empty?
  end

  failure_message do |actual|
    message = "expected #{actual} to promise outputs #{expected_outputs.inspect}"
    message += "\n\tmissing outputs: #{@missing_outputs}" if @missing_outputs
    message += "\n\textra outputs: #{@extra_outputs}" if @extra_outputs
    message
  end

  def promised_keys(klass)
    Array(klass.contract.promises.instance_eval { @terms }.json&.rules&.keys)
  end
end

# Custom matcher that implements organize_interactors
#
# e.g. expect(described_class).to organize_interactors(SeparateIntoPackages, SendPackagesToSeko)
RSpec::Matchers.define :organize_interactors do |*expected_interactors|
  match do |actual|
    actual_interactors = actual.organized
    @missing_interactors = expected_interactors - actual_interactors
    @extra_interactors = actual_interactors - expected_interactors

    @missing_interactors.empty? && @extra_interactors.empty?
  end

  failure_message do |actual|
    message = "expected #{actual} to organize interactors #{expected_interactors.inspect}"
    message += "\n\tmissing interactors: #{@missing_interactors}" if @missing_interactors
    message += "\n\textra interactors: #{@extra_interactors}" if @extra_interactors
    message
  end
end
