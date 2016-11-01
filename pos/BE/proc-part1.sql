/*
<Tano Fotang> fotang@gmail.com

Sat Oct 22 13:23:58 WAT 2016

This file uses sqlstates 45200 - 45299

*/

DELIMITER //

/* ---------------------- */
/* Setup service provider */
/* ---------------------- */

DROP PROCEDURE IF EXISTS setup_sp//
CREATE PROCEDURE setup_sp(p_connId VARCHAR(128), p_code INT, p_name VARCHAR(255), p_licenseEnd datetime)
BEGIN
		CALL verifyPrivilege(p_connId, 'setup_sp', 'SPSETUP');
		INSERT INTO VARIABLES(name,value) VALUES
			('sp_code', CAST(p_code AS CHAR(32))), 
			('sp_name', p_name),
			('sp_licend', CAST(p_licenseEnd AS CHAR(32)));
END//


DROP PROCEDURE IF EXISTS deactivate_sp//
CREATE PROCEDURE deactivate_sp()
BEGIN
		CALL verifyPrivilege(p_connId, 'deactivate_sp', 'SPDEACT');
		UPDATE VARIABLES SET value='1900-01-01' WHERE name='sp_licend';
END//


DROP PROCEDURE IF EXISTS update_sp//
CREATE PROCEDURE update_sp(p_connId VARCHAR(128), p_code INT, p_name VARCHAR(255))
BEGIN
		CALL verifyPrivilege(p_connId, 'update_sp', 'SPMOD');
		UPDATE VARIABLES SET value=p_name WHERE name='sp_name';
	--	UPDATE VARIABLES SET value=p_phonenr WHERE name='sp_phonenr';
END//


DROP FUNCTION IF EXISTS getSpCode//
CREATE FUNCTION getSpCode() RETURNS INT DETERMINISTIC
BEGIN
		RETURN (SELECT CAST(value AS UNSIGNED)  FROM VARIABLES WHERE name='sp_code');
END//

/* -------------------------- */
/* Helper functions           */
/* -------------------------- */

DROP FUNCTION IF EXISTS disp2insurer//
CREATE FUNCTION disp2insurer(p_dispId int, strict BOOLEAN) RETURNS int DETERMINISTIC
/* return insurer for a dispensation */
BEGIN
	DECLARE v_insuredId int;

	SET v_insuredId = (select b.insurerId
	  FROM dispensation d
	  JOIN visits v ON v.visitId=d.visitId
	  JOIN beneficiaries b ON b.benId=v.benId
     WHERE d.dispId=p_dispId);
	IF v_insuredId IS NULL AND strict THEN
		SIGNAL SQLSTATE '45201' SET MESSAGE_TEXT = 'No such dispensation';
	END IF;
	return v_insuredId;
END//

DROP FUNCTION IF EXISTS disp2visitId//
CREATE FUNCTION disp2visitId(p_dispId int, strict BOOLEAN) RETURNS int DETERMINISTIC
BEGIN
		DECLARE v_visitId int;
		SET v_visitId = (SELECT visitId FROM dispensation WHERE dispId = p_dispId);
		IF v_visitId IS NULL AND strict THEN
			SIGNAL SQLSTATE '45201' SET MESSAGE_TEXT = 'No such dispensation';
		END IF;
		RETURN v_visitId;
END//

DROP FUNCTION IF EXISTS disp2benId//
CREATE FUNCTION disp2benId(p_dispId int, strict BOOLEAN) RETURNS int DETERMINISTIC
BEGIN
		DECLARE v_benId VARCHAR(32);
		SET v_benId = (
				SELECT b.benId
				  FROM beneficiaries b, dispensation d, visits v
				 WHERE d.dispId = p_dispId AND d.visitId=v.visitId AND v.benId=b.benId);
		IF v_benId IS NULL AND strict THEN
			SIGNAL SQLSTATE '45201' SET MESSAGE_TEXT = 'No such dispensation';
		END IF;
		RETURN v_benId;
END//

DROP FUNCTION IF EXISTS visit2insurer//
CREATE FUNCTION visit2insurer(p_visitId int, strict BOOLEAN) RETURNS int DETERMINISTIC
/* return insurer for a visit */
BEGIN
	DECLARE v_insuredId int;

	SET v_insuredId = (
			select b.insurerId
			  FROM visits v
			  JOIN beneficiaries b ON b.benId=v.benId
			 WHERE v.visitId=p_visitId);
	IF v_insuredId IS NULL AND strict THEN
		SIGNAL SQLSTATE '45203' SET MESSAGE_TEXT = 'Invalid visit ID';
	END IF;
	return v_insuredId;
