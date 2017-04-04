-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE query_files_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120) NOT NULL,
  user_id integer,
  created_at datetime NOT NULL,
  last_use datetime NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
INSERT INTO query_files_temp_alter( id, name, user_id, created_at, last_use) SELECT id, name, user_id, created_at, last_use FROM query_files;

;
DROP TABLE query_files;

;
CREATE TABLE query_files (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120) NOT NULL,
  user_id integer,
  created_at datetime NOT NULL,
  last_use datetime NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX query_files_idx_user_id02 ON query_files (user_id);

;
CREATE UNIQUE INDEX query_file_name_unique02 ON query_files (name, user_id);

;
INSERT INTO query_files SELECT id, name, user_id, created_at, last_use FROM query_files_temp_alter;

;
DROP TABLE query_files_temp_alter;

;
CREATE TEMPORARY TABLE query_records_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120),
  query text,
  user_id integer NOT NULL,
  query_file_id integer,
  created_at datetime NOT NULL,
  last_use datetime NOT NULL,
  FOREIGN KEY (query_file_id) REFERENCES query_files(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
INSERT INTO query_records_temp_alter( id, name, query, user_id, query_file_id, created_at, last_use) SELECT id, name, query, user_id, query_file_id, created_at, last_use FROM query_records;

;
DROP TABLE query_records;

;
CREATE TABLE query_records (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120),
  query text,
  user_id integer NOT NULL,
  query_file_id integer,
  created_at datetime NOT NULL,
  last_use datetime NOT NULL,
  FOREIGN KEY (query_file_id) REFERENCES query_files(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX query_records_idx_query_fil00 ON query_records (query_file_id);

;
CREATE INDEX query_records_idx_user_id02 ON query_records (user_id);

;
INSERT INTO query_records SELECT id, name, query, user_id, query_file_id, created_at, last_use FROM query_records_temp_alter;

;
DROP TABLE query_records_temp_alter;

;

COMMIT;

