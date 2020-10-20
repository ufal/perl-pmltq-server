-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/11/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users DROP COLUMN valid_until;

;

COMMIT;

