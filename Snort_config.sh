#!/bin/bash

snort_config(){
echo "Realizando os updates!!!"
echo "Apos os updates reinicie a maquina"
sleep 3
clear
apt-get update
apt-get upgrade -y
sleep 10
apt-get install flex bison build-essential checkinstall libpcap-dev libnet1-dev libpcre3-dev libnetfilter-queue-dev iptables-dev libdumbnet-dev -y

mkdir /usr/src/snort_src
cd /usr/src/snort_src

# Instalando o Data Acquisition Library (DAQ)

wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz

tar xvfz daq-2.0.6.tar.gz
cd daq-2.0.6

./configure; make; make install

# Instalando Snort

cd /usr/src/snort_src

wget https://www.snort.org/downloads/snort/snort-2.9.8.0.tar.gz

tar xvfz snort-2.9.8.0.tar.gz
cd snort-2.9.8.0

./configure --enable-sourcefire; make; make install

ldconfig

snort --version

ln -s /usr/local/bin/snort /usr/sbin/snort
snort --version


# Deixando Snort para todos os usuarios

groupadd snort
useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

mkdir /etc/snort
mkdir /etc/snort/rules
mkdir /etc/snort/preproc_rules
touch /etc/snort/rules/white_list.rules /etc/snort/rules/black_list.rules /etc/snort/rules/local.rules

mkdir /var/log/snort

mkdir /usr/local/lib/snort_dynamicrules

chmod -R 5775 /etc/snort
chmod -R 5775 /var/log/snort
chmod -R 5775 /usr/local/lib/snort_dynamicrules
chown -R snort:snort /etc/snort
chown -R snort:snort /var/log/snort
chown -R snort:snort /usr/local/lib/snort_dynamicrules 

# Gerando os ficheiros de configuração

cp /usr/src/snort_src/snort*/etc/*.conf* /etc/snort
cp /usr/src/snort_src/snort*/etc/*.map /etc/snort

}

ROT=$(id -u)

if [ "$ROT" = "0" ];then
	snort_config

else
	echo "O script abre apenas com ROOT"
	exit

fi
