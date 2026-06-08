#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "xcodeproj"

root = Pathname.new(__dir__).parent
project = Xcodeproj::Project.open(root.join("Barcade.xcodeproj"))

def ensure_group(root_group, components)
  components.reduce(root_group) do |group, component|
    group.groups.find { |child| child.path == component || child.name == component } ||
      group.new_group(component, component)
  end
end

def sync_swift_files(project:, root:, folder:, target_name:)
  target = project.targets.find { |candidate| candidate.name == target_name } ||
    raise("Missing target: #{target_name}")
  root_group = project.main_group.groups.find do |group|
    group.path == folder || group.name == folder
  end
  raise("Missing group: #{folder}") unless root_group

  target.source_build_phase.files.each do |build_file|
    file = build_file.file_ref
    next unless file&.path&.end_with?(".swift")
    next if file.real_path.exist?

    build_file.remove_from_project
    file.remove_from_project
  end

  root.join(folder).glob("**/*.swift").sort.each do |path|
    relative = path.relative_path_from(root.join(folder))
    group = ensure_group(root_group, relative.each_filename.to_a[0...-1])
    file = group.files.find { |candidate| candidate.path == relative.basename.to_s } ||
      group.new_file(relative.basename.to_s)

    next if target.source_build_phase.files_references.include?(file)

    target.add_file_references([file])
  end
end

sync_swift_files(project: project, root: root, folder: "Sources", target_name: "Barcade")
sync_swift_files(project: project, root: root, folder: "Tests", target_name: "BarcadeTests")
project.save
