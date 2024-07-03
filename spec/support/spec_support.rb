# frozen_string_literal: true

module SpecSupport
  include Interactify

  module LoadInteractifyFixtures
    def load_interactify_fixtures(sub_directory)
      files = Dir.glob("./spec/fixtures/integration_app/app/interactors/#{sub_directory}/**/*.rb")

      files.each do |file|
        silence_warnings { load file }
      end
    end
  end
end

RSpec.configure do |config|
  config.include SpecSupport::LoadInteractifyFixtures
end
