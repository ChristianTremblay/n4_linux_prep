#!/bin/bash
# Run as root
curl https://raw.githubusercontent.com/ChristianTremblay/n4_linux_prep/main/startup.sh | bash -s user_name

message () {
  echo "***************************************"
  echo " $1"
  echo "***************************************"
}

notice () {
  echo "    -> $1"
  echo ""
}

install_packages () {
  dnf update -y
  dnf upgrade -y
  dnf install unzip -y
  dnf install dos2unix -y
  dnf install rsync -y
  dnf install rng-tools -y
  dnf install python3 -y
  dnf install tmux -y
  dnf install htop -y
  dnf install lm_sensors -y
  dnf install wine-tahoma-fonts -y

  # Setup snap...we'll use it later for termshark

  sudo dnf install epel-release -y
  sudo dnf install snapd -y
  sudo systemctl enable --now snapd.socket
  sudo ln -s /var/lib/snapd/snap /snap
}

setup_firewall () {
  sudo firewall-cmd --zone=public --permanent --add-port=4911/udp
  sudo firewall-cmd --zone=public --permanent --add-port=4911/tcp
  sudo firewall-cmd --zone=public --permanent --add-port=5011/tcp
  sudo firewall-cmd --zone=public --permanent --add-port=8443/tcp
  sudo firewall-cmd --zone=public --permanent --add-port=47808/udp
  sudo firewall-cmd --zone=public --permanent --add-forward-port=port=80:proto=tcp:toport=8888
  sudo firewall-cmd --zone=public --permanent --add-forward-port=port=443:proto=tcp:toport=8443 
  sudo firewall-cmd --reload
}

add_entropy () {
  rngd -v
  systemctl start rngd
  # systemctl status rngd
  systemctl enable rngd
}

configure_tmux () {
  if [ -f /home/${USER}/.tmux.conf ]; then
    notice "Tmux configuration file already exist"
  else
    wget https://gist.githubusercontent.com/ChristianTremblay/1ddcf3a8c27bb49b11cd2d8f1d813d87/raw/38cc371e38a7b38b3f6ff6e8bd45b4e84b7f1bd3/.tmux.conf -O /home/${USER}/.tmux.conf

  fi
}

create_termshark_script () {
  if [ -f /home/${USER}/ts.sh ]; then
    notice "Termshark script file already exist"
  else
    wget https://gist.githubusercontent.com/ChristianTremblay/10611dde084fcf63d6d5fe5c739b009f/raw/dda38b30616f1ef6fa4462592bc19dec55307291/ts.sh -O /home/${USER}/ts.sh
    sudo chmod +x /home/${USER}/ts.sh
  fi
}

install_python_packages () {
  sudo -u ${USER} pip3 install BAC0 --user
  sudo -u ${USER} pip3 install pyhaystack --user
  sudo -u ${USER} pip3 install black --user
  sudo -u ${USER} pip3 install ipython --user
}

add_to_bashrc () {
  if grep "$1" /home/${USER}/.bashrc ; then
    notice "is already there"
  else
    notice "Adding $1 to ${USER}'s .bashrc file"
    echo "$1" >> /home/${USER}/.bashrc
  fi
}

NIAGARA_FOLDER=". /opt/Niagara/FacExp-4.8.0.110/bin/.niagara"
ALIAS_PIP="alias pip=pip3"
ALIAS_PYTHON="alias python=python3"
ALIAS_TERMSHARK="alias ts=/home/${USER}/ts.sh"
USER=""
TMUXBASH="if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach -t default || tmux new -s default
fi"

do_main () {
  USER=$1
  if cat /etc/passwd | grep ${USER} ; then
    echo "Good, we'll use ${USER} for the setup"

  else
    message "Provide valid username as argument"
    exit 1
  fi
  
  message "Adding ${USER} to Wheel"
  usermod -aG wheel ${USER}

  message "Installing required packages"
  install_packages

  message "Configuring Firewall"
  message "Don't forget to use port 8443 and port 8888 in your station Web Service."
  setup_firewall

  message "Adding entropy to system to better deal with SSL content"
  add_entropy

  message "Enabling Cockpit for remote monitoring of server"
  sudo systemctl enable --now cockpit.socket

  message "Installing Termshark"
  sudo snap install termshark
  create_termshark_script

  message "Configuring .bashrc for ${user}"
  add_to_bashrc "${NIAGARA_FOLDER}"
  add_to_bashrc "${ALIAS_PIP}"
  add_to_bashrc "${ALIAS_PYTHON}"
  add_to_bashrc "${ALIAS_TERMSHARK}"
  add_to_bashrc "${TMUXBASH}"

  message "Downloading tmux configuration file"
  configure_tmux

  message "Installing Python packages"
  install_python_packages
}


do_main $1 > /tmp/centos_startup.log
echo ""
message "Now switch to root and install Niagara"

