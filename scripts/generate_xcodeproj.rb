#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'rubygems'

ENV['GEM_HOME'] ||= File.expand_path('../../.gem', __dir__)
ENV['GEM_PATH'] ||= ENV['GEM_HOME']
Gem.clear_paths

require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
PROJECT_NAME = 'UsagePulse'
PROJECT_PATH = File.join(ROOT, "#{PROJECT_NAME}.xcodeproj")
DEPLOYMENT_TARGET = '14.0'
APP_GROUP_ID = 'group.com.dannysongyd.usagepulse.shared'

def configure_project_settings(project)
  project.root_object.attributes['LastSwiftUpdateCheck'] = '2600'
  project.root_object.attributes['LastUpgradeCheck'] = '2600'

  project.build_configuration_list.build_configurations.each do |config|
    settings = config.build_settings
    settings['CLANG_ENABLE_MODULES'] = 'YES'
    settings['CURRENT_PROJECT_VERSION'] = '1'
    settings['MACOSX_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    settings['MARKETING_VERSION'] = '1.0'
    settings['SWIFT_VERSION'] = '6.0'
  end
end

def apply_settings(target, values)
  target.build_configurations.each do |config|
    config.build_settings.merge!(values)
  end
end

def add_group_files(group, paths)
  paths.map { |path| group.new_file(path) }
end

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH)
configure_project_settings(project)

main_group = project.main_group
main_group.set_source_tree(:group)

app_group = main_group.new_group('UsagePulseApp', 'UsagePulseApp')
widget_group = main_group.new_group('UsagePulseWidgetExtension', 'UsagePulseWidgetExtension')
shared_group = main_group.new_group('UsagePulseShared', 'UsagePulseShared')
tests_group = main_group.new_group('UsagePulseTests', 'UsagePulseTests')
scripts_group = main_group.new_group('scripts', 'scripts')
scripts_group.new_file('generate_xcodeproj.rb')

shared_target = project.new_target(:framework, 'UsagePulseShared', :osx, DEPLOYMENT_TARGET, nil, :swift)
app_target = project.new_target(:application, PROJECT_NAME, :osx, DEPLOYMENT_TARGET, nil, :swift)
widget_target = project.new_target(:app_extension, 'UsagePulseWidgetExtension', :osx, DEPLOYMENT_TARGET, nil, :swift)
tests_target = project.new_target(:unit_test_bundle, 'UsagePulseTests', :osx, DEPLOYMENT_TARGET, nil, :swift)

widget_target.product_type = 'com.apple.product-type.app-extension'

shared_sources = add_group_files(shared_group, %w[
  Models.swift
  Formatters.swift
  Store.swift
  Providers.swift
])
shared_target.add_file_references(shared_sources)

app_sources = add_group_files(app_group, %w[
  UsagePulseApp.swift
  AppModel.swift
  ContentView.swift
  ProviderCardView.swift
  SettingsView.swift
])
app_assets = app_group.new_file('Assets.xcassets')
app_group.new_file('UsagePulseApp.entitlements')
app_target.add_file_references(app_sources)
app_target.add_resources([app_assets])

widget_sources = add_group_files(widget_group, %w[
  UsagePulseWidgetBundle.swift
  UsagePulseWidget.swift
])
widget_assets = widget_group.new_file('Assets.xcassets')
widget_group.new_file('UsagePulseWidgetExtension.entitlements')
widget_target.add_file_references(widget_sources)
widget_target.add_resources([widget_assets])

test_sources = add_group_files(tests_group, %w[
  UsagePulseSharedTests.swift
])
tests_target.add_file_references(test_sources)

app_target.add_dependency(shared_target)
widget_target.add_dependency(shared_target)
tests_target.add_dependency(shared_target)
app_target.add_dependency(widget_target)

[app_target, widget_target, tests_target].each do |target|
  target.frameworks_build_phase.add_file_reference(shared_target.product_reference, true)
end

embed_frameworks = app_target.new_copy_files_build_phase('Embed Frameworks')
embed_frameworks.dst_subfolder_spec = Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:frameworks]
app_framework_build_file = embed_frameworks.add_file_reference(shared_target.product_reference, true)
app_framework_build_file.settings = { 'ATTRIBUTES' => %w[CodeSignOnCopy RemoveHeadersOnCopy] }

