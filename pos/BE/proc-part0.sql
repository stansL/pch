/*
Procedures to fetch reference data
<Tano Fotang> fotang@gmail.com

Sat Oct 22 12:25:07 WAT 2016

*/

DELIMITER //


DROP PROCEDURE IF EXISTS getexceptiontypes//
CREATE PROCEDURE getexceptiontypes()
BEGIN
	SELECT ex_code as id, name, descr FROM exception_types order by sorter asc;
END//


DROP PROCEDURE IF EXISTS getverificationtypes//
CREATE PROCEDURE getverificationtypes()
BEGIN
	SELECT veri_type_id as id, name, descr FROM verification_types order by sorter asc;
END//


DROP PROCEDURE IF EXISTS getvisittypes//
CREATE PROCEDURE getvisittypes()
BEGIN
	SELECT visit_type_id as id, name, descr FROM visit_types order by sorter asc;
END//


DROP PROCEDURE IF EXISTS getdispSstatetypes//
CREATE PROCEDURE getdispSstatetypes()
BEGIN
	SELECT disp_state_id as id, name, descr FROM dispensation_state_types order by sorter asc;
END//


DROP PROCEDURE IF EXISTS getapprovalRespGroups//
CREATE PROCEDURE getapprovalRespGroups()
BEGIN
	SELECT resp_group_id as id, name, descr FROM approval_resp_groups order by sorter asc;
END//


DROP PROCEDURE IF EXISTS getTxModes//
CREATE PROCEDURE getTxModes()
BEGIN
	SELECT tx_mode_id as id, name, descr FROM transmission_modes order by sorter asc;
END//


DROP PROCEDURE IF EXISTS getdetail_types//
CREATE PROCEDURE getdetail_types()
BEGIN
	SELECT detail_type_id as id, name, descr FROM productcat_detail_types order by sorter asc;
END//


DROP PROCEDURE IF EXISTS get//
CREATE PROCEDURE get()
BEGIN
	SELECT product_categories as id, name, descr FROM productcats order by sorter asc;
END//


DROP PROCEDURE IF EXISTS getUnits//
CREATE PROCEDURE getUnits()
BEGIN
	SELECT unitId as id, name, descr FROM units order by sorter asc;
END//


DROP PROCEDURE IF EXISTS getReqmtTtypes//
CREATE PROCEDURE getReqmtTtypes()
BEGIN
	SELECT reqtypeId as id, name, descr FROM approval_reqmt_types order by sorter asc;
END//

DROP PROCEDURE IF EXISTS getInsurer_status_types//
CREATE PROCEDURE getInsurer_status_types()
BEGIN
	SELECT typeId as id, name, descr FROM insurer_status_types order by sorter asc;
END//



DELIMITER ;