END//

DROP FUNCTION IF EXISTS visit2benId//
CREATE FUNCTION visit2benId(p_visitId int, strict BOOLEAN) RETURNS VARCHAR(32) DETERMINISTIC
/* return beneficiary for a visit */
BEGIN
	DECLARE v_benId VARCHAR(32);

	SET v_benId = (
			select b.benId
			  FROM visits v
			  JOIN beneficiaries b ON b.benId=v.benId
			 WHERE v.visitId=p_visitId);
	IF v_benId IS NULL AND strict THEN
		SIGNAL SQLSTATE '45203' SET MESSAGE_TEXT = 'Invalid visit ID';
	END IF;
	return v_benId;
END//


DROP FUNCTION IF EXISTS productCat//
CREATE FUNCTION productCat(p_productId integer) RETURNS INT
-- get product category
	RETURN (SELECT catId FROM products p WHERE p.productId=p_productId)//


DROP FUNCTION IF EXISTS isExcludedProductCat//
-- insurer doesnt cover category
CREATE FUNCTION isExcludedProductCat(p_catId integer, p_insurerId int) RETURNS BOOLEAN
	RETURN EXISTS(
		SELECT * FROM excluded_categories WHERE catId=p_catId AND insurerId = p_insurerId
		)//

DROP FUNCTION IF EXISTS isExcludedProduct//
CREATE FUNCTION isExcludedProduct(p_productId integer, p_insurerId int) RETURNS BOOLEAN
	RETURN isExcludedProductCat(productCat(p_productId), p_insurerId)//


DROP FUNCTION IF EXISTS isCoveredProductCat//
CREATE FUNCTION isCoveredProductCat(p_catId integer, p_benId int) RETURNS BOOLEAN
/* is product category included in the beneficiary's coverage? */
	RETURN EXISTS(
		SELECT * FROM beneficiaries b
		  JOIN packages p ON b.packageId = p.packageId
		  JOIN coverages c ON p.c.packageId AND c.catId = p_catId AND c.insurerId=b.insurerId
		 WHERE b.benId=p_benId
		)//


DROP FUNCTION IF EXISTS isCoveredProduct//
CREATE FUNCTION isCoveredProduct(p_productId integer, p_benId int) RETURNS BOOLEAN
/* is product covered for the beneficiary? */
	RETURN isCoveredProductCat(productCat(p_productId), p_benId)//

DROP FUNCTION IF EXISTS detailMatchesCat//
CREATE FUNCTION detailMatchesCat(p_dispId int, p_detail_type int) RETURNS BOOLEAN
/* check whether the details match the product and the insurer */
BEGIN
		DECLARE v_insurerId INT;

		SET v_insurerId = disp2insurer(d.dispId, FALSE);
		RETURN EXISTS(
			  select *
				FROM dispensation d
				JOIN products p ON p.productId=d.productId
				JOIN product_categories c ON c.catId=p.productId
				JOIN required_details r ON r.catId = c.catId AND r.detail_type_id=p_detail_type
				WHERE r.insurerId IS NULL OR (v_insurerId IS NOT NULL AND r.insurerId = v_insurerId));
END//


DROP PROCEDURE IF EXISTS getDetailReqForProduct//
CREATE PROCEDURE getDetailReqForProduct(IN p_prouctId int, IN p_insurerId int)
/* fetch the type of details that must be provided at product dispensation */
BEGIN
		select p_productId AS productId, r.insurerId, c.catId,
			   d.detail AS detailId, d.name, d.datatype, d.descr
		  FROM products p
		  JOIN product_categories c ON c.catId=p.catId
		  JOIN required_details r ON r.catId = c.catId AND (r.insurerId IS NULL OR r.insurerId = p_insurerId)
		  JOIN productcat_detail_types d ON d.detail_type_id = r.detail_type_id
		 WHERE p.productId = p_productId
	  ORDER BY d.sorter asc;
END//

/* -------------------- */
/* Products				*/
/* -------------------- */


/* -------------------- */
/* Insurers			*/
/* -------------------- */
DROP PROCEDURE IF EXISTS addInsurer//
CREATE PROCEDURE addInsurer(
		IN p_connId VARCHAR(128),
		IN p_Id INT,
		IN p_alias VARCHAR(128),
		IN p_name VARCHAR(255))
BEGIN
		-- this is a placeholder --
	CALL verifyPrivilege(p_connId, 'addInsurer', 'ADDINSURER');
	INSERT INTO insurers(insurerId, alias, name) values(p_Id, p_alias, p_name);
