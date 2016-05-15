FROM centos:centos5

RUN yum -y install epel-release

RUN yum -y install\
 mysql mysql-server\
 memcached\
 mysql-devel openssl-devel gd-devel expat-devel libxml2-devel giflib-devel db4-devel\
 php php-mysql php-gd php-pecl-memcache\
 git wget bzip2 patch make gcc

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

RUN eval "$(plenv init -)" &&\
 cpanm -f GD LWP::Protocol::https

WORKDIR /root
RUN wget --no-check-certificate http://raw.githubusercontent.com/masiuchi/movabletype/new-master/cpanfile &&\
 eval "$(plenv init -)" &&\
 cpanm --installdeps . &&\
 rm -rf cpanfile /root/.cpanm/

# PHP
RUN sed 's/^;date\.timezone =/date\.timezone = "Asia\/Tokyo"/' -i /etc/php.ini
RUN sed 's/^memory_limit = 128M/memory_limit = 256M/' -i /etc/php.ini

RUN service mysqld start & sleep 10 && \
    mysql -e "create database mt_test default character set utf8;" && \
    mysql -e "grant all privileges on mt_test.* to mt@localhost;" && \
    service mysqld stop

