#!/bin/bash
# Ubuntu MATE (and Debian) post-install script

if lsb_release -cs | grep -qE "bionic|focal|jammy|stretch|buster|bullseye|bookworm|orel|1.7_x86-64"; then
    if lsb_release -cs | grep -q "bionic"; then
        ver=bionic
    fi
    if lsb_release -cs | grep -q "focal"; then
        ver=focal
    fi
    if lsb_release -cs | grep -q "jammy"; then
        ver=jammy
    fi
    if lsb_release -cs | grep -q "stretch"; then
        ver=stretch
    fi
    if lsb_release -cs | grep -q "buster"; then
        ver=buster
    fi
    if lsb_release -cs | grep -q "bullseye"; then
        ver=bullseye
    fi
    if lsb_release -cs | grep -q "bookworm"; then
        ver=bookworm
    fi
    if lsb_release -cs | grep -q "orel"; then
        ver=astra9
    fi
    if lsb_release -cs | grep -q "1.7_x86-64"; then
        ver=astra10
    fi
else
    echo "Currently only Debian 9, 10, 11 and 12; AstraLinux 2.12 and 1.7; Ubuntu MATE 18.04 LTS, 20.04 LTS and 22.04 LTS are supported!"
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
sudo -EHu "$SUDO_USER" -- gsettings set org.mate.peripherals-keyboard-xkb.kbd options "['grp\tgrp:alt_shift_toggle', 'grp_led\tgrp_led:scroll']"

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
  if [[ "$ver" == "stretch" || "$ver" == "bionic" || "$ver" == "astra10" ]]; then
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings unmaximize '<Mod4>Down'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings maximize '<Mod4>Up'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-ne '<Alt><Mod4>Right' || true
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-sw '<Shift><Alt><Mod4>Left' || true
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-side-e '<Mod4>Right'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-se '<Shift><Alt><Mod4>Right' || true
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings move-to-center '<Alt><Mod4>c'
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-nw '<Alt><Mod4>Left' || true
    sudo -EHu "$SUDO_USER" -- gsettings set org.mate.Marco.window-keybindings tile-to-side-w '<Mod4>Left'
  fi # keyboard shortcuts
fi # (is_docker && MATE)?

# Setup the system
rm -v /var/lib/dpkg/lock* /var/cache/apt/archives/lock || true
systemctl stop unattended-upgrades.service || true
apt-get purge unattended-upgrades -y || true

if [ "$ver" == "bionic" ]; then # removal is safe only for Ubuntu 18.04 LTS
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
if [ "$ver" != "astra10" ]; then
    apt-get install -y software-properties-common wget
else
    apt-get install -y wget
fi
if [ "$ver" != "astra9" ]; then # fix for https://bugs.debian.org/1029766 and https://bugs.debian.org/1033502
    apt-get install -y python3-launchpadlib
fi

# Restricted extras
apt-get install -y ubuntu-restricted-addons ubuntu-restricted-extras || true

# Git
apt-get install -y git

# RabbitVCS integration to Caja
if [[ "$ver" == "stretch" || "$ver" == "bionic" || "$ver" == "buster" || "$ver" == "astra10" ]]; then
    if [ "$ver" == "astra10" ]; then
        # download packages from 18.04 LTS
        cd /tmp
        wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pysvn/python-svn_1.9.5-1_amd64.deb
        wget -c http://archive.ubuntu.com/ubuntu/pool/universe/r/rabbitvcs/rabbitvcs-cli_0.16-1.1_all.deb
        wget -c http://archive.ubuntu.com/ubuntu/pool/universe/r/rabbitvcs/rabbitvcs-core_0.16-1.1_all.deb
        wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/python-caja/python-caja-common_1.20.0-1_all.deb
        wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/python-caja/python-caja_1.20.0-1_amd64.deb
        apt-get install -y ./python-caja-common_1.20.0-1_all.deb ./python-caja_1.20.0-1_amd64.deb ./rabbitvcs-cli_0.16-1.1_all.deb ./python-svn_1.9.5-1_amd64.deb ./rabbitvcs-core_0.16-1.1_all.deb python-tk mercurial subversion --allow-downgrades
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

if [[ "$ver" == "focal" || "$ver" == "jammy" || "$ver" == "bullseye" || "$ver" == "bookworm" ]]; then
  apt-get install -y rabbitvcs-cli python3-caja python3-tk git mercurial subversion

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
if [[ "$ver" == "stretch" || "$ver" == "bionic" || "$ver" == "buster" ]]; then
    apt-get install -y fslint
