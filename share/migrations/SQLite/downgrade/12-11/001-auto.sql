-- Convert schema '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/12/001-auto.yml' to '/home/matyas/Documents/UFAL/REP/perl-pmltq-server/script/../share/migrations/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE users_temp_alter (
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

;
INSERT INTO users_temp_alter( id, persistent_token, organization, provider, name, username, email, password, access_all, is_admin, is_active, valid_until, created_at, last_login) SELECT id, persistent_token, organization, provider, name, username, email, password, access_all, is_admin, is_active, valid_until, created_at, last_login FROM users;

;
DROP TABLE users;

;
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

;
CREATE INDEX idx_name02 ON users (username);

;
CREATE INDEX idx_external02 ON users (persistent_token, organization, provider);

;
CREATE UNIQUE INDEX user_username_unique02 ON users (name);

;
INSERT INTO users SELECT id, persistent_token, organization, provider, name, username, email, password, access_all, is_admin, is_active, valid_until, created_at, last_login FROM users_temp_alter;

;
DROP TABLE users_temp_alter;

;

COMMIT;