widget_embed_frameworks = widget_target.new_copy_files_build_phase('Embed Frameworks')
widget_embed_frameworks.dst_subfolder_spec = Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:frameworks]
widget_framework_build_file = widget_embed_frameworks.add_file_reference(shared_target.product_reference, true)
widget_framework_build_file.settings = { 'ATTRIBUTES' => %w[CodeSignOnCopy RemoveHeadersOnCopy] }

embed_extensions = app_target.new_copy_files_build_phase('Embed App Extensions')
embed_extensions.dst_subfolder_spec = Xcodeproj::Constants::COPY_FILES_BUILD_PHASE_DESTINATIONS[:plug_ins]
extension_build_file = embed_extensions.add_file_reference(widget_target.product_reference, true)
extension_build_file.settings = { 'ATTRIBUTES' => %w[CodeSignOnCopy RemoveHeadersOnCopy] }

shared_target.add_system_framework('Foundation')
app_target.add_system_framework(%w[SwiftUI WidgetKit])
widget_target.add_system_framework(%w[SwiftUI WidgetKit])
tests_target.add_system_framework('XCTest')

apply_settings(shared_target, {
  'CODE_SIGN_STYLE' => 'Automatic',
  'DEFINES_MODULE' => 'YES',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'INFOPLIST_KEY_CFBundleDisplayName' => 'UsagePulse Shared',
  'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @loader_path/../Frameworks @loader_path/Frameworks',
  'PRODUCT_BUNDLE_IDENTIFIER' => 'com.dannysongyd.usagepulse.shared',
  'SKIP_INSTALL' => 'YES',
  'SWIFT_VERSION' => '6.0'
})

apply_settings(app_target, {
  'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => 'AccentColor',
  'CODE_SIGN_ENTITLEMENTS' => 'UsagePulseApp/UsagePulseApp.entitlements',
  'CODE_SIGN_STYLE' => 'Automatic',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'INFOPLIST_KEY_CFBundleDisplayName' => PROJECT_NAME,
  'INFOPLIST_KEY_LSApplicationCategoryType' => 'public.app-category.developer-tools',
  'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/../Frameworks',
  'PRODUCT_BUNDLE_IDENTIFIER' => 'com.dannysongyd.usagepulse',
  'PRODUCT_NAME' => PROJECT_NAME,
  'SWIFT_EMIT_LOC_STRINGS' => 'YES',
  'SWIFT_VERSION' => '6.0'
})

apply_settings(widget_target, {
  'APPLICATION_EXTENSION_API_ONLY' => 'YES',
  'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => 'AccentColor',
  'CODE_SIGN_ENTITLEMENTS' => 'UsagePulseWidgetExtension/UsagePulseWidgetExtension.entitlements',
  'CODE_SIGN_STYLE' => 'Automatic',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'INFOPLIST_KEY_CFBundleDisplayName' => 'UsagePulse Widget',
  'INFOPLIST_KEY_NSExtensionPointIdentifier' => 'com.apple.widgetkit-extension',
  'INFOPLIST_KEY_NSExtensionPrincipalClass' => '$(PRODUCT_MODULE_NAME).UsagePulseWidgetBundle',
  'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/../../Frameworks @executable_path/../Frameworks',
  'PRODUCT_BUNDLE_IDENTIFIER' => 'com.dannysongyd.usagepulse.widget',
  'PRODUCT_NAME' => 'UsagePulseWidgetExtension',
  'SKIP_INSTALL' => 'YES',
  'SWIFT_VERSION' => '6.0'
})

apply_settings(tests_target, {
  'CODE_SIGN_STYLE' => 'Automatic',
  'GENERATE_INFOPLIST_FILE' => 'YES',
  'INFOPLIST_KEY_CFBundleDisplayName' => 'UsagePulse Tests',
  'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @loader_path/../Frameworks @loader_path/Frameworks',
  'PRODUCT_BUNDLE_IDENTIFIER' => 'com.dannysongyd.usagepulse.tests',
  'SWIFT_VERSION' => '6.0',
  'TEST_TARGET_NAME' => 'UsagePulseShared'
})

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app_target, tests_target, launch_target: true)
scheme.add_build_target(shared_target, false)
scheme.add_build_target(widget_target, false)
scheme.save_as(PROJECT_PATH, PROJECT_NAME, true)

project.sort
project.save

puts "Generated #{PROJECT_PATH}"
puts "App Group: #{APP_GROUP_ID}"
