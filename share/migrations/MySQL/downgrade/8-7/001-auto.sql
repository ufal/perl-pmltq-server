-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/8/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE query_records ADD COLUMN first_used_treebank integer NULL,
                          ADD INDEX query_records_idx_first_used_treebank (first_used_treebank),
                          ADD CONSTRAINT query_records_fk_first_used_treebank FOREIGN KEY (first_used_treebank) REFERENCES treebanks (id);

;
ALTER TABLE query_record_treebanks DROP FOREIGN KEY query_record_treebanks_fk_query_record_id,
                                   DROP FOREIGN KEY query_record_treebanks_fk_treebank_id;

;
DROP TABLE query_record_treebanks;

;

COMMIT;

