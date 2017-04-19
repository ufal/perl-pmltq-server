-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE query_files ADD COLUMN is_public boolean DEFAULT '0' NOT NULL;

;
ALTER TABLE query_files ADD COLUMN description text;

;
ALTER TABLE query_records ADD COLUMN is_public boolean DEFAULT '0' NOT NULL;

;
ALTER TABLE query_records ADD COLUMN description text;

;
ALTER TABLE query_records ADD COLUMN ord integer DEFAULT 0;

;
ALTER TABLE query_records ADD COLUMN eval_num integer DEFAULT 0;

;
ALTER TABLE query_records ADD COLUMN first_used_treebank integer;

;
ALTER TABLE query_records ADD COLUMN hash character(32);

;
CREATE INDEX query_records_idx_first_used_treebank on query_records (first_used_treebank);

;
ALTER TABLE query_records ADD CONSTRAINT query_records_fk_first_used_treebank FOREIGN KEY (first_used_treebank)
  REFERENCES treebanks (id) DEFERRABLE;

;

COMMIT;

