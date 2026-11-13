#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ping_davinci.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ping_davinci'
  s.version          = '0.0.1'
  s.summary          = 'Flutter bridge for the Ping DaVinci SDK.'
  s.description      = <<-DESC
Flutter bridge for the Ping DaVinci SDK: drives native DaVinci orchestration
(nodes, collectors, sessions) from Dart via ping_core.
                       DESC
  s.homepage         = 'https://github.com/ForgeRock/ping-ios-sdk'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'Ping Identity' => 'oss@pingidentity.com' }
  s.source           = { :path => '.' }
  s.source_files = 'ping_davinci/Sources/ping_davinci/**/*'
  s.dependency 'Flutter'
  s.dependency 'ping_core'
  s.dependency 'PingDavinci', '2.2.0'
  s.dependency 'PingDavinciPlugin', '2.2.0'
  s.dependency 'PingOrchestrate', '2.2.0'
  s.dependency 'PingOidc', '2.2.0'
  s.dependency 'PingBrowser', '2.2.0'
  s.dependency 'PingStorage', '2.2.0'
  s.dependency 'PingLogger', '2.2.0'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'

  s.resource_bundles = {'ping_davinci_privacy' => ['ping_davinci/Sources/ping_davinci/PrivacyInfo.xcprivacy']}
end
