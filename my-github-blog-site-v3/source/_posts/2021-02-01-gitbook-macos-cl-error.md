---
layout: post
title:  MacOS install GitBook 未成功经验
date: 2021-07-01 18:18:45
tags:
  - tools
categories:
  - tech
  - tools
excerpt: MacOS 上安装GitBook遇到的各种问题，最终没有正常安装，选择使用`honkit`的悲伤故事
---

#  安装GitBook遇到的各种问题
- 环境信息
```bash
Node.js v14.17.1
ruby 2.5.8p224 (2020-03-31 revision 67882) [x86_64-darwin18]
MacOS Catalina 10.15.7 (19H1217)
```

- 安装遇到的问题
```bash
npm install gitbook-cli -g
mkdir book-test

# install 
$ gitbook server
```
出现异常：
```bash
Installing GitBook 3.2.3
(node:90003) [DEP0150] DeprecationWarning: Setting process.config is deprecated. In the future the property will be read-only.
(Use `node --trace-deprecation ...` to show where the warning was created)
xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
No receipt for 'com.apple.pkg.CLTools_Executables' found at '/'.
No receipt for 'com.apple.pkg.DeveloperToolsCLILeo' found at '/'.
No receipt for 'com.apple.pkg.DeveloperToolsCLI' found at '/'.
gyp: No Xcode or CLT version detected!
(node:90043) [DEP0150] DeprecationWarning: Setting process.config is deprecated. In the future the property will be read-only.
(Use `node --trace-deprecation ...` to show where the warning was created)
xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
No receipt for 'com.apple.pkg.CLTools_Executables' found at '/'.
No receipt for 'com.apple.pkg.DeveloperToolsCLILeo' found at '/'.
No receipt for 'com.apple.pkg.DeveloperToolsCLI' found at '/'.
gyp: No Xcode or CLT version detected!
/usr/local/lib/node_modules/gitbook-cli/node_modules/npm/node_modules/graceful-fs/polyfills.js:287
      if (cb) cb.apply(this, arguments)
                 ^
TypeError: cb.apply is not a function
    at /usr/local/lib/node_modules/gitbook-cli/node_modules/npm/node_modules/graceful-fs/polyfills.js:287:18
    at FSReqCallback.oncomplete (node:fs:196:5)
```
修复问题：
```bash
#cli pkg noxexits
$ /usr/sbin/pkgutil --packages | grep CL

# reinstall xcode-select
$ sudo rm -rf $(xcode-select -print-path)
$ xcode-select --install
$ /usr/sbin/pkgutil --packages | grep CL
$ sudo npm install -g node-gyp
```
异常日志：
```bash
Installing GitBook 3.2.3
  SOLINK_MODULE(target) Release/.node
  CXX(target) Release/obj.target/fse/fsevents.o
/usr/local/lib/node_modules/gitbook-cli/node_modules/npm/node_modules/graceful-fs/polyfills.js:287
      if (cb) cb.apply(this, arguments)
                 ^
TypeError: cb.apply is not a function
    at /usr/local/lib/node_modules/gitbook-cli/node_modules/npm/node_modules/graceful-fs/polyfills.js:287:1
```
修复：
```bash
$ cd /usr/local/lib/node_modules/gitbook-cli/node_modules/npm/node_modules/
$ npm install graceful-fs@latest --save
```
参考：
[gitbook-cli-install-error-typeerror-cb-apply-is-not-a-function-inside-graceful](https://stackoverflow.com/questions/64211386/gitbook-cli-install-error-typeerror-cb-apply-is-not-a-function-inside-graceful)

- 启动服务异常
```bash
# 启动
$ gitbook serve  --lrport 13244 --port 4002 book-blog
```
 还是遇到异常：
 ```text
Live reload server started on port: 13244
Press CTRL+C to quit ...

info: 7 plugins are installed
info: loading plugin "livereload"... OK
info: loading plugin "highlight"... OK
info: loading plugin "search"... OK
info: loading plugin "lunr"... OK
info: loading plugin "sharing"... OK
info: loading plugin "fontsettings"... OK
info: loading plugin "theme-default"... OK
info: found 1 pages
info: found 0 asset files
internal/streams/readable.js:630
  if (state.pipes.length === 1) {
            ^
TypeError: Cannot read property 'pipes' of undefined
    at ReadStream.Readable.pipe (internal/streams/readable.js:630:13)
    at /Users/ordiy/.gitbook/versions/3.2.3/node_modules/cpr/lib/index.js:163:22
    at callback (/usr/local/lib/node_modules/gitbook-cli/node_modules/npm/node_modules/graceful-fs/polyfills.js:299:20)
    at FSReqCallback.oncomplete (fs.js:192:21)
➜  isun-blog-book git:(master) ✗ gitbook serve  --lrport 13244 --port 4002 book-blog
➜  isun-blog-book git:(master) ✗ npm install cpr
npm WARN saveError ENOENT: no such file or directory, open '/opt/ordiy/px03-private-project/isun-blog-book/package.json'
npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN enoent ENOENT: no such file or directory, open '/opt/ordiy/px03-private-project/isun-blog-book/package.json'
npm WARN isun-blog-book No description
npm WARN isun-blog-book No repository field.
npm WARN isun-blog-book No README data
npm WARN isun-blog-book No license field.

+ cpr@3.0.1
added 16 packages from 15 contributors and audited 16 packages in 4.371s
1 package is looking for funding
  run `npm fund` for details
found 0 vulnerabilities
   ╭────────────────────────────────────────────────────────────────╮
   │                                                                │
   │      New major version of npm available! 6.14.13 → 7.19.0      │
   │   Changelog: https://github.com/npm/cli/releases/tag/v7.19.0   │
   │               Run npm install -g npm to update!                │
   │                                                                │
   ╰────────────────────────────────────────────────────────────────╯
```
 吼吼.... 的node.js 小白水平，仔细看看应该是node.js版本问题

 ```bash
 #当前机器的node js版本是17,版本太高,使用nvm切换版本
 nvm use v12.0.0
 ```
 问题解决～～～



# 总结

 出现失败的问题可能是 gitbook 依赖的组件版本有问题，导致执行出现问题，在尝试了多次为能找到问题，选择使用honkitz作为替代方案
 


