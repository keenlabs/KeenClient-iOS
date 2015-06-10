def default_pods
  pod 'Reachability', '~> 3.2'
end

source 'https://github.com/CocoaPods/Specs.git'

workspace 'KeenClient'
xcodeproj 'KeenClient'

target 'KeenClient' do
  platform :ios, '6.0'
  default_pods
end

target 'KeenClientTests', :exclusive => true do
  pod 'OCMock'
end

target 'KeenClient-Simulator' do
  platform :ios, '6.0'
  default_pods
end

target 'KeenClient-Device' do
  platform :ios, '6.0'
  default_pods
end

target 'KeenClient-Cocoa' do
  platform :osx, '10.8'
  default_pods
end

post_install do |installer|
  installer.project.targets.each do |target|
    target.build_configurations.each do |configuration|
      if target.name == 'Pods-KeenClient-Device' ||
         target.name == 'Pods-KeenClient-Device-Reachability'
        target.build_settings(configuration.name)['SUPPORTED_PLATFORMS'] = 'iphoneos'
      end
      target.build_settings(configuration.name)['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end