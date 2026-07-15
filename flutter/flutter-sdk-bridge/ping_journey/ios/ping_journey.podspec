#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ping_journey.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ping_journey'
  s.version          = '0.0.1'
  s.summary          = 'Flutter bridge for the Ping Journey SDK.'
  s.description      = <<-DESC
Flutter bridge for the Ping Journey SDK: drives native Journey orchestration
(nodes, callbacks, sessions) from Dart via ping_core.
                       DESC
  s.homepage         = 'https://github.com/ForgeRock/ping-ios-sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ping Identity' => 'oss@pingidentity.com' }
  s.source           = { :path => '.' }
  s.source_files = 'ping_journey/Sources/ping_journey/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'ping_journey_privacy' => ['ping_journey/Sources/ping_journey/PrivacyInfo.xcprivacy']}
end
