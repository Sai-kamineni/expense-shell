#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Please run this script with root priveleges $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N"  | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable NODE JS"

dnf module enable nodejs:20 -y &>>$LOG_FILE 
VALIDATE $? "Enable nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then    
    echo -e "expense user is not exisits..$G creating the user $N"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "Creating expense user"
else    
    echo -e "$Y expense user is already existed..skipping $N"    
fi

mkdir -p /app 
VALIDATE $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/* #Removing existing code
unzip /tmp/backend.zip  &>>$LOG_FILE
VALIDATE $? "Extracting backend application code"

npm install
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

# # load the data before running backend

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL Client"

mysql -h mysql.kamineni.site -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restarted Backend"


# [ ec2-user@ip-172-31-44-120 ~/expense-shell ]$ netstat -lntp
# (Not all processes could be identified, non-owned process info
#  will not be shown, you would have to be root to see it all.)
# Active Internet connections (only servers)
# Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
# tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -
# tcp6       0      0 :::22                   :::*                    LISTEN      -
# tcp6       0      0 :::8080                 :::*                    LISTEN      -

# 23.23.71.56 | 172.31.44.120 | t3.micro | https://github.com/Sai-kamineni/expense-shell.git
# [ ec2-user@ip-172-31-44-120 ~/expense-shell ]$

# 23.23.71.56 | 172.31.44.120 | t3.micro | https://github.com/Sai-kamineni/expense-shell.git
# [ ec2-user@ip-172-31-44-120 ~/expense-shell ]$ systemctl status backend
# ● backend.service - Backend Service
#      Loaded: loaded (/etc/systemd/system/backend.service; enabled; preset: disabled)
#      Active: active (running) since Sun 2025-06-01 09:10:46 UTC; 53s ago
#    Main PID: 15140 (node)
#       Tasks: 11 (limit: 4015)
#      Memory: 23.5M
#         CPU: 347ms
#      CGroup: /system.slice/backend.service
#              └─15140 /bin/node /app/index.js

# 23.23.71.56 | 172.31.44.120 | t3.micro | https://github.com/Sai-kamineni/expense-shell.git
# [ ec2-user@ip-172-31-44-120 ~/expense-shell ]$ ps -ef | grep node
# root         716       2  0 07:48 ?        00:00:00 [xfs-inodegc/dm-]
# root         836       2  0 07:48 ?        00:00:00 [xfs-inodegc/dm-]
# root         837       2  0 07:48 ?        00:00:00 [xfs-inodegc/dm-]
# root         859       2  0 07:48 ?        00:00:00 [xfs-inodegc/nvm]
# root         876       2  0 07:48 ?        00:00:00 [xfs-inodegc/dm-]
# root         883       2  0 07:48 ?        00:00:00 [xfs-inodegc/dm-]
# root         897       2  0 07:48 ?        00:00:00 [xfs-inodegc/dm-]
# expense    15140       1  0 09:10 ?        00:00:00 /bin/node /app/index.js
# ec2-user   15169    1346  0 09:11 pts/0    00:00:00 grep --color=auto node

# 23.23.71.56 | 172.31.44.120 | t3.micro | https://github.com/Sai-kamineni/expense-shell.git
# [ ec2-user@ip-172-31-44-120 ~/expense-shell ]$ telnet mysql.kamineni.site 3306
# Trying 172.31.45.36...
# Connected to mysql.kamineni.site.
# Escape character is '^]'.
# J
# 8.0.415I{
# ko▒pMvC&"vcaching_sha2_password^CConnection closed by foreign host.

# 23.23.71.56 | 172.31.44.120 | t3.micro | https://github.com/Sai-kamineni/expense-shell.git
# [ ec2-user@ip-172-31-44-120 ~/expense-shell ]$
