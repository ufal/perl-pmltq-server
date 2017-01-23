-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Thu Dec 17 14:03:25 2015
-- 
;
--
-- Table: language_groups
--
CREATE TABLE "language_groups" (
  "id" serial NOT NULL,
  "name" character varying(200) NOT NULL,
  "position" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT "language_group_name_unique" UNIQUE ("name")
);

;
--
-- Table: languages
--
CREATE TABLE "languages" (
  "id" serial NOT NULL,
  "language_group_id" integer,
  "code" character varying(10) NOT NULL,
  "name" character varying(120) NOT NULL,
  "position" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT "language_code_unique" UNIQUE ("code")
);
CREATE INDEX "languages_idx_language_group_id" on "languages" ("language_group_id");

;
--
-- Table: servers
--
CREATE TABLE "servers" (
  "id" serial NOT NULL,
  "name" character varying(120) NOT NULL,
  "host" character varying(120) NOT NULL,
  "port" integer NOT NULL,
  "username" character varying(120),
  "password" character varying(120),
  PRIMARY KEY ("id"),
  CONSTRAINT "server_name_unique" UNIQUE ("name")
);

;
--
-- Table: tags
--
CREATE TABLE "tags" (
  "id" serial NOT NULL,
  "name" character varying(120) NOT NULL,
  "comment" character varying(250),
  PRIMARY KEY ("id"),
  CONSTRAINT "tag_name_unique" UNIQUE ("name")
);

;
--
-- Table: users
--
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "persistent_token" character varying(250),
  "organization" character varying(250),
  "provider" character varying(250),
  "name" character varying(120),
  "username" character varying(120),
  "email" character varying(120),
  "password" character varying(60),
  "access_all" boolean DEFAULT '0' NOT NULL,
  "is_admin" boolean DEFAULT '0' NOT NULL,
  "is_active" boolean DEFAULT '0' NOT NULL,
  "created_at" timestamp NOT NULL,
  "last_login" timestamp,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_username_unique" UNIQUE ("name")
);
CREATE INDEX "idx_name" on "users" ("username");
CREATE INDEX "idx_external" on "users" ("persistent_token", "organization", "provider");

;
--
-- Table: query_files
--
CREATE TABLE "query_files" (
  "id" serial NOT NULL,
  "name" character varying(120) NOT NULL,
  "user_id" integer,
  "created_at" timestamp NOT NULL,
  "last_use" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "query_file_name_unique" UNIQUE ("name", "user_id")
);
CREATE INDEX "query_files_idx_user_id" on "query_files" ("user_id");

;
--
-- Table: treebanks
--
CREATE TABLE "treebanks" (
  "id" serial NOT NULL,
  "server_id" integer NOT NULL,
  "database" character varying(120) NOT NULL,
  "name" character varying(120) NOT NULL,
  "title" character varying(250) NOT NULL,
  "homepage" character varying(250),
  "handle" character varying(250),
  "description" text,
  "is_public" boolean DEFAULT '1' NOT NULL,
  "is_free" boolean DEFAULT '0' NOT NULL,
  "is_featured" boolean DEFAULT '0' NOT NULL,
  "created_at" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "treebank_name_unique" UNIQUE ("name")
);
CREATE INDEX "treebanks_idx_server_id" on "treebanks" ("server_id");

;
--
-- Table: data_sources
--
CREATE TABLE "data_sources" (
  "treebank_id" integer NOT NULL,
  "layer" character varying(250) NOT NULL,
  "path" character varying(250) NOT NULL,
  PRIMARY KEY ("treebank_id", "layer")
);
CREATE INDEX "data_sources_idx_treebank_id" on "data_sources" ("treebank_id");

;
--
-- Table: manuals
--
CREATE TABLE "manuals" (
  "treebank_id" integer NOT NULL,
  "title" character varying(250) NOT NULL,
  "url" character varying(250) NOT NULL,
  PRIMARY KEY ("treebank_id", "title", "url")
);
CREATE INDEX "manuals_idx_treebank_id" on "manuals" ("treebank_id");

;
--
-- Table: query_records
--
CREATE TABLE "query_records" (
  "id" serial NOT NULL,
  "name" character varying(120),
  "query" text,
  "user_id" integer NOT NULL,
  "query_file_id" integer,
  "created_at" timestamp NOT NULL,
  "last_use" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "query_records_idx_query_file_id" on "query_records" ("query_file_id");
CREATE INDEX "query_records_idx_user_id" on "query_records" ("user_id");

;
--
-- Table: treebank_languages
--
CREATE TABLE "treebank_languages" (
  "treebank_id" integer NOT NULL,
  "language_id" integer NOT NULL,
  PRIMARY KEY ("treebank_id", "language_id")
);
CREATE INDEX "treebank_languages_idx_language_id" on "treebank_languages" ("language_id");
CREATE INDEX "treebank_languages_idx_treebank_id" on "treebank_languages" ("treebank_id");

;
--
-- Table: treebank_tags
--
CREATE TABLE "treebank_tags" (
  "treebank_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY ("treebank_id", "tag_id")
);
CREATE INDEX "treebank_tags_idx_tag_id" on "treebank_tags" ("tag_id");
CREATE INDEX "treebank_tags_idx_treebank_id" on "treebank_tags" ("treebank_id");

;
--
-- Table: user_treebanks
--
CREATE TABLE "user_treebanks" (
  "user_id" integer NOT NULL,
  "treebank_id" integer NOT NULL,
  PRIMARY KEY ("user_id", "treebank_id")
);
CREATE INDEX "user_treebanks_idx_treebank_id" on "user_treebanks" ("treebank_id");
CREATE INDEX "user_treebanks_idx_user_id" on "user_treebanks" ("user_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "languages" ADD CONSTRAINT "languages_fk_language_group_id" FOREIGN KEY ("language_group_id")
  REFERENCES "language_groups" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "query_files" ADD CONSTRAINT "query_files_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "treebanks" ADD CONSTRAINT "treebanks_fk_server_id" FOREIGN KEY ("server_id")
  REFERENCES "servers" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "data_sources" ADD CONSTRAINT "data_sources_fk_treebank_id" FOREIGN KEY ("treebank_id")
  REFERENCES "treebanks" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "manuals" ADD CONSTRAINT "manuals_fk_treebank_id" FOREIGN KEY ("treebank_id")
  REFERENCES "treebanks" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "query_records" ADD CONSTRAINT "query_records_fk_query_file_id" FOREIGN KEY ("query_file_id")
  REFERENCES "query_files" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "query_records" ADD CONSTRAINT "query_records_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "treebank_languages" ADD CONSTRAINT "treebank_languages_fk_language_id" FOREIGN KEY ("language_id")
  REFERENCES "languages" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "treebank_languages" ADD CONSTRAINT "treebank_languages_fk_treebank_id" FOREIGN KEY ("treebank_id")
  REFERENCES "treebanks" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "treebank_tags" ADD CONSTRAINT "treebank_tags_fk_tag_id" FOREIGN KEY ("tag_id")
  REFERENCES "tags" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "treebank_tags" ADD CONSTRAINT "treebank_tags_fk_treebank_id" FOREIGN KEY ("treebank_id")
  REFERENCES "treebanks" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_treebanks" ADD CONSTRAINT "user_treebanks_fk_treebank_id" FOREIGN KEY ("treebank_id")
  REFERENCES "treebanks" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "user_treebanks" ADD CONSTRAINT "user_treebanks_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE DEFERRABLE;

;
