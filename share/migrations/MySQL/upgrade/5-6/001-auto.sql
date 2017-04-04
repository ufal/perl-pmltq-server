-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/5/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE query_files ADD COLUMN is_public enum('0','1') NOT NULL DEFAULT '0',
                        ADD COLUMN description text NULL;

;
ALTER TABLE query_records ADD COLUMN is_public enum('0','1') NOT NULL DEFAULT '0',
                          ADD COLUMN description text NULL,
                          ADD COLUMN ord integer NULL DEFAULT 0,
                          ADD COLUMN eval_num integer NULL DEFAULT 0,
                          ADD COLUMN first_used_treebank integer NULL,
                          ADD COLUMN hash char(32) NULL,
                          ADD INDEX query_records_idx_first_used_treebank (first_used_treebank),
                          ADD CONSTRAINT query_records_fk_first_used_treebank FOREIGN KEY (first_used_treebank) REFERENCES treebanks (id);

;

COMMIT;

