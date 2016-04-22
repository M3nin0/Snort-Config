#!/bin/bash

snort_config(){
echo "Realizando os updates!!!"
echo "Apos os updates reinicie a maquina"
sleep 3
clear
apt-get update
apt-get upgrade -y
echo "Reinicie o equipamento se ainda nao o fez"
sleep 10

echo "Iniciando configuraçao do Snort"
sleep 3

#Instalando pre-requisitos
sudo apt-get install -y build-essential
sudo apt-get install -y libpcap-dev libpcre3-dev libdumbnet-dev

#Criando pasta de instalaçao
mkdir ~/snort_src
cd ~/snort_src

sudo apt-get install -y bison flex

#Instalando DAQ 2.0.6
wget https://snort.org/downloads/snort/daq-2.0.6.tar.gz
tar xvfz daq-2.0.6.tar.gz
cd daq-2.0.6
./configure && make && sudo make install

#Iniciando instalaçao do Snort
#Instalando dependencias
sudo apt-get install -y zlib1g-dev liblzma-dev openssl libssl-dev
cd ~/snort_src
wget https://snort.org/downloads/snort/snort-2.9.8.2.tar.gz
tar xvfz snort-2.9.8.2.tar.gz
cd snort-2.9.8.2
./configure --enable-sourcefire && make && sudo make install

#Atualizando bibliotecas compartilhadas
sudo ldconfig

#Gerando symlink do Snort
sudo ln -s /usr/local/bin/snort /usr/sbin/snort

#Verificando versao
echo "Versao do Snort:"
snort -V
sleep 5

#Configurando Snort em NIDS
#Criando usuario e grupo do Snort
sudo groupadd snort
sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

#Criando os diretorios Snort
sudo mkdir /etc/snort
sudo mkdir /etc/snort/rules
sudo mkdir /etc/snort/rules/iplists
sudo mkdir /etc/snort/preproc_rules
sudo mkdir /usr/local/lib/snort_dynamicrules
sudo mkdir /etc/snort/so_rules

#Criando ficheiros para alocar as regras
sudo touch /etc/snort/rules/iplists/black_list.rules
sudo touch /etc/snort/rules/iplists/white_list.rules 
sudo touch /etc/snort/rules/local.rules
sudo touch /etc/snort/sid-msg.map

#Criando diretorios de log
sudo mkdir /var/log/snort
sudo mkdir /var/log/snort/archived_logs

#Definindo permissoes
sudo chmod -R 5775 /etc/snort
sudo chmod -R 5775 /var/log/snort
sudo chmod -R 5775 /var/log/snort/archived_logs
sudo chmod -R 5775 /etc/snort/so_rules
sudo chmod -R 5775 /usr/local/lib/snort_dynamicrules

#Definindo controle das pastas
sudo chown -R snort:snort /etc/snort
sudo chown -R snort:snort /var/log/snort
sudo chown -R snort:snort /usr/local/lib/snort_dynamicrules

#Copiando arquivos de configuraçao
cd ~/snort_src/snort-2.9.8.2/etc/
sudo cp *.conf* /etc/snort
sudo cp *.map /etc/snort
sudo cp *.dtd /etc/snort
cd ~/snort_src/snort-2.9.8.2/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicrules
sudo cp * /etc/local/lib/snort_dynamicrules

sudo sed -i "s/include \$RULE\_PATH/#include \$RULE\_PATH/" /etc/snort/snort.conf

#Gerando copia de segurança das configuraçoes
sudo cp /etc/snort/snort.conf /etc/snort/snort.BAK

echo "Digite o IP e a classe que sera utilizado (Exemplo:10.0.0.0/24): "
read IPCLASS
sudo sed -i "s/# Setup the network addresses you are protecting/ipvar HOME_NET $IPCLASS/g" /etc/snort/snort.conf

}

ROT=$(id -u)

if [ "$ROT" = "0" ];then
	snort_config

else
	echo "O script abre apenas com ROOT"
	exit

fi
