/*
<Tano Fotang> fotang@gmail.com

Sat Oct 22 13:23:58 WAT 2016

*/

DELIMITER //

/* -------------------- */
/* Dispensation details */
/* -------------------- */
DROP FUNCTION IF EXISTS detailMatchesCat//
CREATE FUNCTION detailMatchesCat(IN p_dispId int, p_detail_type) RETURNS BOOL
/* check whether the details match the product */
BEGIN
		RETURN EXISTS(
			  select * 
				from dispensation d
				join products p ON p.productId=d.productId
				join product_categories c ON c.catId=p.productId
				join required_details r ON r.catId = c.catId
			   		 where r.insurerId=p_insurerId AND r.detail_type_id=p_detail_type);
END//


DROP PROCEDURE IF EXISTS getDetailReqForProduct//
CREATE PROCEDURE getDetailReqForProduct(IN p_prouctId int, IN p_insurerId int)
/* fetch the type of details that must be provided at product dispensation */
BEGIN
		select p_productId AS productId, r.insurerId, c.catId,
			   d.detail AS detailId, d.name, d.datatype, d.descr
		  from products p
		  join product_categories c ON c.catId=p.catId
		  join required_details r ON r.catId = c.catId AND r.insurerId = p_insurerId
		  join approval_reqmt_types d ON d.detail_type_id = r.detail_type_id
		       where p.productId = p_productId
			   order by sorter asc;
END//

DROP PROCEDURE IF EXISTS addInsurer//
CREATE PROCEDURE addInsurer(IN p_connId varchar(255), IN p_alias varchar(128), IN p_name varchar(255), OUT p_Id int)
BEGIN
	CALL verifyPrivilege(in_connId, 'addInsurer', 'ADDINSURER');
	INSERT INTO insurers(alias, name) values(p_alias, p_name);
	SET p_id = LAST_INSERT_ID();
END//
DELIMITER ;
