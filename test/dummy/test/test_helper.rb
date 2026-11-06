# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Migration.maintain_test_schema!

class ActiveSupport::TestCase
  setup do
    Current.reset if defined?(Current) && Current.respond_to?(:reset)
  end

  teardown do
    Current.reset if defined?(Current) && Current.respond_to?(:reset)
  end
end
