-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/7/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE query_record_treebanks (
  query_record_id integer NOT NULL,
  treebank_id integer NOT NULL,
  PRIMARY KEY (query_record_id, treebank_id),
  FOREIGN KEY (query_record_id) REFERENCES query_records(id) ON DELETE CASCADE,
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX query_record_treebanks_idx_query_record_id ON query_record_treebanks (query_record_id);

;
CREATE INDEX query_record_treebanks_idx_treebank_id ON query_record_treebanks (treebank_id);

;
CREATE TEMPORARY TABLE query_records_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120),
  query text,
  user_id integer NOT NULL,
  query_file_id integer,
  is_public boolean NOT NULL DEFAULT 0,
  description text,
  ord integer DEFAULT 0,
  eval_num integer DEFAULT 0,
  created_at datetime NOT NULL,
  last_use datetime NOT NULL,
  hash char(32),
  FOREIGN KEY (query_file_id) REFERENCES query_files(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
INSERT INTO query_records_temp_alter( id, name, query, user_id, query_file_id, is_public, description, ord, eval_num, created_at, last_use, hash) SELECT id, name, query, user_id, query_file_id, is_public, description, ord, eval_num, created_at, last_use, hash FROM query_records;

;
DROP TABLE query_records;

;
CREATE TABLE query_records (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120),
  query text,
  user_id integer NOT NULL,
  query_file_id integer,
  is_public boolean NOT NULL DEFAULT 0,
  description text,
  ord integer DEFAULT 0,
  eval_num integer DEFAULT 0,
  created_at datetime NOT NULL,
  last_use datetime NOT NULL,
  hash char(32),
  FOREIGN KEY (query_file_id) REFERENCES query_files(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX query_records_idx_query_fil00 ON query_records (query_file_id);

;
CREATE INDEX query_records_idx_user_id02 ON query_records (user_id);

;
INSERT INTO query_records SELECT id, name, query, user_id, query_file_id, is_public, description, ord, eval_num, created_at, last_use, hash FROM query_records_temp_alter;

;
DROP TABLE query_records_temp_alter;

;

COMMIT;

