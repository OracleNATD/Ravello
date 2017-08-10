#!/bin/sh -eux
# ravello cloud-init script to initialize oracle linux 7 vm imported from virtualbox.

# enable 'eth0' network connection. --------------------------------------------
# note: oracle linux 7 enp0s3 and enp0s8 devices are not supported in ravello.
nmcli device status
nmcli connection add con-name "eth0" type ethernet ifname eth0

# add public key for user 'NAS Platform Specialist'.-----------------------------
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCu/7L2/uOB8B1jK4I9x3fFo60bejEr9xqoj4bgeK6qxHelkrgWbn7JOXtB3PPE231Pew6bAOFBvHD9c/Dndj4KPf8Zq7mOy7O3/cAvX8VSREaIAAgJ+5dVhoLgrAHq3gYqQYqSAYslnb/hzMXNVpfJSZfVs/+g1UHL2BivLgh5CfqV4VEgr2iy05UJLeDaHFsMHN/YJn2r7gd8ElzSA98RavbRC6GYnS4F/m9Tv7wvu2lSYE32/9LOSa0wbxk+OZxF1PYRQprCFYgqh26V+iEXVU/VCqsttexZKgjEuD0EnuEeON6ZTbxFR90uSX23TefhIXSwAyxcvQwLagn43z2J NAS-Platform-Specialist-GSE" >> /home/oracle/.ssh/authorized_keys
chmod 600 /home/oracle/.ssh/authorized_keys

# disable ssh password authentication. -----------------------------------------
sshdconfig="/etc/ssh/sshd_config"

# check if sshd config file exists.
if [ -f "${sshdconfig}" ]; then
  cp -p ${sshdconfig} ${sshdconfig}.orig

  # modify sshd config file and restart ssh daemon.
  sed -i -e '/^PasswordAuthentication/s/^.*$/PasswordAuthentication no/' ${sshdconfig}
  sed -i -e '/^#RSAAuthentication/s/^.*$/RSAAuthentication yes/' ${sshdconfig}
  sed -i -e '/^#PubkeyAuthentication/s/^.*$/PubkeyAuthentication yes/' ${sshdconfig}
  systemctl restart sshd
fi

# install and configure acpi daemon with shutdown optimizations. ---------------
# install and enable the acpi daemon.
yum -y install acpid
systemctl start acpid
systemctl enable acpid

# initialize acpi power script file paths.
acpiconfig="/etc/acpi/actions/power.sh"
acpitmp="/tmp/power.sh.awk"

# check if acpi power script file exists.
if [ -f "${acpiconfig}" ]; then
  cp -p ${acpiconfig} ${acpiconfig}.orig
  rm -f ${acpitmp}
  touch ${acpitmp}

  # modify acpi power script file and restart acpi daemon.
  awk '{if ($0 ~ /^PATH/) {printf "%s\n\n# Changed to enable immediate shutdown in Ravello.\nshutdown -h now\n", $0} else {print $0}}' ${acpiconfig} >> ${acpitmp}
  mv -f ${acpitmp} ${acpiconfig}
  systemctl restart acpid
fi
