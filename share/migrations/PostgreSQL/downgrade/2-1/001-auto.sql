-- Convert schema '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/2/001-auto.yml' to '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "queries" (
  "id" serial NOT NULL,
  "name" character varying(120),
  "text" character varying(120) NOT NULL,
  "user_id" integer NOT NULL,
  "query_file_id" integer,
  "created_at" timestamp NOT NULL,
  "last_use" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "queries_idx_query_file_id" on "queries" ("query_file_id");
CREATE INDEX "queries_idx_user_id" on "queries" ("user_id");

;
ALTER TABLE "queries" ADD CONSTRAINT "queries_fk_query_file_id" FOREIGN KEY ("query_file_id")
  REFERENCES "query_files" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "queries" ADD CONSTRAINT "queries_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
DROP TABLE query_records CASCADE;

;

COMMIT;

