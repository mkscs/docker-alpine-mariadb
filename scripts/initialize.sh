#!/bin/sh

. /scripts/vars.sh

create_default() {
  echo "Setting up..."
  
  mkdir -v -p {"/run/mysqld","/var/log/mysql"}

  for dir in "$DOCKER_DB_MOUNTPOINT" "/var/run/mysqld" "/var/log/mysql"
  do
    chmod -R 0755 "$dir"
    chown -R "mysql" "$dir"
  done
  mysql_install_db --user=mysql > /dev/null 2>&1
  
  mysqld_safe --user=mysql > /dev/null 2>&1 &
  
  while true; do
    mysql -u root -e "status" > /dev/null 2>&1
    if [ "$?" = 0 ];then
      echo "MySQL's up."
      break
    fi
  done
}

initialize() {
  mysql -u root <<-EOSQL
  use mysql;
  GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
  UPDATE user SET password=PASSWORD("$MYSQL_ROOT_PASSWORD") WHERE user='root';
  CREATE DATABASE IF NOT EXISTS \`$DB_DBNAME\` CHARACTER SET utf8 COLLATE utf8_general_ci;
  GRANT ALL ON \`$DB_DBNAME\`.* to '$DB_USERNAME'@'%' IDENTIFIED BY '$DB_PASSWORD' WITH GRANT OPTION;
  DROP USER ''@'localhost';
EOSQL

  echo "=============================================="
  echo "MySQL USERNAME:             $DB_USERNAME"
  echo "MySQL PASSWORD:             $DB_PASSWORD"
  echo "MySQL DBNAME:               $DB_DBNAME"
  echo "MySQL ROOT PASSWORD:        $DB_ROOT_PASSWORD"
  echo "MySQL PORT:                 $DOCKER_DB_PORT"
  echo "mysqld params:              $@"
  echo "=============================================="
  
  mysqladmin -u root shutdown
}

if [ -d "$DOCKER_DB_MOUNTPOINT/mysql" ];then
  echo "$DOCKER_DB_MOUNTPOINT present."
else
  create_default
  initialize
fi



exec mysqld_safe --user=mysql "$@" 