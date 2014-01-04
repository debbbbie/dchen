#!/bin/bash
#sudo killall -9 nginx
kill -WINCH `cat /home/aliyun/dchen/log/nginx.pid` && kill -9 `cat /home/aliyun/dchen/log/nginx.pid`
sudo nginx -c /home/aliyun/dchen/nginx.conf
