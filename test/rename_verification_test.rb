# frozen_string_literal: true

require "test_helper"

class RenameVerificationTest < Minitest::Test
  def setup
    @root = File.expand_path("..", __dir__)
  end

  def test_no_old_gem_name_references_remain_in_repo_text_files
    files_with_old_refs = tracked_text_files.filter_map do |path|
      next unless File.file?(path)

      contents = File.read(path)
      path if contents.include?("gem_template") || contents.include?("GemTemplate")
    end

    assert_empty files_with_old_refs, "Found old gem name references in:\n#{files_with_old_refs.join("\n")}"
  end

  def test_old_gem_paths_do_not_exist
    old_paths = [
      File.join(@root, "gem_template.gemspec"),
      File.join(@root, "lib", "gem_template.rb"),
      File.join(@root, "lib", "gem_template"),
      File.join(@root, "app", "controllers", "gem_template"),
      File.join(@root, "app", "views", "gem_template"),
      File.join(@root, "lib", "generators", "gem_template")
    ]

    existing_paths = old_paths.select { |path| File.exist?(path) }

    assert_empty existing_paths, "Found old gem paths:\n#{existing_paths.join("\n")}"
  end

  def test_renamed_core_paths_exist
    new_paths = [
      File.join(@root, "recording_studio_duplicatable.gemspec"),
      File.join(@root, "lib", "recording_studio_duplicatable.rb"),
      File.join(@root, "lib", "recording_studio_duplicatable"),
      File.join(@root, "app", "controllers", "recording_studio_duplicatable"),
      File.join(@root, "app", "views", "recording_studio_duplicatable"),
      File.join(@root, "lib", "generators", "recording_studio_duplicatable")
    ]

    missing_paths = new_paths.reject { |path| File.exist?(path) }

    assert_empty missing_paths, "Missing renamed gem paths:\n#{missing_paths.join("\n")}"
  end

  private

  def tracked_text_files
    Dir.glob(File.join(@root, "**", "*"))
       .reject { |path| File.directory?(path) }
       .reject { |path| path.include?("/.git/") || path.include?("/vendor/") || path.include?("/coverage/") }
       .reject { |path| path.end_with?("/test/rename_verification_test.rb") }
       .select { |path| text_file?(path) }
  end

  def text_file?(path)
    text_extensions = %w[.rb .erb .md .gemspec .yml .yaml .sh .ru .rake .css .js .json .lock]
    text_extensions.include?(File.extname(path)) || %w[Gemfile Rakefile].include?(File.basename(path))
  end
end
