Pod::Spec.new do |s|
    s.name        = "AdnuntiusSDK"
    s.version     = "1.10.3"
    s.summary     = "Adnuntius ios SDK"
    s.homepage    = "https://github.com/Adnuntius/ios_sdk"
    s.license     = { :type => "MIT" }
    s.authors     = { "AUTHOR_NAME" => "AUTHOR_EMAIL" }
  
    s.requires_arc = true
    s.swift_version = "5.0"
    s.ios.deployment_target = "9.0"
    s.source   = { :git => "https://github.com/Adnuntius/ios_sdk.git", :tag => s.version }
    s.source_files = "AdnuntiusSDK/*.swift"
  end