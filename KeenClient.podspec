Pod::Spec.new do |spec|
  spec.name         = 'KeenClient'
  spec.version      = '3.2.20'
  spec.license      = { :type => 'MIT' }
  spec.ios.deployment_target = '6.0'
  spec.osx.deployment_target = '10.9'
  spec.homepage     = 'https://github.com/keenlabs/KeenClient-iOS'
  spec.authors      = { 'Daniel Kador' => 'dan@keen.io' }
  spec.summary      = 'Keen iOS client library.'
  spec.description	= <<-DESC
                      The Keen client is designed to be simple to develop with, yet incredibly flexible.  Our goal is to let you decide what events are important to you, use your own vocabulary to describe them, and decide when you want to send them to Keen service.
                      DESC
  spec.source       = { :git => 'https://github.com/keenlabs/KeenClient-iOS.git', :tag => '3.2.20' }
  spec.source_files = 'KeenClient/*.{h,m}','Library/sqlite-amalgamation/*.{h,c}','Library/Reachability/*.{h,m}'
  spec.public_header_files = 'KeenClient/*.h'
  spec.private_header_files = 'Library/sqlite-amalgamation/*.h'
  spec.frameworks   = 'CoreLocation'
  spec.requires_arc = true
end
