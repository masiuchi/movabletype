## -*- mode: perl; coding: utf-8 -*-
requires 'DBI';
requires 'DBD::mysql';
requires 'Digest::SHA';
requires 'Plack';
requires 'CGI::PSGI';
requires 'CGI::Parse::PSGI';
requires 'CGI::Compile';
requires 'XMLRPC::Transport::HTTP::Plack';
requires 'HTML::Entities';
requires 'HTML::Parser';
requires 'Imager';
requires 'Crypt::DSA';
requires 'Crypt::SSLeay';
requires 'Cache::File';
requires 'Archive::Tar';
requires 'IO::Compress::Gzip';
requires 'IO::Uncompress::Gunzip';
requires 'Archive::Zip';
requires 'Digest::SHA1';
requires 'Net::SMTP';
requires 'Authen::SASL';
requires 'Net::SMTP::SSL';
requires 'Net::SMTP::TLS';
requires 'IO::Socket::SSL';
requires 'Net::SSLeay';
requires 'XML::Parser';

requires 'YAML::Syck';     # MT::Util::YAML::Syck
requires 'Net::FTPSSL';    # MT::FileMgr::FTPS
requires 'DBD::SQLite';
requires 'GD';

## recommends
requires 'XML::LibXML';
requires 'Web::Scraper';

on 'test' => sub {
    requires 'Clone';
    requires 'DateTime';
    requires 'Test::Base';
    requires 'Test::Class';
    requires 'Test::LeakTrace';
    requires 'Test::MockModule';
    requires 'Test::MockObject';
    requires 'Test::Perl::Critic';
};

## % carton exec -- local/bin/start_server --port 8000 --pid-file=log/mt.pid -- plackup -s Starlet --max-workers=2 --access-log=log/access.log mt.psgi >& log/error.log &

