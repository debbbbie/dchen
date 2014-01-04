#!/bin/bash
#sudo killall -9 nginx
kill -WINCH `cat /home/aliyun/dichen/log/nginx.pid` && kill -9 `cat /home/aliyun/dichen/log/nginx.pid`
sudo nginx -c /home/aliyun/dichen/nginx.conf
