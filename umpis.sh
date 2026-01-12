#!/bin/bash
# Ubuntu MATE (and Debian) post-install script

if lsb_release -cs | grep -qE -e "trusty" -e "xenial|sarah|serena|sonya|sylvia" -e "bionic|tara|tessa|tina|tricia" -e "focal|ulyana|ulyssa|uma|una" -e "jammy|vanessa|vera|victoria|virginia" -e "stretch|cindy" -e "buster|debbie" -e "bullseye|elsie" -e "bookworm|faye" -e "trixie|gigi" -e "noble|wilma|xia|zara|zena" -e "orel|1.7_x86-64|1.8_x86-64"; then
  if lsb_release -cs | grep -q "trusty"; then
    ver=trusty
  fi
  if lsb_release -cs | grep -qE "xenial|sarah|serena|sonya|sylvia"; then
    ver=xenial
  fi
  if lsb_release -cs | grep -qE "bionic|tara|tessa|tina|tricia"; then
    ver=bionic
  fi
  if lsb_release -cs | grep -qE "focal|ulyana|ulyssa|uma|una"; then
    ver=focal
  fi
  if lsb_release -cs | grep -qE "jammy|vanessa|vera|victoria|virginia"; then
    ver=jammy
  fi
  if lsb_release -cs | grep -qE "noble|wilma|xia|zara|zena"; then
    ver=noble
  fi
  if lsb_release -cs | grep -qE "stretch|cindy"; then
    ver=stretch
  fi
  if lsb_release -cs | grep -qE "buster|debbie"; then
    ver=buster
  fi
  if lsb_release -cs | grep -qE "bullseye|elsie"; then
    ver=bullseye
  fi
  if lsb_release -cs | grep -qE "bookworm|faye"; then
    ver=bookworm
  fi
  if lsb_release -cs | grep -qE "trixie|gigi"; then
    ver=trixie
  fi
  if lsb_release -cs | grep -q "orel"; then
    ver=astra9
  fi
  if lsb_release -cs | grep -q "1.7_x86-64"; then
    ver=astra10
  fi
  if lsb_release -cs | grep -q "1.8_x86-64"; then
    ver=astra12
  fi
else
  echo "Currently only Debian 9, 10, 11, 12 and 13; AstraLinux 2.12, 1.7 and 1.8; Ubuntu MATE 14.04 LTS, 16.04 LTS, 18.04 LTS, 20.04 LTS, 22.04 LTS and 24.04 LTS; Linux Mint 18, 18.1, 18.2, 18.3, 19, 19.1, 19.2, 19.3, 20, 20.1, 20.2, 20.3, 21, 21.1, 21.2, 21.3, 22, 22.1, 22.2 and 22.3; LMDE 3, 4, 5, 6 and 7 are supported!"
  exit 1
fi

is_docker=0
if [ -f /.dockerenv ]; then
  echo "Note: we are running inside Docker container, so some adjustings will be applied!"
  is_docker=1
fi

dpkg_arch=$(dpkg --print-architecture)
if [[ "$dpkg_arch" == "amd64" || "$dpkg_arch" == "armhf" || "$dpkg_arch" == "arm64" ]]; then
  echo "Detected CPU architecture is $dpkg_arch, it is supported."
else
  echo "Currently only amd64 (x86_64), armhf and arm64 CPU architectures are supported!"
  exit 2
fi

if [ "$UID" -ne "0" ]
then
  echo "Please run this script as root user with 'sudo -E ./umpis.sh'"
  exit 3
fi

echo "Welcome to the Ubuntu MATE (and Debian) post-install script!"
set -e
set -x

# Initialize
export DEBIAN_FRONTEND=noninteractive

# Configure MATE desktop
if [[ $is_docker == 0 && "$DESKTOP_SESSION" == "mate" ]]; then
## keyboard layouts, Alt+Shift for layout toggle
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['us', 'ru']"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.peripherals-keyboard-xkb.kbd model "''"
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.peripherals-keyboard-xkb.kbd options "['grp\tgrp:alt_shift_toggle']"

## terminal
cat <<EOF > /tmp/dconf-mate-terminal
[keybindings]
help='disabled'

[profiles/default]
allow-bold=false
background-color='#FFFFFFFFDDDD'
palette='#2E2E34343636:#CCCC00000000:#4E4E9A9A0606:#C4C4A0A00000:#34346565A4A4:#757550507B7B:#060698209A9A:#D3D3D7D7CFCF:#555557575353:#EFEF29292929:#8A8AE2E23434:#FCFCE9E94F4F:#72729F9FCFCF:#ADAD7F7FA8A8:#3434E2E2E2E2:#EEEEEEEEECEC'
bold-color='#000000000000'
foreground-color='#000000000000'
visible-name='Default'
scrollback-unlimited=true
EOF

sudo -EHu "$SUDO_USER" -- dconf load /org/mate/terminal/ < /tmp/dconf-mate-terminal

  ## window management keyboard shortcuts for Ubuntu MATE 18.04 LTS
  if [[ "$ver" == "trusty" || "$ver" == "xenial" || "$ver" == "stretch" || "$ver" == "bionic" || "$ver" == "astra10" ]]; then
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings unmaximize '<Mod4>Down'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings maximize '<Mod4>Up'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-ne '<Alt><Mod4>Right' || true
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-sw '<Shift><Alt><Mod4>Left' || true
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-side-e '<Mod4>Right' || true
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-se '<Shift><Alt><Mod4>Right' || true
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings move-to-center '<Alt><Mod4>c'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-nw '<Alt><Mod4>Left' || true
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-side-w '<Mod4>Left' || true
  fi # keyboard shortcuts
fi # (is_docker && MATE)?

# Setup the system
rm -v /var/lib/dpkg/lock* /var/cache/apt/archives/lock || true
systemctl stop unattended-upgrades.service || true
apt-get purge unattended-upgrades -y || true

if [[ "$ver" == "trusty" || "$ver" == "xenial" || "$ver" == "bionic" ]]; then # removal is safe only for Ubuntu 14.04 LTS, 16.04 LTS and 18.04 LTS
  apt-get purge ubuntu-advantage-tools -y
else # mask relevant services instead of removing the package on newer versions
  systemctl stop ua-messaging.timer || true
  systemctl stop ua-messaging.service || true
  systemctl mask ua-messaging.timer || true
  systemctl mask ua-messaging.service || true
fi

echo 'APT::Periodic::Enable "0";' > /etc/apt/apt.conf.d/99periodic-disable

systemctl stop apt-daily.service || true
systemctl stop apt-daily.timer || true
systemctl stop apt-daily-upgrade.timer || true
systemctl stop apt-daily-upgrade.service || true
systemctl mask apt-daily.service || true
systemctl mask apt-daily.timer || true
systemctl mask apt-daily-upgrade.timer || true
systemctl mask apt-daily-upgrade.service || true

sed -i "s/^enabled=1/enabled=0/" /etc/default/apport || true
sed -i "s/^Prompt=normal/Prompt=never/" /etc/update-manager/release-upgrades || true
sed -i "s/^Prompt=lts/Prompt=never/" /etc/update-manager/release-upgrades || true

