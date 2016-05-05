#!/bin/bash

archive_file=ImageMagick.tar.gz
archive_url=https://www.imagemagick.org/download/$archive_file

dir=$1

if [[ -v TRAVIS_PHP_VERSION ]]; then
  exit 0
fi

if [[ -f $dir/$archive_file ]]; then
  exit 0
fi

if [[ ! -d $dir ]]; then
  mkdir -p $dir
fi

pushd $dir

wget $archive_url
tar xzvf $archive_file
mv ImageMagick-* ImageMagick
cd ImageMagick
./configure --prefix=$dir --with-perl
make
make install

popd

