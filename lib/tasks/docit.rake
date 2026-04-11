# frozen_string_literal: true

namespace :docit do
  desc "Generate documentation for undocumented API endpoints using AI"
  task :autodoc, [:controller] => :environment do |_t, args|
    dry_run = ENV.fetch("DRY_RUN", "0") == "1" || ARGV.include?("--dry-run")
    controller_filter = args[:controller]

    runner = Docit::Ai::AutodocRunner.new(
      controller_filter: controller_filter,
      dry_run: dry_run
    )

    runner.run
  rescue Docit::Error => e
    warn e.message
    exit 1
  end
end