END//
/* -------------------- */
/* Beneficiary          */
/* -------------------- */
-- 45230--45239
-- after reading FROM SC, add beneficiary if record doesnt yet exist


DROP PROCEDURE IF EXISTS addBeneficiary//
CREATE PROCEDURE addBeneficiary(
	p_connId VARCHAR(255)
	,p_cardId VARCHAR(32)
	,p_surname VARCHAR(64)
	,p_lastname VARCHAR(64)
	,p_sex char(1)
	,p_dob date
	,p_insurerId int
	,p_package VARCHAR(32)	
)
BEGIN
	DECLARE v_pkgId INT DEFAULT NULL;
	DECLARE v_status char(5) DEFAULT NULL;
	DECLARE v_status_name VARCHAR(32);
	DECLARE v_alias VARCHAR(32) DEFAULT NULL;
--	DECLARE v_insurerId INT DEFAULT NULL;

	CALL verifyPrivilege(in_connId, 'addBeneficiary', 'ADDBENI');
	/* verify insurerer status */
	   SELECT i.alias, i.status, s.name
	     FROM insurers i
	LEFT JOIN insurer_status_types s ON i.status=s.typeId -- could also use an inner JOIN...
		WHERE s.insurerId = p_insurerId
		 INTO v_alias, v_status, v_status_name;
	IF FOUND_ROWS() = 0 THEN
		BEGIN
			SET @msg =  'Insurer is not registered ('||p_insurerId||')';
			SIGNAL SQLSTATE '45232' SET MESSAGE_TEXT = @msg;
		END;
	END IF;
	IF v_status NOT IN ('act') THEN
		BEGIN
			SET @msg =  'Insurer ' || p_insurerId || ' is not permitted: ' || IFNULL(v_status_name,'<unknown>');
			SIGNAL SQLSTATE '45233' SET MESSAGE_TEXT = @msg;
		END;
	END IF;

	/* todo: perform other checks */

	SET v_pkgId = (SELECT packageId FROM packages WHERE name=p_package AND insurerId = p_insurerId);
	IF v_pkgId IS NULL THEN
		BEGIN
			SET @msg =  'Undefined package \''||p_package||'\' for '|| v_alias;
			SIGNAL SQLSTATE '45234' SET MESSAGE_TEXT = @msg;
		END;
	END IF;
	insert into beneficiaries(benId,surname,lastname,sex,dob,insurerId, packageId) VALUES
		(p_insurerId || ':' || p_cardId, p_surname, p_lastname, p_sex, p_dob, p_insurerId, v_pkgId);
	
END//

/* -------------------- */
/* Coverage				*/
/* -------------------- */

DROP PROCEDURE IF EXISTS addPackage//
CREATE PROCEDURE addPackage(
		p_connId VARCHAR(128),
		p_name VARCHAR(64), -- may be used for localisation
		p_insurerId int,
		p_descr VARCHAR(255))
BEGIN
	CALL verifyPrivilege(p_connId, 'addPackage', 'ADDPACKG');
	INSERT INTO packages(insurerId, name, descr) values
		(p_insurerId, p_name, p_descr);
END//

/* -------------------- */
/* Dispensation			*/
/* -------------------- */

/*DROP FUNCTION IF EXISTS payload//
CREATE FUNCTION payload(IN p_dispId int) RETURNS VARCHAR(160)
BEGIN
		RETURN (SELECT payload FROM payloads WHERE dispId=p_dispId);
END//
*/


DROP FUNCTION IF EXISTS dispState//
CREATE FUNCTION dispState(p_dispId int) RETURNS char(5)
/* fetch curent (last added) dispensation state */
RETURN
/*
    	(SELECT disp_state_id
		  FROM dispensation_state_types
		 WHERE dispId = p_dispId AND createdAt = 
				(SELECT MAX(createdAt) FROM dispensation_state_types
				  WHERE dispId=p_dispId group by(dispId)));
		*/

		/* use below, provided recId values will not wrap round and MIN becomes MAX ! */
    	(SELECT disp_state_id
		   FROM dispensation_state_types
		  WHERE dispId = p_dispId AND recId = 
				(SELECT MAX(recId) FROM dispensation_state_types
			      WHERE dispId=p_dispId GROUP BY(dispId)))
//

DROP PROCEDURE IF EXISTS setDispState//
CREATE PROCEDURE setDispState(p_dispId int, p_status char(5), p_remark VARCHAR(255))
/* change the state of dispensation */
BEGIN
	INSERT INTO dispensation_statess(dispId, disp_state_id, remark) VALUES(p_dispId, p_status, p_remark);
