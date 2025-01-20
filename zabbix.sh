#!/bin/bash

# Обновление репозиториев
echo "Обновление репозиториев..."
apt-get update -y

# Установка PostgreSQL и Zabbix
echo "Установка PostgreSQL и Zabbix..."
apt-get install postgresql16-server zabbix-server-pgsql -y

# Инициализация базы данных PostgreSQL
echo "Инициализация базы данных PostgreSQL..."
/etc/init.d/postgresql initdb

# Включение и запуск PostgreSQL
echo "Включение и запуск PostgreSQL..."
systemctl enable --now postgresql

# Создание пользователя Zabbix в PostgreSQL
echo "Создание пользователя Zabbix..."
su - postgres -s /bin/sh -c 'createuser --no-superuser --no-createdb --no-createrole --encrypted --pwprompt zabbix'

# Ввод пароля для базы данных Zabbix
read -sp "Введите пароль для пользователя zabbix: " zabbix_password
echo

# Создание базы данных Zabbix
echo "Создание базы данных Zabbix..."
su - postgres -s /bin/sh -c "createdb -O zabbix zabbix"

# Импорт схемы базы данных Zabbix
echo "Импорт схемы базы данных Zabbix..."
su - postgres -s /bin/sh -c "psql -U zabbix -f /usr/share/doc/zabbix-common-database-pgsql-*/schema.sql zabbix"

# Импорт изображений базы данных Zabbix
echo "Импорт изображений базы данных Zabbix..."
su - postgres -s /bin/sh -c "psql -U zabbix -f /usr/share/doc/zabbix-common-database-pgsql-*/images.sql zabbix"

# Импорт данных Zabbix
echo "Импорт данных базы данных Zabbix..."
su - postgres -s /bin/sh -c "psql -U zabbix -f /usr/share/doc/zabbix-common-database-pgsql-*/data.sql zabbix"

# Установка Apache и PHP
echo "Установка Apache и PHP..."
apt-get install apache2 apache2-mod_php8.2 -y

# Включение и запуск Apache
echo "Включение и запуск Apache..."
systemctl enable --now httpd2

# Установка дополнительных пакетов PHP
echo "Установка дополнительных пакетов PHP..."
apt-get install php8.2 php8.2-mbstring php8.2-sockets php8.2-gd php8.2-xmlreader php8.2-pgsql php8.2-ldap php8.2-openssl -y

# Редактирование php.ini
echo "Редактирование php.ini..."
cat <<EOL >> /etc/php/8.2/apache2-mod_php/php.ini
memory_limit = 256M
post_max_size = 32M
max_execution_time = 600
max_input_time = 600
date.timezone = Europe/Moscow
EOL

# Перезапуск Apache
echo "Перезапуск Apache..."
systemctl restart httpd2

# Редактирование конфигурации zabbix_server.conf
echo "Редактирование конфигурации zabbix_server.conf..."
cat <<EOL >> /etc/zabbix/zabbix_server.conf
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=$zabbix_password
EOL

# Включение и запуск службы Zabbix
echo "Включение и запуск службы Zabbix..."
systemctl enable --now zabbix_pgsql

# Установка PHP-фронтенда для Zabbix
echo "Установка PHP-фронтенда для Zabbix..."
apt-get install zabbix-phpfrontend-apache2 zabbix-phpfrontend-php8.2 -y

# Создание символической ссылки для конфигурации Apache
echo "Создание символической ссылки для конфигурации Apache..."
ln -s /etc/httpd2/conf/addon.d/A.zabbix.conf /etc/httpd2/conf/extra-enabled/

# Перезапуск Apache
echo "Перезапуск Apache..."
service httpd2 restart

# Изменение владельца для директории Zabbix
echo "Изменение владельца для директории Zabbix..."
chown apache2:apache2 /var/www/webapps/zabbix/ui/conf

echo "Скрипт завершен успешно!"
