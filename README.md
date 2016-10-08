# docker-paperwork
docker build paperwork


# 参数
    RESET: 是否中心初始化应用，默认为0。RESET=1，初始化整个系统。
    MYSQL_HOST: 依赖数据库的host
    MYSQL_USER: mysql的用户
    MYSQL_PASS: mysql的密码
    MYSQL_PORT: mysql的端口
    MAXWAIT:    等待mysql的最长连接时间，默认为30s
    HTTP_PORT:  对外的端口号
    
# 执行指令
    docker run -it -p 5000:5000 -v /xx/xx:/data --link git-mysql:mysql -e RESET=1 -e HTTP_PORT=5000 paperwork