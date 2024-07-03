# frozen_string_literal: true

require "debug"

require "./spec/support/coverage"

require "interactify"

if Interactify.sidekiq?
  require "sidekiq/testing"
  Sidekiq::Testing.fake!
end

Dir.glob("spec/support/**/*.rb").each { |f| require "./#{f}" }

RSpec.configure do |config|
  config.before do
    allow(Rails).to receive(:root).and_return(Pathname.new("spec/example_app")) if Interactify.railties?
  end
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