elif [ "$ver" == "astra9" ]; then
    cd /tmp
    wget -c http://deb.debian.org/debian/pool/main/f/fslint/fslint_2.46-1_all.deb
    apt-get install -y ./fslint_2.46-1_all.deb
fi

if [[ "$ver" == "astra9" || "$ver" == "astra10" ]]; then
    apt-get install -y htop mc ncdu aptitude synaptic apt-file
    cd /tmp
    wget -c http://deb.debian.org/debian/pool/main/a/apt-xapian-index/apt-xapian-index_0.49_all.deb
    apt-get install -y ./apt-xapian-index_0.49_all.deb
else
    apt-get install -y htop mc ncdu aptitude synaptic apt-xapian-index apt-file command-not-found
fi

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

if [[ "$ver" == "bookworm" || "$ver" == "jammy" ]]; then
  apt-get install -y meld
else
  cd /tmp
  if [ "$dpkg_arch" == "amd64" ]; then
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pygtksourceview/python-gtksourceview2_2.10.1-3_amd64.deb http://archive.ubuntu.com/ubuntu/pool/universe/g/gtksourceview2/libgtksourceview2.0-0_2.10.5-3_amd64.deb http://archive.ubuntu.com/ubuntu/pool/universe/g/gtksourceview2/libgtksourceview2.0-common_2.10.5-3_all.deb
    apt-get install -y --reinstall --allow-downgrades python-gtksourceview2 || apt-get install -y --reinstall --allow-downgrades ./python-gtksourceview2_2.10.1-3_amd64.deb ./libgtksourceview2.0-0_2.10.5-3_amd64.deb ./libgtksourceview2.0-common_2.10.5-3_all.deb
  fi # TODO add manual download links for armhf, arm64

  wget -c http://old-releases.ubuntu.com/ubuntu/pool/universe/m/meld/meld_1.5.3-1ubuntu1_all.deb -O /var/cache/apt/archives/meld_1.5.3-1ubuntu1_all.deb 
  apt-get install -y --allow-downgrades /var/cache/apt/archives/meld_1.5.3-1ubuntu1_all.deb

cat <<EOF > /etc/apt/preferences.d/pin-meld
Package: meld
Pin: version 1.5.3-1ubuntu1
Pin-Priority: 1337
EOF

fi

