-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Jan 22 16:32:39 2020
-- 

;
BEGIN TRANSACTION;
--
-- Table: language_groups
--
CREATE TABLE language_groups (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(200) NOT NULL,
  position integer
);
CREATE UNIQUE INDEX language_group_name_unique ON language_groups (name);
--
-- Table: languages
--
CREATE TABLE languages (
  id INTEGER PRIMARY KEY NOT NULL,
  language_group_id integer,
  code varchar(10) NOT NULL,
  name varchar(120) NOT NULL,
  position integer,
  FOREIGN KEY (language_group_id) REFERENCES language_groups(id)
);
CREATE INDEX languages_idx_language_group_id ON languages (language_group_id);
CREATE UNIQUE INDEX language_code_unique ON languages (code);
--
-- Table: servers
--
CREATE TABLE servers (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120) NOT NULL,
  host varchar(120) NOT NULL,
  port integer NOT NULL,
  username varchar(120),
  password varchar(120)
);
CREATE UNIQUE INDEX server_name_unique ON servers (name);
--
-- Table: tags
--
CREATE TABLE tags (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120) NOT NULL,
  comment varchar(250),
  documentation text
);
CREATE UNIQUE INDEX tag_name_unique ON tags (name);
--
-- Table: users
--
CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  persistent_token varchar(250),
  organization varchar(250),
  provider varchar(250),
  name varchar(120),
  username varchar(120),
  email varchar(120),
  password varchar(60),
  access_all boolean NOT NULL DEFAULT 0,
  is_admin boolean NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT 0,
  valid_until datetime,
  created_at datetime NOT NULL,
  last_login datetime
);
CREATE INDEX idx_name ON users (username);
CREATE INDEX idx_external ON users (persistent_token, organization, provider);
CREATE UNIQUE INDEX user_username_unique ON users (name);
--
-- Table: query_files
--
CREATE TABLE query_files (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(120) NOT NULL,
  user_id integer,
  is_public boolean NOT NULL DEFAULT 0,
  description text,
  created_at datetime NOT NULL,
  last_use datetime NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX query_files_idx_user_id ON query_files (user_id);
CREATE UNIQUE INDEX query_file_name_unique ON query_files (name, user_id);
--
-- Table: treebanks
--
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
  is_all_logged boolean NOT NULL DEFAULT 1,
  is_featured boolean NOT NULL DEFAULT 0,
  created_at datetime NOT NULL,
  last_modified datetime NOT NULL,
  documentation text,
  metadata text,
  FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE
);
CREATE INDEX treebanks_idx_server_id ON treebanks (server_id);
CREATE UNIQUE INDEX treebank_name_unique ON treebanks (name);
--
-- Table: data_sources
--
CREATE TABLE data_sources (
  treebank_id integer NOT NULL,
  layer varchar(250) NOT NULL,
  path varchar(250) NOT NULL,
  svg varchar(250),
  PRIMARY KEY (treebank_id, layer),
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX data_sources_idx_treebank_id ON data_sources (treebank_id);
--
-- Table: manuals
--
CREATE TABLE manuals (
  treebank_id integer NOT NULL,
  title varchar(250) NOT NULL,
  url varchar(250) NOT NULL,
  PRIMARY KEY (treebank_id, title, url),
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX manuals_idx_treebank_id ON manuals (treebank_id);
--
-- Table: query_records
--
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
CREATE INDEX query_records_idx_query_file_id ON query_records (query_file_id);
CREATE INDEX query_records_idx_user_id ON query_records (user_id);
--
-- Table: treebank_provider_ids
--
CREATE TABLE treebank_provider_ids (
  treebank_id integer NOT NULL,
  provider varchar(250) NOT NULL,
  provider_id varchar(120) NOT NULL,
  PRIMARY KEY (treebank_id, provider, provider_id),
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX treebank_provider_ids_idx_treebank_id ON treebank_provider_ids (treebank_id);
--
-- Table: user_tags
--
CREATE TABLE user_tags (
  user_id integer NOT NULL,
  tag_id integer NOT NULL,
  PRIMARY KEY (user_id, tag_id),
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX user_tags_idx_tag_id ON user_tags (tag_id);
CREATE INDEX user_tags_idx_user_id ON user_tags (user_id);
--
-- Table: treebank_languages
--
CREATE TABLE treebank_languages (
  treebank_id integer NOT NULL,
  language_id integer NOT NULL,
  PRIMARY KEY (treebank_id, language_id),
  FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX treebank_languages_idx_language_id ON treebank_languages (language_id);
CREATE INDEX treebank_languages_idx_treebank_id ON treebank_languages (treebank_id);
--
-- Table: treebank_tags
--
CREATE TABLE treebank_tags (
  treebank_id integer NOT NULL,
  tag_id integer NOT NULL,
  PRIMARY KEY (treebank_id, tag_id),
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX treebank_tags_idx_tag_id ON treebank_tags (tag_id);
CREATE INDEX treebank_tags_idx_treebank_id ON treebank_tags (treebank_id);
--
-- Table: user_treebanks
--
CREATE TABLE user_treebanks (
  user_id integer NOT NULL,
  treebank_id integer NOT NULL,
  PRIMARY KEY (user_id, treebank_id),
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX user_treebanks_idx_treebank_id ON user_treebanks (treebank_id);
CREATE INDEX user_treebanks_idx_user_id ON user_treebanks (user_id);
--
-- Table: query_record_treebanks
--
CREATE TABLE query_record_treebanks (
  query_record_id integer NOT NULL,
  treebank_id integer NOT NULL,
  PRIMARY KEY (query_record_id, treebank_id),
  FOREIGN KEY (query_record_id) REFERENCES query_records(id) ON DELETE CASCADE,
  FOREIGN KEY (treebank_id) REFERENCES treebanks(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX query_record_treebanks_idx_query_record_id ON query_record_treebanks (query_record_id);
CREATE INDEX query_record_treebanks_idx_treebank_id ON query_record_treebanks (treebank_id);
COMMIT;
