-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE treebank_provider_ids DROP FOREIGN KEY treebank_provider_ids_fk_treebank_id;

;
DROP TABLE treebank_provider_ids;

;

COMMIT;

