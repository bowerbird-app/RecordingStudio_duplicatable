# frozen_string_literal: true

module RecordingStudioDuplicatable
  # Rules registered for a recordable type. Duplicatable stores and runs them.
  # It does not know which gem registered a rule.
  module CopyRules
    COPY = :copy
    SKIP = :skip

    # Child class names from Recording Studio and Recording Studio Accessible
    # that hold grants or access requests. A child is also excluded when its
    # class name ends in Token or Secret.
    EXCLUDED_CLASS_NAMES = %w[
      Access
      AccessBoundary
      AccessConstraint
      AccessRequest
      AccessRule
      Grant
    ].freeze

    Context = Data.define(:actor, :root_recording, :parent_recording)

    class << self
      def register(type, rule)
        registry[type_name(type)] = validate!(rule)
      end

      def for(type)
        registry[type_name(type)]
      end

      def clear!
        registry.clear
      end

      def excluded?(type)
        name = class_name(type_name(type))
        EXCLUDED_CLASS_NAMES.include?(name) || name.end_with?("Token", "Secret")
      end

      # Per-call and per-type overrides win over the registry.
      # An excluded child type is :skip even when an override says otherwise.
      def resolve(type, overrides = nil)
        return SKIP if excluded?(type)

        name = type_name(type)
        overrides = {} if overrides.nil?
        return overrides[name] if overrides.key?(name)

        registry.fetch(name, COPY)
      end

      def normalize_overrides(rules)
        return {} if rules.nil?

        unless rules.respond_to?(:each_pair)
          raise ArgumentError, "copy_rules must be a Hash of recordable type to :copy, :skip, or a callable"
        end

        rules.each_with_object({}) do |(type, rule), normalized|
          normalized[type_name(type)] = validate!(rule)
        end
      end

      def validate!(rule)
        return rule if [COPY, SKIP].include?(rule)
        return rule if rule.respond_to?(:call)

        raise ArgumentError, "copy rule must be :copy, :skip, or a callable"
      end

      def type_name(type)
        name = type.is_a?(Module) ? type.name : type.to_s
        raise ArgumentError, "copy rule type must be a class or type name" if name.nil? || name.empty?

        name
      end

      def class_name(type_name)
        type_name.to_s.split("::").last
      end

      def registry
        @registry ||= {}
      end
    end
  end
end
