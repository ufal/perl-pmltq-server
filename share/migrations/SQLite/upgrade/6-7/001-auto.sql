-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE query_files ADD COLUMN is_public boolean NOT NULL DEFAULT 0;

;
ALTER TABLE query_files ADD COLUMN description text;

;
ALTER TABLE query_records ADD COLUMN is_public boolean NOT NULL DEFAULT 0;

;
ALTER TABLE query_records ADD COLUMN description text;

;
ALTER TABLE query_records ADD COLUMN ord integer DEFAULT 0;

;
ALTER TABLE query_records ADD COLUMN eval_num integer DEFAULT 0;

;
ALTER TABLE query_records ADD COLUMN first_used_treebank integer;

;
ALTER TABLE query_records ADD COLUMN hash char(32);

;
CREATE INDEX query_records_idx_first_used_treebank ON query_records (first_used_treebank);

;

;

COMMIT;

