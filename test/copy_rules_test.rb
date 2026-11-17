# frozen_string_literal: true

require "test_helper"

module RecordingStudioDuplicatable
  class CopyRulesTest < Minitest::Test
    def setup
      super
      RecordingStudioDuplicatable.clear_copy_rules!
    end

    def teardown
      RecordingStudioDuplicatable.clear_copy_rules!
      super
    end

    def test_register_copy_rule_stores_skip_copy_and_callables
      callable = ->(**) {}

      RecordingStudioDuplicatable.register_copy_rule("Draft", :skip)
      RecordingStudioDuplicatable.register_copy_rule(:Note, :copy)
      RecordingStudioDuplicatable.register_copy_rule(StatusName, callable)

      assert_equal :skip, RecordingStudioDuplicatable.copy_rule_for("Draft")
      assert_equal :copy, RecordingStudioDuplicatable.copy_rule_for("Note")
      stored = RecordingStudioDuplicatable.copy_rule_for(StatusName.name)
      assert_equal callable, stored
    end

    def test_register_copy_rule_replaces_the_previous_rule
      RecordingStudioDuplicatable.register_copy_rule("Draft", :copy)
      RecordingStudioDuplicatable.register_copy_rule("Draft", :skip)

      assert_equal :skip, RecordingStudioDuplicatable.copy_rule_for("Draft")
    end

    def test_clear_copy_rules_removes_registered_rules
      RecordingStudioDuplicatable.register_copy_rule("Draft", :skip)

      RecordingStudioDuplicatable.clear_copy_rules!

      assert_nil RecordingStudioDuplicatable.copy_rule_for("Draft")
    end

    def test_register_copy_rule_rejects_an_unknown_rule
      error = assert_raises(ArgumentError) do
        RecordingStudioDuplicatable.register_copy_rule("Draft", :clone)
      end

      assert_equal "copy rule must be :copy, :skip, or a callable", error.message
    end

    def test_register_copy_rule_rejects_a_blank_type
      error = assert_raises(ArgumentError) do
        RecordingStudioDuplicatable.register_copy_rule("", :copy)
      end

      assert_equal "copy rule type must be a class or type name", error.message
    end

    def test_excluded_access_token_and_secret_types
      excluded = [
        "RecordingStudio::Access",
        "RecordingStudio::AccessBoundary",
        "RecordingStudio::AccessConstraint",
        "RecordingStudio::AccessRequest",
        "RecordingStudio::AccessRule",
        "RecordingStudio::Grant",
        "Host::ApiToken",
        "SigningSecret"
      ]

      excluded.each do |type|
        assert CopyRules.excluded?(type), "#{type} should be excluded"
      end
      refute CopyRules.excluded?("Page")
      refute CopyRules.excluded?("Comment")
    end

    def test_resolve_prefers_an_override_over_the_registry
      RecordingStudioDuplicatable.register_copy_rule("Page", :skip)

      assert_equal :copy, CopyRules.resolve("Page", { "Page" => :copy })
      assert_equal :skip, CopyRules.resolve("Page", {})
    end

    def test_resolve_keeps_an_excluded_type_on_skip
      assert_equal :skip, CopyRules.resolve("RecordingStudio::Access", { "RecordingStudio::Access" => :copy })
    end

    def test_normalize_overrides_accepts_class_keys
      normalized = CopyRules.normalize_overrides(StatusName => :skip)

      assert_equal({ "RecordingStudioDuplicatable::CopyRulesTest::StatusName" => :skip }, normalized)
    end

    def test_normalize_overrides_rejects_a_non_hash
      error = assert_raises(ArgumentError) do
        CopyRules.normalize_overrides(:skip)
      end

      assert_match(/copy_rules must be a Hash/, error.message)
    end

    class StatusName
      def self.label
        "status"
      end
    end
  end
end
