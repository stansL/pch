/*
<Tano Fotang> fotang@gmail.com

Sat Oct 22 12:08:47 WAT 2016

This file uses sqlstates 45100-45199
*/
DELIMITER //

DROP TRIGGER IF EXISTS bi_itemdetails//
CREATE TRIGGER bi_itemdetails before insert ON itemdetails
	FOR EACH ROW
		IF NOT detailMatchesCat(NEW.dispID, NEW.detail_type_id) THEN
				SIGNAL SQLSTATE '45101' SET MESSAGE_TEXT = 'Detail does not match product';
		END IF//

DROP TRIGGER IF EXISTS bu_itemdetails//
CREATE TRIGGER bu_itemdetails before update ON itemdetails
	FOR EACH ROW
		IF NOT detailMatchesCat(NEW.dispID, NEW.detail_type_id) THEN
				SIGNAL SQLSTATE '45101' 
					SET MESSAGE_TEXT = 'Detail does not match product';
		END IF//

DROP TRIGGER IF EXISTS bi_coverages//
CREATE TRIGGER bi_coverages before insert ON coverages
	FOR EACH ROW BEGIN
		IF NEW.amount IS NULL AND NEW.percentage IS NULL THEN
				SIGNAL SQLSTATE '45102' 
					SET MESSAGE_TEXT = 'Missing a valid value';
		END IF;
		IF NEW.percentage IS NOT NULL AND NEW.percentage>100 THEN
				SIGNAL SQLSTATE '45103' 
					SET MESSAGE_TEXT = 'Invalid value';
		END IF;
	END//

DROP TRIGGER IF EXISTS bu_coverages//
CREATE TRIGGER bu_coverages before update ON coverages
	FOR EACH ROW BEGIN
		IF NEW.amount IS NULL AND NEW.percentage IS NULL THEN
				SIGNAL SQLSTATE '45102' 
					SET MESSAGE_TEXT = 'Missing a valid value';
		END IF;
		IF NEW.percentage IS NOT NULL AND NEW.percentage>100 THEN
				SIGNAL SQLSTATE '45103' 
					SET MESSAGE_TEXT = 'Invalid value';
		END IF;
	END//

DROP TRIGGER IF EXISTS bi_dispensation//
CREATE TRIGGER bi_dispensation BEFORE INSERT on dispensation
	FOR EACH ROW BEGIN
		IF isExcludedProduct(NEW.productId, visit2insurer(NEW.visitId, TRUE)) THEN
				SIGNAL SQLSTATE '45105'
					SET MESSAGE_TEXT = 'Product is not offered';
		END IF;
		IF NOT isCoveredProduct(NEW.productId, visit2insurer(NEW.visitId, TRUE)) THEN
				SIGNAL SQLSTATE '45106'
					SET MESSAGE_TEXT = 'Product is not covered';
		END IF;
		/* apportion costs. Will it work here?? else do it in addDispensation() */
		SET @uprice = NEW.unitcost;
		CALL apportion_costs(visit2benId(NEW.visitId), NEW.productId, NEW.qty, @uprice, @totalcost, @insurercost);
		SET NEW.totalcost=@totalcost;
		SET NEW.insurer_cost=@insurer_cost;
		SET NEW.unitcost=@uprice;
	END//

DROP TRIGGER IF EXISTS ai_dispensation//
CREATE TRIGGER ai_dispensation AFTER INSERT on dispensation
	FOR EACH ROW BEGIN
		CALL setDispState(NEW.dispId, 'init', 'dispensation created');
		CALL make_approval_payload(NEW.dispId);
	END//

DROP TRIGGER IF EXISTS bu_dispensation//
CREATE TRIGGER bu_dispensation BEFORE UPDATE on dispensation
	FOR EACH ROW BEGIN
		IF isExcludedProduct(NEW.productId, visit2insurer(NEW.visitId, TRUE)) THEN
				SIGNAL SQLSTATE '45105'
					SET MESSAGE_TEXT = 'Product is not offered';
		END IF;
		IF NOT isCoveredProduct(NEW.productId, visit2insurer(NEW.visitId, TRUE)) THEN
				SIGNAL SQLSTATE '45106'
					SET MESSAGE_TEXT = 'Product is not covered';
		END IF;
		/* apportion costs. Will it work here?? else do it in updateDispensation() */
		SET @uprice = NEW.unitcost;
		CALL apportion_costs(visit2benId(NEW.visitId), NEW.productId, NEW.qty, @uprice,
			@totalcost, @insurercost);
		SET NEW.totalcost=@totalcost;
		SET NEW.insurer_cost=@insurer_cost;
		SET NEW.unitcost=@uprice;
	END//

DROP TRIGGER IF EXISTS au_dispensation//
CREATE TRIGGER au_dispensation AFTER UPDATE on dispensation
	FOR EACH ROW
		CALL make_approval_payload(NEW.dispId)
	//

DROP TRIGGER IF EXISTS bd_dispensation//
CREATE TRIGGER bd_dispensation BEFORE DELETE on dispensation
	FOR EACH ROW BEGIN
			IF dispState(OLD.dispId) IN ('done', 'abort') THEN
				SIGNAL SQLSTATE '45110' SET MESSAGE_TEXT = 'Already completed';
			END IF;
			IF responseRecvd(OLD.dispId) OR approvalSent(OLD.dispId) THEN
				CALL setDispState(OLD.dispId, 'abort', 'cancelled by user');
				SIGNAL SQLSTATE '45111' SET MESSAGE_TEXT = 'OK. State has been changed';
			END IF;
	END//


