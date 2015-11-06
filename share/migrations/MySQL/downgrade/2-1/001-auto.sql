-- Convert schema '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/2/001-auto.yml' to '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `queries` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(120) NULL,
  `text` varchar(120) NOT NULL,
  `user_id` integer NOT NULL,
  `query_file_id` integer NULL,
  `created_at` datetime NOT NULL,
  `last_use` datetime NOT NULL,
  INDEX `queries_idx_query_file_id` (`query_file_id`),
  INDEX `queries_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `queries_fk_query_file_id` FOREIGN KEY (`query_file_id`) REFERENCES `query_files` (`id`) ON DELETE CASCADE,
  CONSTRAINT `queries_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE query_records DROP FOREIGN KEY query_records_fk_query_file_id,
                          DROP FOREIGN KEY query_records_fk_user_id;

;
DROP TABLE query_records;

;

COMMIT;

