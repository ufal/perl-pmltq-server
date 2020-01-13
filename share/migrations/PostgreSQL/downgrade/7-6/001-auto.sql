-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/7/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE query_files DROP COLUMN is_public;

;
ALTER TABLE query_files DROP COLUMN description;

;
ALTER TABLE query_records DROP CONSTRAINT query_records_fk_first_used_treebank;

;
DROP INDEX query_records_idx_first_used_treebank;

;
ALTER TABLE query_records DROP COLUMN is_public;

;
ALTER TABLE query_records DROP COLUMN description;

;
ALTER TABLE query_records DROP COLUMN ord;

;
ALTER TABLE query_records DROP COLUMN eval_num;

;
ALTER TABLE query_records DROP COLUMN first_used_treebank;

;
ALTER TABLE query_records DROP COLUMN hash;

;

COMMIT;

