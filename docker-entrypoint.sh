#!/usr/bin/env bash


# 判断是否有强制清理参数
export RESET=${RESET:-0}
if [[ ${RESET} -ne 0 ]]; then
    echo "now clear store data"
    rm -rf /data/*
    rm -rf /var/www/paperwork/frontend/app/storage/config/setup
fi


# 判断是否有持久化数据
if [[ -d /data/storage ]]; then
    rm -rf /var/www/paperwork/frontend/app/storage
    cp -R /data/storage /var/www/paperwork/frontend/app/
fi

chown -R www-data:www-data /var/www/


export MYSQL_HOST=${MYSQL_HOST:-$MYSQL_PORT_3306_TCP_ADDR}
if [[ ! -z "${MYSQL_HOST}" ]]; then
    export MYSQL_USER=${MYSQL_USER:-root}
    export MYSQL_PASS=${MYSQL_PASS:-$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
    export MYSQL_PORT=${MYSQL_PORT:-$MYSQL_PORT_3306_TCP_PORT}
    if [[ -z "${MYSQL_PORT}" ]];then
        export MYSQL_PORT=${MYSQL_PORT_3306_TCP_PORT}
    else
        if [[ ${#MYSQL_PORT} -gt 8 ]]; then
            export MYSQL_PORT=${MYSQL_PORT_3306_TCP_PORT}
        else
            export MYSQL_PORT=${MYSQL_PORT}
        fi
    fi
fi


MAXWAIT=${MAXWAIT:-30}
wait=0
while [ ${wait} -lt ${MAXWAIT} ]
do
    echo stat | nc ${MYSQL_HOST} ${MYSQL_PORT}
    if [ $? -eq 0 ];then
        break
    fi
    wait=`expr ${wait} + 1`;
    echo "Waiting mysql service ${wait} seconds"
    sleep 1
done
if [ "${wait}" =  ${MAXWAIT} ]; then
    echo >&2 'paperwork start failed, please ensure mysql service has started.'
    exit 1
fi


# config mysql
sed -i \
    -e "s|{MYSQL_HOST}|${MYSQL_HOST}|" \
    -e "s|{MYSQL_USER}|${MYSQL_USER}|" \
    -e "s|{MYSQL_PASS}|${MYSQL_PASS}|" \
    -e "s|{MYSQL_PORT}|${MYSQL_PORT}|" \
    /var/www/paperwork/frontend/app/storage/config/database.json


if [[ -f /var/www/paperwork/frontend/app/storage/config/setup ]]; then
    echo "has init...."
else
    # 重新初始化数据库
    cat > /tmp/init.sql <<EOF
DROP DATABASE IF EXISTS paperwork;
CREATE DATABASE IF NOT EXISTS paperwork DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
EOF
    mysql -h${MYSQL_HOST} -u${MYSQL_USER} -p${MYSQL_PASS} -P${MYSQL_PORT} < /tmp/init.sql
    cd /var/www/paperwork/frontend/
    php artisan migrate --force
fi


# config ngx
export HTTP_PORT=${HTTP_PORT:-5000}
sed -i \
    -e "s|{HTTP_PORT}|${HTTP_PORT}|" \
    /etc/nginx/sites-available/paperwork.conf


service nginx start
service php5-fpm restart
cp -R /var/www/paperwork/frontend/app/storage /data/


# qjuery cdn source update
sed -i \
    -e "s|ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js|cdn.bootcss.com/jquery/1.11.3/jquery.min.js|" \
    /var/www/paperwork/frontend/public/setup.php


if [[ $1 == "bash" ]]; then
    /bin/bash
else
    cron -f
fi


