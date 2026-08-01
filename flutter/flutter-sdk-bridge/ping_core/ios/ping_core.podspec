#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ping_core.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ping_core'
  s.version          = '0.0.1'
  s.summary          = 'Shared runtime for the Ping Flutter SDK bridge.'
  s.description      = <<-DESC
Shared runtime for the Ping Flutter SDK bridge: process-wide native handle
registries, JSON codec, and exception types used by feature plugins.
                       DESC
  s.homepage         = 'https://github.com/ForgeRock/ping-ios-sdk'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'Ping Identity' => 'oss@pingidentity.com' }
  s.source           = { :path => '.' }
  s.source_files = 'ping_core/Sources/ping_core/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'

  s.resource_bundles = {'ping_core_privacy' => ['ping_core/Sources/ping_core/PrivacyInfo.xcprivacy']}
end
