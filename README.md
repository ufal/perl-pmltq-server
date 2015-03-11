[![Build Status](https://travis-ci.org/ufal/perl-pmltq-server.png)](https://travis-ci.org/ufal/perl-pmltq-server)
[![Coverage Status](https://coveralls.io/repos/ufal/perl-pmltq-server/badge.svg)](https://coveralls.io/r/ufal/perl-pmltq-server)

# PML-TQ Server - work in progress

This is a refactored version of PMLTQ::CGI server. It is an implementation of PML-TQ powered by SQL database.

# Development

    git clone https://github.com/ufal/perl-pmltq-server.git
    cd perl-pmltq-server
    cpanm --installdeps .
    morbo ./script/pmltq-server

# TODO

- Treebank administration
- TrEd compatible REST api
- PMLTQ::Web compatible REST api
