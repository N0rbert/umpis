#!/bin/bash
# Ubuntu MATE post-install script

if lsb_release -cs | grep -qE "bionic|focal|hirsute|impish|jammy|kinetic|buster|bullseye|bookworm"; then
    if lsb_release -cs | grep -q "bionic"; then
        ver=bionic
    fi
    if lsb_release -cs | grep -q "focal"; then
        ver=focal
    fi
    if lsb_release -cs | grep -q "hirsute"; then
        ver=hirsute
    fi
    if lsb_release -cs | grep -q "impish"; then
        ver=impish
    fi
    if lsb_release -cs | grep -q "jammy"; then
        ver=jammy
    fi
    if lsb_release -cs | grep -q "kinetic"; then
        ver=kinetic
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
else
    echo "Currently only Debian 10, 11 and 12; Ubuntu MATE 18.04 LTS, 20.04 LTS, 21.04, 21.10, 22.04 LTS and upcoming 22.10 are supported!"
    exit 1
fi

is_docker=0
if [ -f /.dockerenv ]; then
    echo "Note: we are running inside Docker container, so some adjustings will be applied!"
    is_docker=1
fi

dpkg_arch=$(dpkg --print-architecture)
if [ "$dpkg_arch" == "amd64" ]; then
    use_ports=0
elif [[ "$dpkg_arch" == "armhf" || "$dpkg_arch" == "arm64" ]]; then
    use_ports=1
else
    echo "Currently only amd64 (x86_64), armhf and arm64 CPU architectures are supported!"
    exit 2
fi

if [ "$UID" -ne "0" ]
then
    echo "Please run this script as root user with 'sudo -E ./umpis.sh'"
    exit 3
fi

echo "Welcome to the Ubuntu MATE post-install script!"
set -e
set -x

# Initialize
export DEBIAN_FRONTEND=noninteractive

# Configure MATE desktop
if [ $is_docker == 0 ]; then
## keyboard layouts, Alt+Shift for layout toggle
sudo -EHu $SUDO_USER -- gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['us', 'ru']"
sudo -EHu $SUDO_USER -- gsettings set org.mate.peripherals-keyboard-xkb.kbd model "''"
sudo -EHu $SUDO_USER -- gsettings set org.mate.peripherals-keyboard-xkb.kbd options "['grp\tgrp:alt_shift_toggle', 'grp_led\tgrp_led:scroll']"

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
sudo -EHu $SUDO_USER -- dconf load /org/mate/terminal/ < /tmp/dconf-mate-terminal

## window management keyboard shortcuts for Ubuntu MATE 18.04 LTS
if [ "$ver" == "bionic" ]; then
    sudo -EHu $SUDO_USER -- gsettings set org.mate.Marco.window-keybindings unmaximize '<Mod4>Down'
    sudo -EHu $SUDO_USER -- gsettings set org.mate.Marco.window-keybindings maximize '<Mod4>Up'
    sudo -EHu $SUDO_USER -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-ne '<Alt><Mod4>Right'
    sudo -EHu $SUDO_USER -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-sw '<Shift><Alt><Mod4>Left'
    sudo -EHu $SUDO_USER -- gsettings set org.mate.Marco.window-keybindings tile-to-side-e '<Mod4>Right'
    sudo -EHu $SUDO_USER -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-se '<Shift><Alt><Mod4>Right'
    sudo -EHu $SUDO_USER -- gsettings set org.mate.Marco.window-keybindings move-to-center '<Alt><Mod4>c'
    sudo -EHu $SUDO_USER -- gsettings set org.mate.Marco.window-keybindings tile-to-corner-nw '<Alt><Mod4>Left'
    sudo -EHu $SUDO_USER -- gsettings set org.mate.Marco.window-keybindings tile-to-side-w '<Mod4>Left'
fi
fi # /is_docker

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
apt-get update
apt-get dist-upgrade -o DPkg::Options::=--force-confdef --force-yes -y
apt-get install -f -y
dpkg --configure -a

# add-apt-repository, wget
apt-get install -y software-properties-common wget

# Restricted extras
apt-get install -y ubuntu-restricted-addons ubuntu-restricted-extras || true

# Git
apt-get install -y git

