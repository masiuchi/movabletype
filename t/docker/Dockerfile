FROM ubuntu:precise

RUN apt-get update
RUN apt-get -y upgrade

RUN DEBIAN_FRONTEND=nointeractive\
 apt-get -y install\
 apache2\
 mysql-server mysql-client\
 memcached\
 php5 php5-cli php5-mysql php5-gd php5-memcache\
 git make gcc wget curl unzip bzip2\
 libssl-dev libgmp-dev libgd2-xpm-dev libxml2-dev libmysql++-dev libgif-dev libdb-dev

RUN mysqld_safe & sleep 10 &&\
 mysql -e "create database mt_test default character set utf8;" &&\
 mysql -e "grant all privileges on mt_test.* to mt@localhost;"

ENV HOME /root
ENV PATH $PATH:$HOME/.plenv/bin
RUN git clone git://github.com/tokuhirom/plenv.git $HOME/.plenv &&\
 git clone git://github.com/tokuhirom/Perl-Build.git $HOME/.plenv/plugins/perl-build/ &&\
 echo 'eval "$(plenv init -)"' >> $HOME/.bashrc

RUN eval "$(plenv init -)" &&\
 plenv install 5.24.0 -Duseshrplib &&\
 plenv global 5.24.0 &&\
 plenv rehash
RUN eval "$(plenv init -)" &&\
 plenv install-cpanm

RUN eval "$(plenv init -)" &&\
 cpanm Alien::ImageMagick

WORKDIR /root
RUN wget https://raw.githubusercontent.com/masiuchi/movabletype/new-master/cpanfile &&\
 eval "$(plenv init -)" &&\
 cpanm --installdeps . &&\
 rm -rf cpanfile /root/.cpanm/

