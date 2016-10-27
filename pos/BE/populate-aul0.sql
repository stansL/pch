-- admin units level1 for NGA, CMR, GHA.
-- additional: sample level2, level3, towns for CMA, quarters for CMR/Bamenda
--
-- mfotang, 15-sep-13


--#SET TERMINATOR ;



-- cameroon
INSERT into aul1(aul1code,countrycode,aul1Name) VALUES ('AD','CM','Adamawa'),('CE','CM','Centre'),('E','CM','East'),('EN' ,'CM','Extreme Nord'),('LT','CM','Littoral'),('N','CM','Nord'),('NW','CM','Northwest'),('OU','CM','Ouest'),('S','CM','South'),('SW','CM','Southwest');
insert into aul1(countrycode,aul1Code,aul1Name) values('CM','xx','Unknown');
-- nigeria
INSERT into aul1(aul1code,countrycode,aul1Name) VALUES ('AB','NG','Abia'),('AD','NG','Adamawa'),('AI','NG','Akwa ibom'),('AN','NG','Anambra'),('BA','NG','Bauchi'),('BN','NG','Benue'),('BO','NG','Borno'),('BY','NG','Bayelsa'),('CR','NG','Cross river'),('DT','NG','Delta'),
('EB','NG','Ebonyi'),('ED','NG','Edo'),('EK','NG','Ekiti'),('EN','NG','Enugu'),('FC','NG','FCT'),('GB','NG','Gombe'),('IM','NG','Imo'),('JG','NG','Jigawa'),('KB','NG','Kebbi'),('KD','NG','Kaduna'),('KG','NG','Kogi'),('KN','NG','Kano'),('KT','NG','Katsina'),('KW','NG',
'Kwara'),('LA','NG','Lagos'),('NG','NG','Niger'),('NS','NG','Nassarawa'),('OD','NG','Ondo') ,('OG','NG','Ogun'),('OS','NG','Osun'),('OY','NG','Oyo'),('PL','NG','Plateau'),('RV','NG', 'Rivers'),('SO','NG','Sokoto'),('TR','NG','Taraba'),('YB','NG','Yobe'),('ZF','NG','Zamfara');
insert into aul1(countrycode,aul1Code,aul1Name) values('NG','xx','Unknown');
-- ghana
insert into aul1 (AUL1Code, countrycode, aul1Name) values('as','GH','Ashanti');
insert into aul1 (aul1Code, countrycode, aul1Name) values('br','GH','Brong Ahafo');
insert into aul1 (aul1Code, countrycode, aul1Name) values('ct','GH','Central');
insert into aul1 (aul1Code, countrycode, aul1Name) values('et','GH','Eastern');
insert into aul1 (aul1Code, countrycode, aul1Name) values('ga','GH','Greater Accra');
insert into aul1 (aul1Code, countrycode, aul1Name) values('nt','GH','Northern');
insert into aul1 (aul1Code, countrycode, aul1Name) values('ue','GH','Upper East');
insert into aul1 (aul1Code, countrycode, aul1Name) values('uw','GH','Upper West');
insert into aul1 (aul1Code, countrycode, aul1Name) values('vl','GH','Volta');
insert into aul1 (aul1Code, countrycode, aul1Name) values('wt','GH','Western');
insert into aul1(countrycode,aul1Code,aul1Name) values('GH','xx','Unknown');

-- select 'populating AUL2' from sysibm.sysdummy1;
insert into aul2(countrycode,aul1Code,aul2Code,aul2name) values('CM','xx',99,'Unknown');
insert into aul2(countrycode,aul1Code,aul2Code,aul2name) values('CM','NW',1,'Mezam');
insert into aul2(countrycode,aul1Code,aul2Code,aul2name) values('CM','NW',99,'unknown');
insert into aul2(countrycode,aul1Code,aul2Code,aul2name) values('CM','SW',1,'Lebialem');
insert into aul2(countrycode,aul1Code,aul2Code,aul2name) values('CM','SW',99,'unknown');
insert into aul2(countrycode,aul1Code,aul2Code,aul2name) values('CM','LT',99,'Unknown');
insert into aul2(countrycode,aul1Code,aul2Code,aul2name) values('CM','OU',99,'Unknown');
insert into aul2(countrycode,aul1Code,aul2Code,aul2name) values('CM','CE',99,'Unknown');

insert into aul3(aul3Id, countrycode,aul1Code,aul2Code,aul3code,aul3name) values
(20000, 'CM','xx',99,99,'Unknown'),
(20001, 'CM','NW',99,99,'Unknown'),
(20002, 'CM','NW',01,99,'Unknown'),
(20003, 'CM','SW',99,99,'Unknown'),
(20004, 'CM','SW',01,99,'Unknown'), 
(20005, 'CM','LT',99,99,'Unknown'), 
(20006, 'CM','OU',99,99,'Unknown'),
(20008, 'CM','CE',99,99,'Unknown');

-- echo populate towns;
insert into towns(townId,townName,aul3Id) values('bda','Bamenda', 20002),('dla','Douala', 20005),('yde','Yaounde', 20008),('baf','Bafoussam', 20006),('ml','Mmuock-Leteh', 20004);
-- echo 'populate qtrs';
insert into addr_quarters(qtrname, townId) values('Atuakom', 'bda'),('Abangoh', 'bda'),('Metta Qtrs', 'bda'), ('Old Town', 'bda'),('Upstation', 'bda'),('Big Mankon', 'bda'),('Cow Street', 'bda') ,('Ghana Street', 'bda'),('Ntarikon', 'bda'),('Small Mankon', 'bda'),('Mile 4 Nkwen', 'bda');


