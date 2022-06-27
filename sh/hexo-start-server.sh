#!/bin/bash
echo "start bash =====> "

#cd ..
pwd
npx hexo clean 
npx hexo g --config _config.yml,_config.next.yml --debug
npx hexo server --config _config.yml,_config.next.yml  --port 14000 --watch --open 

echo "====COMPLETE "