# VirtualBox
if [ "$dpkg_arch" == "amd64" ]; then
    if [[ "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "astra9" && "$ver" != "astra10" ]]; then
        echo "virtualbox-ext-pack virtualbox-ext-pack/license select true" | debconf-set-selections
        apt-get install -y virtualbox
      if [ $is_docker == 0 ]; then
        usermod -a -G vboxusers "$SUDO_USER"
      fi
    fi
    if [[ "$ver" == "stretch" || "$ver" == "astra9" || "$ver" == "buster" || "$ver" == "astra10" || "$ver" == "bullseye" ]]; then
        apt-get install -y ca-certificates gpg apt-transport-https
        wget https://www.virtualbox.org/download/oracle_vbox_2016.asc -O - | apt-key add

        deb_ver="$ver"
        if [[ "$ver" == "stretch" || "$ver" == "astra9" ]]; then
          deb_ver=stretch
        elif [ "$ver" == "astra10" ]; then
          deb_ver=buster
          cd /tmp
          wget -c http://deb.debian.org/debian/pool/main/libv/libvpx/libvpx5_1.7.0-3+deb10u1_amd64.deb
          apt-get install -y ./libvpx5_1.7.0-3+deb10u1_amd64.deb
        fi

        echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $deb_ver contrib" | tee /etc/apt/sources.list.d/virtualbox.list
        apt-get update
        apt-get install -y virtualbox-6.1
      if [ $is_docker == 0 ]; then
        usermod -a -G vboxusers "$SUDO_USER"
      fi
    else
      apt-get install -y virtualbox || true
      apt-get install -y virtualbox-ext-pack || true
      apt-get install -y virtualbox-guest-additions-iso || true
    fi
fi #/amd64

# LibreOffice
if [[ "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "astra9" && "$ver" != "astra10" ]]; then
    add-apt-repository -y ppa:libreoffice/ppa
fi
apt-get update
apt-get install libreoffice -y
apt-get dist-upgrade -y
apt-get install -f -y
apt-get dist-upgrade -y

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
  echo "deb http://cloud.r-project.org/bin/linux/debian buster-cran35/" | tee /etc/apt/sources.list.d/r-cran.list

  if [ "$ver" == "astra10" ]; then
cat <<EOF > /etc/apt/preferences.d/pin-r-cran
Package: *
Pin: origin cloud.r-project.org
Pin-Priority: 1337
EOF
  fi # /astra10

  apt-get update
fi

if [ "$ver" == "bionic" ]; then
  apt-key adv --keyserver keyserver.ubuntu.com --recv-key 'E298A3A825C0D65DFD57CBB651716619E084DAB9'
  echo "deb http://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/" | tee /etc/apt/sources.list.d/r-cran.list
  apt-get update
fi

apt-get install -y r-base-dev

if [ "$dpkg_arch" == "amd64" ]; then
  cd /tmp

  if [[ "$ver" == "jammy" || "$ver" == "bookworm" ]]; then
    wget -c https://download1.rstudio.org/desktop/jammy/amd64/rstudio-2022.02.3-492-amd64.deb -O rstudio-latest-amd64.deb
  elif [[ "$ver" == "stretch" || "$ver" == "astra9" ]]; then
    wget -c https://download1.rstudio.org/desktop/debian9/x86_64/rstudio-2021.09.0-351-amd64.deb -O rstudio-latest-amd64.deb
  else
	wget -c https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2021.09.0-351-amd64.deb -O rstudio-latest-amd64.deb \
	|| wget -c https://rstudio.org/download/latest/stable/desktop/bionic/rstudio-latest-amd64.deb -O rstudio-latest-amd64.deb \
	|| wget -c https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.4.1717-amd64.deb -O rstudio-latest-amd64.deb
  fi
  
  apt-get install -y --allow-downgrades ./rstudio-latest-amd64.deb
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
    apt install -y --allow-downgrades /tmp/pandoc*.deb;
fi

# bookdown install for local user
apt-get install -y build-essential libssl-dev libcurl4-openssl-dev libxml2-dev libcairo2-dev libfribidi-dev libtiff-dev libharfbuzz-dev

if [[ "$ver" == "focal" || "$ver" == "jammy" || "$ver" == "buster" || "$ver" == "bullseye" || "$ver" == "bookworm" || "$ver" == "astra10" ]]; then
    apt-get install -y libgit2-dev
fi

if [ "$ver" == "astra10" ]; then
     apt-key adv --keyserver keyserver.ubuntu.com --recv E756285F30DB2B2BB35012E219BFCAF5168D33A9
     echo "deb http://ppa.launchpad.net/nrbrtx/evince10/ubuntu bionic main"| tee /etc/apt/sources.list.d/evince.list
     apt-get update
fi

apt-get install -y evince

if [[ "$ver" == "focal" || "$ver" == "stretch" || "$ver" == "astra9" || "$ver" == "buster" || "$ver" == "astra10" ]]; then
    r_ver="3.6"
fi
if [ "$ver" == "bullseye" ]; then
    r_ver="4.0"
fi
if [ "$ver" == "jammy" ]; then
    r_ver="4.1"
fi
if [ "$ver" == "bookworm" ]; then
    r_ver="4.2"
fi
if [ "$ver" == "bionic" ]; then
    r_ver="4.3"
fi

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

if [[ "$ver" == "jammy" || "$ver" == "bookworm" ]]; then
  if [ $is_docker == 0 ]; then
    sudo -u "$SUDO_USER" -- R -e "install.packages(c('bookdown','knitr','xaringan'), repos='http://cran.r-project.org/')"
  else
    R -e "install.packages(c('bookdown','knitr','xaringan'), repos='http://cran.r-project.org/')"
  fi
else
  if [ $is_docker == 0 ]; then
    ## FIXME on bookdown side, waiting for 0.23
    sudo -u "$SUDO_USER" -- R -e "require(devtools); install_version('bookdown', version = '0.21', repos = 'http://cran.r-project.org')"
    ## FIXME for is_abs_path on knitr 1.34
    sudo -u "$SUDO_USER" -- R -e "require(devtools); install_version('knitr', version = '1.33', repos = 'http://cran.r-project.org')"
    ## Xaringan
    sudo -u "$SUDO_USER" -- R -e "install.packages('xaringan', repos='http://cran.r-project.org/')"
  else
    ## FIXME on bookdown side, waiting for 0.23
    R -e "require(devtools); install_version('bookdown', version = '0.21', repos = 'http://cran.r-project.org')"
    ## FIXME for is_abs_path on knitr 1.34
    R -e "require(devtools); install_version('knitr', version = '1.33', repos = 'http://cran.r-project.org')"
    ## Xaringan
    R -e "install.packages('xaringan', repos='http://cran.r-project.org/')"
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

if [[ "$ver" == "astra9" || "$ver" == "astra10" ]]; then
    if [ "$ver" == "astra9" ]; then
      apt-get install -y texlive-luatex texlive-generic-recommended
    fi

    apt-get install -y texlive-extra-utils texlive-lang-cyrillic texlive-xetex texlive-fonts-extra texlive-science-doc texlive-science texlive-latex-extra lmodern
    cd /tmp
    wget -c http://deb.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.7_all.deb
    apt-get install -y --allow-downgrades ./ttf-mscorefonts-installer_3.7_all.deb
    
    wget -c http://deb.debian.org/debian/pool/main/f/fonts-cmu/fonts-cmu_0.7.0-3_all.deb
    apt-get install -y ./fonts-cmu_0.7.0-3_all.deb
else
    apt-get install -y texlive-extra-utils biber texlive-lang-cyrillic fonts-cmu texlive-xetex texlive-fonts-extra texlive-science-doc texlive-science font-manager ttf-mscorefonts-installer texlive-latex-extra texlive-luatex lmodern
    apt-get install --reinstall -y ttf-mscorefonts-installer
fi

# ReText
if [[ "$ver" == "astra9" || "$ver" == "astra10" ]]; then
    # download packages from 20.04 LTS to fix rendering
    cd /tmp
    
    if [ "$ver" == "astra9" ]; then
      wget -c http://archive.ubuntu.com/ubuntu/pool/main/p/python-markdown/python3-markdown_3.1.1-3_all.deb
      wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/python-markdown-math/python3-mdx-math_0.6-1_all.deb
      apt-get install --reinstall -y ./python3-markdown_3.1.1-3_all.deb ./python3-mdx-math_0.6-1_all.deb
    fi
    
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/p/pymarkups/python3-markups_3.0.0-1_all.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/r/retext/retext_7.1.0-1_all.deb
    apt-get install -y ./python3-markups_3.0.0-1_all.deb ./retext_7.1.0-1_all.deb
else
    apt-get install -y retext
fi

if [[ "$ver" == "stretch" || "$ver" == "bionic" || "$ver" == "buster" || "$ver" == "focal" || "$ver" == "astra9" ]]; then
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

apt-get install -y --reinstall python3-markdown
patch -u /usr/lib/python3/dist-packages/markdown/extensions/fenced_code.py -s --force < /tmp/fenced_code.patch
fi # versions

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
if [[ "$ver" == "stretch" || "$ver" == "bionic" ]]; then
  cd /tmp
  wget -c https://www.playonlinux.com/script_files/PlayOnLinux/4.3.4/PlayOnLinux_4.3.4.deb -O PlayOnLinux_4.3.4.deb
  apt-get install -y --allow-downgrades ./PlayOnLinux_4.3.4.deb
else
  apt-get install -y playonlinux
fi

# Y PPA Manager
apt-get install -y ppa-purge || true

if [[ "$ver" != "jammy" && "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "astra9" && "$ver" != "astra10" ]]; then
    add-apt-repository -y ppa:webupd8team/y-ppa-manager
    apt-get update
    apt-get install -y y-ppa-manager
fi

# Telegram
if [[ "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "astra9" && "$ver" != "astra10" ]]; then
    if [ "$dpkg_arch" == "amd64" ]; then
        add-apt-repository -y ppa:atareao/telegram
        apt-get update
        apt-get install -y telegram
    fi
fi

# NotepadQQ
if [ "$ver" == "bionic" ]; then
    add-apt-repository -y ppa:notepadqq-team/notepadqq
    apt-get update
    apt-get install -y notepadqq
fi

# Install locale packages
apt-get install -y locales
apt-get install -y $(check-language-support -l en) $(check-language-support -l ru) || true
apt-get install -y --reinstall --install-recommends task-russian task-russian-desktop || true

# Flatpak
if [[ "$ver" == "bionic" || "$ver" == "focal" ]]; then
    add-apt-repository -y ppa:alexlarsson/flatpak
fi

apt-get update
apt-get install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Ubuntu Make
if [[ "$ver" != "stretch" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" && "$ver" != "astra9" && "$ver" != "astra10" ]]; then
    add-apt-repository -y ppa:lyzardking/ubuntu-make
    apt-get update
    apt-get install -y ubuntu-make
fi
if [ "$ver" == "astra10" ]; then
    cd /tmp
    wget -c http://security.debian.org/debian-security/pool/updates/main/s/snapd/snapd_2.37.4-1+deb10u2_amd64.deb
    wget -c http://deb.debian.org/debian/pool/main/s/snapd-glib/libsnapd-glib1_1.45-1.1_amd64.deb
    wget -c http://deb.debian.org/debian/pool/main/s/snapd-glib/gir1.2-snapd-1_1.45-1.1_amd64.deb

    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/g/gcc-avr/gcc-avr_5.4.0+Atmel3.6.0-1build1_amd64.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/b/binutils-avr/binutils-avr_2.26.20160125+Atmel3.6.0-1_amd64.deb
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/a/avr-libc/avr-libc_2.0.0+Atmel3.6.0-1_all.deb
    apt-get install -y ./snapd_2.37.4-1+deb10u2_amd64.deb ./libsnapd-glib1_1.45-1.1_amd64.deb ./gir1.2-snapd-1_1.45-1.1_amd64.deb
    apt-get install -y  --allow-downgrades ./gcc-avr_5.4.0+Atmel3.6.0-1build1_amd64.deb ./binutils-avr_2.26.20160125+Atmel3.6.0-1_amd64.deb ./avr-libc_2.0.0+Atmel3.6.0-1_all.deb
fi

if [ $is_docker == 0 ] ; then
    umake_path=umake
    if [[ "$ver" != "astra9" && "$ver" != "stretch" && "$ver" != "bionic" && "$ver" != "focal" && "$ver" != "jammy" || "$ver" == "astra10" || "$ver" == "buster" || "$ver" == "bullseye" || "$ver" == "bookworm" ]]; then
        apt-get install -y snapd

        systemctl unmask snapd.seeded snapd
        systemctl enable snapd.seeded snapd
        systemctl start snapd.seeded snapd

        snap install ubuntu-make --classic --edge
        snap refresh ubuntu-make --classic --edge

        umake_path=/snap/bin/umake

        # need to use SDDM on Debian because of https://github.com/ubuntu/ubuntu-make/issues/678
        if [[ "$ver" == "buster" || "$ver" == "bullseye" || "$ver" == "bookworm" ]]; then
          apt-get install -y --reinstall sddm --no-install-recommends --no-install-suggests
          unset DEBIAN_FRONTEND
          dpkg-reconfigure sddm
          export DEBIAN_FRONTEND=noninteractive
        fi
    fi
fi

# fixes for Jammy
if [ "$ver" == "jammy" ]; then
    # Readline fix for LP#1926256 bug
    echo "set enable-bracketed-paste Off" | sudo -u "$SUDO_USER" tee ~/.inputrc

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

    # VTE fix for LP#1922276 bug
    add-apt-repository -y ppa:nrbrtx/vte
    apt-get dist-upgrade -y
fi

# fixes for Bullseye, Bookworm and Jammy
if [[ "$ver" == "bullseye" || "$ver" == "bookworm" || "$ver" == "jammy" ]]; then
    # Readline fix for LP#1926256 bug
    echo "set enable-bracketed-paste Off" | sudo -u "$SUDO_USER" tee ~/.inputrc

	# VTE fix for LP#1922276 bug
	apt-key adv --keyserver keyserver.ubuntu.com --recv E756285F30DB2B2BB35012E219BFCAF5168D33A9
    add-apt-repository -y "deb http://ppa.launchpad.net/nrbrtx/vte/ubuntu jammy main"
	apt-get update
    apt-get dist-upgrade -y
fi

# fixes for Jammy and Bookworm (see LP#1947420)
if [[ "$ver" == "bookworm" || "$ver" == "jammy" ]]; then
  apt-key adv --keyserver keyserver.ubuntu.com --recv E756285F30DB2B2BB35012E219BFCAF5168D33A9
  add-apt-repository -y "deb http://ppa.launchpad.net/nrbrtx/wnck/ubuntu jammy main"
  apt-get update
  apt-get dist-upgrade -y
fi

# Remove possibly installed WSL utilites
apt-get purge -y wslu || true

# Cleaning up
apt-get autoremove -y

## Arduino
if [[ "$ver" != "stretch" && "$ver" != "astra9" ]]; then
    if [ $is_docker == 0 ] ; then
        usermod -a -G dialout "$SUDO_USER"

        sudo -u "$SUDO_USER" -- "$umake_path" electronics arduino-legacy
    fi
fi

echo "Ubuntu MATE (and Debian) post-install script finished! Reboot to apply all new settings and enjoy newly installed software."

exit 0
