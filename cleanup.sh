!#/bin/bash

#Internal Field Separator (IFS) indicates the start of a "new file". It has to be set to "new line". Otherwise find-loop won't work on files in folder.

IFS="
" 

#Create folders and logfiles

function initiate(){
	
	#Check if folder ~/cleanup exists. If not, create it.
	
	if [ ! -d ~/cleanup ];then
		mkdir ~/cleanup;
	fi
	
	#Check if folder ~/cleanup/log exists. If not, create it.
	
	if [ ! -d ~/cleanup/log ];then
		mkdir ~/cleanup/log;
	fi	
	
	#Check if folder ~/cleanup/log/once exists. If not, create it.
	
	if [ ! -d ~/cleanup/log/once ];then
		mkdir ~/cleanup/log/once;
	fi	
	
	#Check if folder ~/cleanup/log/cron exists. If not, create it.
	
	if [ ! -d ~/cleanup/log/cron ];then
		mkdir ~/cleanup/log/cron;
	fi	
	
	#Check if file cleanup.conf exists. If not, create it. 
	
	if [ ! -f ~/cleanup/cleanup.conf ];then
		touch ~/cleanup/cleanup.conf;
	fi
	
	#Anacron as a user from https://grinux.wordpress.com/2012/04/18/run-anacron-as-user/ [10.01.2017]
	#Check if folder ~/.anacron and subfolders exists. If not, create them.
	
	if [ ! -d ~/.anacron ];then
		mkdir ~/.anacron
		mkdir ~/.anacron/cron.daily
		mkdir ~/.anacron/cron.weekly
		mkdir ~/.anacron/cron.monthly
		mkdir ~/.anacron/spool
		mkdir ~/.anacron/etc
		touch ~/.anacron/etc/anacrontab;
	fi

	#Write anacrontab

	if [ ! -s ~/.anacron/etc/anacrontab ];then
	echo -e '# See anacron(8) and anacrontab(5) for details.

SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# These replace crons entries
1	5	cron.daily	run-parts --report ~/.anacron/cron.daily
7	10	cron.weekly	run-parts --report ~/.anacron/cron.weekly
@monthly	15	cron.monthly	run-parts --report ~/.anacron/cron.monthly' | tee --append ~/.anacron/etc/anacrontab > /dev/null
	
	#Write to ~/.profile
	
	echo -e '\n#Starting anachron on user-level
/usr/sbin/anacron -t ~/.anacron/etc/anacrontab -S ~/.anacron/spool &> ~/.anacron/anacron.log'  | tee --append ~/.profile > /dev/null;
	fi
	
	menu
	
	}

