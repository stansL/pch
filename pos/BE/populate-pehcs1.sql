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
INSERT INTO PermissionTypes(mode,Description, sort) VALUES
	('DEAORG','Deactivate service provider',1050),
	('ACTORG','Activate service provider', 1055),
	('ADDINSURER','Add insurer',2000),
	('UPDINSURER','Modify insurer',2001),
	('DELINSURER','Remove insurer',2002),
/*	('ADDBENIF','Add beneficiary', 2200), -- */
	('DELBENIF','Remove beneficiary', 2202),
	('UPDBENIF','Modify beneficiary', 2203),
	('ADDPACKG','Add a package', 2300),
	('UPDPACKG','Modify a package', 2302),
	('DELPACKG','Remove a package', 2303),
	('ADDVISIT','Add a visitation',2400),
	('ENDVISIT','Close a visitation',2401),
	('RESVISIT','Resume a visitation',2402),
	('ADDDISP','Make a dispensation',2410),
	('UPDDISP','Modify a dispensation',2412),
	('DELDISP','Remove a dispensation',2413),
	('RDDISP','See dispensations',2415);
