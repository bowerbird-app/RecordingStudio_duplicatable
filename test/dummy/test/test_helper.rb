# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

ActiveRecord::Migration.maintain_test_schema!

module ResetCurrentAttributes
  def setup
    Current.reset if defined?(Current) && Current.respond_to?(:reset)
    super
  end

  def teardown
    super
    Current.reset if defined?(Current) && Current.respond_to?(:reset)
  end
end

ActiveSupport::TestCase.prepend(ResetCurrentAttributes)
