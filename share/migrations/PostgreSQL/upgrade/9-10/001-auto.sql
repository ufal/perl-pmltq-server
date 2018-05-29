-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/9/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE data_sources ADD COLUMN svg character varying(250);

;

COMMIT;

