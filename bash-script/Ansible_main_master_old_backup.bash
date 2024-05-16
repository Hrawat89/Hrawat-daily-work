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
echo "$file_name_with_PasswordAuthentication"
############### commant out the all search value
for file in $file_name_with_PasswordAuthentication
 do
	 file_Name=$(basename $file)
	 echo $file_path
   cp $file  /opt/$file_Name-$NOW
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' $file
    echo "Occurrences of PasswordAuthentication in $file have been changed"
    VALIDATE $? "Value changed"
    systemctl restart sshd.service
    VALIDATE $? "ssh service restart"
    sleep 5
done
############
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
				 set -x
                        #       $USERADD -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME"
                                adduser  --disabled-password --gecos "" "$USERNAME"

                                hashed_password=$(openssl passwd -1 "$PASSWORD")
                                echo $hashed_password

				echo "$USERNAME:$hashed_password" | chpasswd -e
                                echo -e "$G $USERNAME is Successfully Created $N"
                         fi
                                VALIDATE $? "$USERNAME user create"
		apt update
		apt install -y software-properties-common
		add-apt-repository -y ppa:ansible/ansible
		apt update
		apt install -y ansible
		ansible --version
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
				yum install -y ansible-*
				ALIDATE $? "Ansible install successful"
				ansible --version
				ansible all -m ping
                sleep 5
                ;;
            *)
                echo "Unknown Linux distribution"
                ;;
        esac
        fi

###################
su - $USERNAME <<'EOF'
##############genrate pub nd private key
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
N='\033[0m' # Reset to default color
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
   if [[ -f ~/.ssh/id_rsa ]]
   then
   rm -r ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
   fi
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
VALIDATE $? "SSh key genrated"
sleep 5
set -x
#########copy the pub key to  local host server
pub_key_data=$(cat ~/.ssh/id_rsa.pub)
echo  "$pub_key_data"
###############chek file /.ssh/authorized_keys is available or not
if [[ -f ~/.ssh/id_rsa.pub ]]
then
     if [[ ! -f ~/.ssh/authorized_keys ]]
        then
         	touch ~/.ssh/authorized_keys
         	chmod 600 ~/.ssh/authorized_keys
		VALIDATE $? "authorized_keys created successful"
		sleep 10
    fi
echo "$pub_key_data" >> ~/.ssh/authorized_keys
cat ~/.ssh/authorized_keys
VALIDATE $? "copy id_rsa.pub to authorized_keys"
echo $PWD
fi
EOF
echo $(whoami)

################# install ansible server 
yum install -y ansible-*

