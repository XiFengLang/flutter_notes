# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

require 'json'

# Install pods needed to embed Flutter application, Flutter engine, and plugins
# from the host application Podfile.
#
# @example
#   target 'MyApp' do
#     flutter_application_path = '../flutter_module/'     
#     load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')
#     install_all_flutter_pods(flutter_application_path)
#   end
# @param [String] flutter_application_path Path of the root directory of the Flutter module.  # Flutter Module所在目录
#                                          Optional, defaults to two levels up from the directory of this script.
#                                          MyApp/my_flutter/.ios/Flutter/../..    # 本脚本所在位置
def install_all_flutter_pods(flutter_application_path = nil)
  flutter_application_path ||= File.join('..', '..')

  # 本地依赖 Flutter.framework
  install_flutter_engine_pod
  # 本地依赖 FlutterPluginRegistrant 和 其它第三方库
  install_flutter_plugin_pods(flutter_application_path)
  # 本地依赖  App.framework
  install_flutter_application_pod(flutter_application_path)
end

# Install Flutter engine pod.
#
# @example
#   target 'MyApp' do
#     install_flutter_engine_pod
#   end
# 增加Flutter本地依赖，导入了Flutter.xcframework，也就是包含了核心引擎
def install_flutter_engine_pod
  # 当前目录  flutter_module/.ios/Flutter
  current_directory = File.expand_path('..', __FILE__)

  # flutter_module/.ios/Flutter/engine
  engine_dir = File.expand_path('engine', current_directory)

  # flutter_module/.ios/Flutter/engine/Flutter.xcframework
  framework_name = 'Flutter.xcframework'
  copied_engine = File.expand_path(framework_name, engine_dir)

  if !File.exist?(copied_engine)
    # Copy the debug engine to have something to link against if the xcode backend script has not run yet.
    # CocoaPods will not embed the framework on pod install (before any build phases can generate) if the dylib does not exist.

    # 3种编译模式下Flutter.xcframework源文件对应的路径，这些路径都在Flutter engine里面
    # {FLUTTER_ROOT}/bin/cache/artifacts/engine/ios/
    # {FLUTTER_ROOT}/bin/cache/artifacts/engine/ios-release/
    # {FLUTTER_ROOT}/bin/cache/artifacts/engine/ios-profile/
    # 这些文件夹里面包含了 Flutter.podspec / LICENSE / Flutter.xcframework / gen_snapshot_arm64 / gen_snapshot_armv7


    release_framework_dir = File.join(flutter_root, 'bin', 'cache', 'artifacts', 'engine', 'ios-release')
    unless Dir.exist?(release_framework_dir)
      # iOS artifacts have not been downloaded.
      raise "#{release_framework_dir} must exist. Make sure \"flutter build ios\" has been run at least once"
    end

    # 从{FLUTTER_ROOT}/bin/cache/artifacts/engine/ios-release/ 拷贝 Flutter.xcframework 到 flutter_module/.ios/Flutter/engine/
    FileUtils.cp_r(File.join(release_framework_dir, framework_name), engine_dir)
  end

  # Keep pod path relative so it can be checked into Podfile.lock.
  # Process will be run from project directory.
  engine_pathname = Pathname.new engine_dir
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  project_directory_pathname = defined_in_file.dirname
  # 相对路径
  relative = engine_pathname.relative_path_from project_directory_pathname

  # 由于 flutter_module/.ios/Flutter/engine/ 里面还有个 Flutter.podspec，所以这里就直接本地依赖Flutter
  pod 'Flutter', :path => relative.to_s, :inhibit_warnings => true
end

# Install Flutter plugin pods.
#
# @example
#   target 'MyApp' do
#     install_flutter_plugin_pods 'my_flutter'
#   end
# @param [String] flutter_application_path Path of the root directory of the Flutter module.
#                                          Optional, defaults to two levels up from the directory of this script.
#                                          MyApp/my_flutter/.ios/Flutter/../..
# 本地依赖 FlutterPluginRegistrant 和 其它第三方库
def install_flutter_plugin_pods(flutter_application_path)
  flutter_application_path ||= File.join('..', '..')

  # Keep pod path relative so it can be checked into Podfile.lock.
  # Process will be run from project directory.
  # Runner.xcworkspace 所在目录
  ios_project_directory_pathname = Pathname.new File.expand_path(File.join('..', '..'), __FILE__)
  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  project_directory_pathname = defined_in_file.dirname
  # 相对于Podfile所在目录的相对路径
  relative = ios_project_directory_pathname.relative_path_from project_directory_pathname

  # 新增本地依赖 FlutterPluginRegistrant 
  pod 'FlutterPluginRegistrant', :path => File.join(relative, 'Flutter', 'FlutterPluginRegistrant'), :inhibit_warnings => true

  # 创建 /.symlinks/plugins/
  symlinks_dir = File.join(relative, '.symlinks', 'plugins')
  FileUtils.mkdir_p(symlinks_dir)

  plugins_file = File.expand_path('.flutter-plugins-dependencies', flutter_application_path)
  # 解析.flutter-plugins-dependencies文件里的JSON数据，读取ios端依赖的第三方插件
  plugin_pods = flutter_parse_dependencies_file_for_ios_plugin(plugins_file)
  plugin_pods.each do |plugin_hash|
    plugin_name = plugin_hash['name']   # 插件名
    plugin_path = plugin_hash['path']   # 代码所在的相对路径
    if (plugin_name && plugin_path)
      # 给每个插件创建文件替身，实际的文件在 flutter_root/.pub-cache/git/plugin_name-identifier 文件夹里
      symlink = File.join(symlinks_dir, plugin_name)
      FileUtils.rm_f(symlink)
      File.symlink(plugin_path, symlink)

      # 新增第三方组件库的本地依赖
      pod plugin_name, :path => File.join(symlink, 'ios'), :inhibit_warnings => true
    end
  end
