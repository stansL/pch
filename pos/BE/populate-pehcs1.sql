/*
application-specific reference data

fotang, Tue Nov  8 19:42:04 WAT 2016

 */
INSERT INTO PermissionTypes(mode,Description, sort) VALUES
	('ADDORGDADDR','add organisation address',1020),
	('UPDORGDADDR','modify an address of the organisation',1025),
	('DELORGDADDR','remove organisation address',1030),
	('ADDORGFONE','add organisation phone#',1035),
	('UPDORGFONE','modify organisation phone#',1036),
	('DELORGFONE','remove organisation phone#',1037),
	('ADDORGEMAIL','add organisation email address',1038),
	('UPDORGEMAIL','modify organisation email address',1039),
	('DELORGEMAIL','remove organisation email address',1040),
	('ADDORGCONTACT','add organisation contact person', 1041),
	('UPDORGCONTACT','update contact person details', 1042),
	('DELORGCONTACT','remove contact person', 1043);
