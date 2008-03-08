-- description: bibliographic schema for PostgreSQL
-- license: LGPL
-- copyright: Bruce D'Arcus, 2006

-- TODO: foreign-key constraints, rethink contributors-names, finish reftype and role table content

-- ===========================================================

-- reference_items are citable content, and include both parts (articles) and monographs (books)

CREATE TABLE "reference_items" (
  "id" SERIAL PRIMARY KEY,
  "reference_type_id" INTEGER, -- REFERENCES reference_types,
  "title" VARCHAR(255),
  "year" INTEGER, -- need better DATE handling
  "description" TEXT,
  "abstract" TEXT,
  "container_id" INTEGER, -- REFERENCES reference_items, 
  "collection_id" INTEGER, -- REFERENCES collections,
  "original_id" INTEGER, -- REFERENCES reference_items,
  "event_id" INTEGER -- REFERENCES events
  );

CREATE TABLE "reference_types" (
  "id" INTEGER PRIMARY KEY,
  "name" VARCHAR(25)
  );

-- this list needs to be expanded

INSERT INTO reference_types VALUES (1, 'Article');
INSERT INTO reference_types VALUES (2, 'Book');
INSERT INTO reference_types VALUES (3, 'Chapter');
INSERT INTO reference_types VALUES (4, 'EditedBook');
INSERT INTO reference_types VALUES (5, 'LegalCase');
INSERT INTO reference_types VALUES (6, 'Manuscript');
INSERT INTO reference_types VALUES (7, 'Report');

-- collections are non-citable related items such as periodicals and archival collections

CREATE TABLE "collections" (
  "id" SERIAL PRIMARY KEY,
  "collection_type_id" INTEGER,
  "title" VARCHAR(255),
  "short_title" VARCHAR(255),
  "description" TEXT
  );

CREATE TABLE "collection_types" (
  "id" INTEGER PRIMARY KEY,
  "name" VARCHAR(25)
  );

INSERT INTO collection_types VALUES (1, 'Collection');
INSERT INTO collection_types VALUES (2, 'Periodical');
INSERT INTO collection_types VALUES (3, 'Journal');
INSERT INTO collection_types VALUES (4, 'Series');

-- ===========================================================

-- contributors stores all people and organizations (including publishers, event sponsors, etc.)

CREATE TABLE "contributors" (
  "id" SERIAL PRIMARY KEY,
  "organization" BOOLEAN default '0',
  "display_name" VARCHAR(255),
  "sort_name" VARCHAR(255), 
  "description" TEXT
  );

-- joins contributors to reference_items

CREATE TABLE "contributions" (
  "reference_item_id" INTEGER, -- REFERENCES reference_item,
  "contributor_id" INTEGER, -- REFERENCES contributors,
  "position" INTEGER,
  "role_id" INTEGER default '1' -- REFERENCES roles
  );

CREATE TABLE "roles" (
  "id" INTEGER PRIMARY KEY,
  "name" VARCHAR(15)
  );

INSERT INTO roles VALUES (1, 'author');
INSERT INTO roles VALUES (2, 'editor');
INSERT INTO roles VALUES (3, 'translator');
INSERT INTO roles VALUES (4, 'publisher');

-- in order to track in particular changed names, we have a separate table

CREATE TABLE "names" (
  "contributor_id" INTEGER, -- REFERENCES contributors,
  "givenname" VARCHAR(50),
  "familyname" VARCHAR(50),
  "articular" VARCHAR(50),
  "prefix" VARCHAR(50),
  "suffix" VARCHAR(50),
  "preferred" BOOLEAN default '1',
  "language" VARCHAR(5),
  "valid" INTEGER
  );

-- ===========================================================

CREATE TABLE "events" (
  "id" SERIAL PRIMARY KEY,
  "event_type_id" INTEGER, -- REFERENCES events,
  "name" VARCHAR(255),
  "sponsor_id" INTEGER, -- REFERENCES contributors,
  "begin_date" DATE,
  "end_date" DATE,
  "other_date" VARCHAR(50)
  );

CREATE TABLE "event_types" (
  "id" INTEGER PRIMARY KEY,
  "name" VARCHAR(15)
  );

INSERT INTO event_types VALUES (1, 'Conference');
INSERT INTO event_types VALUES (2, 'Hearing');
INSERT INTO event_types VALUES (3, 'Workshop');

-- ===========================================================

CREATE TABLE "locators" (
  "reference_item_id" INTEGER, -- REFERENCES reference_item,
  "content" VARCHAR(10),
  "locator_type_id" INTEGER, -- REFERENCES locator_types,
  "last_accessed" DATE
  );

CREATE TABLE "locator_types" (
  "id" INTEGER PRIMARY KEY,
  "name" VARCHAR(15)
  );

INSERT INTO locator_types VALUES (1, 'volume');
INSERT INTO locator_types VALUES (2, 'issue');
INSERT INTO locator_types VALUES (3, 'document');
INSERT INTO locator_types VALUES (4, 'pages');
INSERT INTO locator_types VALUES (5, 'box');
INSERT INTO locator_types VALUES (6, 'folder');
INSERT INTO locator_types VALUES (7, 'url');

CREATE TABLE "identifiers" (
  "reference_item_id" INTEGER, -- REFERENCES reference_item,
  "content" VARCHAR(10),
  "identifier_type_id" INTEGER -- REFERENCES identifier_types
  );

CREATE TABLE "identifier_types" (
  "id" INTEGER PRIMARY KEY,
  "name" VARCHAR(15)
  );

INSERT INTO identifier_types VALUES (1, 'isbn');
INSERT INTO identifier_types VALUES (2, 'doi');
INSERT INTO identifier_types VALUES (3, 'sici');
INSERT INTO identifier_types VALUES (4, 'lccn');
INSERT INTO identifier_types VALUES (5, 'pmid');

-- ===========================================================

CREATE TABLE "annotations" (
  "id" SERIAL PRIMARY KEY,
  "user_id" INTEGER,
  "content" TEXT
  );

CREATE TABLE "annotations_reference_items" (
  "reference_item_id" INTEGER,
  "annotation_id" INTEGER
  );

-- ===========================================================

-- for use with new acts_as_taggable in Rails 1.1

CREATE TABLE "tags" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(50)
  );


CREATE TABLE "taggings" (
  "taggable_id" INTEGER,
  "tag_id" INTEGER,
  "taggable_type" VARCHAR(25)
  );

-- ===========================================================

-- how to deal with multi-user access?

CREATE TABLE users (
  "id" SERIAL PRIMARY KEY,
  "nick" VARCHAR NOT NULL,
  "name" VARCHAR,
  "password" VARCHAR NOT NULL,
  "modified" TIMESTAMP with time zone NOT NULL,
  "created" TIMESTAMP with time zone NOT NULL,
  "access" TIMESTAMP with time zone
  );

-- for those applications that want to integrate feed reading as part of reference management

CREATE TABLE "feeds" (
  "id" SERIAL PRIMARY KEY,
  "url" VARCHAR(255),
  "title" VARCHAR(255),
  "link" VARCHAR(255),
  "feed_data" TEXT,
  "feed_data_type" VARCHAR(20),
  "http_headers" TEXT,
  "last_retrieved" DATETIME
  );
