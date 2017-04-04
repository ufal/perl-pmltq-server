-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE query_files DROP COLUMN is_public,
                        DROP COLUMN description;

;
ALTER TABLE query_records DROP FOREIGN KEY query_records_fk_first_used_treebank,
                          DROP INDEX query_records_idx_first_used_treebank,
                          DROP COLUMN is_public,
                          DROP COLUMN description,
                          DROP COLUMN ord,
                          DROP COLUMN eval_num,
                          DROP COLUMN first_used_treebank,
                          DROP COLUMN hash;

;

COMMIT;

