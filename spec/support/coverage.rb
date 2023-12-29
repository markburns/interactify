# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_group "Wiring specs", "lib/interactify/interactor_wiring"
  add_group "RSpec matchers", "lib/interactify/rspec"
end