# Install updates
rm -vrf /var/lib/apt/lists/* || true

if [ "$ver" == "astra9" ]; then
  sed -i "s|^deb https://download.astralinux.ru|deb http://mirror.yandex.ru|g" /etc/apt/sources.list /etc/apt/sources.list.d/*.list || true
  wrong_repo_astra9="/astra/stable/orel/repository/"
  correct_repo_astra9="/astra/stable/2.12_x86-64/repository/"
  echo "On AstraLinux 2.12 (Debian 9 based) we should replace wrong repository $wrong_repo_astra9 to correct one $correct_repo_astra9 and only then upgrade packages."
  sed -i "s|$wrong_repo_astra9|$correct_repo_astra9|g" /etc/apt/sources.list /etc/apt/sources.list.d/*.list || true
fi

apt-get update
apt-get install -f -y
apt-get dist-upgrade -o DPkg::Options::=--force-confdef --force-yes -y
apt-get install -f -y
dpkg --configure -a

# add-apt-repository, wget
if [[ "$ver" != "astra10" && "$ver" != "trixie" ]]; then
  apt-get install -y software-properties-common wget
else
  apt-get install -y wget
fi
if [ "$ver" != "astra9" ]; then # fix for https://bugs.debian.org/1029766 and https://bugs.debian.org/1033502
  if [ "$ver" == "trusty" ]; then
    apt-get install -y python-launchpadlib
  else
    apt-get install -y python3-launchpadlib
  fi
fi

# Restricted extras
apt-get install -y ubuntu-restricted-addons ubuntu-restricted-extras || true

# Git
apt-get install -y git

# RabbitVCS integration to Caja
if [[ "$ver" == "trusty" || "$ver" == "xenial" || "$ver" == "stretch" || "$ver" == "bionic" || "$ver" == "buster" || "$ver" == "astra10" ]]; then
  if [ "$ver" == "astra10" ]; then
    # download packages from 18.04 LTS
    cd /tmp
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pysvn/python-svn_1.9.5-1_amd64.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/r/rabbitvcs/rabbitvcs-cli_0.16-1.1_all.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/r/rabbitvcs/rabbitvcs-core_0.16-1.1_all.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/python-caja/python-caja-common_1.20.0-1_all.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/python-caja/python-caja_1.20.0-1_amd64.deb
    if [ "$ver" == "trusty" ]; then
      apt-get install -y ./python-caja-common_1.20.0-1_all.deb ./python-caja_1.20.0-1_amd64.deb ./rabbitvcs-cli_0.16-1.1_all.deb ./python-svn_1.9.5-1_amd64.deb ./rabbitvcs-core_0.16-1.1_all.deb python-tk mercurial subversion
    else
      apt-get install -y ./python-caja-common_1.20.0-1_all.deb ./python-caja_1.20.0-1_amd64.deb ./rabbitvcs-cli_0.16-1.1_all.deb ./python-svn_1.9.5-1_amd64.deb ./rabbitvcs-core_0.16-1.1_all.deb python-tk mercurial subversion --allow-downgrades
    fi
  else
    apt-get install -y rabbitvcs-cli python-caja python-tk mercurial subversion
  fi

  if [ $is_docker == 0 ]; then
    sudo -u "$SUDO_USER" -- mkdir -p ~/.local/share/caja-python/extensions
    cd ~/.local/share/caja-python/extensions
    sudo -u "$SUDO_USER" -- wget -c https://raw.githubusercontent.com/rabbitvcs/rabbitvcs/v0.16/clients/caja/RabbitVCS.py
  else
    mkdir -p /usr/local/share/caja-python/extensions
    wget -c https://raw.githubusercontent.com/rabbitvcs/rabbitvcs/v0.16/clients/caja/RabbitVCS.py -O /usr/local/share/caja-python/extensions/RabbitVCS.py
  fi
fi

if [[ "$ver" == "focal" || "$ver" == "jammy" || "$ver" == "noble" || "$ver" == "bullseye" || "$ver" == "bookworm" || "$ver" == "trixie" || "$ver" == "astra12" ]]; then
  if [ "$ver" == "astra12" ]; then
    cd /tmp
    wget -c http://deb.debian.org/debian/pool/main/p/pysvn/python3-svn_1.9.15-1+b3_amd64.deb
    wget -c http://deb.debian.org/debian/pool/main/r/rabbitvcs/rabbitvcs-cli_0.18-6_all.deb
    wget -c http://deb.debian.org/debian/pool/main/r/rabbitvcs/rabbitvcs-core_0.18-6_all.deb
    wget -c http://deb.debian.org/debian/pool/main/p/python-caja/python-caja-common_1.26.0-1_all.deb
    wget -c http://deb.debian.org/debian/pool/main/p/python-caja/python3-caja_1.26.0-1+b2_amd64.deb
    apt-get install -y --allow-downgrades ./python3-svn_1.9.15-1+b3_amd64.deb ./python-caja-common_1.26.0-1_all.deb ./python3-caja_1.26.0-1+b2_amd64.deb ./rabbitvcs-core_0.18-6_all.deb ./rabbitvcs-cli_0.18-6_all.deb
    apt-get install -y python3-tk git mercurial subversion
  else
    apt-get install -y rabbitvcs-cli python3-caja python3-tk git mercurial subversion
  fi

  if [ $is_docker == 0 ]; then
    sudo -u "$SUDO_USER" -- mkdir -p ~/.local/share/caja-python/extensions
    cd ~/.local/share/caja-python/extensions
    sudo -u "$SUDO_USER" -- wget -c https://raw.githubusercontent.com/rabbitvcs/rabbitvcs/v0.18/clients/caja/RabbitVCS.py
  else
    mkdir -p /usr/local/share/caja-python/extensions
    wget -c https://raw.githubusercontent.com/rabbitvcs/rabbitvcs/v0.18/clients/caja/RabbitVCS.py -O /usr/local/share/caja-python/extensions/RabbitVCS.py
  fi
fi

# GIMP
apt-get install -y gimp

# Inkscape
apt-get install -y inkscape

# Double Commander
apt-get install -y doublecmd-gtk

# System tools
if [[ "$ver" == "trusty" || "$ver" == "xenial" || "$ver" == "stretch" || "$ver" == "bionic" || "$ver" == "buster" ]]; then
  apt-get install -y fslint
elif [ "$ver" == "astra9" ]; then
  cd /tmp
  wget -c http://archive.debian.org/debian/pool/main/f/fslint/fslint_2.46-1_all.deb
  apt-get install -y ./fslint_2.46-1_all.deb
fi

if [[ "$ver" == "astra9" || "$ver" == "astra10" || "$ver" == "astra12" ]]; then
  apt-get install -y htop mc ncdu aptitude synaptic apt-file
  cd /tmp
  if [ "$ver" == "astra12" ]; then
    wget -c http://deb.debian.org/debian/pool/main/a/apt-xapian-index/apt-xapian-index_0.53_all.deb
    apt-get install -y ./apt-xapian-index_0.53_all.deb
  else
    wget -c http://archive.debian.org/debian/pool/main/a/apt-xapian-index/apt-xapian-index_0.49_all.deb
    apt-get install -y ./apt-xapian-index_0.49_all.deb
  fi
else
  # restore Quick Filter and apt-xapian-index in the Synaptic
  if [ "$ver" == "trixie" ]; then
      cat <<EOF | tee /etc/apt/sources.list.d/nrbrtx-ubuntu-synaptic-questing.sources
Types: deb deb-src
URIs: http://ppa.launchpad.net/nrbrtx/synaptic/ubuntu/
Suites: questing
Components: main
Signed-By: 
 -----BEGIN PGP PUBLIC KEY BLOCK-----
 .
 mQINBFUPLWABEADRWUm0WCjOSgpUEl2Tm2vFbn99vFlrnA+08JqAEQBroXd54fF3
 t6vyHzV7CsxrGmriNhYPk3O9L+PZZ64HaXKB3THic//GOhip1j4b+LMx3gEIMVqp
 +g9vAhaKkOXa57BIuJT0zqggw7d9dMiJlvmFyTCgMvR4Hklo3M/72itRxiPfh7dM
 VauI98swPkEfK858vXOkniRdFAtl7OaoR0x+qWBvLqLFSkIIRALoxuw2BpAyEAtZ
 aZaXfXYqne9EFl8Q1dvV+w9TzCgPfQDVfwheiZl3Z4fcWuTt9tKl5/D0DJLnenY9
 QRATDTczHT7olhAucfabRbVqa1Hdg8cK+8puIo35+dPoxdbVnQW63wtwIfu07Ya4
 kKWp4YSTNp6iEHIYX5tGECI7mQNaU292fYR8Y4Of+uR8RWPjO/Vv4UyGPoUnpApv
 J3mpN4miQHOSvA/76F9ZkUr6SyOANATsrmSj5EyWbExtAKf064Crubub2wFK3Fp3
 HUOdwc31aDTr8tkdMV2U8okNcLO+tAwUZs7uR/5gzq41uearQ+GABtYQE3+K7Nnf
 XU9cMV5nKDI/lzJv9o+ftwztbmUUh3LJ373qjtX3013XUkUP2HCRn+yYkc/nkni3
 jgUhnwhRMXKX9JFa1VnnfoTZxztV2uWF7LMOg4Z68nOWhkw1+2j8LZomLwARAQAB
 tBlMYXVuY2hwYWQgUFBBIGZvciBOb3JiZXJ0iQI4BBMBAgAiBQJVDy1gAhsDBgsJ
 CAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRAZv8r1Fo0zqWbqD/9Qkh4fW+Whu5iI
 Pko+RioENNMoNK012uA9yWJBFgTD8uMC0/mD8Q7zwh2aPJ8M5wnmq9OqIVj4/1PW
 ufgf0LrkR1yL34cX+9urm3+npiOnmjlizdFz34gi4ni9DS0DjTLIUPXEkJosxTYw
 4T2BQlqop3xIQPo9nYh026pQ1UQg1blL4k81y88Le4LIRhb0E3mvPGW1mFta779H
 slQ4P8CkylohsQ3VsBdOgOp0UcOAVldPy12FGnB9D9A1W2QK/zmqCjQhqvNHP2Gl
 60fsPJBd1q4FXqvMsJ7MbKri6N3PoTZoEQwPoE9UX8uTDpJyD2csG47+2cTjQtCC
 SlDDPET5U01LXfK1nGcT1qDiiYdn8Vo8GMT8Uxul+B871Tq+0TBNVn6uB12b0z+F
 HWWhwyqZ8l09Z30CsX2N4qlw6uMYtbKVXpXoZKcJGZZ5jgy6Cv9yY6XTUCHZvlMi
 e5q0gmfK9rGf5o/jodR3Nx4agMLtOsVh5nX9F3kfcjA+yScxG7XTSCzTLZZ7yh8c
 GZnkgRjSCl/EERtdzA/zvTJNv3qocT5qefa9OHFLzXhapJdT7rqBBvodpz7aEuyt
 PzF7SnKUFqC96fJva1I0FRspkTU/FpFjAe4u0AhNmrq+KM5ix4t2OvoW7/lmfy+t
 7V41wW5M4tl+fD20NiPBA+/Y+pP5sQ==
 =nhoj
 -----END PGP PUBLIC KEY BLOCK-----
EOF

      cat <<EOF > /etc/apt/preferences.d/pin-lp-nrbrtx-synaptic
Package: *
Pin: release o=LP-PPA-nrbrtx-synaptic
Pin-Priority: 1337
EOF

    apt-get update
  fi

  apt-get install -y htop mc ncdu aptitude synaptic apt-xapian-index apt-file command-not-found
fi

[ ! -e "/var/lib/synaptic/preferences" ] && mkdir -p /var/lib/synaptic/ && touch /var/lib/synaptic/preferences
ln -sfv /var/lib/synaptic/preferences /etc/apt/preferences.d/synaptic

update-apt-xapian-index
apt-file update

# Kate text editor
apt-get install -y kate

# Meld 1.5.3 as in https://askubuntu.com/a/965151/66509
cd /tmp

if [ "$ver" == "bullseye" ]; then
  if [ "$dpkg_arch" == "amd64" ]; then
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pycairo/python-cairo_1.16.2-2ubuntu2_amd64.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pygobject-2/python-gobject-2_2.28.6-14ubuntu1_amd64.deb
    apt-get install -y ./python-cairo_1.16.2-2ubuntu2_amd64.deb
    apt-get install -y ./python-gobject-2_2.28.6-14ubuntu1_amd64.deb
  elif [[ "$dpkg_arch" == "armhf" || "$dpkg_arch" == "arm64" ]]; then
    wget -c "http://ports.ubuntu.com/pool/universe/p/pycairo/python-cairo_1.16.2-2ubuntu2_$dpkg_arch.deb"
    wget -c "http://ports.ubuntu.com/pool/universe/p/pygobject-2/python-gobject-2_2.28.6-14ubuntu1_$dpkg_arch.deb"
    apt-get install -y "./python-cairo_1.16.2-2ubuntu2_$dpkg_arch.deb"
    apt-get install -y "./python-gobject-2_2.28.6-14ubuntu1_$dpkg_arch.deb"
  fi
fi

if [[ "$ver" == "focal" || "$ver" == "bullseye" ]]; then
  if [ "$dpkg_arch" == "amd64" ]; then
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pygtk/python-gtk2_2.24.0-5.1ubuntu2_amd64.deb
    apt-get install -y ./python-gtk2_2.24.0-5.1ubuntu2_amd64.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pygtk/python-glade2_2.24.0-5.1ubuntu2_amd64.deb
    apt-get install -y ./python-glade2_2.24.0-5.1ubuntu2_amd64.deb
  elif [[ "$dpkg_arch" == "armhf" || "$dpkg_arch" == "arm64" ]]; then
    wget -c "http://ports.ubuntu.com/pool/universe/p/pygtk/python-gtk2_2.24.0-5.1ubuntu2_$dpkg_arch.deb"
    apt-get install -y "./python-gtk2_2.24.0-5.1ubuntu2_$dpkg_arch.deb"
    wget -c "http://ports.ubuntu.com/pool/universe/p/pygtk/python-glade2_2.24.0-5.1ubuntu2_$dpkg_arch.deb"
    apt-get install -y "./python-glade2_2.24.0-5.1ubuntu2_$dpkg_arch.deb"
  fi
fi

if [[ "$ver" == "bookworm" || "$ver" == "trixie" || "$ver" == "jammy" || "$ver" == "noble" || "$ver" == "astra12" ]]; then
  apt-get install -y meld
else
  cd /tmp
  if [ "$dpkg_arch" == "amd64" ]; then
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pygtksourceview/python-gtksourceview2_2.10.1-3_amd64.deb http://archive.ubuntu.com/ubuntu/pool/universe/g/gtksourceview2/libgtksourceview2.0-0_2.10.5-3_amd64.deb http://archive.ubuntu.com/ubuntu/pool/universe/g/gtksourceview2/libgtksourceview2.0-common_2.10.5-3_all.deb
    if [ "$ver" == "trusty" ]; then
      apt-get install -y --reinstall python-gtksourceview2 || apt-get install -y --reinstall ./python-gtksourceview2_2.10.1-3_amd64.deb ./libgtksourceview2.0-0_2.10.5-3_amd64.deb ./libgtksourceview2.0-common_2.10.5-3_all.deb
    else
      apt-get install -y --reinstall --allow-downgrades python-gtksourceview2 || apt-get install -y --reinstall --allow-downgrades ./python-gtksourceview2_2.10.1-3_amd64.deb ./libgtksourceview2.0-0_2.10.5-3_amd64.deb ./libgtksourceview2.0-common_2.10.5-3_all.deb
    fi
  fi # TODO add manual download links for armhf, arm64

  wget -c http://old-releases.ubuntu.com/ubuntu/pool/universe/m/meld/meld_1.5.3-1ubuntu1_all.deb -O /var/cache/apt/archives/meld_1.5.3-1ubuntu1_all.deb
  if [ "$ver" == "trusty" ]; then
    dpkg -i /var/cache/apt/archives/meld_1.5.3-1ubuntu1_all.deb
    apt-get install -f -y
  else
    apt-get install -y --allow-downgrades /var/cache/apt/archives/meld_1.5.3-1ubuntu1_all.deb
  fi

cat <<EOF > /etc/apt/preferences.d/pin-meld
Package: meld
Pin: version 1.5.3-1ubuntu1
Pin-Priority: 1337
EOF

fi

# VirtualBox
if [ "$dpkg_arch" == "amd64" ]; then
  if [[ "$ver" != "trusty" && "$ver" != "xenial" && "$ver" != "bionic" && "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "trixie" && "$ver" != "astra9" && "$ver" != "astra10" && "$ver" != "astra12" ]]; then
    echo "virtualbox-ext-pack virtualbox-ext-pack/license select true" | debconf-set-selections
    apt-get install -y virtualbox
    if [ $is_docker == 0 ]; then
      usermod -a -G vboxusers "$SUDO_USER"
    fi
  fi
  if [[ "$ver" == "trusty" || "$ver" == "xenial" || "$ver" == "stretch" || "$ver" == "bionic" || "$ver" == "astra9" || "$ver" == "buster" || "$ver" == "astra10" || "$ver" == "bullseye" || "$ver" == "bookworm" || "$ver" == "astra12" || "$ver" == "trixie" ]]; then
    if [ "$ver" == "xenial" ]; then
      apt-get install -y ca-certificates apt-transport-https
    else
      if [ "$ver" == "trusty" ]; then
        apt-get install -y ca-certificates dirmngr apt-transport-https
      else
        apt-get install -y ca-certificates gpg apt-transport-https
      fi
    fi

    if [ "$ver" == "trusty" ]; then
      wget https://www.virtualbox.org/download/oracle_vbox_2016.asc -O /tmp/vbox.key
      apt-key add /tmp/vbox.key
      apt-key adv --keyserver keyserver.ubuntu.com --recv-key 54422A4B98AB5139
    elif [ "$ver" != "trixie" ]; then
      wget https://www.virtualbox.org/download/oracle_vbox_2016.asc -O - | apt-key add
    elif [ "$ver" == "trixie" ]; then
      wget https://www.virtualbox.org/download/oracle_vbox_2016.asc -O - | gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor
    fi

    deb_ver="$ver"
    if [[ "$ver" == "stretch" || "$ver" == "astra9" ]]; then
      deb_ver=stretch
    elif [ "$ver" == "astra10" ]; then
      deb_ver=buster
      cd /tmp
      wget -c http://archive.debian.org/debian/pool/main/libv/libvpx/libvpx5_1.7.0-3+deb10u1_amd64.deb
      apt-get install -y ./libvpx5_1.7.0-3+deb10u1_amd64.deb
    elif [ "$ver" == "astra12" ]; then
      deb_ver=bookworm
      apt-get install -y linux-headers-all
    fi

    if [ "$ver" == "trixie" ]; then
      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $deb_ver contrib" | tee /etc/apt/sources.list.d/virtualbox.list
      apt-get update
      apt-get install -y virtualbox-7.1
    else
      echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $deb_ver contrib" | tee /etc/apt/sources.list.d/virtualbox.list
      apt-get update
      apt-get install -y virtualbox-6.1
    fi

    # download and install extpack using the same method as in alpis.sh
    mkdir -p /usr/lib/virtualbox/ExtensionPacks
    vbox_version=$(VBoxManage -V | tail -n1 | awk -Fr '{print $1}')
    cd /tmp

    if echo "$vbox_version" | grep -Eq -e '^(5|6)' -e '7.0'; then # ver 5.x, 6.x, 7.0
      wget -c "https://download.virtualbox.org/virtualbox/${vbox_version}/Oracle_VM_VirtualBox_Extension_Pack-${vbox_version}.vbox-extpack" || true
      VBoxManage extpack cleanup
      VBoxManage extpack install --replace "/tmp/Oracle_VM_VirtualBox_Extension_Pack-${vbox_version}.vbox-extpack" --accept-license=33d7284dc4a0ece381196fda3cfe2ed0e1e8e7ed7f27b9a9ebc4ee22e24bd23c
    else # ver 7.1
      wget -c "https://download.virtualbox.org/virtualbox/${vbox_version}/Oracle_VirtualBox_Extension_Pack-${vbox_version}.vbox-extpack" || true
      VBoxManage extpack cleanup
      VBoxManage extpack install --replace "/tmp/Oracle_VirtualBox_Extension_Pack-${vbox_version}.vbox-extpack" --accept-license=eb31505e56e9b4d0fbca139104da41ac6f6b98f8e78968bdf01b1f3da3c4f9ae
    fi

    if [ $is_docker == 0 ]; then
      usermod -a -G vboxusers "$SUDO_USER"
    fi
  else
    apt-get install -y virtualbox || true
    echo "virtualbox-ext-pack virtualbox-ext-pack/license select true" | debconf-set-selections
    apt-get install -y virtualbox-ext-pack || true
    apt-get install -y virtualbox-guest-additions-iso || true
  fi
fi #/amd64

# LibreOffice
if [[ "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "trixie" && "$ver" != "astra9" && "$ver" != "astra10" && "$ver" != "astra12" ]]; then
  add-apt-repository -y ppa:libreoffice/ppa
fi
apt-get update
apt-get install libreoffice -y
apt-get dist-upgrade -y
apt-get install -f -y
apt-get dist-upgrade -y

if [ "$ver" == "trusty" ]; then
  apt-get install --reinstall -y ure
fi

# RStudio
if [[ "$ver" == "stretch" || "$ver" == "astra9" ]]; then
  apt-key adv --keyserver keyserver.ubuntu.com --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7'
  echo "deb http://cloud.r-project.org/bin/linux/debian stretch-cran35/" | tee /etc/apt/sources.list.d/r-cran.list
  apt-get update

  if [ "$ver" == "astra9" ]; then
    cd /tmp
    wget -c http://archive.debian.org/debian-security/pool/updates/main/i/icu/libicu57_57.1-6+deb9u5_amd64.deb

    apt-get install -y ./libicu57_57.1-6+deb9u5_amd64.deb
  fi
fi

if [[ "$ver" == "buster" || "$ver" == "astra10" ]]; then
  apt-key adv --keyserver keyserver.ubuntu.com --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7'
  echo "deb http://cloud.r-project.org/bin/linux/debian buster-cran40/" | tee /etc/apt/sources.list.d/r-cran.list

  if [ "$ver" == "astra10" ]; then
cat <<EOF > /etc/apt/preferences.d/pin-r-cran
Package: *
Pin: origin cloud.r-project.org
Pin-Priority: 1337
EOF
  fi # /astra10

  apt-get update
fi

if [ "$ver" == "trusty" ]; then
  add-apt-repository -y ppa:marutter/rrutter3.5
  apt-get update
fi

if [[ "$ver" == "xenial" || "$ver" == "bionic" || "$ver" == "focal" ]]; then
  apt-key adv --keyserver keyserver.ubuntu.com --recv-key 'E298A3A825C0D65DFD57CBB651716619E084DAB9'
  echo "deb http://cloud.r-project.org/bin/linux/ubuntu ${ver}-cran40/" | tee /etc/apt/sources.list.d/r-cran.list
  apt-get update

  if [[ "$ver" == "xenial" || "$ver" == "bionic" ]]; then
cat <<EOF > /etc/apt/preferences.d/pin-r43
Package: r-*
Pin: version 4.3.*
Pin-Priority: 1337

Package: r-*
Pin: version 4.4.*
Pin-Priority: -10
EOF
  fi
fi

apt-get install -y r-base-dev

if [ "$dpkg_arch" == "amd64" ]; then
  cd /tmp

  if [[ "$ver" == "jammy" || "$ver" == "noble" || "$ver" == "bookworm" || "$ver" == "astra12" ]]; then
    wget -c https://download1.rstudio.org/desktop/jammy/amd64/rstudio-2022.02.3-492-amd64.deb -O rstudio-latest-amd64.deb
  elif [ "$ver" == "focal" ]; then
    wget -c https://s3.amazonaws.com/rstudio-ide-build/electron/focal/amd64/rstudio-2024.12.1-563-amd64.deb -O rstudio-latest-amd64.deb
  elif [ "$ver" == "trixie" ]; then
    wget -c https://s3.amazonaws.com/rstudio-ide-build/electron/jammy/amd64/rstudio-2024.12.1-563-amd64.deb -O rstudio-latest-amd64.deb
  elif [[ "$ver" == "stretch" || "$ver" == "astra9" ]]; then
    wget -c https://download1.rstudio.org/desktop/debian9/x86_64/rstudio-2021.09.0-351-amd64.deb -O rstudio-latest-amd64.deb
  elif [ "$ver" == "xenial" ]; then
    wget -c https://archive.org/download/rstudio-1.3.1093-amd64-xenial/rstudio-1.3.1093-amd64-xenial.deb -O rstudio-latest-amd64.deb || echo "Note: please put local deb-file of RStudio named 'rstudio-1.3.1093-amd64-xenial.deb' with MD5 51ca6c8e21e25fe8162c2de408571e79 to '/tmp/rstudio-latest-amd64.deb' and restart this script."
  elif [ "$ver" == "trusty" ]; then
    wget -c https://download1.rstudio.org/desktop/trusty/amd64/rstudio-1.2.5042-amd64.deb -O rstudio-latest-amd64.deb
  else
    wget -c https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2021.09.0-351-amd64.deb -O rstudio-latest-amd64.deb \
    || wget -c https://rstudio.org/download/latest/stable/desktop/bionic/rstudio-latest-amd64.deb -O rstudio-latest-amd64.deb \
    || wget -c https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.4.1717-amd64.deb -O rstudio-latest-amd64.deb
  fi

  if [ "$ver" == "trusty" ]; then
    apt-get install -y libclang-dev libxkbcommon-x11-0
    dpkg -i ./rstudio-latest-amd64.deb
    apt-get install -f -y
  else
    apt-get install -y --allow-downgrades --reinstall ./rstudio-latest-amd64.deb
  fi
fi

if [ $is_docker == 0 ]; then
  sudo -u "$SUDO_USER" -- mkdir -p ~/.config/rstudio
  cat <<EOF > ~/.config/rstudio/rstudio-prefs.json
{
    "check_for_updates": false,
    "pdf_previewer": "rstudio",
    "posix_terminal_shell": "bash",
    "submit_crash_reports": false
}
EOF
  chown "$SUDO_USER": ~/.config/rstudio/rstudio-prefs.json

  echo 'crash-handling-enabled="0"' | sudo -u "$SUDO_USER" -- tee ~/.config/rstudio/crash-handler.conf
else
  mkdir -p /etc/skel/.config/rstudio
  cat <<EOF > /etc/skel/.config/rstudio/rstudio-prefs.json
{
    "check_for_updates": false,
    "pdf_previewer": "rstudio",
    "posix_terminal_shell": "bash",
    "submit_crash_reports": false
}
EOF

  echo 'crash-handling-enabled="0"' > /etc/skel/.config/rstudio/crash-handler.conf
fi

# Pandoc
cd /tmp
if [ "$dpkg_arch" == "amd64" ]; then
  #LATEST_PANDOC_DEB_PATH=$(wget https://github.com/jgm/pandoc/releases/latest -O - | grep \.deb | grep href | sed 's/.*href="//g' | sed 's/\.deb.*/\.deb/g' | grep amd64)
  #echo $LATEST_PANDOC_DEB_PATH;
  #LATEST_PANDOC_DEB_URL="https://github.com${LATEST_PANDOC_DEB_PATH}";
  LATEST_PANDOC_DEB_URL="https://github.com/jgm/pandoc/releases/download/2.16.1/pandoc-2.16.1-1-amd64.deb"
