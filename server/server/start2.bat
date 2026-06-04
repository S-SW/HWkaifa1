@echo off
chcp 65001 >nul
title 校园食堂外卖后端服务

java -Dfile.encoding=UTF-8 -jar canteen-order-server-1.0.0.jar --spring.datasource.url=jdbc:mysql://127.0.0.1:3307/canteen_order spring.datasource.username=root --spring.datasource.password=123456
pause