# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_group "Sidekiq jobs" do |src_file|
    src_file.project_filename =~ /lib\/interactify\/job/ || 
      src_file.project_filename =~ /spec\/lib\/interactify\/job/
  end

  add_group "Wiring", "lib/interactify/interactor_wiring"
  add_group "RSpec matchers", "lib/interactify/rspec"

  coverage_dir "coverage/#{ENV['RUBY_VERSION']}-#{ENV['APPRAISAL']}"
end