elif [ "$dpkg_arch" == "arm64" ]; then
  LATEST_PANDOC_DEB_URL="https://github.com/jgm/pandoc/releases/download/2.16.1/pandoc-2.16.1-1-arm64.deb"
fi

if [[ "$dpkg_arch" == "amd64" || "$dpkg_arch" == "arm64" ]]; then
  wget -c "$LATEST_PANDOC_DEB_URL";
  if [ "$ver" == "trusty" ]; then
    dpkg -i /tmp/pandoc*.deb
    apt-get install -f
  else
    apt install -y --allow-downgrades /tmp/pandoc*.deb;
  fi
fi

# bookdown install for local user
apt-get install -y build-essential libssl-dev libcurl4-openssl-dev libxml2-dev libcairo2-dev libfribidi-dev libtiff-dev libharfbuzz-dev libwebp-dev

if [[ "$ver" == "trusty" || "$ver" == "xenial" ]]; then
  apt-get install -y libtool
fi

if [[ "$ver" == "focal" || "$ver" == "jammy" || "$ver" == "noble" || "$ver" == "buster" || "$ver" == "bullseye" || "$ver" == "bookworm" || "$ver" == "trixie" || "$ver" == "astra10" ]]; then
  apt-get install -y libgit2-dev
fi

if [ "$ver" == "astra10" ]; then
  apt-key adv --keyserver keyserver.ubuntu.com --recv E756285F30DB2B2BB35012E219BFCAF5168D33A9
  echo "deb http://ppa.launchpad.net/nrbrtx/evince10/ubuntu bionic main"| tee /etc/apt/sources.list.d/evince.list
  apt-get update