function create_folder_and_files(){

	#Enter folder to clean up.
	
	clear
	echo "Enter full folder:"
	read folder
	
	#Check if last char of folder is /, then remove it.
	
	if [[ "${folder:${#x}-1}" == "/" ]]; then
		folder=${folder::-1}
	fi
	
	#Check if first char of folder is /, then remove it for postfix
	
	if [[ $folder == /* ]]; then
		postfix=${folder:1}
		else postfix=$folder
	fi
	
	postfix=$(echo ${postfix////-})
	
	#Check if log-file exists in folder ~/cleanup/log/once. If not, create it.
	
	if [ ! -f ~/cleanup/log/once/log-$postfix ];then
		touch ~/cleanup/log/once/log-$postfix;
		echo -e "Delete date\tDownloaded\tFilename" >> ~/cleanup/log/once/log-$postfix;
	fi
	
	delete_files
	}

function delete_files(){
	#Delete files and create add to logfile
		
	#Enter max age of files before deleting them
	
	clear
	echo "Enter max ctime:"
	read time
	clear
	
	#Find files with 
	
	for file in $(find $folder -ctime +$time);
		do 
			#Get ctime from each file (Time of Download)
			ctime=$(stat -c %z $file | cut -d" " -f1);
			#Get current date
			date=$(date +%d.%m.%Y);
			#Get basename of file
			filename=$(basename $file);
			echo -e "$date \t $ctime \t $filename" >> ~/cleanup/log/once/log-$postfix;
			#Remove file
			rm $file
		done
	clear
	echo "All files are deleted and log-file is created/added"
	
	#Remove empty folders
	
	echo "Do you want to remove empty folders in $folder now? [Y/N]"
	read option
	case $option in
		y) remove_empty_folders;;
		Y) remove_empty_folders;;
		n) menu;;
		N) menu;;
		*) echo "Wrong input"
		   read -p "Press [Enter] to continue..."
	esac
	menu
	}
	
function remove_empty_folders(){
	#Find and remove empty folders
	
	clear
	#Find empty folders
	find $folder -type d -empty -delete
	echo "Empty folders removed."
	read -p "Press [Enter] to continue..."
	clear
	menu
	}
	
function set_cron_menu(){
	clear
	echo "After which interval should the script be executed?"
	echo "[1] Daily"
	echo "[2] Weekly"
	echo "[3] Monthly"
	echo -n "Enter a number>"
	read option
	case $option in
		1) cron_interval=daily;;
		2) cron_interval=weekly;;
		3) cron_interval=monthly;;
		*) clear
		   echo "Wrong input"
		   echo "Press [Enter] to repeat input..."
		   set_cron_menu;;
	esac
	set_cron
	}
	
function set_cron(){
	#Input folder to keep clean
	echo "Enter full folder to clean up:"
	read folder
	
	#Check if last char of folder is /, then remove it
	if [[ $folder == */ ]]; then
		folder=${folder::-1}
	fi
	
	#Check if first char of folder is /, then remove it for cronname
	if [[ $folder == /* ]]; then
		postfix=${folder:1}
		else postfix=$folder
	fi
		
	#Create name of postfix. Replace slash with minus.
		
	postfix=$(echo ${postfix////-})
	cronname=cleanup-$postfix
	
	#Check if log-file exists in folder ~/cleanup/log/cron/. If not, create it.
	
	if [ ! -f ~/cleanup/log/cron/log-$postfix ];then
		touch ~/cleanup/log/cron/log-$postfix;
		echo -e "Delete date\tCreated\tFilename" >> ~/cleanup/log/cron/log-$postfix;
	fi
		
	echo "Enter max ctime:"
	read time
	clear
	echo -e '#!/bin/bash
#'$folder'
#'$time'

for file in $(find '$folder' -type f -ctime +'$time');
	do 
		#Get ctime from each file (creation time)
		ctime=$(stat -c %z $file | cut -d" " -f1);
		#Get current date
		date=$(date +%Y-%m-%d);
		#Get basename of file
		filename=$(basename $file);
		echo -e "$date\t$ctime\t$filename">> ~/cleanup/log/cron/log-'$postfix';
		#Remove file
		rm $file
	done' | tee --append ~/.anacron/cron.$cron_interval/$cronname > /dev/null
	chmod +x ~/.anacron/cron.$cron_interval/$cronname
	clear
	echo "Cronjob created."
	read -p "Press [Enter] to return to menu..."	
	clear
	menu
	}

#function downthemall(){
	#clear
	#echo "Anleitung zur Einrichtung des FF-Plugins DownThemAll"
	#echo ""
	#echo "1) Herunterladen und Installieren des Plugins über Add-ons."
	#echo "2) Neustart des Firefox-Browser."
	#echo "3) Download beliebiger Datei."
	#echo "4) Bei Download im PopUp-Fenster \"DownThemAll\" auswählen."
	#echo "5) Unter Maske \"*refer*_._*name*.*ext*\" eintragen."
	#echo "6) Download starten."
	#echo "7) Folgende Downloads mit \"dTa OneClick!\" herunterladen."
	#echo ""
	#read -p "Press [Enter] to continue..."
	#clear
	#menu
	#}

function check_cron(){

	unset cronjobs[*]

	clear
	
	i=1

	for file in $(find ~/.anacron/cron.* -name cleanup-\*);
		do
			interval=$(echo $file | cut -d "/" -f5 | cut -d "." -f2)
			if [ "$interval" == "daily" ]; then
				#interval="täglich"
				folder=$(head -2 $file | tail -1)
				folder=${folder:1}
				time=$(head -3 $file | tail -1)
				time=${time:1}
				cronjobs[$i]=$(echo -e "$i) $file\nInterval: $interval\nFolder: $folder\nDelete files $time days after creation.")
				i=$((i+1))
				elif [ "$interval" == "weekly" ]; then
					#interval="wöchentlich"
					folder=$(head -2 $file | tail -1)
					folder=${folder:1}
					time=$(head -3 $file | tail -1)
					time=${time:1}
					cronjobs[$i]=$(echo -e "$i) $file\nInterval: $interval\nFolder: $folder\nDelete files $time days after creation.")
					i=$((i+1))
					elif [ "$interval" == "monthly" ]; then
						#interval="monatlich"
						folder=$(head -2 $file | tail -1)
						folder=${folder:1}
						time=$(head -3 $file | tail -1)
						time=${time:1}
						cronjobs[$i]=$(echo -e "$i) $file\nInterval: $interval\nFolder: $folder\nDelete files $time days after creation.")
						i=$((i+1))
			fi			
		done	
	echo "Overview of cronjobs"
	echo ""

	if [ ${#cronjobs[@]} -eq 0 ]; then
		echo ""
		echo "No chronjobs available"
		echo ""
	else
		printf '%s\n' "${cronjobs[*]}"
	fi
	
	echo ""
	read -p "Press [Enter] to continue..."
	clear
	menu
	}

function remove_chron(){
	
	unset cronjobs[*]
	
	clear
	
	i=0

	for file in $(find ~/.anacron/cron.* -name cleanup-\*);
		do
			interval=$(echo $file | cut -d "/" -f5 | cut -d "." -f2)
			if [ "$interval" == "daily" ]; then
				#interval="täglich"
				folder=$(head -2 $file | tail -1)
				folder=${folder:2}
				time=$(head -3 $file | tail -1)
				time=${time:1}
				i=$((i+1))
				cronjobs[$i]=$(echo -e "$i) $file\nIntervall: $interval\nOrdner: $folder\nDelete files $time days after creation.")
				elif [ "$interval" == "weekly" ]; then
					#interval="wöchentlich"
					folder=$(head -2 $file | tail -1)
					folder=${folder:2}
					time=$(head -3 $file | tail -1)
					time=${time:1}
					i=$((i+1))
					cronjobs[$i]=$(echo -e "$i) $file\nIntervall: $interval\nOrdner: $folder\nDelete files $time days after creation.")
					elif [ "$interval" == "monthly" ]; then
						#interval="monatlich"
						folder=$(head -2 $file | tail -1)
						folder=${folder:2}
						time=$(head -3 $file | tail -1)
						time=${time:1}
						i=$((i+1))
						cronjobs[$i]=$(echo -e "$i) $file\nIntervall: $interval\nOrdner: $folder\nDelete files $time days after creation.")				
			fi		
		done
	
	echo "Overview of cronjobs"
	echo ""
	
	if [ ${#cronjobs[@]} -eq 0 ]; then
		echo ""
		echo "No chronjobs available"
		echo ""
		echo "Press [Enter] to continue..."
		read
		clear
		menu
	else
		printf '%s\n' "${cronjobs[*]}"
		echo ""
	
		echo "Which chronjob should be deleted? Enter a Number between 1 and "$i"."
		read del_num
		filename=$(echo ${cronjobs[$del_num]} | cut -d " " -f 2)
		echo "Delete "$filename" ? [Y/N]"
		read option
		case $option in
			y) 	rm $filename
				clear
				echo "Cronjob deleted."
				read -p "Press [Enter] to continue..."
				menu;;
			Y) 	rm $filename
				clear
				echo "Cronjob deleted."
				read -p "Press [Enter] to continue..."
				menu;;
			n) 	clear
				menu;;
			N) 	clear
				menu;;
			*) menu
		esac	
	fi
		
	}

function menu(){
	
	clear
	#Menü-Optionen
	echo "Cleanup-Menu"
	echo "[1] Start cleanup once"
	echo "[2] Set cronjob"
	echo "[3] Check cronjob"
	echo "[4] Remove cronjob"
	echo "[5] Set up DownThemAll"
	echo "[6] Scriptinfo"
	echo "[9] Exit"
	echo -n "Enter a number>"
	
	read option
	case $option in
		1) create_folder_and_files;;
		2) set_cron_menu;;
		3) check_cron;;
		4) remove_chron;;
		5) empty;;
		6) scriptinfo;;
		9) clear
		   exit;;
		*) clear
		   echo "Please repeat input"
		   echo ""
		   menu;;
	esac
	}

function empty(){
	
	clear
	echo "In Progress.."
	read -p "Press [Enter] to continue..."
	menu
	}

function scriptinfo(){

	clear
	#Scriptinfo
	echo "Autodelete v0.1"
	echo "by start2code"
	echo ""
	read -p "Press [Enter] to continue..."
	menu
	}
	
initiate

