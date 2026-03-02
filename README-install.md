Blog
====


## npm 版本更新
```text
$ npm update --save
npm update hexo@xxx --save

$ hexo v
```

## 配置  themes next
```shell 
git clone https://github.com/next-theme/hexo-theme-next themes/next

```

## hexo 使用指定了两个自定义配置文件
```
hexo generate --config _config.yml,_config.next.yml
```

## 创建文章

## draf 草稿文章   到publish 流程

```shell script

# 创建草稿
npx hexo new draft tech '2023-06-11-hbase-export-snapshot-guide'


# 预览草稿
hexo s --draft --watch --open

# draf --> post

#Moves a draft post from _drafts to _posts folder.
npx hexo publish '2021-04-11-kerberos-guide'
```

### post文章
```bash

# post tech 模板创建文章



hexo new tech :year-:month-:day-:title
# hexo new tech 2022-02-20-hbase-fix-rit-lock.md
```


##  构建/启动server/部署-命令
```shell script
#generate 
npx hexo g --watch

hexo s --draft --watch
#server 
npx hexo s --watch
# server watch 
 npx  hexo clean && npx hexo g --debug && npx hexo server --port 14000 --watch --open
 
 npx hexo server --port 14000 --watch --open --draft
#自动 deploy 
# 不要使用！～～
#npx  hexo clean && npx hexo g --silent && npx hexo d
```



## 手动deploy
手动delpoy编译后的文件（只更新改/deloy 改动过的文件)
```bash 
npx hexo clean && npx hexo g

#mkdir ./.deplog_git
cd ./._deploy_tmp_dir
cp -r ../public/* ./ordiy.github.io

cd ./ordiy.github.io
git add .
git commit -m "update doc"
proxychains4 git push -u origin gh-pages

cd ../..

```

## Next theme document 

https://theme-next.js.org/

修改主题:
```bash
vim {root_dir}/_config.yml

theme: next
```


## 使用指定config进行调试
```
hexo server --config custom-test.yml
```
