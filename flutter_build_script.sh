#!/bin/bash
# 编译Flutter Module，并上传编译产物到Git


# >--------------------------------------------------------------------
# 一些通用的函数


color_cyan="\033[0;36m"
color_red="\033[41;37m"
color_default="\033[0;m"


function echo_log() {
	echo -e "${color_cyan}$*${color_default}"
}

function echo_error() {
	echo -e "${color_red}$*${color_default}"
}


RunCommand() {
  # 打印指令
  echo_log "-> ♦ $*"

  # 执行指令
  "$@"

  # $? 获取上一个命令的退出状态
  return $?
}


# 移除收尾空格，打印的时候记得用""
function delete_white_space() {
	echo -n  "$1" | sed  's/^[ t]*//;s/[ t]*$//'
}

function log_separator() {
	echo_log "----------------------------------------------------------"
}



# >--------------------------------------------------------------------
# 几个关键的路径，需要改的也就是这儿

readonly workspace_root_path="$HOME/Desktop/workspace"
readonly flutter_module_path="${workspace_root_path}/flutter_notes/flutter_module"
readonly flutter_build_output_path="${workspace_root_path}/futter_build_tmp"
readonly flutter_module_sdk_podspec_path="${workspace_root_path}/flutter_module_sdk_podspec"
readonly flutter_app_sdk_path="${workspace_root_path}/flutter_app_sdk"
readonly flutter_plugin_sdk_path="${workspace_root_path}/flutter_plugin_sdk"

readonly app_sdk_podspec_path="$flutter_module_sdk_podspec_path/FlutterAppSDK.podspec"
readonly plugin_sdk_podspec_path="$flutter_module_sdk_podspec_path/FlutterPluginSDK.podspec"



# 黑名单，如果编译出来的.xcframework在黑名单里，提交git前会删除掉，不打包到FlutterPluginSDK里面去
# 这是为了避免framework重复出现编译错误 `Multiple commands produce '.../.../.framework'`
blacklist=(
"FMDB.xcframework"
"MMKV.xcframework"
"MMKVCore.xcframework"
"Sentry.xcframework"
)


# 过滤掉黑名单中的xcframework
function filter_frameworks() {
	filelist=`ls $flutter_plugin_sdk_path`
	if [[ ${blacklist[@]} ]]; then
		echo_log ">>> 开始处理黑名单"
		for file in $filelist; do
			if [[ "${blacklist[@]}" =~ "$file" ]]; then
		    	RunCommand rm -r "$flutter_plugin_sdk_path/$file"
		  	fi
		done
		echo_log ">>> 已完成"
	fi
}


# >--------------------------------------------------------------------
# 校验路径是否正常     -d 目录是否存在    -f 文件是否存在

log_separator
echo_log ">>> 开始校验相关路径"

if [[ ! -d $workspace_root_path ]]; then
	echo_error "目录不存在！ $workspace_root_path"
	exit 1
fi

if [[ ! -d $flutter_module_path ]]; then
	echo_error "目录不存在！ $flutter_module_path"
	exit 1
fi

if [[ ! -d $flutter_module_sdk_podspec_path ]]; then
	echo_error "目录不存在！ $flutter_module_sdk_podspec_path"
	exit 1
fi

if [[ ! -d $flutter_app_sdk_path ]]; then
	echo_error "目录不存在！ $flutter_app_sdk_path"
	exit 1
fi

if [[ ! -d $flutter_plugin_sdk_path ]]; then
	echo_error "目录不存在！ $flutter_plugin_sdk_path"
	exit 1
fi


cd $workspace_root_path

if [[ ! -d $flutter_build_output_path ]]; then
	mkdir $flutter_build_output_path
else
	rm -r $flutter_build_output_path
	mkdir $flutter_build_output_path
fi


echo_log "<<< 路径正常"

# >--------------------------------------------------------------------
# 先拉取各个Git，避免出现冲突

log_separator
echo_log ">>> 开始校验相关Git"

RunCommand cd $flutter_app_sdk_path 
if [ -n "$(git status -s)" ];then
	echo_error "有未提交的更新，请手动检查Git $flutter_app_sdk_path"
	exit 1

    #  RunCommand git add -A && git commit -m "$new_tag_version"
    #  if [[ $? -ne 0 ]]; then
	# 	echo_error "'git add -A && git commit -m，请检查错误信息 $flutter_plugin_sdk_path"
	# 	exit 1
	# fi
fi

RunCommand git pull origin master
if [[ $? -ne 0 ]]; then
	echo_error "'git pull origin' failed，请检查错误信息"
	exit 1
fi



