# frozen_string_literal: true

# ---------------------------------------------------------------------------
# RecordingStudio stubs
# These must be defined before test_helper loads gem_template so that
# the `include RecordingStudio::Capability if defined?(RecordingStudio::Capability)`
# guard in RecordingMethods resolves correctly.
# ---------------------------------------------------------------------------
unless defined?(RecordingStudio)
  module RecordingStudio
    class AccessDenied < StandardError; end
    class CapabilityDisabled < StandardError; end

    # Minimal stub for RecordingStudio::Capability.
    # The real module provides private assert_capability!(name).
    module Capability
      private

      def assert_capability!(_name)
        # no-op stub — FakeRecording overrides this to simulate enabled/disabled states
      end
    end

    module Services
      module AccessCheck
        def self.allowed?(actor:, recording:, role:)
          # Overridden per-test via AccessCheck.stub(:allowed?, ...) or by
          # swapping the implementation below.
          true
        end
      end
    end

    REGISTERED_CAPABILITIES   = {}
    ENABLED_CAPABILITIES      = Hash.new { |h, k| h[k] = [] }
    CAPABILITY_OPTIONS_STORE  = {}

    def self.enable_capability(name, on:)
      ENABLED_CAPABILITIES[name] << on
    end

    def self.set_capability_options(name, on:, **opts)
      CAPABILITY_OPTIONS_STORE[[name, on]] = opts
    end

    def self.capability_options(name, for_type:)
      CAPABILITY_OPTIONS_STORE[[name, for_type]]
    end

    def self.record!(**kwargs)
      # Returns a fake new Recording built from kwargs so callers can inspect it.
      FakeRecording.new(
        recordable:       kwargs[:recordable],
        recordable_type:  kwargs[:recordable]&.class&.name,
        root_recording:   kwargs[:root_recording],
        parent_recording: kwargs[:parent_recording]
      )
    end

    def self.register_capability(name, mod)
      REGISTERED_CAPABILITIES[name] = mod
    end

    def self.reset!
      # Only clear per-type state that should be isolated between tests.
      # REGISTERED_CAPABILITIES is set at load time and must not be cleared.
      ENABLED_CAPABILITIES.clear
      CAPABILITY_OPTIONS_STORE.clear
    end
  end
end

require "test_helper"

# ---------------------------------------------------------------------------
# Fake Recording — a plain Ruby object that stands in for
# RecordingStudio::Recording without touching the database.
# ---------------------------------------------------------------------------
class FakeRecording
  include GemTemplate::Capabilities::Duplicatable::RecordingMethods

  attr_accessor :id, :recordable, :recordable_type, :recordable_id,
                :root_recording, :parent_recording, :child_recordings,
                :capability_enabled

  def initialize(recordable: nil, recordable_type: nil, root_recording: nil,
                 parent_recording: nil, child_recordings: [], id: 1,
                 capability_enabled: true)
    @id               = id
    @recordable       = recordable
    @recordable_type  = recordable_type || recordable&.class&.name
    @recordable_id    = recordable&.id
    @root_recording   = root_recording
    @parent_recording = parent_recording
    @child_recordings = child_recordings
    @capability_enabled = capability_enabled
  end

  # Bypass ActiveRecord transaction — just yield
  def self.transaction
    yield
  end

  # Bypass ActiveRecord lock().find(id) — return self
  def acquire_lock
    self
  end

  # Bypass ActiveRecord reload
  def reload
    self
  end

  # Stub assert_capability! — raises CapabilityDisabled when @capability_enabled is false
  def assert_capability!(_name)
    raise RecordingStudio::CapabilityDisabled, "capability not enabled" unless @capability_enabled
  end

  # Stub duplicate_recordable — dup the recordable object
  def duplicate_recordable(recordable)
    recordable.dup
  end
end

# ---------------------------------------------------------------------------
# Simple recordable structs used as test data
# ---------------------------------------------------------------------------
NamedRecordable = Struct.new(:id, :name, keyword_init: true) do
  def save! = true
  def respond_to?(method_name, include_private = false)
    method_name.to_sym == :name || super
  end
end

TitledRecordable = Struct.new(:id, :title, keyword_init: true) do
  def save! = true
  def respond_to?(method_name, include_private = false)
    [:title].include?(method_name.to_sym) || (method_name.to_sym != :name && super)
  end
end

UnnamedRecordable = Struct.new(:id, keyword_init: true) do
  def save! = true
end

