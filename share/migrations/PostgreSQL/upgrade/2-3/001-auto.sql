-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/2/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "user_tags" (
  "user_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY ("user_id", "tag_id")
);
CREATE INDEX "user_tags_idx_tag_id" on "user_tags" ("tag_id");
CREATE INDEX "user_tags_idx_user_id" on "user_tags" ("user_id");

;
ALTER TABLE "user_tags" ADD CONSTRAINT "user_tags_fk_tag_id" FOREIGN KEY ("tag_id")
  REFERENCES "tags" ("id") DEFERRABLE;

;
ALTER TABLE "user_tags" ADD CONSTRAINT "user_tags_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE languages DROP CONSTRAINT languages_fk_language_group_id;

;
ALTER TABLE languages ADD CONSTRAINT languages_fk_language_group_id FOREIGN KEY (language_group_id)
  REFERENCES language_groups (id) DEFERRABLE;

;
ALTER TABLE treebanks ADD COLUMN is_all_logged boolean DEFAULT '1' NOT NULL;

;

COMMIT;

