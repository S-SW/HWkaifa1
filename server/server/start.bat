@echo off
chcp 65001 >nul
title 校园食堂外卖后端服务


java -Dfile.encoding=UTF-8 -jar canteen-order-server-1.0.0.jar --spring.config.location=file:./application.yml
pause