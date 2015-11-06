-- Convert schema '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/1/001-auto.yml' to '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "query_records" (
  "id" serial NOT NULL,
  "name" character varying(120),
  "query" text NOT NULL,
  "user_id" integer NOT NULL,
  "query_file_id" integer,
  "created_at" timestamp NOT NULL,
  "last_use" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "query_records_idx_query_file_id" on "query_records" ("query_file_id");
CREATE INDEX "query_records_idx_user_id" on "query_records" ("user_id");

;
ALTER TABLE "query_records" ADD CONSTRAINT "query_records_fk_query_file_id" FOREIGN KEY ("query_file_id")
  REFERENCES "query_files" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "query_records" ADD CONSTRAINT "query_records_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
DROP TABLE queries CASCADE;

;

COMMIT;

