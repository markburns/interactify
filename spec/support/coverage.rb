# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_filter "/spec/"
  add_filter %r{_spec\.rb$}  # This line excludes all files ending with _spec.rb

  add_group "Sidekiq jobs" do |src_file|
    src_file.project_filename =~ %r{lib/interactify/async} && src_file.filename !~ /_spec\.rb/
  end

  add_group "Wiring", "lib/interactify/wiring"
  add_group "RSpec matchers", "lib/interactify/rspec_matchers"

  coverage_dir "coverage/#{ENV.fetch('RUBY_VERSION', nil)}-#{ENV.fetch('APPRAISAL', nil)}"
end