fi

if [ "$ver" != "astra12" ]; then
  apt-get install -y evince
fi

if [[ "$ver" == "trusty" || "$ver" == "stretch" || "$ver" == "astra9" ]]; then
    r_ver="3.6"
fi
if [ "$ver" == "bullseye" ]; then
    r_ver="4.0"
fi
if [ "$ver" == "jammy" ]; then
    r_ver="4.1"
fi
if [[ "$ver" == "bookworm" || "$ver" == "astra12" ]]; then
    r_ver="4.2"
fi
if [[ "$ver" == "xenial" || "$ver" == "bionic" || "$ver" == "noble" ]]; then
    r_ver="4.3"
fi
if [[ "$ver" == "buster" || "$ver" == "astra10" ]]; then
    r_ver="4.4"
fi
if [[ "$ver" == "focal" || "$ver" == "trixie" ]]; then
    r_ver="4.5"
fi

## Use R-packages with specific versions for reproducibility
bookdown_ver="0.37"
knitr_ver="1.45"
xaringan_ver="0.29"

if [[ "$ver" == "trusty" || "$ver" == "stretch" || "$ver" == "astra9" || "$ver" == "xenial" || "$ver" == "bionic" || "$ver" == "bullseye" || "$ver" == "buster" || "$ver" == "focal" ]]; then
  ## installation of 'devtools' is difficult with 
  ## R 3.6 (trusty, stretch, astra9)
  ## R 4.0 (bullseye)
  ## R 4.3 (xenial, bionic)
  ## R 4.4 (buster)
  ## R 4.5 (focal)
  ## so let's try to install fixed versions
  if [ "$dpkg_arch" == "amd64" ]; then
    if [ $is_docker == 0 ] ; then
      sudo -u "$SUDO_USER" -- mkdir -p ~/R/x86_64-pc-linux-gnu-library/"$r_ver"
      sudo -u "$SUDO_USER" -- R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/evaluate/evaluate_0.23.tar.gz', repos=NULL, type='source', lib='/home/$SUDO_USER/R/x86_64-pc-linux-gnu-library/$r_ver')"
      sudo -u "$SUDO_USER" -- R -e "install.packages(c('bookdown', 'knitr', 'xaringan', 'tikzDevice'), repos='http://cran.r-project.org/', type='source', lib='/home/$SUDO_USER/R/x86_64-pc-linux-gnu-library/$r_ver')"
      sudo -u "$SUDO_USER" -- R -e "install.packages(c('https://cran.r-project.org/src/contrib/Archive/bookdown/bookdown_${bookdown_ver}.tar.gz', 'https://cran.r-project.org/src/contrib/Archive/knitr/knitr_${knitr_ver}.tar.gz', 'https://cran.r-project.org/src/contrib/Archive/xaringan/xaringan_${xaringan_ver}.tar.gz'), repos=NULL, type='source', lib='/home/$SUDO_USER/R/x86_64-pc-linux-gnu-library/$r_ver')"
    else
      R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/evaluate/evaluate_0.23.tar.gz', repos=NULL, type='source')"
      R -e "install.packages(c('bookdown', 'knitr', 'xaringan', 'tikzDevice'), repos='http://cran.r-project.org/', type='source')"
      R -e "install.packages(c('https://cran.r-project.org/src/contrib/Archive/bookdown/bookdown_${bookdown_ver}.tar.gz', 'https://cran.r-project.org/src/contrib/Archive/knitr/knitr_${knitr_ver}.tar.gz', 'https://cran.r-project.org/src/contrib/Archive/xaringan/xaringan_${xaringan_ver}.tar.gz'), repos=NULL, type='source')"
    fi
  fi
