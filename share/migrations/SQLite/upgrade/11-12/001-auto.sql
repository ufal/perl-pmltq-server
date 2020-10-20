-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/11/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN allow_history boolean NOT NULL DEFAULT 1;

;
ALTER TABLE users ADD COLUMN allow_query_lists boolean NOT NULL DEFAULT 1;

;
ALTER TABLE users ADD COLUMN allow_publish_query_lists boolean NOT NULL DEFAULT 1;

;

COMMIT;

