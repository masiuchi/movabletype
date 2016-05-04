#!/bin/bash

dir=$1
archive_file=https://www.imagemagick.org/download/ImageMagick.tar.gz

if [[ -f $dir/ImageMagick.tar.gz]]; then
  exit 0
fi

if [[ ! -d $dir ]]; then
  mkdir $dir
fi

pushd $dir

wget $archive_file
tar xzvf $archive_file
mv ImageMagick-* ImageMagick
cd ImageMagick
./configure --prefix=$dir --with-perl
make
make install

popd