else
  ## on newer releases install 'devtools' and then specify package versions for reproducibility
  if [ "$dpkg_arch" == "amd64" ]; then
    if [ $is_docker == 0 ] ; then
      sudo -u "$SUDO_USER" -- mkdir -p ~/R/x86_64-pc-linux-gnu-library/"$r_ver"
      sudo -u "$SUDO_USER" -- R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.r-project.org/', lib='/home/$SUDO_USER/R/x86_64-pc-linux-gnu-library/$r_ver')"
    else
      R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.r-project.org/')"
    fi
  elif [ "$dpkg_arch" == "arm64" ]; then
    if [ $is_docker == 0 ] ; then
      sudo -u "$SUDO_USER" -- mkdir -p ~/R/aarch64-unknown-linux-gnu-library/"$r_ver"
      sudo -u "$SUDO_USER" -- R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.r-project.org/', lib='/home/$SUDO_USER/R/aarch64-unknown-linux-gnu-library/$r_ver')"
    else
      R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.r-project.org/')"
    fi
  elif [ "$dpkg_arch" == "armhf" ]; then
    if [ $is_docker == 0 ] ; then
      sudo -u "$SUDO_USER" -- mkdir -p ~/R/arm-unknown-linux-gnueabihf-library/"$r_ver"
      sudo -u "$SUDO_USER" -- R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.r-project.org/', lib='/home/$SUDO_USER/R/arm-unknown-linux-gnueabihf-library/$r_ver')"
    else
      R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.r-project.org/')"
    fi
  fi

  if [ $is_docker == 0 ]; then
    sudo -u "$SUDO_USER" -- R -e "require(devtools); install_version('bookdown', version = '$bookdown_ver', repos = 'http://cran.r-project.org')"
    sudo -u "$SUDO_USER" -- R -e "require(devtools); install_version('knitr', version = '$knitr_ver', repos = 'http://cran.r-project.org')"
    sudo -u "$SUDO_USER" -- R -e "require(devtools); install_version('xaringan', version = '$xaringan_ver', repos = 'http://cran.r-project.org/')"
  else
    R -e "require(devtools); install_version('bookdown', version = '$bookdown_ver', repos = 'http://cran.r-project.org')"
    R -e "require(devtools); install_version('knitr', version = '$knitr_ver', repos = 'http://cran.r-project.org')"
    R -e "require(devtools); install_version('xaringan', version = '$xaringan_ver', repos = 'http://cran.r-project.org/')"
  fi
