# PML-TQ Server - work in progress

This is a refactored version of PMLTQ::CGI server. It is an implementation of PML-TQ powered by SQL database.

# Development

    git clone https://github.com/ufal/perl-pmltq-server.git
    cd perl-pmltq-server
    cpanm -n Mojolicious
    morbo ./script/pmltq-server

# TODO

- Treebank administration
- TrEd compatible REST api
- PMLTQ::Web compatible REST api
