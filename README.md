[![Build Status](https://travis-ci.org/ufal/perl-pmltq-server.png)](https://travis-ci.org/ufal/perl-pmltq-server)
[![Coverage Status](https://coveralls.io/repos/ufal/perl-pmltq-server/badge.svg)](https://coveralls.io/r/ufal/perl-pmltq-server)

# PML-TQ Server

PML-TQ REST API server for querying treebanks.

# Development

    git clone https://github.com/ufal/perl-pmltq-server.git
    cd perl-pmltq-server
    cpanm --installdeps .
    morbo ./script/pmltq-server

# Updating database

Be cautious to which database are you connected to. This can easily destroy data in the database by using these commands.

If not sure, delete your `pmltq_server.private.pl` configuration and use default SQLite configuration.

- Increase schema version in `PMLTQ::Schema`
- Prepare a new version `./script/db-migration prepare`
- Upgrade the current database `./script/db-migration upgrade`
- Dump data for fixtures `./script/db-migration dump_all_sets`

# Deployment

<(UFAL specific)>

The deployment uses [Rex](https://metacpan.org/pod/Rex) to facilitate the
deployment. If you don't have Rex installed, install Rex by running:

    cpanm -n Rex

Also if you don't have that already upload you ssh keys on the server so you can deploy without inputting the password all the time.

    ssh-copy-id pmltq@euler.ms.mff.cuni.cz

Then you can deploy new version by running:

    rex deploy
