# frozen_string_literal: true

module GemTemplate
  module Services
    # Service object that wraps Recording#duplicate_in_place! with a
    # standardised Result interface.
    #
    # Handles all expected failure modes from the :duplicatable capability
    # (AccessDenied, CapabilityDisabled) and any unexpected StandardError,
    # converting each into a failure Result so callers don't need rescue blocks.
    #
    # @example Basic usage
    #   result = GemTemplate::Services::DuplicationService.call(
    #     recording: recording,
    #     actor:     current_user
    #   )
    #   result.on_success { |new_rec| redirect_to new_rec }
    #   result.on_failure { |msg|     render_error(msg) }
    #
    # @example With rename override and child copying
    #   result = GemTemplate::Services::DuplicationService.call(
    #     recording:        recording,
    #     actor:            current_user,
    #     suffix:           " — clone",
    #     include_children: ["Section"]
    #   )
    #
    # @example With a post-duplication callback
    #   result = GemTemplate::Services::DuplicationService.call(
    #     recording:      recording,
    #     actor:          current_user,
    #     after_duplicate: ->(new_rec) { notify_team(new_rec) }
    #   )
    #
    class DuplicationService < BaseService
      # @param recording [RecordingStudio::Recording] The recording to duplicate
      # @param actor [Object] The actor performing the duplication
      # @param prefix [String, nil, :default] Prefix for the duplicate's name/title
      # @param suffix [String, nil, :default] Suffix for the duplicate's name/title
      # @param include_children [:default, Array, nil] Child types to copy
      # @param exclude_children [:default, Array, nil] Child types to skip
      # @param impersonator [Object, nil] Impersonating actor, if any
      # @param metadata [Hash] Metadata stored on the recording event
      # @param after_duplicate [Proc, nil] Optional callback called with the new recording
      def initialize(recording:, actor:,
                     prefix: :default, suffix: :default,
                     include_children: :default, exclude_children: :default,
                     impersonator: nil, metadata: {},
                     after_duplicate: nil)
        @recording        = recording
        @actor            = actor
        @prefix           = prefix
        @suffix           = suffix
        @include_children = include_children
        @exclude_children = exclude_children
        @impersonator     = impersonator
        @metadata         = metadata
        @after_duplicate  = after_duplicate
      end

      private

      def perform
        new_recording = @recording.duplicate_in_place!(
          actor:            @actor,
          impersonator:     @impersonator,
          metadata:         @metadata,
          prefix:           @prefix,
          suffix:           @suffix,
          include_children: @include_children,
          exclude_children: @exclude_children,
          &@after_duplicate
        )
        success(new_recording)
      rescue RecordingStudio::AccessDenied, RecordingStudio::CapabilityDisabled => e
        # Expected capability failures — return as structured failures
        failure(e)
      rescue StandardError => e
        # Unexpected errors — still converted to failure Results so callers
        # never need bare rescue blocks around DuplicationService.call
        failure(e)
      end

      def service_args
        { recording: @recording, actor: @actor }
      end
    end
  end
end
