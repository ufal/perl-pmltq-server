-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/5/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "treebank_provider_ids" (
  "treebank_id" integer NOT NULL,
  "provider" character varying(250) NOT NULL,
  "provider_id" character varying(120) NOT NULL,
  PRIMARY KEY ("treebank_id", "provider", "provider_id")
);
CREATE INDEX "treebank_provider_ids_idx_treebank_id" on "treebank_provider_ids" ("treebank_id");

;
ALTER TABLE "treebank_provider_ids" ADD CONSTRAINT "treebank_provider_ids_fk_treebank_id" FOREIGN KEY ("treebank_id")
  REFERENCES "treebanks" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

