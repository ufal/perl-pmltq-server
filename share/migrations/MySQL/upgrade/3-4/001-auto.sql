-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/3/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE treebanks ADD COLUMN documentation text NULL;

;

COMMIT;

