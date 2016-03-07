#!/bin/bash
### Configuração do Snort ###

# Instalando updates

apt-get install update
apt-get install dist-upgrade -y
apt-get install -y openssh-server
reboot

# Configurando placa de rede

cp /etc/network/interfaces /etc/network/interfaces.old
rm /etc/network/interfaces

# Configurando o arquivos interfaces

echo "# This file describes the network interfaces available on your system" >> /etc/network/interfaces
echo " and how to active them. For more information, see interfaces(5)." >> /etc/network/interfaces
echo "" >> /etc/network/interfaces
echo "source /etc/network/interfaces.d/*" >> /etc/network/interfaces
echo "" >> /etc/network/interfaces
echo "#The loopback network interface" >> /etc/network/interfaces
echo "auto lo" >> /etc/network/interfaces
echo "iface lo inet loopback" >> /etc/network/interfaces
echo "" >> /etc/network/interfaces
echo "# The primary network interface" >> /etc/network/interfaces
echo "auto eth0" >> /etc/network/interfaces
echo "iface eth0 inet dhcp" >> /etc/network/interfaces
echo "auto eth1" >> /etc/network/interfaces
echo "iface eth1 inet static" >> /etc/network/interfaces
echo "address 192.168.0.100" >> /etc/network/interfaces
echo "netmask 255.255.255.0" >> /etc/network/interfaces
echo "network 192.168.0.0" >> /etc/network/interfaces
echo "broadcast 192.168.0.255" >> /etc/network/interfaces
echo "post-up ethtool -K eth1 gro off" >> /etc/network/interfaces
echo "post-up ethtool -K eth1 lro off" >> /etc/network/interfaces

# Reiniciando os serviços de rede

ifconfig eth1 down && ifconfig eth1 up
ethtool -k eth1 | grep receive-offload

# Instalando pacotes essenciais

apt-get install -y build-essential
apt-get install -y libpcap-dev libpcre3-dev libdumbnet-dev

# Snort SRC

mkdir snort_src
cd snort_src

# Instalando bison flex

apt-get install -y bison flex

# Baixando o daq

wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
tar -xvzf daq-2.0.6.tar.gz
cd daq-2.0.6
./configure
make
make install

# Instalando Snort

apt-get install -y zlib1g-dev liblzma-dev openssl libssl-dev
cd snort_src
wget https://snort.org/downloads/snort/snort-2.9.8.0.tar.gz
tar -xvzf snort-2.9.8.0.tar.gz
cd snort-2.9.8.0 

# Fazendo atualização das bibliotecas compartilhadas

ldconfig

ln -s /usr/local/bin/snort /usr/sbin/snort

# Criando Usuario e grupo snort

groupadd snort
useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

# Criando os diretorios do snort

mkdir /etc/snort
mkdir /etc/snort/rules
mkdir /etc/snort/rules/iplist
mkdir /etc/snort/preproc_rules
mkdir /usr/local/lib/snort_dynamicrules
mkdir /etc/snort/so_rules

# Criando regras e lista de ip

touch /etc/snort/rules/iplist/black_list.rules
touch /etc/snort/rules/iplist/white_list.rules
touch /etc/snort/rules/local.rules
touch /etc/snort/sid-msg.map

# Criando diretorios de logging

mkdir /var/log/snort
mkdir /var/log/snort/archived_logs

# Ajustando permisões

chmod -R 5775 /etc/snort
chmod -R 5775 /var/log/snort
chmod -R 5775 /var/log/archived_logs

