#!/bin/bash

config_Snort(){

echo "Iniciando configuraçao do Snort"
sleep 3

#Instalando pre-requisitos
apt-get install -y build-essential
apt-get install -y libpcap-dev libpcre3-dev libdumbnet-dev

#Criando pasta de instalaçao
mkdir ~/snort_src
cd ~/snort_src

apt-get install -y bison flex

#Instalando DAQ 2.0.6
wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
tar xvfz daq-2.0.6.tar.gz
cd daq-2.0.6
./configure && make && sudo make install

#Iniciando instalaçao do Snort
#Instalando dependencias
apt-get install -y zlib1g-dev liblzma-dev openssl libssl-dev

#Instalando Snort
cd ~/snort_src
wget https://www.snort.org/downloads/snort/snort-2.9.8.2.tar.gz
tar xvfz snort-2.9.8.2.tar.gz
cd snort-2.9.8.2
./configure --enable-sourcefire && make && sudo make install

#Atualizando bibliotecas compartilhadas
ldconfig

#Gerando symlink do Snort
ln -s /usr/local/bin/snort /usr/sbin/snort

#Verificando versao
echo "Versao do Snort:"
snort -V
sleep 5

# Create the snort user and group:
groupadd snort
useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

# Criando diretorios do Snort
mkdir /etc/snort
mkdir /etc/snort/rules
mkdir /etc/snort/rules/iplists
mkdir /etc/snort/preproc_rules
mkdir /usr/local/lib/snort_dynamicrules
mkdir /etc/snort/so_rules

# Criando arquivos das regras 
touch /etc/snort/rules/iplists/black_list.rules
touch /etc/snort/rules/iplists/white_list.rules
touch /etc/snort/rules/local.rules
touch /etc/snort/sid-msg.map

# Gerando diretorios de logs:
mkdir /var/log/snort
mkdir /var/log/snort/archived_logs

# Definindo permissoes:
chmod -R 5775 /etc/snort
chmod -R 5775 /var/log/snort
chmod -R 5775 /var/log/snort/archived_logs
chmod -R 5775 /etc/snort/so_rules
chmod -R 5775 /usr/local/lib/snort_dynamicrules

# Definindo donos dos diretorios:
chown -R snort:snort /etc/snort
chown -R snort:snort /var/log/snort
chown -R snort:snort /usr/local/lib/snort_dynamicrules

cd ~/snort_src/snort-2.9.8.2/etc/
cp *.conf* /etc/snort
cp *.map /etc/snort
cp *.dtd /etc/snort
cd ~/snort_src/snort-2.9.8.2/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/
cp * /usr/local/lib/snort_dynamicpreprocessor/

#Gerando copia de segurança das configuraçoes
cp /etc/snort/snort.conf /etc/snort/snort.BAK_INIT

sed -i "s/include \$RULE\_PATH/#include \$RULE\_PATH/" /etc/snort/snort.conf
#Escolhendo IP da rede a ser protegida
sed -i "s/ipvar HOME_NET any/ipvar HOME_NET 192.168.0.0\/24/g" /etc/snort/snort.conf

#Escrevendo caminho das regras
sed -i "s/var RULE_PATH ..\/rules/var RULE_PATH \/etc\/snort\/rules/g" /etc/snort/snort.conf
sed -i "s/var SO_RULE_PATH ..\/so_rules/var SO_RULE_PATH \/etc\/snort\/so_rules/g" /etc/snort/snort.conf
sed -i "s/var PREPROC_RULE_PATH ..\/preproc_rules/var PREPROC_RULE_PATH \/etc\/snort\/preproc_rules/g" /etc/snort/snort.conf

#Caminhos das regras de IP
sed -i "s/var WHITE_LIST_PATH ..\/rules/var WHITE_LIST_PATH \/etc\/snort\/rules\/iplists/g" /etc/snort/snort.conf
sed -i "s/var BLACK_LIST_PATH ..\/rules/var BLACK_LIST_PATH \/etc\/snort\/rules\/iplists/g" /etc/snort/snort.conf

#Ativando regras locais
sed -i "s/#include \$RULE\_PATH\/local.rules/include \$RULE\_PATH\/local.rules/g" /etc/snort/snort.conf

#Validando configuraçao
snort -T -i eth0 -c /etc/snort/snort.conf
sleep 5
#Copia das configuraçoes feitas
cp /etc/snort/snort.conf /etc/snort/snort.BAK_RULES
}

