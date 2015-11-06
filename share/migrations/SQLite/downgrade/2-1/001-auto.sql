-- Convert schema '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/2/001-auto.yml' to '/home/m1ch4ls/work/perl-pmltq-server/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE queries (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120),
  text varchar(120) NOT NULL,
  user_id integer NOT NULL,
  query_file_id integer,
  created_at datetime NOT NULL,
  last_use datetime NOT NULL,
  FOREIGN KEY (query_file_id) REFERENCES query_files(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

;
CREATE INDEX queries_idx_query_file_id ON queries (query_file_id);

;
CREATE INDEX queries_idx_user_id ON queries (user_id);

;
DROP TABLE query_records;

;

COMMIT;

