-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Tue Jan 24 17:44:16 2017
-- 
;
SET foreign_key_checks=0;
--
-- Table: `language_groups`
--
CREATE TABLE `language_groups` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(200) NOT NULL,
  `position` integer NULL,
  PRIMARY KEY (`id`),
  UNIQUE `language_group_name_unique` (`name`)
) ENGINE=InnoDB;
--
-- Table: `languages`
--
CREATE TABLE `languages` (
  `id` integer NOT NULL auto_increment,
  `language_group_id` integer NULL,
  `code` varchar(10) NOT NULL,
  `name` varchar(120) NOT NULL,
  `position` integer NULL,
  INDEX `languages_idx_language_group_id` (`language_group_id`),
  PRIMARY KEY (`id`),
  UNIQUE `language_code_unique` (`code`),
  CONSTRAINT `languages_fk_language_group_id` FOREIGN KEY (`language_group_id`) REFERENCES `language_groups` (`id`)
) ENGINE=InnoDB;
--
-- Table: `servers`
--
CREATE TABLE `servers` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(120) NOT NULL,
  `host` varchar(120) NOT NULL,
  `port` integer NOT NULL,
  `username` varchar(120) NULL,
  `password` varchar(120) NULL,
  PRIMARY KEY (`id`),
  UNIQUE `server_name_unique` (`name`)
) ENGINE=InnoDB;
--
-- Table: `tags`
--
CREATE TABLE `tags` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(120) NOT NULL,
  `comment` varchar(250) NULL,
  PRIMARY KEY (`id`),
  UNIQUE `tag_name_unique` (`name`)
) ENGINE=InnoDB;
--
-- Table: `users`
--
CREATE TABLE `users` (
  `id` integer NOT NULL auto_increment,
  `persistent_token` varchar(250) NULL,
  `organization` varchar(250) NULL,
  `provider` varchar(250) NULL,
  `name` varchar(120) NULL,
  `username` varchar(120) NULL,
  `email` varchar(120) NULL,
  `password` varchar(60) NULL,
  `access_all` enum('0','1') NOT NULL DEFAULT '0',
  `is_admin` enum('0','1') NOT NULL DEFAULT '0',
  `is_active` enum('0','1') NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `last_login` datetime NULL,
  INDEX `idx_name` (`username`),
  INDEX `idx_external` (`persistent_token`, `organization`, `provider`),
  PRIMARY KEY (`id`),
  UNIQUE `user_username_unique` (`name`)
) ENGINE=InnoDB;
--
-- Table: `query_files`
--
CREATE TABLE `query_files` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(120) NOT NULL,
  `user_id` integer NULL,
  `created_at` datetime NOT NULL,
  `last_use` datetime NOT NULL,
  INDEX `query_files_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  UNIQUE `query_file_name_unique` (`name`, `user_id`),
  CONSTRAINT `query_files_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
--
-- Table: `treebanks`
--
CREATE TABLE `treebanks` (
  `id` integer NOT NULL auto_increment,
  `server_id` integer NOT NULL,
  `database` varchar(120) NOT NULL,
  `name` varchar(120) NOT NULL,
  `title` varchar(250) NOT NULL,
  `homepage` varchar(250) NULL,
  `handle` varchar(250) NULL,
  `description` text NULL,
  `is_public` enum('0','1') NOT NULL DEFAULT '1',
  `is_free` enum('0','1') NOT NULL DEFAULT '0',
  `is_all_logged` enum('0','1') NOT NULL DEFAULT '1',
  `is_featured` enum('0','1') NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `last_modified` datetime NOT NULL,
  INDEX `treebanks_idx_server_id` (`server_id`),
  PRIMARY KEY (`id`),
  UNIQUE `treebank_name_unique` (`name`),
  CONSTRAINT `treebanks_fk_server_id` FOREIGN KEY (`server_id`) REFERENCES `servers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
--
-- Table: `data_sources`
--
CREATE TABLE `data_sources` (
  `treebank_id` integer NOT NULL,
  `layer` varchar(250) NOT NULL,
  `path` varchar(250) NOT NULL,
  INDEX `data_sources_idx_treebank_id` (`treebank_id`),
  PRIMARY KEY (`treebank_id`, `layer`),
  CONSTRAINT `data_sources_fk_treebank_id` FOREIGN KEY (`treebank_id`) REFERENCES `treebanks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `manuals`
--
CREATE TABLE `manuals` (
  `treebank_id` integer NOT NULL,
  `title` varchar(250) NOT NULL,
  `url` varchar(250) NOT NULL,
  INDEX `manuals_idx_treebank_id` (`treebank_id`),
  PRIMARY KEY (`treebank_id`, `title`, `url`),
  CONSTRAINT `manuals_fk_treebank_id` FOREIGN KEY (`treebank_id`) REFERENCES `treebanks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `query_records`
--
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
--
-- Table: `user_tags`
--
CREATE TABLE `user_tags` (
  `user_id` integer NOT NULL,
  `tag_id` integer NOT NULL,
  INDEX `user_tags_idx_tag_id` (`tag_id`),
  INDEX `user_tags_idx_user_id` (`user_id`),
  PRIMARY KEY (`user_id`, `tag_id`),
  CONSTRAINT `user_tags_fk_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`),
  CONSTRAINT `user_tags_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
--
-- Table: `treebank_languages`
--
CREATE TABLE `treebank_languages` (
  `treebank_id` integer NOT NULL,
  `language_id` integer NOT NULL,
  INDEX `treebank_languages_idx_language_id` (`language_id`),
  INDEX `treebank_languages_idx_treebank_id` (`treebank_id`),
  PRIMARY KEY (`treebank_id`, `language_id`),
  CONSTRAINT `treebank_languages_fk_language_id` FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `treebank_languages_fk_treebank_id` FOREIGN KEY (`treebank_id`) REFERENCES `treebanks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `treebank_tags`
--
CREATE TABLE `treebank_tags` (
  `treebank_id` integer NOT NULL,
  `tag_id` integer NOT NULL,
  INDEX `treebank_tags_idx_tag_id` (`tag_id`),
  INDEX `treebank_tags_idx_treebank_id` (`treebank_id`),
  PRIMARY KEY (`treebank_id`, `tag_id`),
  CONSTRAINT `treebank_tags_fk_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE,
  CONSTRAINT `treebank_tags_fk_treebank_id` FOREIGN KEY (`treebank_id`) REFERENCES `treebanks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `user_treebanks`
--
CREATE TABLE `user_treebanks` (
  `user_id` integer NOT NULL,
  `treebank_id` integer NOT NULL,
  INDEX `user_treebanks_idx_treebank_id` (`treebank_id`),
  INDEX `user_treebanks_idx_user_id` (`user_id`),
  PRIMARY KEY (`user_id`, `treebank_id`),
  CONSTRAINT `user_treebanks_fk_treebank_id` FOREIGN KEY (`treebank_id`) REFERENCES `treebanks` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_treebanks_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
SET foreign_key_checks=1;
