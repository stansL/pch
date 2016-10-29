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
		CALL verifyPrivilege(p_connId, 'setup_sp', 'SPSUPER');
		INSERT INTO VARIABLES(name,value) VALUES
			('sp_code', CAST(p_code AS CHAR(32))), 
			('sp_name', p_name),
			('sp_licend', CAST(p_licenseEnd AS CHAR(32)));
END//


DROP PROCEDURE IF EXISTS deactivate_sp//
CREATE PROCEDURE deactivate_sp()
BEGIN
		CALL verifyPrivilege(p_connId, 'deactivate_sp', 'SPSUPER');
		UPDATE VARIABLES SET value='1900-01-01' WHERE name='sp_licend';
END//


DROP PROCEDURE IF EXISTS update_sp//
CREATE PROCEDURE update_sp(p_connId VARCHAR(128), p_code INT, p_name VARCHAR(255))
BEGIN
		CALL verifyPrivilege(p_connId, 'update_sp', 'SPADMIN');
		UPDATE VARIABLES SET value=p_name WHERE name='sp_name';
	--	UPDATE VARIABLES SET value=p_phonenr WHERE name='sp_phonenr';
END//


DROP FUNCTION IF EXISTS getSpCode//
CREATE FUNCTION getSpCode() RETURNS INT DETERMINISTIC
BEGIN
		RETURN (SELECT CAST(value AS UNSIGNED)  FROM VARIABLES WHERE name='sp_code');
END//

/* -------------------- */
/* Dispensation details */
/* -------------------- */
DROP FUNCTION IF EXISTS disp2insurer//
CREATE FUNCTION disp2insurer(p_dispId int, strict boolean) RETURNS int DETERMINISTIC
/* return insurer for a dispensation */
BEGIN
 	DECLARE v_insuredId int;

	SET v_insuredId = (select b.insurerId
	  from dispensation d
	  join visits v ON v.visitId=d.visitId
	  join beneficiaries b ON b.benId=v.benId
     where d.dispId=p_dispId);
	IF v_insuredId IS NULL AND strict THEN
		SIGNAL SQLSTATE '45201' SET MESSAGE_TEXT = 'No such dispensation';
	END IF;
	return v_insuredId;
END//


DROP FUNCTION IF EXISTS disp2visitId//
CREATE FUNCTION disp2visitId(p_dispId int, strict boolean) RETURNS int DETERMINISTIC
BEGIN
		DECLARE v_visitId int;
		SET v_visitId = (SELECT visitId FROM dispensation WHERE dispId = p_dispId);
		IF v_visitId IS NULL AND strict THEN
			SIGNAL SQLSTATE '45201' SET MESSAGE_TEXT = 'No such dispensation';
		END IF;
		RETURN v_visitId;
END//

DROP FUNCTION IF EXISTS detailMatchesCat//
CREATE FUNCTION detailMatchesCat(p_dispId int, p_detail_type int) RETURNS BOOLEAN
/* check whether the details match the product and the insurer */
BEGIN
		DECLARE v_insurerId INT;

		SET v_insurerId = disp2insurer(d.dispId, FALSE);
		RETURN EXISTS(
			  select *
				from dispensation d
				join products p ON p.productId=d.productId
				join product_categories c ON c.catId=p.productId
				join required_details r ON r.catId = c.catId AND r.detail_type_id=p_detail_type
				where r.insurerId IS NULL OR (v_insurerId IS NOT NULL AND r.insurerId = v_insurerId));
END//


DROP PROCEDURE IF EXISTS getDetailReqForProduct//
CREATE PROCEDURE getDetailReqForProduct(IN p_prouctId int, IN p_insurerId int)
/* fetch the type of details that must be provided at product dispensation */
BEGIN
		select p_productId AS productId, r.insurerId, c.catId,
			   d.detail AS detailId, d.name, d.datatype, d.descr
		  from products p
		  join product_categories c ON c.catId=p.catId
		  join required_details r ON r.catId = c.catId AND (r.insurerId IS NULL OR r.insurerId = p_insurerId)
		  join productcat_detail_types d ON d.detail_type_id = r.detail_type_id
		 where p.productId = p_productId
	  order by d.sorter asc;
END//

DROP PROCEDURE IF EXISTS addInsurer//
CREATE PROCEDURE addInsurer(
		IN p_connId VARCHAR(128),
		IN p_Id INT,
		IN p_alias varchar(128),
		IN p_name varchar(255))
BEGIN
		-- this is a placeholder --
	CALL verifyPrivilege(p_connId, 'addInsurer', 'ADDINSURER');
	INSERT INTO insurers(insurerId, alias, name) values(p_Id, p_alias, p_name);
END//


