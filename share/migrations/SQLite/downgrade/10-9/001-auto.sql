-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/10/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE data_sources_temp_alter (
  treebank_id integer NOT NULL,
  layer varchar(250) NOT NULL,
  path varchar(250) NOT NULL,
  PRIMARY KEY (treebank_id, layer),
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO data_sources_temp_alter( treebank_id, layer, path) SELECT treebank_id, layer, path FROM data_sources;

;
DROP TABLE data_sources;

;
CREATE TABLE data_sources (
  treebank_id integer NOT NULL,
  layer varchar(250) NOT NULL,
  path varchar(250) NOT NULL,
  PRIMARY KEY (treebank_id, layer),
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX data_sources_idx_treebank_id02 ON data_sources (treebank_id);

;
INSERT INTO data_sources SELECT treebank_id, layer, path FROM data_sources_temp_alter;

;
DROP TABLE data_sources_temp_alter;

;

COMMIT;

