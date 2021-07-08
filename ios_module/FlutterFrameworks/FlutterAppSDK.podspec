Pod::Spec.new do |s|
  s.name                  = 'FlutterAppSDK'
  s.version               = '1.0.1'
  s.summary               = 'Flutter App SDK'
  s.description           = <<-DESC
SDK整合了FlutterModule编译后的产物
DESC
  s.homepage              = 'https://github.com/XiFengLang/JKFlutter'
  s.license               = { :type => 'MIT', :text => <<-LICENSE
Copyright 2021 The Flutter Authors. All rights reserved.
LICENSE
  }
  s.author                = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source                = { :git => 'http://gitlab.private.com/flutter/flutter_app_sdk.git', :tag => "#{s.version}" }
  s.documentation_url     = 'https://flutter.dev/docs'
  s.platform              = :ios, '8.0'
  s.requires_arc          = true
  s.vendored_frameworks   = '*.xcframework'
end