RunCommand cd $flutter_plugin_sdk_path 
if [ -n "$(git status -s)" ];then
	echo_error "有未提交的更新，请手动检查Git $flutter_plugin_sdk_path"
	exit 1
fi

RunCommand git pull origin master
if [[ $? -ne 0 ]]; then
	echo_error "'git pull origin' failed，请检查错误信息"
	exit 1
fi



RunCommand cd $flutter_module_sdk_podspec_path 
if [ -n "$(git status -s)" ];then
	echo_error "有未提交的更新，请手动检查Git $flutter_module_sdk_podspec_path"
	exit 1
fi

RunCommand git pull origin master
if [[ $? -ne 0 ]]; then
	echo_error "'git pull origin' failed，请检查错误信息"
	exit 1
fi


echo_log "<<< 相关Git正常"



# >--------------------------------------------------------------------
# Runner.xcworkspace是否存在、能否正常编译flutter module

log_separator
echo_log ">>> 开始校验/.ios/Runner.xcworkspace"


cd $flutter_module_path

readonly runner_xcworkspace_path="${flutter_module_path}/.ios/Runner.xcworkspace"

if [[ ! -d $runner_xcworkspace_path ]]; then
	echo_log "Runner.xcworkspace不存在，开始创建Runner，$runner_xcworkspace_path"
	RunCommand flutter build ios

	# 上一步指令的退出状态
	if [[ $? -ne 0 ]]; then
		echo_error "已创建Runner.xcworkspace，但编译出错，请检查错误信息以及编译配置"
		open $runner_xcworkspace_path
		exit 1
	else
		echo_log "已创建Runner.xcworkspace"
	fi

else

	echo_log " 是否需要校验/.ios/Runner.xcworkspace能否正常编译?  Yes or No, 输入 y 执行编译:"
	read -t 30 -p "> " build_ios

	if test "$build_ios" == "y"; then
		RunCommand flutter build ios

		# 上一步指令的退出状态
		if [[ $? -ne 0 ]]; then
			echo_error "编译出错，请检查错误信息以及编译配置"
			open $runner_xcworkspace_path
			exit 1
		fi
	fi
fi

echo_log "<<< /.ios/Runner.xcworkspace正常"


# >--------------------------------------------------------------------
# 编译导出 ios-framework

log_separator
echo_log ">>> 开始编译flutter module"

# 这个编译指令会导出Flutter.framework
# flutter build ios-framework --xcframework --no-universal --output=$flutter_build_output_path

# 这个编译指令会生成Flutter.podspec
RunCommand flutter build ios-framework --cocoapods --xcframework --no-universal --output=$flutter_build_output_path

if [[ $? -ne 0 ]]; then
	echo_error " 编译出错，请检查错误信息。"
	exit 1
fi

echo_log "<<< 结束编译"

# >--------------------------------------------------------------------
# 处理编译产物

log_separator
echo_log ">>> 开始处理编译产物"

readonly flutter_build_product_path="${flutter_build_output_path}/Release"

