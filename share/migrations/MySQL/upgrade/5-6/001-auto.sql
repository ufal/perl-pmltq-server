-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/5/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `treebank_provider_ids` (
  `treebank_id` integer NOT NULL,
  `provider` varchar(250) NOT NULL,
  `provider_id` varchar(120) NOT NULL,
  INDEX `treebank_provider_ids_idx_treebank_id` (`treebank_id`),
  PRIMARY KEY (`treebank_id`, `provider`, `provider_id`),
  CONSTRAINT `treebank_provider_ids_fk_treebank_id` FOREIGN KEY (`treebank_id`) REFERENCES `treebanks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

