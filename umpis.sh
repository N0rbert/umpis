#!/bin/bash
# Ubuntu MATE post-install script

if lsb_release -cs | grep -qE "bionic|focal"; then
    if lsb_release -cs | grep -q "bionic"; then
        ver=bionic
    else
        echo "Ubuntu MATE 20.04 LTS is not supported yet!"
        ver=focal
        exit 2
    fi
else
    echo "Currently only Ubuntu MATE 18.04 LTS is supported!"
    exit 1
fi

if [ "$UID" -ne "0" ]
then
    echo "Please run this script as root user with 'sudo ./umpis.sh'"
    exit
fi

echo "Welcome to the Ubuntu MATE post-install script!"
set -x

# Initialize
export DEBIAN_FRONTEND=noninteractive

# Setup the system
rm -v /var/lib/dpkg/lock* /var/cache/apt/archives/lock
systemctl stop unattended-upgrades.service
apt-get purge unattended-upgrades -y
echo 'APT::Periodic::Enable "0";' > /etc/apt/apt.conf.d/99periodic-disable

systemctl disable apt-daily.service
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.service

sed -i "s/^enabled=1/enabled=0/" /etc/default/apport
sed -i "s/^Prompt=normal/Prompt=never/" /etc/update-manager/release-upgrades
sed -i "s/^Prompt=lts/Prompt=never/" /etc/update-manager/release-upgrades

# Install updates
apt-get update
apt-get dist-upgrade -y
apt-get install -f -y
dpkg --configure -a

# Git
apt-get install git -y

# LibreOffice
add-apt-repository -y ppa:libreoffice/ppa
apt-get update
apt-get install libreoffice -y
apt-get dist-upgrade -y
apt-get install -f -y
apt-get dist-upgrade -y

# RStudio
cd /tmp
wget -c https://rstudio.org/download/latest/stable/desktop/bionic/rstudio-latest-amd64.deb
apt-get install -y r-base-dev ./rstudio-latest-amd64.deb

# Pandoc
cd /tmp
LATEST_PANDOC_DEB_PATH=$(wget https://github.com/jgm/pandoc/releases/latest -O - | grep \.deb | grep href | sed 's/.*href="//g' | sed 's/\.deb.*/\.deb/g' | grep amd64)
echo $LATEST_PANDOC_DEB_PATH;
LATEST_PANDOC_DEB_URL="https://github.com${LATEST_PANDOC_DEB_PATH}";
wget -c $LATEST_PANDOC_DEB_URL;
apt install -y /tmp/pandoc*.deb;

# bookdown install for local user
apt-get install -y build-essential libssl-dev libcurl4-openssl-dev libxml2-dev libcairo2-dev
apt-get install -y evince

sudo -u $SUDO_USER -- mkdir -p /home/$SUDO_USER/R/x86_64-pc-linux-gnu-library/3.4
sudo -u $SUDO_USER -- R -e "install.packages(c('devtools','tikzDevice'), repos='http://cran.rstudio.com/', lib='/home/$SUDO_USER/R/x86_64-pc-linux-gnu-library/3.4')"
    ## FIXME on lua-filter side
    sudo -u $SUDO_USER -- R -e "require(devtools); install_version('bookdown', version = '0.21', repos = 'http://cran.rstudio.com')"

    ## fixes for LibreOffice <-> RStudio interaction as described in https://askubuntu.com/a/1258175/66509
    grep "^export LD_LIBRARY_PATH=\"/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH\"" /home/$SUDO_USER/.profile || echo "export LD_LIBRARY_PATH=\"/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH\"" >> /home/$SUDO_USER/.profile
    grep "^export LD_LIBRARY_PATH=\"/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH\"" /home/$SUDO_USER/.bashrc || echo "export LD_LIBRARY_PATH=\"/usr/lib/libreoffice/program:\$LD_LIBRARY_PATH\"" >> /home/$SUDO_USER/.bashrc

    sudo -u $SUDO_USER -- mkdir -p ~/.local/share/applications/
    sudo -u $SUDO_USER -- cp /usr/share/applications/rstudio.desktop ~/.local/share/applications/
    sudo -u $SUDO_USER -- sed -i "s|/usr/lib/rstudio/bin/rstudio|env LD_LIBRARY_PATH=/usr/lib/libreoffice/program /usr/lib/rstudio/bin/rstudio|"  ~/.local/share/applications/rstudio.desktop

# TexLive and fonts
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | /usr/bin/debconf-set-selections

apt-get install -y texlive-extra-utils texlive-xetex biber texlive-lang-cyrillic fonts-cmu texlive-xetex texlive-fonts-extra texlive-science-doc texlive-science font-manager ttf-mscorefonts-installer lmodern
apt-get install --reinstall -y ttf-mscorefonts-installer

# Cleaning up
apt-get autoremove -y

exit 0
