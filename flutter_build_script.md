# iOS远程依赖flutter module构建脚本

详见[`flutter_build_script.sh 脚本 `](https://github.com/XiFengLang/flutter_notes/blob/main/flutter_build_script.md)

## 实现功能

- [x] 校验git是否有未提交的更新
- [x] git commit, git tag ,git push等一系列git操作
- [x] 校验.ios/Runner.xcworkspace
- [x] 编译Flutter module，导出framework
- [ ] 选择debug / profile / release 编译模式
- [x] 版本号自增 或 手动输入
- [x] 修改podspec版本号
- [x] 钉钉通知
- [x] 杂七杂八的结果校验
- [x] xcframework黑名单，过滤掉重复依赖的framwork


## 参考

> * [linux shell 实现自增版本号](https://github.com/zedxpp/PPPrivatePodPushScript/blob/master/README.md)
> * [PPPrivatePodPushScript iOS私有库发布脚本](https://github.com/zedxpp/PPPrivatePodPushScript)