end

# Install Flutter application pod.
#
# @example
#   target 'MyApp' do
#     install_flutter_application_pod '../flutter_settings_repository'
#   end
# @param [String] flutter_application_path Path of the root directory of the Flutter module.
#                                          Optional, defaults to two levels up from the directory of this script.
#                                          MyApp/my_flutter/.ios/Flutter/../..
# 本地依赖  App.framework
def install_flutter_application_pod(flutter_application_path)
  current_directory_pathname = Pathname.new File.expand_path('..', __FILE__)
  app_framework_dir = File.expand_path('App.framework', current_directory_pathname.to_path)
  # App.framework/App 是一个可执行文件
  app_framework_dylib = File.join(app_framework_dir, 'App')  

  if !File.exist?(app_framework_dylib)
    # Fake an App.framework to have something to link against if the xcode backend script has not run yet.
    # CocoaPods will not embed the framework on pod install (before any build phases can run) if the dylib does not exist.
    # Create a dummy dylib.

    # xcode_backend.sh 按官方推荐是放在build phases中执行的，执行完才会编译导出App.framework，
    # 如果脚本还没执行，就需要先造一个假的App可执行文件放在App.framework里面
    FileUtils.mkdir_p(app_framework_dir)
    `echo "static const int Moo = 88;" | xcrun clang -x c -dynamiclib -o "#{app_framework_dylib}" -`
  end

  # Keep pod and script phase paths relative so they can be checked into source control.
  # Process will be run from project directory.

  # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
  project_directory_pathname = defined_in_file.dirname
  relative = current_directory_pathname.relative_path_from project_directory_pathname

  # 新增依赖 flutter_module，指向的地址就是App.framework所在的相对路径
  pod 'flutter_module', :path => relative.to_s, :inhibit_warnings => true

  # 用到的是flutter_export_environment.sh脚本，声明了一些编译FlutterModule用的常量，执行 xcode_backend.sh 时会用到
  flutter_export_environment_path = File.join('${SRCROOT}', relative, 'flutter_export_environment.sh');

  # 使用script_phase自定义CocoaPods脚本，script_phase的使用方法可以查阅  https://juejin.cn/post/6844903657511583751
  # script_phase 自定义的脚本会被添加到 Build Phases中，名字就叫 `Run Flutter Build flutter_module Script`
  # 这个脚本首先声明各种export，包含了 flutter_export_environment_path.sh里面的export，还有 VERBOSE_SCRIPT_LOGGING
  # 顺带会执行 xcode_backend.sh 脚本，传入参数 build
  # 这些参数可以传  build、thin、embed、embed_and_thin、test_observatory_bonjour_service，相当于这里只是普通编译
  
  # 顺带说一句，早期的Flutter版本，需要手动在Build Phases加执行脚本，以执行 xcode_backend.sh build 和 xcode_backend.sh embed
  
  script_phase :name => 'Run Flutter Build flutter_module Script',
    :script => "set -e\nset -u\nsource \"#{flutter_export_environment_path}\"\nexport VERBOSE_SCRIPT_LOGGING=1 && \"$FLUTTER_ROOT\"/packages/flutter_tools/bin/xcode_backend.sh build",
    :execution_position => :before_compile
end

# .flutter-plugins-dependencies format documented at
# https://flutter.dev/go/plugins-list-migration
# 解析文件里的JSON数据，读取ios端依赖的第三方插件
def flutter_parse_dependencies_file_for_ios_plugin(file)
  file_path = File.expand_path(file)
  return [] unless File.exists? file_path

  dependencies_file = File.read(file)
  dependencies_hash = JSON.parse(dependencies_file)

  # dependencies_hash.dig('plugins', 'ios') not available until Ruby 2.3
  return [] unless dependencies_hash.has_key?('plugins')
  return [] unless dependencies_hash['plugins'].has_key?('ios')
  dependencies_hash['plugins']['ios'] || []
end

# 从 Generated.xcconfig 读取 FLUTTER_ROOT 路径
def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', '..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  # This should never happen...
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end