# RabbitVCS integration to Caja
if [[ "$ver" == "bionic" || "$ver" == "buster" ]]; then
  apt-get install -y rabbitvcs-cli python-caja python-tk mercurial subversion

  if [ $is_docker == 0 ]; then
    sudo -u $SUDO_USER -- mkdir -p ~/.local/share/caja-python/extensions
    cd ~/.local/share/caja-python/extensions
    sudo -u $SUDO_USER -- wget -c https://raw.githubusercontent.com/rabbitvcs/rabbitvcs/v0.16/clients/caja/RabbitVCS.py
  else
    mkdir -p /usr/local/share/caja-python/extensions
    wget -c https://raw.githubusercontent.com/rabbitvcs/rabbitvcs/v0.16/clients/caja/RabbitVCS.py -O /usr/local/share/caja-python/extensions/RabbitVCS.py
  fi
fi

if [[ "$ver" == "focal" || "$ver" == "hirsute" || "$ver" == "impish" || "$ver" == "jammy" || "$ver" == "kinetic" || "$ver" == "bullseye" || "$ver" == "bookworm" ]]; then
  apt-get install -y rabbitvcs-cli python3-caja python3-tk git mercurial subversion

  if [ $is_docker == 0 ]; then
    sudo -u $SUDO_USER -- mkdir -p ~/.local/share/caja-python/extensions
    cd ~/.local/share/caja-python/extensions
    sudo -u $SUDO_USER -- wget -c https://raw.githubusercontent.com/rabbitvcs/rabbitvcs/v0.18/clients/caja/RabbitVCS.py
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
if [[ "$ver" == "bionic" || "$ver" == "buster" ]]; then
    apt-get install -y fslint
fi

apt-get install -y htop mc ncdu aptitude synaptic apt-xapian-index apt-file
update-apt-xapian-index
apt-file update 

# Kate text editor
apt-get install -y kate

# Meld 1.5.3 as in https://askubuntu.com/a/965151/66509
cd /tmp

if [[ "$ver" == "hirsute" || "$ver" == "impish" || "$ver" == "bullseye" ]]; then
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

if [[ "$ver" == "focal" || "$ver" == "hirsute" || "$ver" == "impish" || "$ver" == "bullseye" ]]; then
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

if [[ "$ver" == "bookworm" || "$ver" == "jammy" || "$ver" == "kinetic" ]]; then
  apt-get install -y meld
else
  wget -c http://old-releases.ubuntu.com/ubuntu/pool/universe/m/meld/meld_1.5.3-1ubuntu1_all.deb -O /var/cache/apt/archives/meld_1.5.3-1ubuntu1_all.deb 
apt-get install -y --allow-downgrades /var/cache/apt/archives/meld_1.5.3-1ubuntu1_all.deb

cat <<EOF > /etc/apt/preferences.d/pin-meld
Package: meld
Pin: version 1.5.3-1ubuntu1
Pin-Priority: 1337
EOF

fi

