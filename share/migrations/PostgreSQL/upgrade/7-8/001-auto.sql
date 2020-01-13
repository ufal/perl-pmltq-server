-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/7/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "query_record_treebanks" (
  "query_record_id" integer NOT NULL,
  "treebank_id" integer NOT NULL,
  PRIMARY KEY ("query_record_id", "treebank_id")
);
CREATE INDEX "query_record_treebanks_idx_query_record_id" on "query_record_treebanks" ("query_record_id");
CREATE INDEX "query_record_treebanks_idx_treebank_id" on "query_record_treebanks" ("treebank_id");

;
ALTER TABLE "query_record_treebanks" ADD CONSTRAINT "query_record_treebanks_fk_query_record_id" FOREIGN KEY ("query_record_id")
  REFERENCES "query_records" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "query_record_treebanks" ADD CONSTRAINT "query_record_treebanks_fk_treebank_id" FOREIGN KEY ("treebank_id")
  REFERENCES "treebanks" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE query_records DROP CONSTRAINT query_records_fk_first_used_treebank;

;
DROP INDEX query_records_idx_first_used_treebank;

;
ALTER TABLE query_records DROP COLUMN first_used_treebank;

;

COMMIT;