/*DROP FUNCTION IF EXISTS payload//
CREATE FUNCTION payload(IN p_dispId int) RETURNS varchar(160)
BEGIN
		RETURN (SELECT payload FROM payloads WHERE dispId=p_dispId);
END//
*/

DROP PROCEDURE IF EXISTS make_approval_payload//
CREATE PROCEDURE make_approval_payload(IN p_dispId int)
		-- Table(s) updated:	payloads
		-- Table(s) read:		products, product_approval_reqmts, approval_reqmts, dispensation, visits

		/* APPROVAL REQUIREMENT */

		-- do nothing if approval request has been sent:
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
		DECLARE done boolean default FALSE;
		DECLARE cur CURSOR FOR
				SELECT ar.reqtypeId, par.value
				 FROM products p
				 JOIN product_approval_reqmts par ON par.productId=p.productId
				 JOIN approval_reqmts ar ON ar.id=par.approvalId AND ar.insurerId= disp2insurer(p_dispId, TRUE);
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
							SET @benId = (SELECT benId FROM visits WHERE visitId = v_visitId);
							SET @prodCode = (SELECT productCode FROM products WHERE productId=v_productId);
							SET @payload = getSpCode() || '|' || @benId || '|' || p_dispId || '|' ||  @prodCode || '|' || 
								IFNULL(v_value, CASE v_type WHEN 'cost' THEN v_costToInsurer ELSE v_qty END);
							REPLACE INTO payloads(dispId, payload, createdAt) VALUES(p_dispId, @payload, current_timestamp);
							SET done=TRUE; -- send only one approval request
						END;
				END IF;
			END IF;
		UNTIL done END REPEAT;
		CLOSE cur;
	END;
END IF//


DROP PROCEDURE IF EXISTS apportion_costs//
CREATE PROCEDURE apportion_costs(
				p_visitId INT,
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

		DECLARE v_totcost DECIMAL;
		DECLARE v_costToInsurer DECIMAL;

		IF p_UP IS NULL THEN
			BEGIN /* look up the unit price */
				SET p_UP = (select cost from products where productId=p_productId);
				if p_UP is null then set p_up=0.0; end if;
			END;
		END IF;
		SET v_totcost = p_UP * p_qty;
		SET p_costToInsurer = v_totcost;
		BEGIN
			/* - determine cap */
				DECLARE v_pc float;
				DECLARE v_amount decimal;

				SELECT c.amount, c.percentage
				  FROM visits v
				  JOIN beneficiaries b ON b.benId=v.benId
				  JOIN coverages c ON c.coverageId=b.coverageId
				 WHERE v.visitId=p_visitId
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
		DECLARE v_totcost DECIMAL;
		DECLARE v_costToInsurer DECIMAL;
	    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN
   			ROLLBACK;
			RESIGNAL;
        	END;

		CALL verifyPrivilege(p_connId, 'addDispensation', 'ADDDISP');
		CALL apportion_costs(p_visitId, p_productId, p_qty, p_UP, p_totcost, p_costToInsurer);
		/* record dispensation */
		START TRANSACTION;
		INSERT INTO dispensation(visitId, productId, qty, unitcost, totalcost, insurer_cost,remark, createdBy)
		       VALUES(p_visitId, p_productId, p_qty, p_UP, v_totcost, p_costToInsurer,
				p_remarks, connId2userId(p_connId, TRUE));
		SET p_dispId = LAST_INSERT_ID();
		CALL make_approval_payload(p_dispId);
		COMMIT;
END//

DROP PROCEDURE IF EXISTS updateDispensation//
CREATE PROCEDURE updateDispensation(
				p_connId VARCHAR(128),
				p_dispId int,
				p_qty FLOAT,
				p_UP DECIMAL,
				OUT p_totcost DECIMAL,
				OUT p_costToInsurer DECIMAL
				)
BEGIN
		DECLARE v_totcost DECIMAL;
		DECLARE v_costToInsurer DECIMAL;
		DECLARE v_visitId int;
	    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN
   			ROLLBACK;
			RESIGNAL;
        	END;

		CALL verifyPrivilege(p_connId, 'updateDispensation', 'UPDDISP');
		CALL apportion_costs(disp2visitId(p_dispId, TRUE), p_productId, p_qty, p_UP, p_totcost, p_costToInsurer);
		START TRANSACTION;
		UPDATE dispensation
		   SET qty=p_qty, unitcost=p_UP, totalcost=p_totcost, insurer_cost=p_costToInsurer, 
			   modifieddBy=connId2userId(p_connId, TRUE)
		 WHERE displId=p_dispId;
		CALL make_approval_payload(p_dispId); /* this will raise error if approval has already been sent. Update willl be rolled back */
		COMMIT;
END//

DELIMITER ;
