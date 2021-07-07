#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Exit on error
set -e

RunCommand() {
  # $* 和$@的区别  https://www.cnblogs.com/Template/p/9182534.html
  # "$*" 会把所有位置参数当成一个整体  "$1 $2"
  # "$@" 会把所有位置参数当成一个单独的字段展开 "$1"  "$2"
  
  if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    echo "♦ $*"
  fi
  "$@"

  # $? 获取上一个命令的退出状态
  return $?
}

# When provided with a pipe by the host Flutter build process, output to the
# pipe goes to stdout of the Flutter build process directly.
StreamOutput() {
  if [[ -n "$SCRIPT_OUTPUT_STREAM_FILE" ]]; then
    echo "$1" > $SCRIPT_OUTPUT_STREAM_FILE
  fi
}

EchoError() {
  echo "$@" 1>&2
}

AssertExists() {
  if [[ ! -e "$1" ]]; then
    if [[ -h "$1" ]]; then
      EchoError "The path $1 is a symlink to a path that does not exist"
    else
      EchoError "The path $1 does not exist"
    fi
    exit -1
  fi
  return 0
}

# 解析编译模式，如果没有指定FLUTTER_BUILD_MODE，则会使用Xcode的build configuration
# 如果指定某模式，可以在.zshrc文件添加 export FLUTTER_BUILD_MODE='release'
# flutter build ios --release 也可以指定模式
# Xcode CONFIGURATION
# CONFIGURATION是可以自定义的，在Project   -   Info   -    Configrations 里面添加，
# 然后在Project    -    Build Settings   -     Preprocessor Macros   -   添加自定义的宏定义

ParseFlutterBuildMode() {
  # Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
  # This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
  # they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
  local build_mode="$(echo "${FLUTTER_BUILD_MODE:-${CONFIGURATION}}" | tr "[:upper:]" "[:lower:]")"

  # 目前只支持 release / profile / debug 3种模式，所以自定义的build_mode也必须以这三种命名结尾，否则报错 ERROR: Unknown FLUTTER_BUILD_MODE
  case "$build_mode" in
    *release*) build_mode="release";;
    *profile*) build_mode="profile";;
    *debug*) build_mode="debug";;
    *)
      EchoError "========================================================================"
      EchoError "ERROR: Unknown FLUTTER_BUILD_MODE: ${build_mode}."
      EchoError "Valid values are 'Debug', 'Profile', or 'Release' (case insensitive)."
      EchoError "This is controlled by the FLUTTER_BUILD_MODE environment variable."
      EchoError "If that is not set, the CONFIGURATION environment variable is used."
      EchoError ""
      EchoError "You can fix this by either adding an appropriately named build"
      EchoError "configuration, or adding an appropriate value for FLUTTER_BUILD_MODE to the"
      EchoError ".xcconfig file for the current build configuration (${CONFIGURATION})."
      EchoError "========================================================================"
      exit -1;;
  esac
  echo "${build_mode}"
}


# FLUTTER_APPLICATION_PATH这些配置都在/flutter_module/.ios/Flutter/flutter_export_environment.sh 和 Generated.xcconfig中声明

