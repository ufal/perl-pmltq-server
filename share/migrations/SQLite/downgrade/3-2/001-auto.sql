-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/3/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
DROP INDEX languages_fk_language_group_id;

;

;
CREATE TEMPORARY TABLE treebanks_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  server_id integer NOT NULL,
  database varchar(120) NOT NULL,
  name varchar(120) NOT NULL,
  title varchar(250) NOT NULL,
  homepage varchar(250),
  handle varchar(250),
  description text,
  is_public boolean NOT NULL DEFAULT 1,
  is_free boolean NOT NULL DEFAULT 0,
  is_featured boolean NOT NULL DEFAULT 0,
  created_at datetime NOT NULL,
  last_modified datetime NOT NULL,
  FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE
);

;
INSERT INTO treebanks_temp_alter( id, server_id, database, name, title, homepage, handle, description, is_public, is_free, is_featured, created_at, last_modified) SELECT id, server_id, database, name, title, homepage, handle, description, is_public, is_free, is_featured, created_at, last_modified FROM treebanks;

;
DROP TABLE treebanks;

;
CREATE TABLE treebanks (
  id INTEGER PRIMARY KEY NOT NULL,
  server_id integer NOT NULL,
  database varchar(120) NOT NULL,
  name varchar(120) NOT NULL,
  title varchar(250) NOT NULL,
  homepage varchar(250),
  handle varchar(250),
  description text,
  is_public boolean NOT NULL DEFAULT 1,
  is_free boolean NOT NULL DEFAULT 0,
  is_featured boolean NOT NULL DEFAULT 0,
  created_at datetime NOT NULL,
  last_modified datetime NOT NULL,
  FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE
);

;
CREATE INDEX treebanks_idx_server_id02 ON treebanks (server_id);

;
CREATE UNIQUE INDEX treebank_name_unique02 ON treebanks (name);

;
INSERT INTO treebanks SELECT id, server_id, database, name, title, homepage, handle, description, is_public, is_free, is_featured, created_at, last_modified FROM treebanks_temp_alter;

;
DROP TABLE treebanks_temp_alter;

;
DROP TABLE user_tags;

;

COMMIT;

