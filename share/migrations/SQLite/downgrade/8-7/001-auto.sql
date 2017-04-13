-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/8/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE query_records ADD COLUMN first_used_treebank integer;

;
CREATE INDEX query_records_idx_first_used_treebank ON query_records (first_used_treebank);

;

;
DROP TABLE query_record_treebanks;

;

COMMIT;