config_bndr(){
#Iniciando instalaçao do Barnyard2

apt-get install -y mysql-server libmysqlclient-dev mysql-client autoconf libtool

#Outputs snort em binario
sed -i "s/# output unified2: filename merged.log, limit 128, nostamp, mpls_event_types, vlan_event_types/output unified2: filename snort.u2, limit 128/g" /etc/snort/snort.conf

#Baixando e instalando Barnyard2
cd ~/snort_src
wget https://github.com/firnsy/barnyard2/archive/7254c24702392288fe6be948f88afb74040f6dc9.tar.gz \
-O barnyard2-2-1.14-336.tar.gz
tar zxvf barnyard2-2-1.14-336.tar.gz
mv barnyard2-7254c24702392288fe6be948f88afb74040f6dc9 barnyard2-2-1.14-336
cd barnyard2-2-1.14-336
autoreconf -fvi -I ./m4
ln -s /usr/include/dumbnet.h /usr/include/dnet.h
ldconfig

#Arquitetura do OS

echo "Escolha a arquitetura de seu sistema:"
echo "1 --> x86"
echo "2 --> x64"
read arch

if [ "$arch" = "1" ];then
	./configure --with-mysql --with-mysql-libraries=/usr/lib/i386-linux-gnu
else
	./configure --with-mysql --with-mysql-libraries=/usr/lib/x86_64-linux-gnu
fi

make && sudo make install

#Realizando copias para funcionamento do Barnyard2
cd ~/snort_src/barnyard2-2-1.14-336/
cp etc/barnyard2.conf /etc/snort/
mkdir /var/log/barnyard2
chown snort.snort /var/log/barnyard2

#Arquivos Barnyard2
touch /var/log/snort/barnyard2.waldo
chown snort.snort /var/log/snort/barnyard2.waldo

#Configurando SQL
echo "Nome de seu banco de dados:"
read datab
echo "Nome do usuario para o banco de dados: "
read dbuser
echo "Senha do usuario: "
read dbpass
echo "Insira a senha do Root SQL"
read rtpass

SQL="create database $datab; use $datab; source ~/snort_src/barnyard2-2-1.14-336/schemas/create_mysql; CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass'; grant create, insert, select, delete, update on $datab.* to '$dbuser'@'localhost';"
mysql -u root -p$rtpass -e "$SQL" mysql

chmod 777 /etc/snort/barnyard2.conf
echo "output database: log, mysql, user=$dbuser password=$dbpass dbname=$datab host=localhost" >> /etc/snort/barnyard2.conf
chmod 644 /etc/snort/barnyard2.conf

chmod o-r /etc/snort/barnyard2.conf
}

