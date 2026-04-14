# frozen_string_literal: true

require_relative "hooks"

module GemTemplate
  class Configuration
    attr_accessor :duplication_prefix, :duplication_suffix, :duplication_rename_attribute
    attr_reader :hooks

    def initialize
      @hooks = Hooks.new

      # Duplicatable capability defaults
      @duplication_prefix           = nil
      @duplication_suffix           = " (Copy)"
      @duplication_rename_attribute = nil # nil = auto-detect :name then :title
    end

    def to_h
      {
        duplication_prefix: duplication_prefix,
        duplication_suffix: duplication_suffix,
        duplication_rename_attribute: duplication_rename_attribute,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
