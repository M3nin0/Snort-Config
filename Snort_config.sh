#!/bin/bash

apt-get update
apt-get upgrade -y
echo "Por favor reinicie a maquina!!!"
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


# Configurando seu bloco de IP
# Para Snort não fazer log de sua propria rede 

echo "Dentro da pasta /etc/snort/snort.conf"
echo "Modifique a linha 45 onde há HOME_NET"
echo "Caso não esteja, provavelmente estará mais abaixo ou acima"
echo "Fica assim ipvar HOME_NET IP_DESEJADO"
sleep 120

# Gerando regras 

var RULE_PATH /etc/snort/rules
var SO_RULE_PATH /etc/snort/so_rules
var PREPROC_RULE_PATH /etc/snort/preproc_rules
var WHITE_LIST_PATH /etc/snort/rules
var BLACK_LIST_PATH /etc/snort/rules


# Configurações finalizadas!!!

echo "Para testar o Snort digite: "
echo "snort -T -c /etc/snort/snort.conf"
sleep 20
clear
echo "Até mais!!!"
sleep 5
