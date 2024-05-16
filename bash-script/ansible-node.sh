#!/usr/bin/env bash
# File name is:select_server.sh 
# Script File Creation Time:2024-01-02 22:58:00
# DISCRIPTION:this script use for select server like dbaserver appserver both erver or all server 
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
N='\033[0m' # Reset to default color

USERID=$(id -u)
USERNAME=devops
PASSWORD=devops@123
USERADD=/usr/sbin/useradd
NOW=$(date +%d-%m-%Y)
##########################################################################################
## VALIDATE Function to check the command run sucessfully run or not
VALIDATE() {
        if [[ $1 -ne 0 ]]
        then
                echo -e "$2 ...$R FAILED $N"
                exit 1
        else
                echo -e "$2 ... $G SUCCESS $N"
        fi
}
#check login to root user
#: << 'COMMENT'
if [[ $USERID -ne 0  ]]
 then
      echo -e "$R Please login to root user for run the script $N"
      exit 1
fi 
#####################enable ssh root login and password based root login######
search_dir=/etc/ssh/
file_name_with_PasswordAuthentication=`grep -r -l "^PasswordAuthentication" "$search_dir"`
#echo "$file_name_with_PasswordAuthentication"
############### commant out the all search value
for file in $file_name_with_PasswordAuthentication
 do
	 file_Name=$(basename $file)
	 echo $file_path
   cp $file  /opt/$file_Name-$NOW
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' $file
  #  echo "Occurrences of PasswordAuthentication in $file have been changed"
    VALIDATE $? "Value changed"
    systemctl restart sshd.service
    VALIDATE $? "ssh service restart"
    sleep 5
done
############
####### Set the hostname####
if [ -f /etc/os-release ]; then
        # Check if os-release file exists (common in modern Linux distributions)
        source /etc/os-release
        case $ID in
            debian|ubuntu)
                echo "Debian-based system"
                read -p "Enter the $ID host name:" new_hostname
                hostnamectl hostname "$new_hostname"
                echo $(hostname)
                VALIDATE $? "$new_hostname set "
                sudo_file=/etc/sudoers
		pattern="^%admin"
		Insert_pattern="devops  ALL=(ALL) NOPASSWD: ALL"
		sudo_file_name=$(basename $sudo_file)
		cp  $sudo_file /opt/$sudo_file_name-$NOW
 		VALIDATE $? "copy $sudo_file_name in opt"
 		sed -i "/$pattern/a $Insert_pattern" $sudo_file
 		VALIDATE $? "sudoere file updated"
		if id "$USERNAME" &>/dev/null
 			 then
       				echo -e "$G $USERNAME user alredy exists $N"
			 else
   			#	$USERADD -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME"
			        adduser  --disabled-password --gecos "" "$USERNAME"

				hashed_password=$(openssl passwd -1 "$PASSWORD")
				echo "$USERNAME:$hashed_password" | chpasswd -e
       				echo -e "$G $USERNAME is Successfully Created $N"
			 fi
				VALIDATE $? "$USERNAME user create"

                sleep 5
		;;
            centos|rhel)
                echo "Red Hat-based system"
                read -p "Enter the $ID host name:" new_hostname
                hostnamectl set-hostname "$new_hostname"
                VALIDATE $? "$new_hostname set "
                sudo_file=/etc/sudoers
		pattern="^%wheel"
		Insert_pattern="devops  ALL=(ALL) NOPASSWD: ALL"
		sudo_file_name=$(basename $sudo_file)
		cp  $sudo_file /opt/$sudo_file_name-$NOW
 		VALIDATE $? "copy $sudo_file_name in opt"
 		sed -i "/$pattern/a $Insert_pattern" $sudo_file
 		VALIDATE $? "sudoere file updated"
		if id "$USERNAME" &>/dev/null
 		  then
       			echo -e "$G $USERNAME user alredy exists $N"
		  else
       			$USERADD -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME"
       			echo -e "$G $USERNAME is Successfully Created $N"
		   fi
		VALIDATE $? "$USERNAME user create"

		sleep 5
		;;

		amzn|amazon)
                echo "Red Hat-based system"
                read -p "Enter the $ID host name:" new_hostname
                hostnamectl set-hostname "$new_hostname"
                VALIDATE $? "$new_hostname set "
                sudo_file=/etc/sudoers
                pattern="^%wheel"
                Insert_pattern="devops  ALL=(ALL) NOPASSWD: ALL"
                sudo_file_name=$(basename $sudo_file)
                cp  $sudo_file /opt/$sudo_file_name-$NOW
                VALIDATE $? "copy $sudo_file_name in opt"
                sed -i "/$pattern/a $Insert_pattern" $sudo_file
                VALIDATE $? "sudoere file updated"
                if id "$USERNAME" &>/dev/null
                  then
                        echo -e "$G $USERNAME user alredy exists $N"
                  else
                        $USERADD -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME"
                        echo -e "$G $USERNAME is Successfully Created $N"
                   fi
                VALIDATE $? "$USERNAME user create"

                sleep 5
                ;;

            *)
                echo "Unknown Linux distribution"
                ;;
        esac
        fi
###################
#set -x
su - $USERNAME <<'EOF'
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
N='\033[0m' # Reset to default color

##############genrate pub nd private key
#set -x

ssh_dir=~/.ssh/
VALIDATE() {
        if [[ $1 -ne 0 ]]
        then
                echo -e "$2 ...$R FAILED $N"
                exit 1
        else
                echo -e "$2 ... $G SUCCESS $N"
        fi
}
if [[ ! -d $ssh_dir ]]
then 
	mkdir $ssh_dir
	chmod 700 $ssh_dir
	VALIDATE $? "$ssh_dir dir created"
else 
       echo "$G $ssh_dir already present $N"
fi
###############chek file /.ssh/authorized_keys is available or not
     if [ ! -f ~/.ssh/authorized_keys ]
        then
		touch ~/.ssh/authorized_keys
         	chmod 600 ~/.ssh/authorized_keys
		VALIDATE $? "authorized_keys created successful"
		sleep 10
     fi 
		echo ""ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDCR2m+nOJnaFUV/cnXg1ndiW/IZC0FKPKre0IJvRwATpJCZq6m7Bjxf++j7SYdLDnj9B7Tnq4YCwXBDNtbOV6IqbqlvbJtBebMrZpvMW84rXQuZ0+s+M+/mjI7TWIhPUQ3mC5OZxjaALcTkPIgyriGvuSMnbhxb0eNF0JZ4GQMBGlOb4SK41bGIIoH6mQln0gnY1CriIKzBiQYWdsA2wQi1sfpGV5RkpnP2QB/qaZ09TmX0QeQtwcwwSxx76Mr0/dppsuluu0r928TNnw+NjlWq54FHw6jcdTxDyjztJf0FHsh3PTacNK21j/3zPyv+ss/sMk9wsR5D3EjKQYFzT7NfhYNzWd86de1wyUdJYfT+kpHy+Jf6GQPJr5JSWNvmU+KQc+lmFeQPO0t1YwJJhdW3VCuJuA7o85jy1EWmq7gpPuS7p5Ruj6/9bbHtpyblcEFjGJ05UZ0yXLjjkt5UwU5WjEGTQDnqt/hYjN4Df7R4wycteiTZFjGBFcFRJfHSks= devops@Ansible-Master"" >> ~/.ssh/authorized_keys
#		cat ~/.ssh/authorized_keys
		VALIDATE $? "copy data  authorized_keys"
#		echo $PWD
		

EOF
#echo $(whoami)


