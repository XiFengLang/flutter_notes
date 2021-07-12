Pod::Spec.new do |s|
  s.name                  = 'PodSpecs'
  s.version               = '1.0.0'
  s.summary               = 'Flutter Engine Framework'
  s.description           = <<-DESC
podspec文件汇总仓库
DESC
  s.homepage              = 'https://flutter.dev'
  s.author                = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source                = { :git => 'https://github.com/XiFengLang/podspecs.git', :tag => "#{s.version}" }
  s.documentation_url     = 'https://flutter.dev/docs'
  s.platform              = :ios, '8.0'
  s.source_files          = '*.podspec'
end
