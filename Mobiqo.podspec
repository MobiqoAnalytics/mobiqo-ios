# mobiqo-ios/Mobiqo.podspec
Pod::Spec.new do |s|
  s.name             = 'Mobiqo'
  s.version          = '0.0.9'
  s.summary          = 'Mobiqo SDK for native iOS applications.'
  s.description      = <<-DESC
                     The Mobiqo SDK allows native iOS applications to track user events,
                     sync user data, and integrate with the Mobiqo analytics platform.
                     DESC
  s.homepage         = 'https://github.com/MobiqoAnalytics/mobiqo-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mobiqo' => 'contact@getmobiqo.com' }
  s.source           = { :git => 'https://github.com/MobiqoAnalytics/mobiqo-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.static_framework = true

  s.source_files = 'Sources/**/*.swift'

  # s.dependency 'Alamofire', '~> 5.0' # Example if you had external dependencies
end