RunCommand cd $flutter_build_product_path && du -h -depth=1 ./*

if [[ ! -d "${flutter_build_product_path}/App.xcframework" ]]; then
	echo_error "目录不存在！ ${flutter_build_product_path}/App.xcframework"
	exit 1
fi
if [[ ! -f "${flutter_build_product_path}/Flutter.podspec" ]]; then
	echo_error "文件不存在！ ${flutter_build_product_path}/Flutter.podspec"
	exit 1
fi


RunCommand cp -rf ./App.xcframework $flutter_app_sdk_path
if [[ $? -ne 0 ]]; then
	echo_error "复制App.xcframework文件出错，请检查错误信息"
	exit 1
else
	RunCommand rm -r ./App.xcframework
fi


RunCommand cp -rf ./*.xcframework $flutter_plugin_sdk_path
if [[ $? -ne 0 ]]; then
	echo_error "复制Plugin.xcframework文件出错，请检查错误信息"
	exit 1
else
	RunCommand rm -r ./*.xcframework

	# 过滤掉黑名单总的xcframework
	filter_frameworks
fi

RunCommand cp -rf ./Flutter.podspec $flutter_module_sdk_podspec_path
if [[ $? -ne 0 ]]; then
	echo_error "复制Flutter.podspec文件出错，请检查错误信息"
	exit 1
else
	RunCommand rm -r ./Flutter.podspec
fi

RunCommand rm -r $flutter_build_output_path

echo_log "<<< 编译产物处理完成"


# >--------------------------------------------------------------------
# 更新Git Tag版本号

log_separator
echo_log ">>> 开始更新版本号"

# 自增，满10进1
# increment_version () {
#   declare -a part=( ${1//\./ } )
#   declare    new
#   declare -i carry=1
 
#   for (( CNTR=${#part[@]}-1; CNTR>=0; CNTR-=1 )); do
#     len=${#part[CNTR]}
#     new=$((part[CNTR]+carry))
#     [ ${#new} -gt $len ] && carry=1 || carry=0
#     [ $CNTR -gt 0 ] && part[CNTR]=${new: -len} || part[CNTR]=${new}
#   done
#   new="${part[*]}"
#   echo -e "${new// /.}"
# }


# 一直是最后一位数无限自增，大版本可以手动输入
function increment_last_version () {
  declare -a part=( ${1//\./ } )
  declare    new
  declare -i carry=1
  CNTR=${#part[@]}-1
  len=${#part[CNTR]}
  new=$((part[CNTR]+carry))
  part[CNTR]=${new}
  new="${part[*]}"
  echo -e "${new// /.}"
}


RunCommand cd $flutter_plugin_sdk_path

# 初始版本
old_tag_version="1.0.0"

RunCommand git describe --tags `git rev-list --tags --max-count=1`
if [[ $? -ne 0 ]]; then
	# 自增就是1.0.1，不想改了
	echo_log "当前仓库未发现git --tags，将使用默认的初始版本号 1.0.0"
else
	old_tag_version="$(git describe --tags `git rev-list --tags --max-count=1`)"
fi

new_tag_version="$(increment_last_version $old_tag_version)"


function input_new_tag_version() {
	echo_log "请输入新的版本号"
	read -t 30 -p "> " input_version_a
	version_a=$(delete_white_space $input_version_a)

	echo_log "请再次输入版本号"
	read -t 30 -p "> " input_version_b
	version_b=$(delete_white_space $input_version_b)

	if test $version_a != $version_b; then
		echo_error "两次输入的版本号不一致，请重新输入版本号"
		input_new_tag_version
	fi

	new_tag_version=$version_a
	return 0
}


echo_log "当前flutter_plugin_sdk版本号：${old_tag_version}，如需自定义修改版本号请输入 y ，否则自增版本号"
read -t 30 -p "> " modify_git_tag

if test "$modify_git_tag" == "y"; then
	input_new_tag_version

	if test $new_tag_version == $old_tag_version; then
		echo_error "输入的新版本号 $new_tag_version 和旧版本 $old_tag_version 相同，请重新输入"
		input_new_tag_version

		if test $new_tag_version == $old_tag_version; then
			echo_error "输入的新版本号 $new_tag_version 和旧版本 $old_tag_version 相同，已终止程序!"
			exit 1
		fi

	fi
fi

echo_log "<<< 将使用新版本号：$new_tag_version"

# >--------------------------------------------------------------------
# 提交framework到Git


log_separator
echo_log ">>> 开始更新app_sdk.git"

RunCommand cd $flutter_app_sdk_path 
if [ -n "$(git status -s)" ];then
    RunCommand git add -A && git commit -m "$new_tag_version"
    if [[ $? -ne 0 ]]; then
		echo_error "'git add -A && git commit -m' failed，请检查错误信息 $flutter_app_sdk_path"
		exit 1
	fi

    RunCommand git tag $new_tag_version
    RunCommand git push origin --tags && git push origin master 

	if [[ $? -ne 0 ]]; then
		echo_error "'git push origin' failed，请检查错误信息 $flutter_app_sdk_path"
		exit 1
	fi
else
	echo_error "似乎有异常，Git没有变更的内容  $flutter_app_sdk_path"
	exit 1
fi


echo_log "<<< 已更新git"
echo_log ">>> 开始更新plugin_sdk.git"

RunCommand cd $flutter_plugin_sdk_path 
if [ -n "$(git status -s)" ];then
    RunCommand git add -A && git commit -m "$new_tag_version"
    if [[ $? -ne 0 ]]; then
		echo_error "'git add -A && git commit -m，请检查错误信息 $flutter_plugin_sdk_path"
		exit 1
	fi

    RunCommand git tag $new_tag_version
    RunCommand git push origin --tags && git push origin master 

	if [[ $? -ne 0 ]]; then
		echo_error "'git push origin' failed，请检查错误信息 $flutter_plugin_sdk_path"
		exit 1
	fi
else
	echo_error "似乎有异常，Git没有变更的内容  $flutter_plugin_sdk_path"
	exit 1
fi

echo_log "<<< 已更新git"

# >--------------------------------------------------------------------
# 更新podspec里的版本号，然后提交到Git


log_separator
echo_log ">>> 开始修改podspec版本号"

RunCommand cd $flutter_module_sdk_podspec_path 


# 查到podspec版本号，并且修改传入参数的值，传入的第2/3个参数值会被修改
# 3个参数，No.1是podspec文件路径，No.2是版本号变量，No.3是版本号所在的行文本
function match_podspec_version() {
	podspec_path=$1

	while read line
	do
		if [[ $line == s.version* ]]; then
			# 匹配单引号或者双引号
			quotes="\'([^\']*)\'"
			double_quotes="\"([^\"]*)\""

			# 下面2种方案都行，但是外面打印时一定用""包裹，不然会丢失空格
			# eval $3='$line'
			eval $3='$(echo -n "$line")'

			if [[ $line =~ $quotes || $line =~ $double_quotes ]]; then
				eval $2=${BASH_REMATCH[1]}
			fi
			break
		fi
	done < $podspec_path
}

# 返回 's.version'所在的行文本内容，暂时弃用
# v=$(match_podspec_version_line $plugin_sdk_podspec_path)
# echo_log "$v"
# function match_podspec_version_line() {
# 	podspec_path=$1
# 	text=""

# 	while read line
# 	do
# 		if [[ $line == s.version* ]]; then
# 			text=$(echo -n "$line")
# 			break
# 		fi
# 	done < $podspec_path
# 	echo -n "$text"  #一定要加 -n ，不然会丢失掉一些空格
# }



# 修改podspec版本号，
# 4个参数，No.1是podspec文件路径，No.2是旧版本号变量，No.3是旧版本号所在的行文本，No.4是新版本号
function modify_podspec_version() {
	podspec_path=$1
	shift #左移参数坐标
	version="$1"

	# 如果参数用""包裹，就可以用$3直接取，eg: "$v2"，[建议用]
	# 如果没有用""包裹，就要放最后一个参数，因为有空格，这里不能直接用$3，选择使用shift，接受剩下的所有参数，eg: $v2
	shift
	# line_text="$*" 
	line_text="$1" 

	shift
	new_tag_version="$1" 

	new_line_text=${line_text/$version/$new_tag_version}

	# echo_log "原版本号行文本：$line_text"
	# echo_log "新版本号行文本：$new_line_text"

	sed -i '' "s/${line_text}/${new_line_text}/g" $podspec_path
	if [[ $? -ne 0 ]]; then
		echo_error "修改podspec版本号出错，请检查函数 modify_podspec_version()"
		exit 1
	fi
}



app_sdk_version=""
app_sdk_version_line=""
match_podspec_version $app_sdk_podspec_path app_sdk_version app_sdk_version_line
echo_log "AppSDK版本号   $app_sdk_version_line "
modify_podspec_version $app_sdk_podspec_path "$app_sdk_version" "$app_sdk_version_line" "$new_tag_version"


plugin_sdk_version=""
plugin_sdk_version_line=""
match_podspec_version $plugin_sdk_podspec_path plugin_sdk_version plugin_sdk_version_line
echo_log "PluginSDK版本号   $plugin_sdk_version_line "
modify_podspec_version $plugin_sdk_podspec_path "$plugin_sdk_version" "$plugin_sdk_version_line" "$new_tag_version"

echo_log ""

match_podspec_version $app_sdk_podspec_path app_sdk_version app_sdk_version_line
echo_log "修改后的AppSDK版本号   $app_sdk_version_line "
match_podspec_version $plugin_sdk_podspec_path plugin_sdk_version plugin_sdk_version_line
echo_log "修改后PluginSDK版本号   $plugin_sdk_version_line "

echo_log "<<< 版本已更新"


# >--------------------------------------------------------------------
# 提交Git

log_separator
echo_log ">>> 开始更新podspec.git"

if [ -n "$(git status -s)" ];then
    RunCommand git add -A && git commit -m "$new_tag_version"
    if [[ $? -ne 0 ]]; then
		echo_error "'git add -A && git commit -m' failed，请检查错误信息 $flutter_module_sdk_podspec_path"
		exit 1
	fi

    # RunCommand git tag $new_tag_version
    RunCommand git push origin --tags && git push origin master 

	if [[ $? -ne 0 ]]; then
		echo_error "'git push origin' failed，请检查错误信息 $flutter_module_sdk_podspec_path"
		exit 1
	fi
else
	echo_error "似乎有异常，Git没有变更的内容  $flutter_module_sdk_podspec_path"
	exit 1
fi

echo_log "<<< 已更新git"


# 通知其他人
# readonly dingtalk_notify_robot=""
# curl $dingtalk_notify_robot \
# -H 'Content-Type: application/json' \
# -d '{
# "msgtype": "link",
# "link": {
#     "text": "@某某 @某某 更新flutter_sdk_podspec.git",
#     "title": "flutter module 自动构建成功",
#     "picUrl": "https://.png",
#     "messageUrl": "https://"
# }
# }'


exit 1
