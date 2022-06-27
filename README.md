Blog
====


## npm 版本更新
```text
$ npm update --save
$ hexo v
```

## hexo 使用指定了两个自定义配置文件
```
hexo generate --config _config.yml,_config.next.yml
```

## 创建文章

## draf文章
```shell script
# 创建草稿
npx hexo new draft tech '2021-04-11-kerberos-guide'

# 预览草稿
hexo s --draft --watch

# draf --> post
#Moves a draft post from _drafts to _posts folder.
hexo hexo publish '2021-04-11-kerberos-guide'
```

### post文章
```bash
#访问地址 http://localhost:4000/{{root}}/草稿文章title ,类似于
# http://localhost:4000/ordiychen.github.io/2020-06-30-kk-inevitable-obvious/
#
#hexo new 2021-02-01-nginx-file-server.md
# post tech 模板创建文章
npx hexo new post tech 2021-12-02-hbase-meta-opt

hexo new tech :year-:month-:day-:title
```

## 使用指定config进行调试
```
hexo server --config custom.yml
```

##  构建/启动server/部署-命令
```shell script
#generate 
npx hexo g --watch

#server 
npx hexo s --watch
# server watch 
 npx  hexo clean && npx hexo g --debug && npx hexo server --port 14000 --watch --open

#自动 deploy 
# 不要使用！～～
#npx  hexo clean && npx hexo g --silent && npx hexo d
```

 
## 手动deploy
手动delpoy编译后的文件（只更新改/deloy 改动过的文件)
```bash 
npx hexo clean && npx hexo g

#mkdir ./.deplog_git
cd ./.deplog_git
cp -r ../public/* ./public/

cd ./public/
git add .
git commit -m "update doc"
proxychains4 git push -u origin gh-pages
```

## Next theme document 

https://theme-next.js.org/

修改主题:
```bash
vim {root_dir}/_config.yml

theme: next
```
