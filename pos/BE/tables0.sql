-- generic tbles
-- mfotang, Wed Sep 18 17:28:19 WAT 2013
-- revision, Fri Dec 25 07:40:06 WAT 2015
-- revision, Fri Jan 15 19:41:17 WAT 2016:
--  - userLogins: make connectionId primary key
-- revision, Thu Feb 25 20:36:15 WAT 2016
--	- save orgId in audit log
-- MySQL Port
-- -------------------------
-- ported to MySQL, Sun Oct 23 21:37:16 WAT 2016


DELIMITER ;

drop table if exists VARIABLES;
create table VARIABLES(name varchar(64) not null primary key, value varchar(512));

drop table if exists status_types;
create table status_types(status_id varchar(8) not null primary key,
	descr varchar(64) not null, sort int not null default 99999);

drop table if exists audit_logs;
create table audit_logs(
	topic varchar(32) not null -- what was changed, e.g. loan, account,...
	, aktion varchar(32) not null -- the change event, e.g. update, insert,
	, connId varchar(128) not null	-- actor
	, orgId integer null
	, details varchar(1024) not null
	, final int not null default 0-- 0 => request to change data; 1=>request successful
	, theTime timestamp not null
) ENGINE = MyISAM; /* so that inserts are atomic*/

drop table if exists MachineIDTypes;
CREATE TABLE MachineIDTypes (
	Code VARCHAR(5) NOT NULL PRIMARY KEY,
	Description VARCHAR(64));

drop table if exists Roles;
CREATE TABLE Roles (
	roleId  integer auto_increment not null primary key, 
	orgId integer not null, -- set constraint after creating organisation table
	roleName VARCHAR(64) NOT NULL,
	Description VARCHAR(255) NOT NULL,
	sort int not null default 99999, -- sort column
	constraint uniq_roleName unique(roleName, orgId));

drop table if exists PermissionTypes;
CREATE TABLE PermissionTypes (
	mode VARCHAR(32) NOT NULL PRIMARY KEY,
	description VARCHAR(255) NOT NULL,
	sort int not null default 99999);

drop table if exists PermissionTypesX;
CREATE TABLE PermissionTypesX (
	ptype VARCHAR(32) NOT NULL PRIMARY KEY,
	constraint foreign key(ptype) references PermissionTypes(mode) on delete cascade);