fi

if [ "$dpkg_arch" == "amd64" ]; then
  if [ $is_docker == 0 ]; then
    ## fixes for LibreOffice <-> RStudio interaction
    grep "^alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" ~/.profile || echo "alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" >> ~/.profile
    grep "^alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" ~/.bashrc || echo "alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" >> ~/.bashrc

    sudo -u "$SUDO_USER" -- mkdir -p ~/.local/share/applications/
    sudo -u "$SUDO_USER" -- cp /usr/share/applications/rstudio.desktop ~/.local/share/applications/
    sudo -u "$SUDO_USER" -- sed -i "s|/usr/lib/rstudio/bin/rstudio|env LD_LIBRARY_PATH=/usr/lib/libreoffice/program /usr/lib/rstudio/bin/rstudio|"  ~/.local/share/applications/rstudio.desktop
  else
    ## fixes for LibreOffice <-> RStudio interaction
    grep "^alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" /etc/skel/.profile || echo "alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" >> /etc/skel/.profile
    grep "^alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" /etc/skel/.bashrc || echo "alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" >> /etc/skel/.bashrc

    mkdir -p /usr/local/share/applications/
    cp /usr/share/applications/rstudio.desktop /usr/local/share/applications/
    sed -i "s|/usr/lib/rstudio/bin/rstudio|env LD_LIBRARY_PATH=/usr/lib/libreoffice/program /usr/lib/rstudio/bin/rstudio|" /usr/local/share/applications/rstudio.desktop
  fi
fi

# TexLive and fonts
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | /usr/bin/debconf-set-selections

if [[ "$ver" == "astra9" || "$ver" == "astra10" || "$ver" == "astra12" ]]; then
  if [ "$ver" == "astra9" ]; then
    apt-get install -y texlive-luatex texlive-generic-recommended
  fi

  apt-get install -y texlive-extra-utils texlive-lang-cyrillic texlive-xetex texlive-fonts-extra texlive-science-doc texlive-science texlive-latex-extra lmodern
  cd /tmp
  wget -c http://archive.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.7_all.deb
  if [ "$ver" == "trusty" ]; then
    apt-get install -y ./ttf-mscorefonts-installer_3.7_all.deb
  else
    apt-get install -y --allow-downgrades ./ttf-mscorefonts-installer_3.7_all.deb
  fi

  wget -c http://archive.debian.org/debian/pool/main/f/fonts-cmu/fonts-cmu_0.7.0-3_all.deb
  apt-get install -y ./fonts-cmu_0.7.0-3_all.deb
else
  apt-get install -y texlive-extra-utils biber texlive-lang-cyrillic fonts-cmu texlive-xetex texlive-fonts-extra texlive-science-doc texlive-science font-manager ttf-mscorefonts-installer texlive-latex-extra texlive-luatex lmodern
  apt-get install --reinstall -y ttf-mscorefonts-installer
fi

if [[ "$ver" == "trusty" || "$ver" == "xenial" ]]; then
  apt-get install -y texlive-generic-extra texlive-math-extra
fi

# ReText
if [[ "$ver" == "astra9" || "$ver" == "astra10" || "$ver" == "astra12" ]]; then
  # download packages from 20.04 LTS to fix rendering
  cd /tmp

  if [ "$ver" == "astra9" ]; then
    wget -c http://archive.ubuntu.com/ubuntu/pool/main/p/python-markdown/python3-markdown_3.1.1-3_all.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/python-markdown-math/python3-mdx-math_0.6-1_all.deb
    apt-get install --reinstall -y ./python3-markdown_3.1.1-3_all.deb ./python3-mdx-math_0.6-1_all.deb
  fi

  if [ "$ver" == "astra12" ]; then
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pymarkups/python3-markups_3.1.3-2_all.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/r/retext/retext_7.2.3-1_all.deb
    apt-get install -y ./python3-markups_3.1.3-2_all.deb ./retext_7.2.3-1_all.deb
  else
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pymarkups/python3-markups_3.0.0-1_all.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/r/retext/retext_7.1.0-1_all.deb
    apt-get install -y ./python3-markups_3.0.0-1_all.deb ./retext_7.1.0-1_all.deb
  fi
else
  apt-get install -y retext
fi


