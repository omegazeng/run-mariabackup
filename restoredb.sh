#!/bin/bash

#	The Restore scripts for MariaDB Version 10.2 and above are slightly different 
#	than version 10.1 and previous. This script is designed to follow the conventions suggested on
#	the official MariaDb Docs for version 10.2 and above. I have also attempted to automate
#	preparing of all the incremental directories. It would take forever if you have a ton of them (eg. if you back up your DB every hour)
#	Please consider the warnings below before you go and run this. 
#WARNING : DO NOT RUN THIS SCRIPT Without understanding exactly what it does. 
#BECAUSE Carnivorous lazer wielding baboons will come and EAT your database

# README
# What it basically does, by default is restore the latest increment. Reading the comments should guide you to figure out exactly what you want to do and restore to any point in time
# To restore to a specific point in time, comment out all lines after (and including) the WHILE loop. Then you can open the text file incremental_dirs.txt and simply
# delete all the directory paths after the point you want to restore. Then run only the remaining part of the script (DO NOT RUN the whole script again(
# Yeah I'm making it more complicated than it is - I probably need to write better instructions. 
# Put this script in the same directory as your base and incr directories


for i in $(find . -name backup.stream.gz | xargs dirname) #Get all directory names of directories that contain the .gz file
do 
echo $i >> folders.txt  				#Save all those directory names to a file
mkdir -p $i/backup					#make a backup directory in all those folders
zcat $i/backup.stream.gz | mbstream -x -C $i/backup/	#Restore the database backup from the stream file (See MariaDB knowledge base for this)
done


sort folders.txt > folders_sorted.txt			#If we are doing an incremental restore, then the increments have to be applied in correct order
sed 's/$/\/backup/' folders_sorted.txt > folders_backup.txt	#the relevant data to be passed onto the mariadb argument is stored in the /backup folder within each directory
sed -i 's/\(.\{2\}\)//' folders_backup.txt			#Remove the ./ characters at the start of each directory path - this causes the script to fail
BASE_DIR=`head -1 folders_backup.txt`				#First line of the file is the full backup (Base Dir)
tail -n +2 folders_backup.txt > incremental_dirs.txt		#Remaining lines are of the incremental directories

rm folders_sorted.txt  folders_backup.txt folders.txt		#Clean up the bloody mess


mariabackup --prepare --target-dir "$BASE_DIR"			#Prepare the base_dir - read the maria docs - this sychronises somes stuff which will blow up  the DB 
while IFS="" read -r p || [ -n "$p" ] 				#iterate over the incremental_dirs file
do
  mariabackup --prepare --target-dir "$BASE_DIR" --incremental-dir "$p"		#Restore all incremental backups - merging it with the full backup
done < incremental_dirs.txt

sudo systemctl stop mysql					#stop the db service so we don't blow things up while swapping stuff out
sudo mv /var/lib/mysql /var/lib/mysql_backup			#back up the existing mysql directory. YOU MAY WANT TO CHANGE THIS, if you're using a different place to store your database
sudo mariabackup --copy-back --target-dir "$BASE_DIR"		#restore the backup
sudo chown -R mysql:mysql /var/lib/mysql			#set permissions right. YOU MAY WANT TO CHANGE THIS AS WELL 
sudo systemctl start mysql					#start back up with restored DB
rm incremental_dirs.txt						#Cleaning up
