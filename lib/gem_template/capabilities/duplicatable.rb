# frozen_string_literal: true

module GemTemplate
  module Capabilities
    # Duplicatable capability for RecordingStudio recordable models.
    #
    # Enables in-place duplication of a recording and its recordable, with
    # optional prefix/suffix renaming and selective child recording duplication.
    #
    # == Direct include (uses global GemTemplate.configuration defaults)
    #
    #   class Page < ApplicationRecord
    #     include GemTemplate::Capabilities::Duplicatable
    #   end
    #
    # == Factory method (per-type options override global config)
    #
    #   class Page < ApplicationRecord
    #     include GemTemplate::Capabilities::Duplicatable.with(
    #       prefix: nil,
    #       suffix: " (Copy)",
    #       include_children: nil,
    #       exclude_children: nil
    #     )
    #   end
    #
    module Duplicatable
      extend ActiveSupport::Concern

      included do
        if defined?(RecordingStudio)
          RecordingStudio.enable_capability(:duplicatable, on: name)
        end
      end

      # Returns a Module that, when included in a recordable model, enables the
      # :duplicatable capability with per-type options that override the global
      # GemTemplate.configuration defaults.
      #
      # @param prefix [String, nil] String prepended to the duplicate's name/title
      # @param suffix [String, nil] String appended to the duplicate's name/title
      # @param include_children [Array<String,Class>, nil] Only duplicate these child types
      # @param exclude_children [Array<String,Class>, nil] Duplicate all children EXCEPT these types
      # @return [Module]
      def self.with(prefix: nil, suffix: " (Copy)", include_children: nil, exclude_children: nil)
        type_opts = {
          prefix: prefix,
          suffix: suffix,
          include_children: include_children,
          exclude_children: exclude_children
        }

        Module.new do
          extend ActiveSupport::Concern

          included do
            if defined?(RecordingStudio)
              RecordingStudio.enable_capability(:duplicatable, on: name)
              RecordingStudio.set_capability_options(:duplicatable, on: name, **type_opts)
            end
          end
        end
      end

      # Methods mixed into RecordingStudio::Recording via register_capability.
      #
      # All public methods on this module become instance methods on every
      # RecordingStudio::Recording, but are gated by assert_capability! so they
      # raise RecordingStudio::CapabilityDisabled unless the recording's
      # recordable_type has explicitly enabled :duplicatable.
      #
      module RecordingMethods
        # Include RecordingStudio::Capability when available (production) to pull in
        # assert_capability!. Guarded so the module loads cleanly in isolated unit
        # tests where RecordingStudio is not on the load path.
        include RecordingStudio::Capability if defined?(RecordingStudio::Capability)

        # Duplicates this recording's recordable in-place under the same parent.
        #
        # Wraps the entire operation in a database transaction and locks the row
        # before reading to prevent concurrent duplication races.
        #
        # @param actor [Object] The actor performing the duplication (required)
        # @param impersonator [Object, nil] Impersonating actor, if any
        # @param metadata [Hash] Arbitrary metadata stored on the recording event
        # @param prefix [String, nil, :default] Prepended to the duplicate's name/title.
        #   :default resolves to the per-type option, then GemTemplate.configuration.duplication_prefix
        # @param suffix [String, nil, :default] Appended to the duplicate's name/title.
        #   :default resolves to the per-type option, then GemTemplate.configuration.duplication_suffix
        # @param include_children [:default, Array<String,Class>, nil] Child types to copy.
        #   :default resolves to the per-type option (nil = no children).
        # @param exclude_children [:default, Array<String,Class>, nil] Child types to skip.
        #   :default resolves to the per-type option (nil = no exclusions).
        # @yield [new_recording] Optional block called with the new Recording after creation
        # @return [RecordingStudio::Recording] The newly created recording
        # @raise [RecordingStudio::CapabilityDisabled] if :duplicatable is not enabled for this type
        # @raise [RecordingStudio::AccessDenied] if the actor lacks :edit access
        def duplicate_in_place!(actor:, impersonator: nil, metadata: {},
                                 prefix: :default, suffix: :default,
                                 include_children: :default, exclude_children: :default,
                                 &after_duplicate)
          self.class.transaction do
            locked = acquire_lock
            locked.reload

            locked.assert_capability!(:duplicatable)

            check_target = locked.parent_recording || locked
            unless RecordingStudio::Services::AccessCheck.allowed?(
              actor: actor, recording: check_target, role: :edit
            )
              raise RecordingStudio::AccessDenied, "Actor does not have :edit access for duplication"
            end

            type_name = locked.recordable_type
            type_opts = RecordingStudio.capability_options(:duplicatable, for_type: type_name) || {}
            config    = GemTemplate.configuration

            resolved_prefix  = prefix  == :default ? type_opts.fetch(:prefix,  config.duplication_prefix)  : prefix
            resolved_suffix  = suffix  == :default ? type_opts.fetch(:suffix,  config.duplication_suffix)  : suffix
            resolved_include = include_children == :default ? type_opts[:include_children] : include_children
            resolved_exclude = exclude_children == :default ? type_opts[:exclude_children] : exclude_children

            dup_recordable = locked.send(:duplicate_recordable, locked.recordable)
            apply_duplication_rename(dup_recordable, prefix: resolved_prefix, suffix: resolved_suffix)
            dup_recordable.save!

            new_recording = RecordingStudio.record!(
              action:            "duplicated",
              recordable:        dup_recordable,
              root_recording:    locked.root_recording,
              parent_recording:  locked.parent_recording,
              actor:             actor,
              impersonator:      impersonator,
              metadata:          metadata
            )

            duplicate_child_recordings(
              locked, new_recording,
              actor: actor, impersonator: impersonator, metadata: metadata,
              prefix: resolved_prefix, suffix: resolved_suffix,
              include_children: resolved_include, exclude_children: resolved_exclude
            )

            after_duplicate.call(new_recording) if after_duplicate
            GemTemplate::Hooks.run(:after_duplicate, new_recording)

            new_recording
          end
        end

        private

        # Acquire an exclusive row lock on this recording.
        # Extracted so tests can override without touching ActiveRecord.
        def acquire_lock
          self.class.lock.find(id)
        end

        # Apply prefix/suffix rename to a recordable's name or title attribute.
        # Falls back through: configured attribute → :name → :title.
        # No-ops silently when neither attribute is present.
        def apply_duplication_rename(recordable, prefix:, suffix:)
          attr_name = GemTemplate.configuration.duplication_rename_attribute
          attr_name ||= if recordable.respond_to?(:name)
                          :name
                        elsif recordable.respond_to?(:title)
                          :title
                        end

          return unless attr_name && recordable.respond_to?(attr_name)

          current_value = recordable.public_send(attr_name).to_s
          recordable.public_send(:"#{attr_name}=", "#{prefix}#{current_value}#{suffix}")
        end

        # Duplicate child recordings of *source_recording* under *new_parent*.
        # Filtering rules:
        #   - include_children set  → only copy those types
        #   - exclude_children set  → copy all except those types
        #   - neither set (both nil) → copy nothing (default-off)
        def duplicate_child_recordings(source_recording, new_parent_recording,
                                        actor:, impersonator:, metadata:,
                                        prefix:, suffix:,
                                        include_children:, exclude_children:)
          return if include_children.nil? && exclude_children.nil?

          children = source_recording.child_recordings

          children_to_copy =
            if include_children
              include_types = Array(include_children).map { |t| t.is_a?(Class) ? t.name : t.to_s }
              children.select { |c| include_types.include?(c.recordable_type) }
            elsif exclude_children
              exclude_types = Array(exclude_children).map { |t| t.is_a?(Class) ? t.name : t.to_s }
              children.reject { |c| exclude_types.include?(c.recordable_type) }
            else
              []
            end

          child_root = new_parent_recording.root_recording || new_parent_recording

          children_to_copy.each do |child|
            dup_child = source_recording.send(:duplicate_recordable, child.recordable)
            apply_duplication_rename(dup_child, prefix: prefix, suffix: suffix)
            dup_child.save!

            RecordingStudio.record!(
              action:           "duplicated",
              recordable:       dup_child,
              root_recording:   child_root,
              parent_recording: new_parent_recording,
              actor:            actor,
              impersonator:     impersonator,
              metadata:         metadata
            )
          end
        end
      end
    end
  end
end

if defined?(RecordingStudio)
  RecordingStudio.register_capability(
    :duplicatable,
    GemTemplate::Capabilities::Duplicatable::RecordingMethods
  )
end
