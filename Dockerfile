FROM centos:centos5

RUN yum -y install epel-release
RUN yum -y install memcached

RUN yum -y install mysql mysql-server

RUN yum -y install wget make gcc
RUN wget --no-check-certificate -O - http://cpanmin.us | perl - App::cpanminus

RUN wget --no-check-certificate http://raw.githubusercontent.com/masiuchi/movabletype/support-php-5.1/cpanfile

# For installing Net::SSLeay
RUN yum -y install openssl-devel

# For installing GD
RUN yum -y install gd-devel perl-GD

# Install Image::Magick from RPM.
RUN yum -y install ImageMagick-perl

# For installing XML::Parser.
RUN yum -y install expat-devel perl-XML-Parser

# For installing XML::LibXML.
RUN yum -y install libxml2-devel

# For Imager.
RUN yum -y install giflib-devel

# File::Path is old to install File::Spec.
RUN cpanm File::Path

# For installing Crypt::SSLeay.
RUN cpanm Getopt::Long

# For installing Encode.
RUN cpanm Test::More

RUN cpanm LWP::Protocol::https -f
RUN cpanm GD -f

RUN cpanm --installdeps .

# PHP
RUN yum -y install php php-mysql php-gd php-pecl-memcache
RUN sed 's/^;date\.timezone =/date\.timezone = "Asia\/Tokyo"/' -i /etc/php.ini
RUN sed 's/^memory_limit = 128M/memory_limit = 256M/' -i /etc/php.ini

RUN service mysqld start & sleep 10 && \
    mysql -e "create database mt_test default character set utf8;" && \
    mysql -e "grant all privileges on mt_test.* to mt@localhost;" && \
    service mysqld stop