config_ppok(){
# Instalaçao PulledPork

#Instalando Pre-requisitos
apt-get install -y libcrypt-ssleay-perl liblwp-useragent-determined-perl 

#Baixando PulledPork
cd ~/snort_src
wget https://github.com/finchy/pulledpork/archive/8b9441aeeb7e1477e5be415f27dbc4eb25dd9d59.tar.gz \
-O pulledpork-0.7.2-196.tar.gz
tar xvfvz pulledpork-0.7.2-196.tar.gz
mv pulledpork-8b9441aeeb7e1477e5be415f27dbc4eb25dd9d59 pulledpork-0.7.2-196
cd pulledpork-0.7.2-196/
cp pulledpork.pl /usr/local/bin
chmod +x /usr/local/bin/pulledpork.pl
cp etc/*.conf /etc/snort

#Teste
/usr/local/bin/pulledpork.pl -V
sleep 3

#Alterando configuraçao do PulledPork
mv /etc/snort/pulledpork.conf /etc/snort/pulledpork.BAK
cp  ~/Snort-Config/pulledpork.conf /etc/snort/pulledpork.conf

#Baixando regras
/usr/local/bin/pulledpork.pl -c /etc/snort/pulledpork.conf -l

#Definindo caminho das configurações do Snort
sed -i "s/#include \$RULE\_PATH\/app-detect.rules/include \$RULE\_PATH\/snort.rules/g" /etc/snort/snort.conf

#Validando regras
snort -T -c /etc/snort/snort.conf -i eth0
}

init_script(){
#Script de inicializaçao
cp ~/Snort-Config/snort.script /etc/init/snort.conf
chmod +x /etc/init/snort.conf
initctl list | grep snort

cp ~/Snort-Config/barnyard2.script /etc/init/barnyard2.conf
chmod +x /etc/init/barnyard2.conf
initctl list | grep barnyard


cp ~/Snort-Config/snorby_init.script /etc/init/snorby_worker.conf
chmod +x /etc/init/snorby_worker.conf
initctl list | grep snorby_worker
}


install_snorby(){

echo "Instalando o Snorby"

apt-get install -y imagemagick apache2 libyaml-dev libxml2-dev libxslt-dev git ruby1.9.3
echo "gem: --no-rdoc --no-ri" > ~/.gemrc
sh -c "echo gem: --no-rdoc --no-ri > /etc/gemrc"
gem install wkhtmltopdf
gem install bundler
gem install rake --version=0.9.2
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby
source /etc/profile
source ~/.rvm/scripts/rvm
rvm install 2.1
rvm use 2.1
gem install rails

cd ~/snort_src/
wget https://github.com/Snorby/snorby/archive/v2.6.2.tar.gz -O snorby-2.6.2.tar.gz
tar xzvf snorby-2.6.2.tar.gz
cp -r ./snorby-2.6.2/ /var/www/html/snorby/

cd /var/www/html/snorby
bundle install

cp /var/www/html/snorby/config/database.yml.example /var/www/html/snorby/config/database.yml

echo "Insira a senha do Root Mysql"
read senha
sed -i "s/Enter Password Here/$senha/g" /var/www/html/snorby/config/database.yml

cp /var/www/html/snorby/config/snorby_config.yml.example /var/www/html/snorby/config/snorby_config.yml
sed -i s/"\/usr\/local\/bin\/wkhtmltopdf"/"\/usr\/bin\/wkhtmltopdf"/g /var/www/html/snorby/config/snorby_config.yml

cd /var/www/html/snorby
bundle exec rake snorby:setup

#Configurando SQL para o Snorby
echo "Nome de seu banco de dados:"
read datab
echo "Nome do usuario para o banco de dados: "
read dbuser
echo "Senha do usuario: "
read dbpass
echo "Insira a senha do Root SQL"
read rtpass


SQL="create database $datab; use $datab; CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass'; grant create, insert, select, delete, update on $datab.* to '$dbuser'@'localhost';"
mysql -u root -p$rtpass -e "$SQL" mysql

SQL="create database $datab; use $datab; source ~/snort_src/barnyard2-2-1.14-336/schemas/create_mysql; CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass'; grant create, insert, select, delete, update on $datab.* to '$dbuser'@'localhost';"
mysql -u root -p$rtpass -e "$SQL" mysql

chmod 777 /etc/snort/barnyard2.conf
echo "output database: log, mysql, user=$dbuser password=$dbpass dbname=$datab host=localhost" >> /etc/snort/barnyard2.conf
chmod 644 /etc/snort/barnyard2.conf

chmod o-r /etc/snort/barnyard2.conf

sed -i "s/root/$dbuser/g" /var/www/html/snorby/config/database.yml
sed -i "s/$senha/$dbpass/g" /var/www/html/snorby/config/database.yml

#Instalando Phusion Passenger

apt-get install -y libcurl4-openssl-dev apache2-threaded-dev libaprutil1-dev libapr1-dev
gem install passenger
passenger-install-apache2-module


echo "Insira a saida do comando acima nos seguintes arquivos"
echo "LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-5.0.21/buildout/apache2/mod_passenger.so"
echo "A saida acima equivalente pode variar de acordo com versoes, verifique a sua antes de colocalo no arquivo"
echo "A saida LoadModule insira no arquivo --> /etc/apache2/mods-available/passenger.load"
echo "Já o Passager com as saidas:
			PassengerRoot /var/lib/gems/1.9.1/gems/passenger-5.0.21
			PassengerDefaultRuby /usr/bin/ruby1.9.1 
	Insira no arquivo --> /etc/apache2/mods-available/passenger.conf"

a2enmod passenger
service apache2 restart
apache2ctl -t -D DUMP_MODULES

cp ~/Snort-Config/site.snorby /etc/apache2/sites-available/snorby.conf

cd /etc/apache2/sites-available/
a2ensite snorby.conf
service apache2 reload
 
cd /etc/apache2/sites-enabled
a2dissite 000-default
service apache2 reload

echo "output database: log, mysql, user=$dbuser password=$dbpass dbname=$datab host=localhost sensor_name=sensor1" >> /etc/snort/barnyard2.conf

service barnyard2 restart

}

menu(){
echo "Realizando os updates!!!"
echo "Apos os updates reinicie a maquina"
sleep 3
clear
apt-get update
apt-get dist-upgrade -y
apt-get install -y openssh-server
echo "Reinicie o equipamento se ainda nao o fez"
sleep 10

echo "Selecione o que deseja fazer:"
echo "1 - Instalar o Snort"
echo "2 - Instalar o Barnyard2"
echo "3 - Instalar o PulledPork"
echo "4 - Instalar o Snorby"
echo "5 - Gerar scripts de inicializaçao"
read opcao

case $opcao in

1)
echo "Instalaçao do Snort"
	config_Snort

;;

2)
echo "Instalaçao do Barnyard2"
	config_bndr

;;

3)
echo "Instalaçao do PulledPork"
	config_ppok

;;
4)
echo "Instalando o Snorby"
	install_snorby
	
;;

5)
echo "Criaçao de script de inicializaçao"
	init_script

;;
*)
echo "Opçao Invalida!!!"
echo "Voltando ao Menu"
sleep 5	
	menu
esac
}


ROT=$(id -u)

if [ "$ROT" = "0" ];then
	menu

else
	echo "O script abre apenas com ROOT"
	exit

fi
