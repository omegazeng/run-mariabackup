*forked from [jmfederico/run-xtrabackup.sh](https://gist.github.com/jmfederico/1495347)*

## Create a backup user
    GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'backup'@'localhost' identified by 'YourPassword';
    FLUSH PRIVILEGES;
## Usage:
    MYSQL_PASSWORD=YourPassword bash run-mariabackup.sh
