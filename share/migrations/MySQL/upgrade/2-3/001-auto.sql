-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/2/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `user_tags` (
  `user_id` integer NOT NULL,
  `tag_id` integer NOT NULL,
  INDEX `user_tags_idx_tag_id` (`tag_id`),
  INDEX `user_tags_idx_user_id` (`user_id`),
  PRIMARY KEY (`user_id`, `tag_id`),
  CONSTRAINT `user_tags_fk_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_tags_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE languages DROP FOREIGN KEY languages_fk_language_group_id;

;
ALTER TABLE languages ADD CONSTRAINT languages_fk_language_group_id FOREIGN KEY (language_group_id) REFERENCES language_groups (id);

;
ALTER TABLE treebanks ADD COLUMN is_all_logged enum('0','1') NOT NULL DEFAULT '1';

;

COMMIT;

