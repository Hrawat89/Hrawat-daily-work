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
		echo ""no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="echo 'Please login as the user \"ubuntu\" rather than the user \"root\".';echo;sleep 10;exit 142" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZQXyxevk67I8lCOvTtMufZA/zW3Qq5TDmOVK1p6Jsgv6n7WmvqEBR4Fvhw+fpSXdwYA99Xo+xOKDEZMGfOcPATeRYdAmnh+7qgK+Hyyzj7jDP2I7K73UIYyxuCiQOAL1SOp7Dn13GIOAxPnKhE2/76eWQAqqHVQmFwg/owustr1N+4Qru+fdIh8Zz87v9KwQK3SrWJl2Im0Xke9y0yMiE8Qkf3t4IHwjmaMA2CtjdMZuM2zmAc6YD6na4LqXze0CUfn0yle6dQ3PwOXAQCq/S8rKLx91425ZvuHHs8TPqSOpVBFlqM3GWIfnE1H7zGxX1gNFT8s81e/Lu/ogXuPrB anisble_office"" >> ~/.ssh/authorized_keys
#		cat ~/.ssh/authorized_keys
		VALIDATE $? "copy data  authorized_keys"
#		echo $PWD
		

EOF
#echo $(whoami)

