# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioDuplicatable::Configuration.new
  end

  def test_merge_updates_known_attributes
    resolver = ->(**_) { true }

    @configuration.merge!(
      duplication_prefix: "[copy] ",
      duplication_suffix: " [dup]",
      authorization_resolver: resolver
    )

    assert_equal "[copy] ", @configuration.duplication_prefix
    assert_equal " [dup]", @configuration.duplication_suffix
    assert_equal resolver, @configuration.authorization_resolver
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", duplication_suffix: " (duplicate)")

    refute_respond_to @configuration, :unknown_key
    assert_equal " (duplicate)", @configuration.duplication_suffix
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_nil @configuration.duplication_prefix if original[:duplication_prefix].nil?
    unless original[:duplication_prefix].nil?
      assert_equal original[:duplication_prefix],
                   @configuration.duplication_prefix
    end
    assert_equal original[:duplication_suffix], @configuration.duplication_suffix
    assert_nil @configuration.duplication_rename_attribute if original[:duplication_rename_attribute].nil?
    return if original[:duplication_rename_attribute].nil?

    assert_equal(
      original[:duplication_rename_attribute],
      @configuration.duplication_rename_attribute
    )
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
    assert_equal false, result.fetch(:authorization_resolver_configured)
  end

  def test_configure_without_block_is_safe
    RecordingStudioDuplicatable.configure

    assert_kind_of RecordingStudioDuplicatable::Configuration, RecordingStudioDuplicatable.configuration
  end
end