module GemTemplate
  module Capabilities
    class DuplicatableTest < Minitest::Test
      def setup
        RecordingStudio.reset!
        GemTemplate.configuration.duplication_prefix           = nil
        GemTemplate.configuration.duplication_suffix           = " (Copy)"
        GemTemplate.configuration.duplication_rename_attribute = nil
      end

      # -------------------------------------------------------------------
      # Module shape
      # -------------------------------------------------------------------

      def test_recording_methods_is_a_module
        assert_kind_of Module, Duplicatable::RecordingMethods
      end

      def test_duplicate_in_place_is_defined_on_fake_recording
        assert_respond_to FakeRecording.new, :duplicate_in_place!
      end

      # -------------------------------------------------------------------
      # .with() factory creates a module that enables the capability
      # -------------------------------------------------------------------

      def test_with_returns_a_module
        mod = Duplicatable.with
        assert_kind_of Module, mod
      end

      def test_with_enables_capability_when_included
        RecordingStudio.reset!

        Class.new do
          def self.name = "TestPage"
          include GemTemplate::Capabilities::Duplicatable.with(suffix: " [dup]")
        end

        assert_includes RecordingStudio::ENABLED_CAPABILITIES[:duplicatable], "TestPage"
        opts = RecordingStudio.capability_options(:duplicatable, for_type: "TestPage")
        assert_equal " [dup]", opts[:suffix]
      end

      def test_direct_include_enables_capability_without_per_type_options
        RecordingStudio.reset!

        Class.new do
          def self.name = "TestWidget"
          include GemTemplate::Capabilities::Duplicatable
        end

        assert_includes RecordingStudio::ENABLED_CAPABILITIES[:duplicatable], "TestWidget"
        # No per-type options stored for direct include
        opts = RecordingStudio.capability_options(:duplicatable, for_type: "TestWidget")
        assert_nil opts
      end

      # -------------------------------------------------------------------
      # CapabilityDisabled
      # -------------------------------------------------------------------

      def test_raises_capability_disabled_when_not_enabled
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Original"),
          capability_enabled: false
        )

        assert_raises(RecordingStudio::CapabilityDisabled) do
          recording.duplicate_in_place!(actor: :user)
        end
      end

      # -------------------------------------------------------------------
      # AccessDenied
      # -------------------------------------------------------------------

      def test_raises_access_denied_when_actor_lacks_edit_access
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Original")
        )

        RecordingStudio::Services::AccessCheck.stub(:allowed?, false) do
          assert_raises(RecordingStudio::AccessDenied) do
            recording.duplicate_in_place!(actor: :user)
          end
        end
      end

      def test_uses_parent_recording_for_access_check_when_present
        parent = FakeRecording.new(id: 99)
        recording = FakeRecording.new(
          recordable:       NamedRecordable.new(id: 1, name: "Original"),
          parent_recording: parent
        )

        checked_recording = nil
        RecordingStudio::Services::AccessCheck.stub(
          :allowed?,
          ->(**kwargs) { checked_recording = kwargs[:recording]; true }
        ) do
          recording.duplicate_in_place!(actor: :user)
        end

        assert_equal parent, checked_recording
      end

      def test_uses_self_for_access_check_when_no_parent
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Original")
        )

        checked_recording = nil
        RecordingStudio::Services::AccessCheck.stub(
          :allowed?,
          ->(**kwargs) { checked_recording = kwargs[:recording]; true }
        ) do
          recording.duplicate_in_place!(actor: :user)
        end

        assert_equal recording, checked_recording
      end

      # -------------------------------------------------------------------
      # Rename logic — suffix
      # -------------------------------------------------------------------

      def test_applies_default_suffix_from_global_config
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "My Page")
        )

        new_rec = recording.duplicate_in_place!(actor: :user)

        assert_equal "My Page (Copy)", new_rec.recordable.name
      end

      def test_applies_explicit_suffix_override
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Doc")
        )

        new_rec = recording.duplicate_in_place!(actor: :user, suffix: " — clone")

        assert_equal "Doc — clone", new_rec.recordable.name
      end

      def test_applies_per_type_suffix_via_capability_options
        RecordingStudio.set_capability_options(:duplicatable, on: "NamedRecordable", suffix: " (Dup)")
        recording = FakeRecording.new(
          recordable:      NamedRecordable.new(id: 1, name: "Item"),
          recordable_type: "NamedRecordable"
        )

        new_rec = recording.duplicate_in_place!(actor: :user)

        assert_equal "Item (Dup)", new_rec.recordable.name
      end

      def test_explicit_suffix_overrides_per_type_options
        RecordingStudio.set_capability_options(:duplicatable, on: "NamedRecordable", suffix: " (Dup)")
        recording = FakeRecording.new(
          recordable:      NamedRecordable.new(id: 1, name: "Item"),
          recordable_type: "NamedRecordable"
        )

        new_rec = recording.duplicate_in_place!(actor: :user, suffix: " — winner")

        assert_equal "Item — winner", new_rec.recordable.name
      end

      def test_nil_suffix_leaves_name_unchanged
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Clean")
        )

        new_rec = recording.duplicate_in_place!(actor: :user, suffix: nil)

        assert_equal "Clean", new_rec.recordable.name
      end

      # -------------------------------------------------------------------
      # Rename logic — prefix
      # -------------------------------------------------------------------

      def test_applies_prefix_from_global_config
        GemTemplate.configuration.duplication_prefix = "COPY — "
        GemTemplate.configuration.duplication_suffix = nil

        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Report")
        )

        new_rec = recording.duplicate_in_place!(actor: :user)

        assert_equal "COPY — Report", new_rec.recordable.name
      end

      def test_applies_both_prefix_and_suffix
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Doc")
        )

        new_rec = recording.duplicate_in_place!(actor: :user, prefix: "[COPY] ", suffix: nil)

        assert_equal "[COPY] Doc", new_rec.recordable.name
      end

      # -------------------------------------------------------------------
      # Rename logic — attribute detection
      # -------------------------------------------------------------------

      def test_renames_title_when_name_not_present
        recording = FakeRecording.new(
          recordable: TitledRecordable.new(id: 2, title: "Main Title")
        )

        new_rec = recording.duplicate_in_place!(actor: :user, suffix: " (Copy)")

        assert_equal "Main Title (Copy)", new_rec.recordable.title
      end

      def test_skips_rename_when_no_name_or_title
        recording = FakeRecording.new(
          recordable: UnnamedRecordable.new(id: 3)
        )

        # Should not raise — rename is silently skipped
        assert recording.duplicate_in_place!(actor: :user)
      end

      def test_renames_configured_attribute
        GemTemplate.configuration.duplication_rename_attribute = :title

        recording = FakeRecording.new(
          recordable: TitledRecordable.new(id: 2, title: "My Title")
        )

        new_rec = recording.duplicate_in_place!(actor: :user, suffix: " [dup]")

        assert_equal "My Title [dup]", new_rec.recordable.title
      end

      # -------------------------------------------------------------------
      # Child duplication — include_children
      # -------------------------------------------------------------------

      def test_no_children_copied_by_default
        child_recordable = NamedRecordable.new(id: 10, name: "Child")
        child = FakeRecording.new(
          id:              10,
          recordable:      child_recordable,
          recordable_type: "NamedRecordable"
        )

        recording = FakeRecording.new(
          recordable:       NamedRecordable.new(id: 1, name: "Parent"),
          child_recordings: [child]
        )

        recorded_calls = []
        RecordingStudio.stub(:record!, ->(action:, **_kwargs) { recorded_calls << action; FakeRecording.new }) do
          recording.duplicate_in_place!(actor: :user)
        end

        # Only one record! call: the parent duplicate
        assert_equal 1, recorded_calls.size
      end

      def test_include_children_copies_matching_types
        child_a = FakeRecording.new(id: 10, recordable: NamedRecordable.new(id: 10, name: "A"),
                                    recordable_type: "NamedRecordable")
        child_b = FakeRecording.new(id: 11, recordable: TitledRecordable.new(id: 11, title: "B"),
                                    recordable_type: "TitledRecordable")

        recording = FakeRecording.new(
          recordable:       NamedRecordable.new(id: 1, name: "Parent"),
          child_recordings: [child_a, child_b]
        )

        record_calls = []
        RecordingStudio.stub(
          :record!,
          ->(**kwargs) { record_calls << kwargs[:recordable]; FakeRecording.new }
        ) do
          recording.duplicate_in_place!(actor: :user, include_children: ["NamedRecordable"])
        end

        # 1 parent + 1 matching child = 2
        assert_equal 2, record_calls.size
        assert_kind_of NamedRecordable, record_calls.last
      end

      def test_exclude_children_skips_matching_types
        child_a = FakeRecording.new(id: 10, recordable: NamedRecordable.new(id: 10, name: "A"),
                                    recordable_type: "NamedRecordable")
        child_b = FakeRecording.new(id: 11, recordable: TitledRecordable.new(id: 11, title: "B"),
                                    recordable_type: "TitledRecordable")

        recording = FakeRecording.new(
          recordable:       NamedRecordable.new(id: 1, name: "Parent"),
          child_recordings: [child_a, child_b]
        )

        record_calls = []
        RecordingStudio.stub(
          :record!,
          ->(**kwargs) { record_calls << kwargs[:recordable]; FakeRecording.new }
        ) do
          recording.duplicate_in_place!(actor: :user, exclude_children: ["NamedRecordable"])
        end

        # 1 parent + 1 non-excluded child (TitledRecordable) = 2
        assert_equal 2, record_calls.size
        assert_kind_of TitledRecordable, record_calls.last
      end

      def test_per_type_include_children_option
        RecordingStudio.set_capability_options(
          :duplicatable, on: "NamedRecordable", include_children: ["TitledRecordable"]
        )

        child_a = FakeRecording.new(id: 10, recordable: NamedRecordable.new(id: 10, name: "A"),
                                    recordable_type: "NamedRecordable")
        child_b = FakeRecording.new(id: 11, recordable: TitledRecordable.new(id: 11, title: "B"),
                                    recordable_type: "TitledRecordable")

        recording = FakeRecording.new(
          recordable:       NamedRecordable.new(id: 1, name: "Parent"),
          recordable_type:  "NamedRecordable",
          child_recordings: [child_a, child_b]
        )

        record_calls = []
        RecordingStudio.stub(
          :record!,
          ->(**kwargs) { record_calls << kwargs[:recordable]; FakeRecording.new }
        ) do
          recording.duplicate_in_place!(actor: :user)
        end

        # 1 parent + 1 TitledRecordable child = 2
        assert_equal 2, record_calls.size
      end

      # -------------------------------------------------------------------
      # after_duplicate block
      # -------------------------------------------------------------------

      def test_after_duplicate_block_is_called_with_new_recording
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Original")
        )

        received = nil
        recording.duplicate_in_place!(actor: :user) { |new_rec| received = new_rec }

        refute_nil received
        assert_kind_of FakeRecording, received
      end

      def test_after_duplicate_block_not_required
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Original")
        )

        # Should not raise
        result = recording.duplicate_in_place!(actor: :user)
        assert_kind_of FakeRecording, result
      end

      # -------------------------------------------------------------------
      # Hook firing
      # -------------------------------------------------------------------

      def test_fires_after_duplicate_hook
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Hook Test")
        )

        hook_received = nil
        GemTemplate.configuration.hooks.on(:after_duplicate) { |rec| hook_received = rec }

        recording.duplicate_in_place!(actor: :user)

        refute_nil hook_received
      ensure
        GemTemplate.configuration.hooks.clear(:after_duplicate)
      end

      # -------------------------------------------------------------------
      # Return value
      # -------------------------------------------------------------------

      def test_returns_the_new_recording
        recording = FakeRecording.new(
          recordable: NamedRecordable.new(id: 1, name: "Original")
        )

        result = recording.duplicate_in_place!(actor: :user)

        assert_kind_of FakeRecording, result
      end

      # -------------------------------------------------------------------
      # Registration
      # -------------------------------------------------------------------

      def test_capability_is_registered_with_recording_studio
        assert_equal(
          GemTemplate::Capabilities::Duplicatable::RecordingMethods,
          RecordingStudio::REGISTERED_CAPABILITIES[:duplicatable]
        )
      end

      # -------------------------------------------------------------------
      # acquire_lock — verify it calls self.class.lock.find(id)
      # -------------------------------------------------------------------

      def test_acquire_lock_calls_lock_find_with_id
        rec = FakeRecording.new(id: 42)
        found_id = nil
        lock_obj = Object.new
        lock_obj.define_singleton_method(:find) { |id| found_id = id; rec }

        # Define a temporary class-level lock method so the stub can be exercised
        FakeRecording.define_singleton_method(:lock) { lock_obj }

        # Call the original acquire_lock from RecordingMethods (not the FakeRecording override)
        GemTemplate::Capabilities::Duplicatable::RecordingMethods
          .instance_method(:acquire_lock)
          .bind(rec)
          .call

        assert_equal 42, found_id
      ensure
        # Remove the temporary method to avoid polluting other tests
        FakeRecording.singleton_class.remove_method(:lock) if FakeRecording.singleton_class.method_defined?(:lock, false)
      end

      # -------------------------------------------------------------------
      # Child duplication — include_children: false covers the else [] branch
      # -------------------------------------------------------------------

      def test_no_children_when_include_children_is_false
        child = FakeRecording.new(id: 10, recordable: NamedRecordable.new(id: 10, name: "Child"),
                                  recordable_type: "NamedRecordable")
        recording = FakeRecording.new(
          recordable:       NamedRecordable.new(id: 1, name: "Parent"),
          child_recordings: [child]
        )

        record_calls = []
        RecordingStudio.stub(:record!, ->(**kwargs) { record_calls << kwargs; FakeRecording.new }) do
          # include_children: false — not nil so guard doesn't exit, but falsy so else [] is reached
          recording.duplicate_in_place!(actor: :user, include_children: false, exclude_children: nil)
        end

        # Only the parent recording is duplicated; the else [] branch produces no children
        assert_equal 1, record_calls.size
      end
    end
  end
end
