-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/5/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE tags_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120) NOT NULL,
  comment varchar(250)
);

;
INSERT INTO tags_temp_alter( id, name, comment) SELECT id, name, comment FROM tags;

;
DROP TABLE tags;

;
CREATE TABLE tags (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120) NOT NULL,
  comment varchar(250)
);

;
CREATE UNIQUE INDEX tag_name_unique02 ON tags (name);

;
INSERT INTO tags SELECT id, name, comment FROM tags_temp_alter;

;
DROP TABLE tags_temp_alter;

;

COMMIT;

