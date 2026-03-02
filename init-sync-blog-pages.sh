#cp -r /opt/ping/08-my-private-doc/my-private-blog-site-v2/my-github-blog-site-v3/ ./
rsync -av /opt/ping/08-my-private-doc/my-private-blog-site-v2/my-github-blog-site-v3/ .

echo "=== debug start"
hexo server --debug
