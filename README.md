Blog
====

## 更新主题
```text
cd themes/next-theme
git pull
```


## npm 版本更新
```text
$ npm update --save
$ hexo v
```

## hexo 命令 use
```shell script
clean     Remove generated files and cache.
  config    Get or set configurations.
  deploy    Deploy your website.
  generate  Generate static files.
  help      Get help on a command.
  init      Create a new Hexo folder.
  list      List the information of the site
  migrate   Migrate your site from other system to Hexo.
  new       Create a new post.
  publish   Moves a draft post from _drafts to _posts folder.
  render    Render files with renderer plugins.
  server    Start the server.
  version   Display version information.

Global Options:
  --config  Specify config file instead of using _config.yml
  --cwd     Specify the CWD
  --debug   Display all verbose messages in the terminal
  --draft   Display draft posts
  --safe    Disable all plugins and scripts
  --silent  Hide output on console


npx hexo generate 
npx hexo generate  && hexo server --watch

```
- 部署到github
```shell script
#安装插件
npm install hexo-deployer-git --save
#hexo clien
#hexo generate && hexo deploy
```

## 创建文章
```shell script
#使用模版 创建新文章
hexo new tech 2021-01-11-test.md
 
# 创建草稿
npx hexo new draft '2021-04-11-kerberos-guide'

#发布draft 文章
npx hexo publish  `文件名称`

# 预览草稿
hexo s --draft --watch
#访问地址 http://localhost:4000/{{root}}/草稿文章title ,类似于
# http://localhost:4000/ordiychen.github.io/2020-06-30-kk-inevitable-obvious/
#
hexo new 2021-02-01-nginx-file-server.md
npx hexo new tech 2021-12-2-hbase-meta-opt.md


hexo new tech :year-:month-:day-:title.md
hexo publish post
```


##  构建/启动server/部署-命令
```shell script
#generate 
npx hexo g --watch

#server 
npx hexo s --watch
# server watch 
 npx  hexo clean && npx hexo g --silent && npx hexo s --watch
# deploy 

npx  hexo clean && npx hexo g --silent && npx hexo d
```

 
## 手动deploy
手动delpoy编译后的文件（只更新改/deloy 改动过的文件)
```bash 
npx hexo g

mkdir ./.deplog_git
cd ./.deplog_git
cp -r ../public/* ./public/

cd ./public/
git add .
git commit -m "update doc"
proxychains4 git push -u origin gh-pages

```

## Next theme document 
https://theme-next.js.org/
