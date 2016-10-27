/*
<Tano Fotang> fotang@gmail.com

Sat Oct 22 12:08:47 WAT 2016

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
	FOR EACH ROW
		IF NEW.amount IS NULL AND NEW.percentage IS NULL THEN
				SIGNAL SQLSTATE '45102' 
					SET MESSAGE_TEXT = 'Missing a valid value';
		END IF//

DROP TRIGGER IF EXISTS bu_coverages//
CREATE TRIGGER bu_coverages before update ON coverages
	FOR EACH ROW
		IF NEW.amount is null AND NEW.percentage is null THEN
				SIGNAL SQLSTATE '45102'
					SET MESSAGE_TEXT = 'Missing a valid value';
		END IF//

DELIMITER ;