DROP TRIGGER IF EXISTS bi_beneficiaries//
CREATE TRIGGER bi_beneficiaries BEFORE INSERT ON beneficiaries
	FOR EACH ROW
		/* verify package/insurer match */
		IF NEW.packageId IS NOT NULL AND
				NOT EXISTS (
				SELECT * FROM packages
				 WHERE packageId=NEW.packageId AND insurerId = NEW.insurerId) THEN 
					SIGNAL SQLSTATE '45120'
						SET MESSAGE_TEXT = 'Package not for insurer';
		END IF//

DROP TRIGGER IF EXISTS bu_beneficiaries//
CREATE TRIGGER bu_beneficiaries BEFORE UPDATE ON beneficiaries
	FOR EACH ROW
		/* verify package/insurer match */
		IF NEW.packageId IS NOT NULL AND
				NOT EXISTS (
				SELECT * FROM packages
				 WHERE packageId=NEW.packageId AND insurerId = NEW.insurerId) THEN 
					SIGNAL SQLSTATE '45121'
						SET MESSAGE_TEXT = 'Package not for insurer';
		END IF//


DROP TRIGGER IF EXISTS ai_OrgsG3N3RAL//
CREATE TRIGGER ai_OrgsG3N3RAL AFTER INSERT ON organisations
FOR EACH ROW BEGIN 
	DECLARE v_userId int;
	DECLARE v_roleId int;
	DECLARE v_wheel int;
	DECLARE v_sysusr int;
	DECLARE out_orgId int;

	SET out_orgId=NEW.orgId;
--	BEGIN ATOMIC -- START TRANSACTION;
	INSERT INTO Roles(roleName,Description, orgId) VALUES('wheel', 'user administrative tasks', out_orgId);
	SET v_wheel=LAST_INSERT_ID();
	INSERT INTO Permissions(mode,RoleID) VALUES('USER', v_wheel);
	INSERT INTO users(orgId, Username,Password,Surname)
	       VALUES(out_orgId, 'wheel',  PASSWORD('3biggxz'), 'Big Wheel');
	SET v_userId = LAST_INSERT_ID();
	INSERT INTO User_roles(userId, roleId) VALUES(v_userId, v_wheel);

	INSERT INTO Roles(roleName,Description, orgId) VALUES('system','system rule keeper', out_orgId);
	SET v_roleId= LAST_INSERT_ID();
	INSERT INTO Permissions(mode,RoleID) VALUES('SYS', v_roleId),
	('ADDCATRANS', v_roleId),
	('ADDBATRANS', v_roleId),
	('ADDICTRANS', v_roleId);
	INSERT INTO users(orgId, Username,Password,Surname, othernames)
	    VALUES(out_orgId, 'system', PASSWORD('___0  ____'), 'system','internal rule keeper');
	SET v_userId = LAST_INSERT_ID();
	SET v_sysusr=v_userId;
	INSERT INTO User_roles(userId, roleId) VALUES(v_userId, v_roleId);

	INSERT INTO Roles(roleName,Description, orgId) VALUES('supervisor','Authorize exceptions', out_orgId);
	SET v_roleId= LAST_INSERT_ID();
	INSERT INTO Permissions(mode,RoleID) VALUES('AUTEX', v_roleId);

	INSERT INTO users(orgId, Username,Password,Surname, othernames)
		VALUES(out_orgId, 'super', PASSWORD('p@55wd'),'Super','Authorizor');
	SET v_userId = LAST_INSERT_ID();
	INSERT INTO User_roles(userId, roleId) VALUES(v_userId, v_roleId);

	INSERT INTO Roles(roleName,Description, orgId) VALUES('admin','system administrator',out_orgId);
	SET v_roleId= LAST_INSERT_ID();
	INSERT INTO Permissions(mode,RoleID) VALUES('DATA', v_roleId),
	('ADDQTR', v_roleId),
	('UPDQTR', v_roleId),
	('DELQTR', v_roleId),
	('ADMORG', v_roleId),
	('UPDORG', v_roleId),
	('DELORG', v_roleId),
	('ADDORGDADDR', v_roleId),
	('UPDORGDADDR', v_roleId),
	('DELORGDADDR', v_roleId),
	('ADDORGFONE', v_roleId),
	('UPDORGFONE', v_roleId),
	('DELORGFONE', v_roleId),
	('ADDORGEMAIL', v_roleId),
	('UPDORGEMAIL', v_roleId),
	('DELORGEMAIL', v_roleId),
	('ADDORGCONTACT', v_roleId),
	('UPDORGCONTACT', v_roleId),
	('DELORGCONTACT', v_roleId),
	('USER', v_roleId),
	('AUTEX', v_roleId);
	INSERT INTO Roles(roleName,Description, orgId) VALUES('reports','generate reports',out_orgId);

--	insert into salutation_types2(abbrev, orgId, descr, sort) select s.salut_id, out_orgId, s.descr, 100 from salutation_types s order by sort,salut_id asc;

-- END;--	COMMIT;
END//


DELIMITER ;
