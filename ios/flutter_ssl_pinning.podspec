#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_ssl_pinning.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_ssl_pinning'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for validating SHA-1 or SHA-256 SSL certificate.'
  s.description      = <<-DESC
A Flutter plugin for validating SHA-1 or SHA-256 SSL certificate.
                       DESC
  s.homepage         = 'https://github.com/eyro-labs/flutter_ssl_pinning'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Eyro Labs' => 'maulana@cubeacon.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'CryptoSwift'
  s.dependency 'Alamofire', '~> 4.7'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
