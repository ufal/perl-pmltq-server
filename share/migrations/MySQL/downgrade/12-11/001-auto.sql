-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/12/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users DROP COLUMN allow_history,
                  DROP COLUMN allow_query_lists,
                  DROP COLUMN allow_publish_query_lists;

;

COMMIT;

