-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/2/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE user_tags (
  user_id integer NOT NULL,
  tag_id integer NOT NULL,
  PRIMARY KEY (user_id, tag_id),
  FOREIGN KEY (tag_id) REFERENCES tags(id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX user_tags_idx_tag_id ON user_tags (tag_id);

;
CREATE INDEX user_tags_idx_user_id ON user_tags (user_id);

;
DROP INDEX languages_fk_language_group_id;

;

;
ALTER TABLE treebanks ADD COLUMN is_all_logged boolean NOT NULL DEFAULT 1;

;

COMMIT;

