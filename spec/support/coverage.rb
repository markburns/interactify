# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_group "Sidekiq jobs" do |src_file|
    src_file.project_filename =~ %r{lib/interactify/job} ||
      src_file.project_filename =~ %r{spec/lib/interactify/job}
  end

  add_group "Wiring", "lib/interactify/wiring"
  add_group "RSpec matchers", "lib/interactify/rspec_matchers"

  coverage_dir "coverage/#{ENV.fetch('RUBY_VERSION', nil)}-#{ENV.fetch('APPRAISAL', nil)}"
end
