# README

*forked from [jmfederico/run-xtrabackup.sh](https://gist.github.com/jmfederico/1495347)*

Note: have tested on Ubuntu 18.04 with MariaDB 10.3

## Links

[Full Backup and Restore with Mariabackup](https://mariadb.com/kb/en/library/full-backup-and-restore-with-mariabackup/)

[Incremental Backup and Restore with Mariabackup](https://mariadb.com/kb/en/library/incremental-backup-and-restore-with-mariabackup/)

---

## Install mariabackup

    sudo apt install mariadb-backup

## Create a backup user

    GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'backup'@'localhost' identified by 'YourPassword';
    FLUSH PRIVILEGES;

## Usage

    MYSQL_PASSWORD=YourPassword bash run-mariabackup.sh

## Crontab

    #MySQL Backup
    30 2 * * * MYSQL_PASSWORD=YourPassword bash /data/script/run-mariabackup.sh > /data/script/logs/run-mariabackup.sh.out 2>&1

---

## Restore Example

    tree /data/mysql_backup/
    /data/mysql_backup/
    ├── base
    │   └── 2018-10-23_10-07-31
    │       ├── backup.stream.gz
    │       └── xtrabackup_checkpoints
    └── incr
        └── 2018-10-23_10-07-31
            ├── 2018-10-23_10-08-49
            │   ├── backup.stream.gz
            │   └── xtrabackup_checkpoints
            └── 2018-10-23_10-13-58
                ├── backup.stream.gz
                └── xtrabackup_checkpoints

```bash
# decompress
cd /data/mysql_backup/
for i in $(find . -name backup.stream.gz | grep '2018-10-23_10-07-31' | xargs dirname); \
do \
mkdir -p $i/backup; \
zcat $i/backup.stream.gz | mbstream -x -C $i/backup/; \
done

# prepare
mariabackup --prepare --target-dir base/2018-10-23_10-07-31/backup/ --user backup --password "YourPassword" --apply-log-only
mariabackup --prepare --target-dir base/2018-10-23_10-07-31/backup/ --user backup --password "YourPassword" --apply-log-only --incremental-dir incr/2018-10-23_10-07-31/2018-10-23_10-08-49/backup/
mariabackup --prepare --target-dir base/2018-10-23_10-07-31/backup/ --user backup --password "YourPassword" --apply-log-only --incremental-dir incr/2018-10-23_10-07-31/2018-10-23_10-13-58/backup/

# stop mairadb
service mariadb stop

# empty datadir
mv /data/mysql/ /data/mysql_bak/

# copy-back
mariabackup --copy-back --target-dir base/2018-10-23_10-07-31/backup/ --user backup --password "YourPassword" --datadir /data/mysql/

# fix privileges
chown -R mysql:mysql /data/mysql/

# start mariadb
service mariadb start

# done!
```