END//

DROP PROCEDURE IF EXISTS make_approval_payload//
CREATE PROCEDURE make_approval_payload(IN p_dispId int)
        -- Table(s) updated:payloads
        -- Table(s) read:   products, product_approval_reqmts, approval_reqmts, dispensation, visits

		/* APPROVAL REQUIREMENT */

		-- Must raise error if approval request has been sent:
IF EXISTS(SELECT * FROM approval_reqs WHERE dispId = p_dispId) THEN
		SIGNAL SQLSTATE '45205' SET MESSAGE_TEXT = 'Approval request exists';
ELSE
	BEGIN
		DECLARE v_productId INT;
		DECLARE v_qty FLOAT;
		DECLARE v_totcost DECIMAL;
		DECLARE v_costToInsurer DECIMAL;
		DECLARE v_insurerId INT; -- the insurer
		DECLARE v_visitId INT;
		DECLARE v_type char(5) default NULL; -- requirement type
		DECLARE v_value DECIMAL default NULL;
		DECLARE approval_needed BOOLEAN default FALSE;
		DECLARE done BOOLEAN default FALSE;
		DECLARE cur CURSOR FOR
				SELECT ar.reqtypeId, par.value
				 FROM products p
				 JOIN product_approval_reqmts par ON par.productId=p.productId
				 JOIN approval_reqmts ar ON ar.id=par.approvalId AND
					  ar.insurerId= disp2insurer(p_dispId, TRUE);
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

		SELECT visitId, productId, qty, totalcost, insurer_cost
		  FROM dispensation
		 WHERE dispId = p_dispId
		  INTO v_visitId, v_productId, v_qty, v_totcost, v_costToInsurer;
		IF FOUND_ROWS() = 0 THEN
				SIGNAL SQLSTATE '45206' SET MESSAGE_TEXT = 'No such dispensation';
		END IF;
		OPEN cur;
		REPEAT
			FETCH cur INTO v_type, v_value; -- v_type, v_value: approval requirement types and the threshold values
			IF v_type NOT IN ('cost','qty') THEN
				SIGNAL SQLSTATE '45210' SET MESSAGE_TEXT = 'Not implemented';
			END IF;
			IF NOT done THEN
				IF v_value IS NULL OR v_value <
					CASE v_type WHEN 'cost' THEN v_costToInsurer ELSE v_qty END THEN
						BEGIN
							SET approval_needed = TRUE;
							SET @benId = (SELECT benId FROM visits WHERE visitId = v_visitId);
							SET @prodCode = (SELECT productCode FROM products WHERE productId=v_productId);
							SET @payload = getSpCode() || '|' || @benId || '|' || p_dispId || '|' || 
								@prodCode || '|' || 
								IFNULL(v_value, CASE v_type WHEN 'cost' THEN v_costToInsurer ELSE v_qty END);
							REPLACE INTO payloads(dispId, payload, createdAt) VALUES(p_dispId, @payload, current_timestamp);
							CALL setDispState(p_dispId, 'pendi', 'payload created'); 
							SET done=TRUE; -- we're sending only one approval request
						END;
				END IF;
			END IF;
		UNTIL done END REPEAT;
		CLOSE cur;
		IF NOT approval_needed AND 'ok' <> dispState(p_dispId) THEN
			CALL setDispState(p_dispId, 'ok', NULL);
		END IF;
	END;
END IF//


DROP PROCEDURE IF EXISTS apportion_costs//
CREATE PROCEDURE apportion_costs(
				p_benId VARCHAR(32),
				p_productId INT,
				p_qty FLOAT,
				INOUT p_UP DECIMAL,
				OUT p_totcost DECIMAL,
				OUT p_costToInsurer DECIMAL
				)
	/* apportion costs between insurer and the insured */
BEGIN
		-- Tables(s) updated: <None>
		-- Table(s) read	: visits, beneficiaries, coverages

		IF p_UP IS NULL THEN /* look up the unit price */
				SET p_UP = IFNULL((select cost FROM products WHERE productId=p_productId), 0.0);
		END IF;
		SET p_totcost = p_UP * p_qty;
		SET p_costToInsurer = p_totcost;
		BEGIN
			/* - determine cap */
				DECLARE v_pc float;
				DECLARE v_amount decimal;

				SELECT c.amount, c.percentage
				  FROM beneficiaries b
				  JOIN coverages c ON c.coverageId=b.coverageId
				 WHERE b.benId=p_benId
				  INTO v_amount, v_pc;
				IF v_pc IS NOT NULL THEN /* there is a % cap */
						SET p_costToInsurer = v_pc * p_costToInsurer/100.0;
				END IF;
				IF v_amount IS NOT NULL /* there is a monetary cap */
						AND p_costToInsurer>v_amount /* total cost exceeds cap */
						THEN SET p_costToInsurer=v_amount;
				END IF;
		END;
