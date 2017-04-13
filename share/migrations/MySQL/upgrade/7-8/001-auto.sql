-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/7/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `query_record_treebanks` (
  `query_record_id` integer NOT NULL,
  `treebank_id` integer NOT NULL,
  INDEX `query_record_treebanks_idx_query_record_id` (`query_record_id`),
  INDEX `query_record_treebanks_idx_treebank_id` (`treebank_id`),
  PRIMARY KEY (`query_record_id`, `treebank_id`),
  CONSTRAINT `query_record_treebanks_fk_query_record_id` FOREIGN KEY (`query_record_id`) REFERENCES `query_records` (`id`) ON DELETE CASCADE,
  CONSTRAINT `query_record_treebanks_fk_treebank_id` FOREIGN KEY (`treebank_id`) REFERENCES `treebanks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE query_records DROP FOREIGN KEY query_records_fk_first_used_treebank,
                          DROP INDEX query_records_idx_first_used_treebank,
                          DROP COLUMN first_used_treebank;

;

COMMIT;

