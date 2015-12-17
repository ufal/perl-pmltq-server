-- Convert schema '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/1/001-auto.yml' to '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `query_records` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(120) NULL,
  `query` text NULL,
  `user_id` integer NOT NULL,
  `query_file_id` integer NULL,
  `created_at` datetime NOT NULL,
  `last_use` datetime NOT NULL,
  INDEX `query_records_idx_query_file_id` (`query_file_id`),
  INDEX `query_records_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `query_records_fk_query_file_id` FOREIGN KEY (`query_file_id`) REFERENCES `query_files` (`id`) ON DELETE CASCADE,
  CONSTRAINT `query_records_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE queries DROP FOREIGN KEY queries_fk_query_file_id,
                    DROP FOREIGN KEY queries_fk_user_id;

;
DROP TABLE queries;

;

COMMIT;

