-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/3/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE languages DROP FOREIGN KEY languages_fk_language_group_id;

;
ALTER TABLE languages ADD CONSTRAINT languages_fk_language_group_id FOREIGN KEY (language_group_id) REFERENCES language_groups (id) ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE treebanks DROP COLUMN is_all_logged;

;
ALTER TABLE user_tags DROP FOREIGN KEY user_tags_fk_tag_id,
                      DROP FOREIGN KEY user_tags_fk_user_id;

;
DROP TABLE user_tags;

;

COMMIT;