if [[ "$ver" == "xenial" || "$ver" == "stretch" || "$ver" == "bionic" || "$ver" == "buster" || "$ver" == "focal" || "$ver" == "astra9" ]]; then
cat <<\EOF > /tmp/fenced_code.patch
--- org	2021-04-24 18:00:50.029754001 +0300
+++ new	2021-04-24 18:10:19.790492001 +0300
@@ -37,7 +37,7 @@
 class FencedBlockPreprocessor(Preprocessor):
     FENCED_BLOCK_RE = re.compile(r'''
 (?P<fence>^(?:~{3,}|`{3,}))[ ]*         # Opening ``` or ~~~
-(\{?\.?(?P<lang>[\w#.+-]*))?[ ]*        # Optional {, and lang
+(\{?\.?(?P<lang>[\w#.+-]*))?([ ]*|[ ,="\w-]+)        # Optional {, and lang        # Optional {, and lang
 # Optional highlight lines, single- or double-quote-delimited
 (hl_lines=(?P<quot>"|')(?P<hl_lines>.*?)(?P=quot))?[ ]*
 }?[ ]*\n                                # Optional closing }
EOF

if [ "$ver" == "xenial" ]; then # on Ubuntu 16.04 LTS use updated version from Debian 9
  cd /tmp
  wget -c http://archive.debian.org/debian/pool/main/p/python-markdown/python3-markdown_2.6.8-1_all.deb
  apt-get install -y --allow-downgrades --reinstall ./python3-markdown_2.6.8-1_all.deb
else
  apt-get install -y --reinstall python3-markdown
fi # /xenial

patch -u /usr/lib/python3/dist-packages/markdown/extensions/fenced_code.py -s --force < /tmp/fenced_code.patch
fi # /versions

if [ $is_docker == 0 ]; then
  mkdir -p ~/.config
  chown -R "$SUDO_USER":  ~/.config
  echo mathjax | sudo -u "$SUDO_USER" -- tee -a ~/.config/markdown-extensions.txt
  chown "$SUDO_USER": ~/.config/markdown-extensions.txt
else
  echo mathjax >> /etc/skel/.config/markdown-extensions.txt
fi

# PlayOnLinux
dpkg --add-architecture i386
apt-get update
apt-get install -y wine32 || true
if [[ "$ver" == "trusty" || "$ver" == "xenial" || "$ver" == "stretch" || "$ver" == "bionic" ]]; then
  if [ "$ver" == "xenial" ]; then
    apt-get install -y wine:i386
  fi
  cd /tmp
  wget -c https://www.playonlinux.com/script_files/PlayOnLinux/4.3.4/PlayOnLinux_4.3.4.deb -O PlayOnLinux_4.3.4.deb
  if [ "$ver" == "trusty" ]; then
    apt-get install -y winetricks jq python-wxgtk2.8
    dpkg -i ./PlayOnLinux_4.3.4.deb
    apt-get install -f -y
  else
    apt-get install -y --allow-downgrades ./PlayOnLinux_4.3.4.deb winetricks
  fi
else
  if [ "$ver" != "astra10" ]; then
    apt-get install -y playonlinux
  fi

  apt-get install -y winetricks

  if [[ "$ver" == "noble" || "$ver" == "trixie" ]]; then
    apt-get install -y python3-pyasyncore
  fi 
fi

# Y PPA Manager, install gawk to prevent LP#2036761
apt-get install -y ppa-purge gawk || true

if [[ "$ver" != "jammy" && "$ver" != "noble" && "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "trixie" && "$ver" != "astra9" && "$ver" != "astra10" && "$ver" != "astra12" ]]; then
  add-apt-repository -y ppa:webupd8team/y-ppa-manager
  apt-get update
  apt-get install -y y-ppa-manager
fi

# Telegram
if [[ "$ver" != "trusty" && "$ver" != "noble" && "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "trixie" && "$ver" != "astra9" && "$ver" != "astra10" && "$ver" != "astra12" ]]; then
  if [ "$dpkg_arch" == "amd64" ]; then
    add-apt-repository -y ppa:atareao/telegram
    apt-get update
    apt-get install -y telegram
  fi
fi

# NotepadQQ
if [[ "$ver" == "xenial" || "$ver" == "bionic" ]]; then
  add-apt-repository -y ppa:notepadqq-team/notepadqq
  apt-get update
  apt-get install -y notepadqq
fi

# Install locale packages
apt-get install -y locales
apt-get install -y $(check-language-support -l en) $(check-language-support -l ru) || true
apt-get install -y --reinstall --install-recommends task-russian task-russian-desktop || true

# Flatpak
if [[ "$ver" == "xenial" || "$ver" == "bionic" || "$ver" == "focal" ]]; then
  add-apt-repository -y ppa:alexlarsson/flatpak
fi

if [ "$ver" != "trusty" ]; then
  apt-get update
  apt-get install -y flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Ubuntu Make
if [[ "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "trixie" && "$ver" != "astra9" && "$ver" != "astra10" &&  "$ver" != "trusty" && "$ver" != "astra12" ]]; then
  add-apt-repository -y ppa:lyzardking/ubuntu-make
  apt-get update
  apt-get install -y ubuntu-make
fi
if [ "$ver" == "astra10" ]; then
  cd /tmp
  wget -c http://archive.debian.org/debian-security/pool/updates/main/s/snapd/snapd_2.37.4-1+deb10u3_amd64.deb
  wget -c http://archive.debian.org/debian/pool/main/s/snapd-glib/libsnapd-glib1_1.45-1.1_amd64.deb
  wget -c http://archive.debian.org/debian/pool/main/s/snapd-glib/gir1.2-snapd-1_1.45-1.1_amd64.deb

  wget -c http://archive.ubuntu.com/ubuntu/pool/universe/g/gcc-avr/gcc-avr_5.4.0+Atmel3.6.0-1build1_amd64.deb
  wget -c http://archive.ubuntu.com/ubuntu/pool/universe/b/binutils-avr/binutils-avr_2.26.20160125+Atmel3.6.0-1_amd64.deb
  wget -c http://archive.ubuntu.com/ubuntu/pool/universe/a/avr-libc/avr-libc_2.0.0+Atmel3.6.0-1_all.deb
  apt-get install -y ./snapd_2.37.4-1+deb10u3_amd64.deb ./libsnapd-glib1_1.45-1.1_amd64.deb ./gir1.2-snapd-1_1.45-1.1_amd64.deb
  if [ "$ver" == "trusty" ]; then
    apt-get install -y ./gcc-avr_5.4.0+Atmel3.6.0-1build1_amd64.deb ./binutils-avr_2.26.20160125+Atmel3.6.0-1_amd64.deb ./avr-libc_2.0.0+Atmel3.6.0-1_all.deb
  else
    apt-get install -y --allow-downgrades ./gcc-avr_5.4.0+Atmel3.6.0-1build1_amd64.deb ./binutils-avr_2.26.20160125+Atmel3.6.0-1_amd64.deb ./avr-libc_2.0.0+Atmel3.6.0-1_all.deb
  fi
fi
if [ "$ver" == "astra12" ]; then
  cd /tmp
  wget -c http://deb.debian.org/debian/pool/main/s/snapd/snapd_2.57.6-1+b6_amd64.deb
  apt-get install -y ./snapd_2.57.6-1+b6_amd64.deb

  wget -c http://deb.debian.org/debian/pool/main/g/gcc-avr/gcc-avr_5.4.0+Atmel3.6.2-3_amd64.deb
  wget -c http://deb.debian.org/debian/pool/main/b/binutils-avr/binutils-avr_2.26.20160125+Atmel3.6.2-4_amd64.deb
  wget -c http://deb.debian.org/debian/pool/main/a/avr-libc/avr-libc_2.0.0+Atmel3.6.2-3_all.deb
  apt-get install -y --allow-downgrades ./gcc-avr_5.4.0+Atmel3.6.2-3_amd64.deb ./binutils-avr_2.26.20160125+Atmel3.6.2-4_amd64.deb ./avr-libc_2.0.0+Atmel3.6.2-3_all.deb
fi

if [ $is_docker == 0 ] ; then
  umake_path=umake
  if [[ "$ver" != "astra9" && "$ver" != "stretch" && "$ver" != "trusty" && "$ver" != "xenial" && "$ver" != "bionic" && "$ver" != "focal" && "$ver" != "jammy" && "$ver" != "noble" || "$ver" == "astra10" || "$ver" == "buster" || "$ver" == "bullseye" || "$ver" == "bookworm" || "$ver" == "trixie" || "$ver" == "astra12" ]]; then
    apt-get install -y snapd

    systemctl unmask snapd.seeded snapd
    systemctl enable snapd.seeded snapd
    systemctl start snapd.seeded snapd

    snap install ubuntu-make --classic --edge
    snap refresh ubuntu-make --classic --edge

    umake_path=/snap/bin/umake

    # need to use SDDM on Debian because of https://github.com/ubuntu/ubuntu-make/issues/678
    if [[ "$ver" == "buster" || "$ver" == "bullseye" || "$ver" == "bookworm" || "$ver" == "trixie" ]]; then
      apt-get install -y --reinstall sddm --no-install-recommends --no-install-suggests
      unset DEBIAN_FRONTEND
      dpkg-reconfigure sddm
      export DEBIAN_FRONTEND=noninteractive
    fi
  fi
fi

# fixes for Jammy
if [[ "$ver" == "jammy" || "$ver" == "noble" ]]; then
cat <<\EOF > /etc/X11/Xsession.d/20x11-add-hasoption
# temporary fix for LP# 1922414, 1955135 and 1955136 bugs
# read OPTIONFILE
OPTIONS=$(cat "$OPTIONFILE") || true

has_option() {
  if [ "${OPTIONS#*
$1}" != "$OPTIONS" ]; then
    return 0
  else
    return 1
  fi
}
EOF
fi

# fixes for Bullseye, Bookworm, Trixie, Jammy and Noble
if [[ "$ver" == "bullseye" || "$ver" == "bookworm" || "$ver" == "trixie" || "$ver" == "jammy" || "$ver" == "noble" || "$ver" == "astra12" ]]; then
  # Readline fix for LP#1926256 bug
  if [ $is_docker == 0 ]; then
    echo "set enable-bracketed-paste Off" | sudo -u "$SUDO_USER" tee -a ~/.inputrc
  else
    echo "set enable-bracketed-paste Off" | tee -a /etc/inputrc
  fi

  # VTE fix for LP#1922276 bug
  if [[ "$ver" != "noble" && "$ver" != "trixie" ]]; then
    apt-key adv --keyserver keyserver.ubuntu.com --recv E756285F30DB2B2BB35012E219BFCAF5168D33A9
    if [ "$ver" == "astra12" ]; then
      echo "deb http://ppa.launchpad.net/nrbrtx/vte/ubuntu jammy main" | tee /etc/apt/sources.list.d/lp-nrbrtx-vte-jammy.list
      cat <<EOF > /etc/apt/preferences.d/pin-lp-nrbrtx-vte
Package: *vte*
Pin: release o=LP-PPA-nrbrtx-vte
Pin-Priority: 1337
EOF
    else
      add-apt-repository -y "deb http://ppa.launchpad.net/nrbrtx/vte/ubuntu jammy main"
    fi
    apt-get update
    apt-get dist-upgrade -y
  fi
fi

# fixes for Bookworm, Jammy and Noble (see LP#1947420)
if [[ "$ver" == "bookworm" || "$ver" == "jammy" || "$ver" == "noble" || "$ver" == "astra12" || "$ver" == "trixie" ]]; then
  if [ "$ver" != "trixie" ]; then
    apt-key adv --keyserver keyserver.ubuntu.com --recv E756285F30DB2B2BB35012E219BFCAF5168D33A9
  fi

  if [ "$ver" == "astra12" ]; then
    echo "deb http://ppa.launchpad.net/nrbrtx/wnck/ubuntu jammy main" | tee /etc/apt/sources.list.d/lp-nrbrtx-wnck-jammy.list
      cat <<EOF > /etc/apt/preferences.d/pin-lp-nrbrtx-wnck
Package: *wnck*
Pin: release o=LP-PPA-nrbrtx-wnck
Pin-Priority: 1337
EOF
  elif [ "$ver" == "trixie" ]; then
    cat <<EOF | tee /etc/apt/sources.list.d/lp-nrbrtx-wnck-jammy.sources
Types: deb deb-src
URIs: http://ppa.launchpad.net/nrbrtx/wnck/ubuntu/
Suites: jammy
Components: main
Signed-By: 
 -----BEGIN PGP PUBLIC KEY BLOCK-----
 .
 mQINBFUPLWABEADRWUm0WCjOSgpUEl2Tm2vFbn99vFlrnA+08JqAEQBroXd54fF3
 t6vyHzV7CsxrGmriNhYPk3O9L+PZZ64HaXKB3THic//GOhip1j4b+LMx3gEIMVqp
 +g9vAhaKkOXa57BIuJT0zqggw7d9dMiJlvmFyTCgMvR4Hklo3M/72itRxiPfh7dM
 VauI98swPkEfK858vXOkniRdFAtl7OaoR0x+qWBvLqLFSkIIRALoxuw2BpAyEAtZ
 aZaXfXYqne9EFl8Q1dvV+w9TzCgPfQDVfwheiZl3Z4fcWuTt9tKl5/D0DJLnenY9
 QRATDTczHT7olhAucfabRbVqa1Hdg8cK+8puIo35+dPoxdbVnQW63wtwIfu07Ya4
 kKWp4YSTNp6iEHIYX5tGECI7mQNaU292fYR8Y4Of+uR8RWPjO/Vv4UyGPoUnpApv
 J3mpN4miQHOSvA/76F9ZkUr6SyOANATsrmSj5EyWbExtAKf064Crubub2wFK3Fp3
 HUOdwc31aDTr8tkdMV2U8okNcLO+tAwUZs7uR/5gzq41uearQ+GABtYQE3+K7Nnf
 XU9cMV5nKDI/lzJv9o+ftwztbmUUh3LJ373qjtX3013XUkUP2HCRn+yYkc/nkni3
 jgUhnwhRMXKX9JFa1VnnfoTZxztV2uWF7LMOg4Z68nOWhkw1+2j8LZomLwARAQAB
 tBlMYXVuY2hwYWQgUFBBIGZvciBOb3JiZXJ0iQI4BBMBAgAiBQJVDy1gAhsDBgsJ
 CAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRAZv8r1Fo0zqWbqD/9Qkh4fW+Whu5iI
 Pko+RioENNMoNK012uA9yWJBFgTD8uMC0/mD8Q7zwh2aPJ8M5wnmq9OqIVj4/1PW
 ufgf0LrkR1yL34cX+9urm3+npiOnmjlizdFz34gi4ni9DS0DjTLIUPXEkJosxTYw
 4T2BQlqop3xIQPo9nYh026pQ1UQg1blL4k81y88Le4LIRhb0E3mvPGW1mFta779H
 slQ4P8CkylohsQ3VsBdOgOp0UcOAVldPy12FGnB9D9A1W2QK/zmqCjQhqvNHP2Gl
 60fsPJBd1q4FXqvMsJ7MbKri6N3PoTZoEQwPoE9UX8uTDpJyD2csG47+2cTjQtCC
 SlDDPET5U01LXfK1nGcT1qDiiYdn8Vo8GMT8Uxul+B871Tq+0TBNVn6uB12b0z+F
 HWWhwyqZ8l09Z30CsX2N4qlw6uMYtbKVXpXoZKcJGZZ5jgy6Cv9yY6XTUCHZvlMi
 e5q0gmfK9rGf5o/jodR3Nx4agMLtOsVh5nX9F3kfcjA+yScxG7XTSCzTLZZ7yh8c
 GZnkgRjSCl/EERtdzA/zvTJNv3qocT5qefa9OHFLzXhapJdT7rqBBvodpz7aEuyt
 PzF7SnKUFqC96fJva1I0FRspkTU/FpFjAe4u0AhNmrq+KM5ix4t2OvoW7/lmfy+t
 7V41wW5M4tl+fD20NiPBA+/Y+pP5sQ==
 =nhoj
 -----END PGP PUBLIC KEY BLOCK-----
EOF

    cat <<EOF > /etc/apt/preferences.d/pin-lp-nrbrtx-wnck
Package: *wnck*
Pin: release o=LP-PPA-nrbrtx-wnck
Pin-Priority: 1337
EOF
  else
    add-apt-repository -y "deb http://ppa.launchpad.net/nrbrtx/wnck/ubuntu jammy main"
  fi
  apt-get update
  apt-get dist-upgrade -y
fi

# Remove possibly installed WSL utilites
apt-get purge -y wslu || true

# Cleaning up
apt-get autoremove -y

## Arduino
if [[ "$ver" != "stretch" && "$ver" != "astra9" && "$ver" != "trusty" ]]; then
  if [ $is_docker == 0 ] ; then
    usermod -a -G dialout "$SUDO_USER"
    sudo -u "$SUDO_USER" -- "$umake_path" electronics arduino-legacy || sudo apt-get install -y arduino || echo "Error: unable to install Arduino Legacy 1.x IDE using neither umake nor APT, you have to choose other method of installation!"
  fi
fi

echo "Ubuntu MATE (and Debian) post-install script finished! Reboot to apply all new settings and enjoy newly installed software."

exit 0