BuildApp() {
  local project_path="${SOURCE_ROOT}/.."
  if [[ -n "$FLUTTER_APPLICATION_PATH" ]]; then
    project_path="${FLUTTER_APPLICATION_PATH}"
  fi

  local target_path="lib/main.dart"
  if [[ -n "$FLUTTER_TARGET" ]]; then
    target_path="${FLUTTER_TARGET}"
  fi

  local derived_dir="${SOURCE_ROOT}/Flutter"
  if [[ -e "${project_path}/.ios" ]]; then
    derived_dir="${project_path}/.ios/Flutter"
  fi

  local bundle_sksl_path=""
  if [[ -n "$BUNDLE_SKSL_PATH" ]]; then
    bundle_sksl_path="-iBundleSkSLPath=${BUNDLE_SKSL_PATH}"
  fi

  # Default value of assets_path is flutter_assets
  local assets_path="flutter_assets"
  # The value of assets_path can set by add FLTAssetsPath to
  # AppFrameworkInfo.plist.
  if FLTAssetsPath=$(/usr/libexec/PlistBuddy -c "Print :FLTAssetsPath" "${derived_dir}/AppFrameworkInfo.plist" 2>/dev/null); then
    if [[ -n "$FLTAssetsPath" ]]; then
      assets_path="${FLTAssetsPath}"
    fi
  fi

  # Use FLUTTER_BUILD_MODE if it's set, otherwise use the Xcode build configuration name
  # This means that if someone wants to use an Xcode build config other than Debug/Profile/Release,
  # they _must_ set FLUTTER_BUILD_MODE so we know what type of artifact to build.
  local build_mode="$(ParseFlutterBuildMode)"
  local artifact_variant="unknown"
  case "$build_mode" in
    release ) artifact_variant="ios-release";;
    profile ) artifact_variant="ios-profile";;
    debug ) artifact_variant="ios";;
  esac

  # 在非release模式打包，警告用户
  # Warn the user if not archiving (ACTION=install) in release mode.
  if [[ "$ACTION" == "install" && "$build_mode" != "release" ]]; then
    echo "warning: Flutter archive not built in Release mode. Ensure FLUTTER_BUILD_MODE \
is set to release or run \"flutter build ios --release\", then re-run Archive from Xcode."
  fi


  # 3种编译模式下Flutter.xcframework源文件对应的路径，这些路径都在Flutter engine里面
  # {FLUTTER_ROOT}/bin/cache/artifacts/engine/ios/
  # {FLUTTER_ROOT}/bin/cache/artifacts/engine/ios-release/
  # {FLUTTER_ROOT}/bin/cache/artifacts/engine/ios-profile/
  # 这些文件夹里面包含了 Flutter.podspec / LICENSE / Flutter.xcframework / gen_snapshot_arm64 / gen_snapshot_armv7

  # flutter_framework 指向了Flutter.xcframework源文件所在路径，编译产物就是从这里复制出去加工的

  local framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/${artifact_variant}"
  local flutter_engine_flag=""
  local local_engine_flag=""
  local flutter_framework="${framework_path}/Flutter.xcframework"

  if [[ -n "$FLUTTER_ENGINE" ]]; then
    flutter_engine_flag="--local-engine-src-path=${FLUTTER_ENGINE}"
  fi

  # 这里应该是指向自定义的引擎路径
  if [[ -n "$LOCAL_ENGINE" ]]; then
    if [[ $(echo "$LOCAL_ENGINE" | tr "[:upper:]" "[:lower:]") != *"$build_mode"* ]]; then
      EchoError "========================================================================"
      EchoError "ERROR: Requested build with Flutter local engine at '${LOCAL_ENGINE}'"
      EchoError "This engine is not compatible with FLUTTER_BUILD_MODE: '${build_mode}'."
      EchoError "You can fix this by updating the LOCAL_ENGINE environment variable, or"
      EchoError "by running:"
      EchoError "  flutter build ios --local-engine=ios_${build_mode}"
      EchoError "or"
      EchoError "  flutter build ios --local-engine=ios_${build_mode}_unopt"
      EchoError "========================================================================"
      exit -1
    fi
    local_engine_flag="--local-engine=${LOCAL_ENGINE}"
    flutter_framework="${FLUTTER_ENGINE}/out/${LOCAL_ENGINE}/Flutter.xcframework"
  fi

  # ENABLE_BITCODE
  local bitcode_flag=""
  if [[ "$ENABLE_BITCODE" == "YES" ]]; then
    bitcode_flag="true"
  fi

  # 先移除掉project_path/.ios/Flutter/engine/，再从flutter_framework拷贝过去
  # TODO(jmagman): use assemble copied engine in add-to-app.
  if [[ -e "${project_path}/.ios" ]]; then
    RunCommand rm -rf -- "${derived_dir}/engine/Flutter.framework"
    RunCommand cp -r -- "${flutter_framework}" "${derived_dir}/engine"
  fi

  # 将 project_path 放到虚拟堆栈里
  # 切换脚本执行目录到project_path，以便执行flutter指令
  RunCommand pushd "${project_path}" > /dev/null

  # 打印执行过程的详细日志
  local verbose_flag=""
  if [[ -n "$VERBOSE_SCRIPT_LOGGING" ]]; then
    verbose_flag="--verbose"
  fi

  local performance_measurement_option=""
  if [[ -n "$PERFORMANCE_MEASUREMENT_FILE" ]]; then
    performance_measurement_option="--performance-measurement-file=${PERFORMANCE_MEASUREMENT_FILE}"
  fi

  local code_size_directory=""
  if [[ -n "$CODE_SIZE_DIRECTORY" ]]; then
    code_size_directory="-dCodeSizeDirectory=${CODE_SIZE_DIRECTORY}"
  fi

  RunCommand "${FLUTTER_ROOT}/bin/flutter"                                \
    ${verbose_flag}                                                       \
    ${flutter_engine_flag}                                                \
    ${local_engine_flag}                                                  \
    assemble                                                              \
    --output="${BUILT_PRODUCTS_DIR}/"                                     \
    ${performance_measurement_option}                                     \
    -dTargetPlatform=ios                                                  \
    -dTargetFile="${target_path}"                                         \
    -dBuildMode=${build_mode}                                             \
    -dIosArchs="${ARCHS}"                                                 \
    -dSdkRoot="${SDKROOT}"                                                \
    -dSplitDebugInfo="${SPLIT_DEBUG_INFO}"                                \
    -dTreeShakeIcons="${TREE_SHAKE_ICONS}"                                \
    -dTrackWidgetCreation="${TRACK_WIDGET_CREATION}"                      \
    -dDartObfuscation="${DART_OBFUSCATION}"                               \
    -dEnableBitcode="${bitcode_flag}"                                     \
    ${bundle_sksl_path}                                                   \
    ${code_size_directory}                                                \
    --ExtraGenSnapshotOptions="${EXTRA_GEN_SNAPSHOT_OPTIONS}"             \
    --DartDefines="${DART_DEFINES}"                                       \
    --ExtraFrontEndOptions="${EXTRA_FRONT_END_OPTIONS}"                   \
    "${build_mode}_ios_bundle_flutter_assets"

  # if [[ $? -ne 0 ]] 上一条指令的返回结果 不等于 0 ，代表有异常
  if [[ $? -ne 0 ]]; then
    EchoError "Failed to package ${project_path}."
    exit -1
  fi
  StreamOutput "done"
  StreamOutput " └─Compiling, linking and signing..."

  # 出栈
  RunCommand popd > /dev/null

  echo "Project ${project_path} built and packaged successfully."
  return 0
}

