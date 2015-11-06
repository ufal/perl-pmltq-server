-- Convert schema '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/1/001-auto.yml' to '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE query_records (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120),
  query text NOT NULL,
  user_id integer NOT NULL,
  query_file_id integer,
  created_at datetime NOT NULL,
  last_use datetime NOT NULL,
  FOREIGN KEY (query_file_id) REFERENCES query_files(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX query_records_idx_query_file_id ON query_records (query_file_id);

;
CREATE INDEX query_records_idx_user_id ON query_records (user_id);

;
DROP TABLE queries;

;

COMMIT;