# VirtualBox
if [[ "$dpkg_arch" == "amd64" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" ]]; then
    echo "virtualbox-ext-pack virtualbox-ext-pack/license select true" | debconf-set-selections
    apt-get install -y virtualbox virtualbox-ext-pack virtualbox-guest-additions-iso
  if [ $is_docker == 0 ]; then
    usermod -a -G vboxusers $SUDO_USER
  fi
fi

# LibreOffice
if [[ "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" ]]; then
    add-apt-repository -y ppa:libreoffice/ppa
fi
apt-get update
apt-get install libreoffice -y
apt-get dist-upgrade -y
apt-get install -f -y
apt-get dist-upgrade -y

# RStudio
apt-get install -y r-base-dev

if [ "$dpkg_arch" == "amd64" ]; then
  cd /tmp

  if [[ "$ver" == "jammy" || "$ver" == "kinetic" ]]; then
    wget -c https://download1.rstudio.org/desktop/jammy/amd64/rstudio-2022.02.3-492-amd64.deb -O rstudio-latest-amd64.deb
  else
	wget -c https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2021.09.0-351-amd64.deb -O rstudio-latest-amd64.deb \
	|| wget -c https://rstudio.org/download/latest/stable/desktop/bionic/rstudio-latest-amd64.deb -O rstudio-latest-amd64.deb \
	|| wget -c https://download1.rstudio.org/desktop/bionic/amd64/rstudio-1.4.1717-amd64.deb -O rstudio-latest-amd64.deb
  fi
	apt-get install -y --allow-downgrades ./rstudio-latest-amd64.deb
fi

if [ $is_docker == 0 ]; then
	sudo -u $SUDO_USER -- mkdir -p ~/.config/rstudio
	cat <<EOF > ~/.config/rstudio/rstudio-prefs.json 
{
    "check_for_updates": false,
    "pdf_previewer": "rstudio",
    "posix_terminal_shell": "bash",
    "submit_crash_reports": false
}
EOF
	chown $SUDO_USER: ~/.config/rstudio/rstudio-prefs.json

	echo 'crash-handling-enabled="0"' | sudo -u $SUDO_USER -- tee ~/.config/rstudio/crash-handler.conf
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
    wget -c $LATEST_PANDOC_DEB_URL;
    apt install -y --allow-downgrades /tmp/pandoc*.deb;
fi

# bookdown install for local user
apt-get install -y build-essential libssl-dev libcurl4-openssl-dev libxml2-dev libcairo2-dev libfribidi-dev libtiff-dev libharfbuzz-dev

if [[ "$ver" == "focal" || "$ver" == "hirsute" || "$ver" == "impish" || "$ver" == "jammy" || "$ver" == "kinetic" || "$ver" == "buster" || "$ver" == "bullseye" || "$ver" == "bookworm" ]]; then
    apt-get install -y libgit2-dev
fi
apt-get install -y evince

if [ "$ver" == "bionic" ]; then
    r_ver="3.4"
fi
if [ "$ver" == "buster" ]; then
    r_ver="3.5"
fi
if [ "$ver" == "focal" ]; then
    r_ver="3.6"
fi
if [[ "$ver" == "hirsute" || "$ver" == "impish" || "$ver" == "bullseye" ]]; then
    r_ver="4.0"
fi
if [ "$ver" == "jammy" ]; then
    r_ver="4.1"
fi
if [[ "$ver" == "bookworm" || "$ver" == "kinetic" ]]; then
    r_ver="4.2"
fi

if [ "$dpkg_arch" == "amd64" ]; then
    if [ $is_docker == 0 ] ; then
        sudo -u $SUDO_USER -- mkdir -p ~/R/x86_64-pc-linux-gnu-library/$r_ver
        sudo -u $SUDO_USER -- R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.rstudio.com/', lib='/home/$SUDO_USER/R/x86_64-pc-linux-gnu-library/$r_ver')"
    else
        R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.rstudio.com/')"
    fi
elif [ "$dpkg_arch" == "arm64" ]; then
    if [ $is_docker == 0 ] ; then
        sudo -u $SUDO_USER -- mkdir -p ~/R/aarch64-unknown-linux-gnu-library/$r_ver
        sudo -u $SUDO_USER -- R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.rstudio.com/', lib='/home/$SUDO_USER/R/aarch64-unknown-linux-gnu-library/$r_ver')"
    else
        R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.rstudio.com/')"
    fi
elif [ "$dpkg_arch" == "armhf" ]; then
    if [ $is_docker == 0 ] ; then
        sudo -u $SUDO_USER -- mkdir -p ~/R/arm-unknown-linux-gnueabihf-library/$r_ver
        sudo -u $SUDO_USER -- R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.rstudio.com/', lib='/home/$SUDO_USER/R/arm-unknown-linux-gnueabihf-library/$r_ver')"
    else
        R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.rstudio.com/')"
    fi
fi

if [[ "$ver" == "jammy" || "$ver" == "kinetic" ]]; then
  if [ $is_docker == 0 ]; then
    sudo -u $SUDO_USER -- R -e "install.packages(c('bookdown','knitr','xaringan'), repos='http://cran.rstudio.com/')"
  else
    R -e "install.packages(c('bookdown','knitr','xaringan'), repos='http://cran.rstudio.com/')"
  fi
else
  if [ $is_docker == 0 ]; then
    ## FIXME on bookdown side, waiting for 0.23
    sudo -u $SUDO_USER -- R -e "require(devtools); install_version('bookdown', version = '0.21', repos = 'http://cran.rstudio.com')"
    ## FIXME for is_abs_path on knitr 1.34
    sudo -u $SUDO_USER -- R -e "require(devtools); install_version('knitr', version = '1.33', repos = 'http://cran.rstudio.com')"
    ## Xaringan
    sudo -u $SUDO_USER -- R -e "install.packages('xaringan', repos='http://cran.rstudio.com/')"
  else
    ## FIXME on bookdown side, waiting for 0.23
    R -e "require(devtools); install_version('bookdown', version = '0.21', repos = 'http://cran.rstudio.com')"
    ## FIXME for is_abs_path on knitr 1.34
    R -e "require(devtools); install_version('knitr', version = '1.33', repos = 'http://cran.rstudio.com')"
    ## Xaringan
    R -e "install.packages('xaringan', repos='http://cran.rstudio.com/')"
  fi
fi

if [ "$dpkg_arch" == "amd64" ]; then
  if [ $is_docker == 0 ]; then
    ## fixes for LibreOffice <-> RStudio interaction
    grep "^alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" ~/.profile || echo "alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" >> ~/.profile
    grep "^alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" ~/.bashrc || echo "alias rstudio=\"env LD_LIBRARY_PATH=/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH rstudio\"" >> ~/.bashrc

    sudo -u $SUDO_USER -- mkdir -p ~/.local/share/applications/
    sudo -u $SUDO_USER -- cp /usr/share/applications/rstudio.desktop ~/.local/share/applications/
    sudo -u $SUDO_USER -- sed -i "s|/usr/lib/rstudio/bin/rstudio|env LD_LIBRARY_PATH=/usr/lib/libreoffice/program /usr/lib/rstudio/bin/rstudio|"  ~/.local/share/applications/rstudio.desktop
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

apt-get install -y texlive-extra-utils biber texlive-lang-cyrillic fonts-cmu texlive-xetex texlive-fonts-extra texlive-science-doc texlive-science font-manager ttf-mscorefonts-installer texlive-latex-extra lmodern
apt-get install --reinstall -y ttf-mscorefonts-installer

# ReText
apt-get install -y retext

if [[ "$ver" == "bionic" || "$ver" == "buster" || "$ver" == "focal" ]]; then
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
fi

if [ $is_docker == 0 ]; then
  mkdir -p ~/.config
  chown -R $SUDO_USER:  ~/.config
  sudo -u $SUDO_USER -- echo mathjax >> ~/.config/markdown-extensions.txt
  chown $SUDO_USER: ~/.config/markdown-extensions.txt
else
  echo mathjax >> /etc/skel/.config/markdown-extensions.txt
fi

# PlayOnLinux
apt-get install -y playonlinux

# Y PPA Manager
apt-get install -y ppa-purge || true

if [[ "$ver" != "kinetic" && "$ver" != "jammy" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" ]]; then
    add-apt-repository -y ppa:webupd8team/y-ppa-manager
    apt-get update
    apt-get install -y y-ppa-manager
fi

# Telegram
if [[ "$ver" != "kinetic" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" ]]; then
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
apt-get install -y $(check-language-support -l en) $(check-language-support -l ru)

# Flatpak
if [[ "$ver" == "bionic" || "$ver" == "focal" ]]; then
    add-apt-repository -y ppa:alexlarsson/flatpak
fi
apt-get update
apt-get install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Ubuntu Make
if [[ "$ver" != "kinetic" && "$ver" != "buster" && "$ver" != "bullseye" && "$ver" != "bookworm" ]]; then
    add-apt-repository -y ppa:lyzardking/ubuntu-make
    apt-get update
    apt-get install -y ubuntu-make
fi

if [ $is_docker == 0 ] ; then
    umake_path=umake
    if [[ "$ver" != "kinetic" && "$ver" == "buster" || "$ver" == "bullseye" || "$ver" == "bookworm" ]]; then
        apt-get install -y snapd
        snap install ubuntu-make --classic
        umake_path=/snap/bin/umake
    fi 
fi

# fixes for Jammy
if [ "$ver" == "jammy" ]; then
    # Readline fix for LP#1926256 bug
    echo "set enable-bracketed-paste Off" | sudo -u $SUDO_USER tee ~/.inputrc

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

# Remove possibly installed WSL utilites
apt-get purge -y wslu || true

# Cleaning up
apt-get autoremove -y

## Arduino
if [ "$ver" != "kinetic" ]; then
    if [ $is_docker == 0 ] ; then
        usermod -a -G dialout $SUDO_USER

        sudo -u $SUDO_USER -- $umake_path electronics arduino
    fi
fi

echo "Ubuntu MATE post-install script finished! Reboot to apply all new settings and enjoy newly installed software."

exit 0