END//

DROP PROCEDURE IF EXISTS addDispensation//
CREATE PROCEDURE addDispensation(
				p_connId VARCHAR(128),
				p_visitId INT,
				p_productId INT,
				p_qty FLOAT,
				INOUT p_UP DECIMAL,
				p_remarks VARCHAR(255),
				OUT p_dispId int,
				OUT p_totcost DECIMAL,
				OUT p_costToInsurer DECIMAL
				)
BEGIN
		DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN
			ROLLBACK;
			RESIGNAL;
			END;

		CALL verifyPrivilege(p_connId, 'addDispensation', 'ADDDISP');
		/* apportion costs. Let's try to do this in a trigger */
--		CALL apportion_costs(visit2benId(p_visitId,TRUE), p_productId, p_qty, p_UP, p_totcost, p_costToInsurer);

		/* record dispensation */
		START TRANSACTION;
		INSERT INTO dispensation(visitId, productId, qty, unitcost, totalcost, insurer_cost,remark, createdBy)
			   VALUES(p_visitId, p_productId, p_qty, p_UP, 0, 0, p_remarks, connId2userId(p_connId, TRUE));
		SET p_dispId = LAST_INSERT_ID();
		SELECT unitcost, totalcost, insurer_cost
		  FROM dispensation
		 WHERE dispId = p_dispId
		  INTO p_UP, p_totcost, p_costToInsurer;
		/* at this point, triggers will have done additional processing */
		COMMIT;
END//

DROP PROCEDURE IF EXISTS updateDispensation//
CREATE PROCEDURE updateDispensation(
				p_connId VARCHAR(128),
				p_dispId int,
				p_qty FLOAT,
				INOUT p_UP DECIMAL,
				OUT p_totcost DECIMAL,
				OUT p_costToInsurer DECIMAL
				)
BEGIN
		DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN
			ROLLBACK;
			RESIGNAL;
			END;

		CALL verifyPrivilege(p_connId, 'updateDispensation', 'UPDDISP');
		/* try using bu trigger. */
--		CALL apportion_costs(disp2benId(p_dispId, TRUE), p_productId, p_qty, p_UP, p_totcost, p_costToInsurer);
		START TRANSACTION; -- necessary because of work done by any triggers
		UPDATE dispensation
		   SET qty=p_qty, unitcost=p_UP, modifieddBy=connId2userId(p_connId, TRUE)
		 WHERE displId=p_dispId;
--		CALL make_approval_payload(p_dispId); /* this will raise error if approval has already been sent. Update willl be rolled back */
		SELECT unitcost, totalcost, insurer_cost
		  FROM dispensation
		 WHERE dispId = p_dispId
		  INTO p_UP, p_totcost, p_costToInsurer;
		COMMIT;
END//


DROP PROCEDURE IF EXISTS getDispDetails//
CREATE PROCEDURE getDispDetails(IN p_connId VARCHAR(128), p_dispId int)
BEGIN
	CALL verifyPrivilege(in_connId, 'getDispDetails', 'RDDISP');
	SELECT dispId, visitId, productId, qty, unitcost, totalcost, insurer_cost,remark,
			createdBy, createdAt, modifiedBy,  createdBy
	  FROM dispensation WHERE dispId=p_dispId;
END//


DROP PROCEDURE IF EXISTS getDispensations4Visit//
CREATE PROCEDURE getDispensations4Visit(IN p_connId VARCHAR(128), IN p_visitId int)
	/* fetch all the items that were selected for dispensation */
BEGIN
	CALL verifyPrivilege(in_connId, 'getDispensations4Visit', 'RDDISP');
	SELECT d.dispId, d.visitId, d.productId, d.qty, d.unitcost, d.totalcost,
		   d.insurer_cost, ds.disp_state_id, dst.name, d.remark
	  FROM dispensation d
 LEFT JOIN dispensation_states ds ON ds.dispId=d.dispId AND ds.recId=(
		SELECT MAX(recId) from dispensation_states WHERE dispId=d.dispId GROUP BY (dispId))
 	 WHERE d.visitId=p_visitId;
END//


DELIMITER ;
