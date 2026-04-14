Recording Studio duplicatable addon install complete.

Next steps:

1. Review config/initializers/gem_template.rb and set any duplication defaults you need.
2. If you use environment-specific settings, create config/gem_template.yml.
3. Run bin/rails tailwindcss:build if you use Tailwind CSS.
4. Mount routes are added at the configured mount path. Adjust auth, layout, and `Current.actor` integration to match your host app.
