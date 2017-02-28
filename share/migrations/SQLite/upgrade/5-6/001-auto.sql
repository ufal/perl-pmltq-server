-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/5/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE treebank_provider_ids (
  treebank_id integer NOT NULL,
  provider integer NOT NULL,
  provider_id varchar(120) NOT NULL,
  PRIMARY KEY (treebank_id, provider, provider_id),
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX treebank_provider_ids_idx_treebank_id ON treebank_provider_ids (treebank_id);

;

COMMIT;

