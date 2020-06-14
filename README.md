# simple-mysql-backups
Configurable Bash script for creating backups of a mysql database.

I often have a need for a cron script to simply dump a database on a nightly basis.
This very simple bash script fills that need when executed as a cron job.

# Installation
1. Copy the file to a secure place in your account
2. Give the file execute permissions `chmod 755 simple-mysql-backups.sh` 
(750 might be more appropriate depending on your server configuration)
3. Add the sample command below to your crontab

## Database credentials
The script executes `mysqldump` without passing any credentials. Thus, you 
need to make sure `mysqldump` is in your path and it can connect to the
database you are trying to back up. A common approach for handling credentials
is to add your credetials to a .my.cnf and put that file in the root of your
account. A sample .my.cnf file is included in this repo.

# Usage
`./simple-backup-creator.sh -k shoe_shop -p backups -d shoe_shop_database`

Will produce a directory of up to 30 files with the following date-adjusted names:

    shoe_shop_2020-06-14_030000.tar.gz
    shoe_shop_2020-06-15_030000.tar.gz
    shoe_shop_2020-06-16_030000.tar.gz
    shoe_shop_2020-06-17_030000.tar.gz

## to see built-in help
`./simple-backup-creator.sh -h`
