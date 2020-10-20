-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/10/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN valid_until datetime NULL;

;

COMMIT;