-- roles that contain other roles
drop table if exists RolePermissions;
CREATE TABLE RolePermissions (
	ownerRoleId int NOT NULL, -- the super role
	roleId int NOT NULL, -- the role that is inclued in owner
	sort int not null default 99999, -- sort column
	PRIMARY KEY(roleId,ownerRoleId),
	constraint check_roleId check(ownerRoleId<>roleId),
	constraint FOREIGN KEY(ownerRoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE,
	constraint FOREIGN KEY(RoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE);



-- user permissions
drop table if exists Permissions;
CREATE TABLE Permissions (
	mode VARCHAR(32) NOT NULL,
	roleId int NOT NULL,
	sort int not null default 99999, -- sort column
	PRIMARY KEY(roleId,mode),
	constraint FOREIGN KEY(mode) REFERENCES PermissionTypes(mode) ON DELETE CASCADE,
	constraint FOREIGN KEY(RoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE);

drop table if exists maritalstatus_types;
CREATE TABLE maritalstatus_types(
	marit_satus CHAR(1) NOT NULL primary key,
	descr VARCHAR(32) NOT NULL, sort int not null default 99999);


drop table if exists gender_types;
create table gender_types(
	sex char(1) not null primary key,
	descr varchar(32) not null,
	sort int not null default 99999);

drop table if exists salutation_types;
create table salutation_types(
		  salut_id varchar(12) not null primary key,
		  descr varchar(64) not null, sort int not null default 99999) ENGINE=InnoDB;

drop table if exists honorifics;
create table honorifics(
-- honorifics in other languages
	salut_id varchar(12) not null
	,lang char(5) not null -- fr, de, etc
	,descr varchar(64) not null, sort int not null default 99999
	,primary key(salut_id, lang)
	,constraint foreign key(salut_id) references salutation_types(salut_id) on delete cascade
	) ENGINE=InnoDB;

drop table if exists users;
CREATE TABLE users (
	userId integer auto_increment primary key not null,
	orgId integer not null, -- we'll add the FK constraint after creating the organisations table
	username VARCHAR(64) NOT NULL,
	password VARCHAR(255) NOT NULL,
	surname VARCHAR(128) NULL,
	otherNames VARCHAR(128) NULL,
	emailaddr VARCHAR(255) NULL,
	constraint uniq_orgId_username unique(orgId,username));

drop table if exists stale_passwds;
create table stale_passwds(
-- users who must change their passwords at next login
	userId integer primary key not null,
	createdAt timestamp default current_timestamp not null,
	CONSTRAINT fk_stalepasswds_users FOREIGN KEY (UserId) REFERENCES users (UserId) ON DELETE CASCADE);

drop table if exists passwd_reset_reqs;
create table passwd_reset_reqs(
-- requests for password reset
	id integer auto_increment primary key not null,
	emailaddr varchar(255) not null
	,rhost varchar(255) NOT NULL -- visitor's IP address
	,sysuser varchar(128) NOT NULL -- the db2 user who created this entry
	,createdAt TIMESTAMP NOT NULL default current_timestamp
);

drop table if exists passwd_resets;
create table passwd_resets(
-- requests for password reset, after we've determined the userId
	id integer not null -- the request id
	,userId integer not NULL
-- confirmation email:
	,authCode varchar(255) CHARACTER SET latin1 NOT NULL PRIMARY KEY
	,emailSentAt TIMESTAMP NULL -- NULL: email hasnt been sent
	,confRxAt TIMESTAMP NULL -- time confirmation was received
	,resetAt TIMESTAMP NULL -- time passwd reset
--	,constraint uniq_authCode unique(authCode)
--	,primary key(id,userId)
	,constraint foreign key(id) references passwd_reset_reqs(id) on delete cascade
	,constraint foreign key(userId) references users(userId) on delete cascade
);



drop table if exists User_roles;
create table User_roles(
-- todo ensure orgId in users is the same as the orgid in Roles!!
	UserId integer NOT NULL,
	roleID integer NOT NULL,
	PRIMARY KEY(userId, roleId),
	CONSTRAINT fk_userroles_users FOREIGN KEY (UserId) REFERENCES users (UserId) ON DELETE CASCADE,
	CONSTRAINT fk_UserRoles_roles FOREIGN KEY(roleID) REFERENCES Roles (roleID) ON DELETE CASCADE);

-- user's permissions (set at each login)
drop table if exists user_privs;
create table user_privs(
	UserId integer NOT NULL,
	priv varchar(32) not null,
	primary key(userId, priv),
	CONSTRAINT fk_userperms_users FOREIGN KEY (UserId) REFERENCES users (UserId) ON DELETE CASCADE,
	constraint FOREIGN KEY(priv) REFERENCES PermissionTypes(mode) ON DELETE CASCADE);


drop table if exists UserLogins;
CREATE TABLE UserLogins (
--	id integer auto_increment primary key not null,
	connectionId varchar(128) primary key NOT NULL, -- identifier for current database connection
	UserId integer NOT NULL,
	RemoteHost VARCHAR(255) NOT NULL,
	MachineID VARCHAR(255) NOT NULL,
	MachineIDType VARCHAR(5) NOT NULL,
	LoginTime TIMESTAMP NOT NULL,
	LogoutTime TIMESTAMP NULL,
	CLIENT_WRKST varchar(255) NOT NULL,
--	constraint uniq_connId UNIQUE(connectionId),
	CONSTRAINT fk_userlogins_users FOREIGN KEY (UserId) REFERENCES users (UserId) ON DELETE CASCADE,
	CONSTRAINT fk_userlogins_machineidtypes FOREIGN KEY (MachineIDType) REFERENCES MachineIDTypes (Code) ON DELETE NO ACTION);

drop table if exists continents;
CREATE TABLE continents(
	contId char(2) primary key not null,
	contName varchar(15) not null
	);

drop table if exists countries;
CREATE TABLE countries(
    countryCode char(2) primary key NOT NULL,
    countryName varchar(45) NOT NULL,
    currencyCode char(3),
    population varchar(20) DEFAULT NULL,
    fipsCode char(2) DEFAULT NULL,
    isoNumeric char(4) DEFAULT NULL,
    north varchar(30) DEFAULT NULL,
    south varchar(30) DEFAULT NULL,
    east varchar(30) DEFAULT NULL,
    west varchar(30) DEFAULT NULL,
    capital varchar(30) DEFAULT NULL,
    continentId char(2) DEFAULT NULL,
    areaInSqKm varchar(20) DEFAULT NULL,
    isoAlpha3 char(3) NOT NULL,
    geonameId integer DEFAULT NULL
	,constraint foreign key(continentId) references continents(contId) on delete no action
);

drop table if exists adminUnitNames;
create table adminUnitNames(
		countryCode char(2) not null primary key,
		level1name varchar(64) NOT NULL,
 		level2name varchar(64) NOT NULL,
  		level3name varchar(64) DEFAULT NULL,
  		CONSTRAINT fk_adminUnitNames_countries FOREIGN KEY (countrycode) REFERENCES countries (countrycode) on delete cascade on update restrict);

drop table if exists aul1;
CREATE TABLE aul1 (
 -- aul1Id integer generated always as identity primary key not null,
  aul1Code char(2) NOT NULL,
  countrycode char(2) NOT NULL,
  aul1Name varchar(64) not NULL,
  primary key(countrycode,aul1Code),
  CONSTRAINT fk_aul1_countries FOREIGN KEY (countrycode) REFERENCES countries (countrycode) on delete cascade on update restrict
);

drop table if exists aul2;
CREATE TABLE aul2 (
--  aul2Id integer generated always as identity primary key not null,
  aul2Code smallint NOT NULL,
  aul1Code char(2) NOT NULL,
  countrycode char(2) NOT NULL,
--  aul1Id integer not null,
  aul2Name varchar(128) NOT NULL,
  primary key(countrycode,aul1Code,aul2Code),
  CONSTRAINT fk_aul2_aul1 FOREIGN KEY (countrycode,aul1Code) REFERENCES aul1 (countrycode,aul1Code) on delete cascade on update restrict
);

drop table if exists aul3;
CREATE TABLE aul3 (
  aul3Id integer primary key not null,
  aul3Code smallint NOT NULL,
  aul2Code smallint NOT NULL,
  aul1Code char(2) NOT NULL,
  countrycode char(2) NOT NULL,
  aul3Name varchar(128) NOT NULL,
  constraint uniq_aul3 unique(countrycode,aul1Code,aul2Code,aul3code),
  CONSTRAINT fk_aul3_aul2 FOREIGN KEY (countrycode,aul1Code,aul2Code) REFERENCES aul2 (countrycode,aul1Code,aul2Code) on delete cascade on update restrict
);

drop table if exists towns;
create table towns(
	townId char(3) not null primary key,
	townName varchar(64) not null,
	aul3Id int NOT NULL,
	constraint uniq_townName unique(townName),
	constraint foreign key(aul3Id) references aul3(aul3id) on delete cascade on update restrict
);

drop table if exists addr_quarters;
create table addr_quarters(
	qtrId int auto_increment primary key not null
	,qtrName varchar(255) not null -- quarter, locality, street, etc
	,townId char(3) not null
	,modifiedBy integer
	,modifiedAt timestamp  default current_timestamp not null
	,constraint addrqtrs_unique unique(qtrName(150),townId)
	,constraint foreign key(modifiedBy) references users(userId) on delete no action
	,constraint foreign key(townId) references towns(townId) on delete cascade on update restrict);

drop table if exists educationLevels;
CREATE TABLE educationLevels ( 
eduLevelId int auto_increment primary key not null,
eduLevelAlias varchar(16) not null,
description VARCHAR(64) not null,
countryCode char(3) NOT NULL,
sorter int NOT NULL DEFAULT 99999 -- sort entries by this column
,constraint uniq_eduLevelAlias unique(eduLevelAlias, countryCode)
,constraint foreign key(countryCode) references countries(countryCode) on delete cascade
);

drop table if exists Address_types;
CREATE TABLE Address_types ( 
addrTypeId VARCHAR(8) NOT NULL PRIMARY KEY,
description VARCHAR(32),
sorter int NOT NULL DEFAULT 99999 -- sort entries by this column
); 

drop table if exists frequencyTypes;
CREATE TABLE frequencyTypes ( 
freqID VARCHAR(10) NOT NULL PRIMARY KEY, -- 'daily','weekly',f
description VARCHAR(32),
sorter int NOT NULL DEFAULT 99999 -- sort entries by this column
); 

drop table if exists occupation_categories;
create table occupation_categories(
	occup_catId VARCHAR(16) NOT NULL primary key,
	description VARCHAR(64) not null,
	sorter int NOT NULL DEFAULT 99999
);

drop table if exists occupations;
CREATE TABLE occupations ( 
	occupId int auto_increment primary key not null,
	occup_catId VARCHAR(16) NOT NULL,
	occupAlias VARCHAR(16) NOT NULL,
	description VARCHAR(128) not NULL,
	countryCode char(2) NOT NULL,
	sorter int NOT NULL DEFAULT 99999 -- sort entries by this column
	,constraint uniq_occupAlias unique(occupAlias, occup_catId, countryCode)
	,constraint foreign key(occup_catId) references occupation_categories(occup_catId) on delete cascade
	,constraint foreign key(countryCode) references countries(countryCode) on delete cascade
);


-- table required by user logins. Can later be recreated to suit the application
drop table if exists organisations;
create table organisations(
	orgId INTEGER auto_increment NOT NULL PRIMARY KEY,
	orgName varchar(255)
	);