# 对于CFBundleExecutable的意义可参考 https://www.cnblogs.com/findumars/p/5064742.html
# CFBundleExecutable 在这里就是framework的名称
# Returns the CFBundleExecutable for the specified framework directory.
GetFrameworkExecutablePath() {
  local framework_dir="$1"

  local plist_path="${framework_dir}/Info.plist"
  local executable="$(defaults read "${plist_path}" CFBundleExecutable)"
  # executable 的值应该是ios
  echo "${framework_dir}/${executable}"
}

# Destructively thins the specified executable file to include only the
# specified architectures.
LipoExecutable() {
  local executable="$1"
  shift
  # Split $@ into an array.
  # 支持的几种架构 armv7、arm64、x86_64
  read -r -a archs <<< "$@"

  # Extract architecture-specific framework executables.
  local all_executables=()
  for arch in "${archs[@]}"; do
    local output="${executable}_${arch}"

    # 对于lipo指令的详细讲解可以阅读  https://blog.csdn.net/SoaringLee_fighting/article/details/82994510
    # lipo -info 查看支持的架构，在framework/Info.plist文件中，就是SupportedArchitectures对应的值

    local lipo_info="$(lipo -info "${executable}")"
    if [[ "${lipo_info}" == "Non-fat file:"* ]]; then
      if [[ "${lipo_info}" != *"${arch}" ]]; then
        echo "Non-fat binary ${executable} is not ${arch}. Running lipo -info:"
        echo "${lipo_info}"
        exit 1
      fi
    else
      # 按单个平台提取拆分
      if lipo -output "${output}" -extract "${arch}" "${executable}"; then
        all_executables+=("${output}")
      else
        echo "Failed to extract ${arch} for ${executable}. Running lipo -info:"
        RunCommand lipo -info "${executable}"
        exit 1
      fi
    fi
  done

  # Generate a merged binary from the architecture-specific executables.
  # Skip this step for non-fat executables.
  if [[ ${#all_executables[@]} > 0 ]]; then
    local merged="${executable}_merged"
    # 将拆分出来的平台库合并成一个库
    RunCommand lipo -output "${merged}" -create "${all_executables[@]}"

    RunCommand cp -f -- "${merged}" "${executable}" > /dev/null
    RunCommand rm -f -- "${merged}" "${all_executables[@]}"
  fi
}

# Destructively thins the specified framework to include only the specified
# architectures.
# 破坏性地精简framework，只包含指定的架构
ThinFramework() {
  local framework_dir="$1"
  # 位置参数可以用shift命令左移，不带参数的shift命令相当于shift 1。
  # $1："$framework_dir"，$2："$ARCHS"
  # 执行了shift后，变成了$1："$ARCHS"
  shift

  local executable="$(GetFrameworkExecutablePath "${framework_dir}")"
  # 这里的$@指的是原来的$2，即ARCH参数
  LipoExecutable "${executable}" "$@"
}

ThinAppFrameworks() {
  # frameworks 所在目录
  local xcode_frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

  [[ -d "${xcode_frameworks_dir}" ]] || return 0
  find "${xcode_frameworks_dir}" -type d -name "*.framework" | while read framework_dir; do
    # $ARCHS 是设备架构参数，armv7 / arm64 / x86_64
    ThinFramework "$framework_dir" "$ARCHS"
  done
}

# Adds the App.framework as an embedded binary and the flutter_assets as
# resources.
EmbedFlutterFrameworks() {
  # Embed App.framework from Flutter into the app (after creating the Frameworks directory
  # if it doesn't already exist).
  local xcode_frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
  RunCommand mkdir -p -- "${xcode_frameworks_dir}"
  RunCommand rsync -av --delete --filter "- .DS_Store" "${BUILT_PRODUCTS_DIR}/App.framework" "${xcode_frameworks_dir}"

  # Embed the actual Flutter.framework that the Flutter app expects to run against,
  # which could be a local build or an arch/type specific build.

  # Copy Xcode behavior and don't copy over headers or modules.
  # 复制framework，但是要过滤掉 .DS_Store、Headers、Modules
  RunCommand rsync -av --delete --filter "- .DS_Store" --filter "- Headers" --filter "- Modules" "${BUILT_PRODUCTS_DIR}/Flutter.framework" "${xcode_frameworks_dir}/"
  if [[ "$ACTION" != "install" || "$ENABLE_BITCODE" == "NO" ]]; then
    # Strip bitcode from the destination unless archiving, or if bitcode is disabled entirely.
    # 除非打包或完全禁用bitcode，否则从目标中删除bitcode
    RunCommand "${DT_TOOLCHAIN_DIR}"/usr/bin/bitcode_strip "${BUILT_PRODUCTS_DIR}/Flutter.framework/Flutter" -r -o "${xcode_frameworks_dir}/Flutter.framework/Flutter"
  fi

  # Sign the binaries we moved.
  # 对操作过的framework签名
  if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]]; then
    RunCommand codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${xcode_frameworks_dir}/App.framework/App"
    RunCommand codesign --force --verbose --sign "${EXPANDED_CODE_SIGN_IDENTITY}" -- "${xcode_frameworks_dir}/Flutter.framework/Flutter"
  fi

  AddObservatoryBonjourService
}

# Add the observatory publisher Bonjour service to the produced app bundle Info.plist.
# 在导出的APP包的Info.plist中添加 Bonjour service，两端调试用的，只能在Debug/Profile模式用
AddObservatoryBonjourService() {
  local build_mode="$(ParseFlutterBuildMode)"
  # Debug and profile only.
  if [[ "${build_mode}" == "release" ]]; then
    return
  fi
  local built_products_plist="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

  if [[ ! -f "${built_products_plist}" ]]; then
    EchoError "error: ${INFOPLIST_PATH} does not exist. The Flutter \"Thin Binary\" build phase must run after \"Copy Bundle Resources\"."
    exit -1
  fi
  # If there are already NSBonjourServices specified by the app (uncommon), insert the observatory service name to the existing list.
  # 通过 plutil 指令操作plist文件
  if plutil -extract NSBonjourServices xml1 -o - "${built_products_plist}"; then
    RunCommand plutil -insert NSBonjourServices.0 -string "_dartobservatory._tcp" "${built_products_plist}"
  else
    # Otherwise, add the NSBonjourServices key and observatory service name.
    RunCommand plutil -insert NSBonjourServices -json "[\"_dartobservatory._tcp\"]" "${built_products_plist}"
  fi

  # Don't override the local network description the Flutter app developer specified (uncommon).
  # This text will appear below the "Your app would like to find and connect to devices on your local network" permissions popup.
  # 本地网络连接的权限使用说明
  if ! plutil -extract NSLocalNetworkUsageDescription xml1 -o - "${built_products_plist}"; then
    RunCommand plutil -insert NSLocalNetworkUsageDescription -string "Allow Flutter tools on your computer to connect and debug your application. This prompt will not appear on release builds." "${built_products_plist}"
  fi
}

EmbedAndThinFrameworks() {
  EmbedFlutterFrameworks
  ThinAppFrameworks
}

# Main entry point.
# 主入口
if [[ $# == 0 ]]; then
  # 从Flutter v0.0.7开始引进命名入口函数，如果没有携带参数，则需要更新Runner.xcodeproj版本，重新生成
  # Named entry points were introduced in Flutter v0.0.7.
  EchoError "error: Your Xcode project is incompatible with this version of Flutter. Run \"rm -rf ios/Runner.xcodeproj\" and \"flutter create .\" to regenerate."
  exit -1
else
  echo "[JK Log] $1"
  
  case $1 in
    "build") # 只需要编译  flutter build ios-framework --xcframework
      BuildApp ;;
    "thin") # AppFrameworks 瘦身
      ThinAppFrameworks ;;
    "embed") # 可嵌入的FlutterFrameworks，  flutter build ios-framework --cocoapods --xcframework
      EmbedFlutterFrameworks ;;
    "embed_and_thin") # 嵌入并瘦身的Frameworks
      EmbedAndThinFrameworks ;;
    "test_observatory_bonjour_service") # 调试用的，监听bonjour_service服务，这个需要在Xcode Info.plist文件添加bonjour_service，并且只能在Debug模式用
      # Exposed for integration testing only.
      AddObservatoryBonjourService ;;
  esac
fi
