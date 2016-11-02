/*
fotang, 
Tue Oct 11 20:25:41 WAT 2016

*/

delimiter ;
SET FOREIGN_KEY_CHECKS = 1;
-- 1. Reference data

-- Entity: Exception Type
drop table if exists exception_types;
create table exception_types(
	ex_code varchar(8) not null primary key
	,name varchar(32) not null /* for use in translation strings */
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);


-- Entity: Verification Type
drop table if exists verification_types;
create table verification_types(
	veri_type_id char(5) not null primary key
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);


-- Entity: Visit Type
drop table if exists visit_types;
create table visit_types(
	visit_type_id char(5) not null primary key
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);


-- Entity: DispensationState
drop table if exists dispensation_state_types;
create table dispensation_state_types(
	disp_state_id char(5) not null primary key
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);


-- Entity: Approval Response Type
drop table if exists approval_resp_groups;
create table approval_resp_groups(
	resp_group_id char(5) not null primary key
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
) comment='Types of responses from the approver';


-- Entity:
drop table if exists transmission_modes;
create table transmission_modes(
	tx_mode_id char(5) not null primary key
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);


-- Entity: Datatype
drop table if exists datatypes;
create table datatypes(
	datatype varchar(16) not null primary key
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);


/*
Entity: ProductCategory Detail Type
Kinds of details that are must be provided when a product is dispensed.
*/
drop table if exists productcat_detail_types;
create table productcat_detail_types(
	detail_type_id int auto_increment not null primary key
	,name varchar(32) not null
	,datatype varchar(16) not null default 'text'
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
	,constraint foreign key(datatype) references datatypes(datatype) on delete no action
);

-- Entity: Product Category

drop table if exists product_categories;
create table product_categories(
	catId int not null primary key /* to be set centrally */
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);

-- Entity: Unit

drop table if exists units;
create table units(
	unitId char(5) not null primary key
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);

-- Entity: Approval Requirement Type

drop table if exists approval_reqmt_types;
create table approval_reqmt_types(
	/* service provider must only read this */
	reqtypeId char(5) not null primary key
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);

-- Entity: InsurerStatusType

drop table if exists insurer_status_types;
create table insurer_status_types(
	typeId char(5) not null primary key
	,name varchar(32) not null
	,descr varchar(128) not null
	,sorter int not null default 9999
	,constraint uniq_name unique(name)
);

-- ---------------------------
-- 2. transaction data
-- ---------------------------

-- Entity: Organisation
drop table  if exists organisations;
CREATE TABLE organisations (
	/* the service provider */
		orgId INTEGER auto_increment NOT NULL PRIMARY KEY
		,code INTEGER NOT NULL -- this can also work as PK
		,name VARCHAR(255) NOT NULL
		,expiryDate datetime NOT NULL
		,createdBy integer null
		,createdAt timestamp not null default current_timestamp
		,constraint uniq_code unique(code)
		,constraint foreign key(createdBy) references users(userId) on delete no action
);

-- Entity: Insurer
drop table if exists insurers;
create table insurers(
		/*
		read insurer ID from the SC.
		The ID must already exist we can create a visit.
		ID is assigned centrally to insurers.
		*/
		insurerId int not null primary key
		
		,alias varchar(32) not null comment 'short name' -- may be stored on card
		,name varchar(255) not null comment 'full name'
		,status char(5) not null default 'act'
		,createdAt timestamp not null default current_timestamp
		,createdBy int
		,constraint uniq_alias unique(alias)
		,constraint foreign key(status) references insurer_status_types(typeId) on delete no action
) ENGINE=InnoDB;

-- Entity: SP-Insurer Affiliation

drop table if exists sp_affiliations;
create table sp_affiliations(
	insurerId int not null
	,orgId int not  null
	,status char(5) not null default 'inact'
	,primary key(insurerId, orgId)
	,constraint foreign key(insurerId) references insurers(insurerId) on delete cascade
	,constraint foreign key(orgId) references organisations(orgId) on delete cascade
	,constraint foreign key(status) references insurer_status_types(typeId) on delete no action

);

-- Entity: Detail Requirement
-- details required when an item of the product category is dispensed

drop table if exists required_details;
create table required_details(
	/* this is red-only to the service provider.
 	   this should probably be defined on insurer basis. */
	catId int not null
	,detail_type_id int not null
	,insurerId int null-- null means it applies to all insurers
	,mandatory boolean default TRUE -- must be provided?
	,primary key(detail_type_id, catId) 
	,constraint foreign key(insurerId) references insurers(insurerId) on delete cascade
	,constraint foreign key(catId) references product_categories(catId) on delete cascade
	,constraint foreign key(detail_type_id) references productcat_detail_types(detail_type_id)  on delete cascade 
) ENGINE=InnoDB;

drop table if exists insurer_addresses;
CREATE TABLE insurer_addresses (
	addrId integer auto_increment primary key not null
	,insurerId int not null
	,addrTypeId VARCHAR(8) NOT NULL
	,adrL1 varchar(64) not null
	,adrL2 varchar(64) 
	,city varchar(64) not null
	,countryCode char(2) not null
	,remark varchar(255)
/*	,createdBy integer not null 
	,createdAt timestamp not null default current_timestamp
	,modifiedBy integer 
	,modifiedAt timestamp
*/
	,constraint uniq_addrtypeid unique(insurerId, addrTypeId)
/*	,constraint fk_users foreign key(createdBy) references Users(userId) on delete no action
	,constraint fk_users1 foreign key(modifiedBy) references Users(userId) on delete no action*/
	,constraint fk_addrtypes foreign key(addrTypeId) references Address_types(addrTypeId) on delete no action
/*	,constraint fk_quarters foreign key(qtrId) references addr_quarters(qtrId) on delete no action*/
	,constraint foreign key(insurerId) references insurers(insurerId) on delete cascade
	,constraint fk_cc foreign key(countryCode) references countries(countryCode) on delete no action
) ENGINE=InnoDB;


drop table if exists approvers;
create table approvers(
	approverId int auto_increment not null primary key
	,insurerId int not null
	,TxMode char(5) not null
	,value varchar(255) not null
	,remark varchar(255)
	,constraint uniq_1 unique(insurerId, TxMode, value(128))
	,constraint fk_insurers foreign key(insurerId) references insurers(insurerId) on delete cascade
	,constraint foreign key(TxMode) references transmission_modes(tx_mode_id) on delete cascade

) ENGINE=InnoDB comment 'Destinations for approval requests';

/*
drop table if exists approval_phone_nos;
create table approval_phone_nos(
	phone varchar(32) not null primary key
	,insurerId int not null
	,remark varchar(255)
	,constraint fk_insurers foreign key(insurerId) references insurers(insurerId) on delete cascade
) ENGINE=InnoDB;
*/

-- Entity Product
drop table if exists products;
create table products(
		productId integer auto_increment primary key not null
		,productCode varchar(32) not null -- assigned centrally
		,catId int not null
		,cost decimal(10,2)
		,descr varchar(255)
		,constraint uniq_prodCode unique(productCode)
		,constraint fk_product_category foreign key(catId) references product_categories(catId) on delete cascade
) ENGINE=InnoDB;

-- Entity: ProductUnit
drop table if exists product_units;
create table product_units(
	productId integer not null
	,unitId char(5) not null 
	,primary key(productId, unitId)
	,constraint foreign key(productId) references products(productId) on delete cascade
	,constraint foreign key(unitId) references units(unitId) on delete no action
) ENGINE=InnoDB;

--Entity: Approval Requirement

drop table if exists approval_reqmts;
create table approval_reqmts(
	id int auto_increment not null primary key
	,reqtypeId char(5) not null 
	,insurerId int not null
	,constraint uniq_1 unique(insurerId, reqtypeId)
	,constraint foreign key(insurerId) references insurers(insurerId) on delete cascade
	,constraint foreign key(reqtypeId) references approval_reqmt_types(reqtypeId) on delete cascade
) ENGINE=InnoDB;


-- Entity: Product Approval Requirement

drop table if exists product_approval_reqmts;
create table product_approval_reqmts(
		approvalId int not null
		,productId int not null
		,value decimal default null -- null means: approval is required each and every time
		,primary key(approvalId, productId)
		,constraint foreign key(approvalId) references approval_reqmts(Id) on delete cascade
		,constraint foreign key(productId) references products(productId) on delete cascade
) ENGINE=InnoDB;

--Entity: Package
-- how will the packages be updated at the service provider??
drop table if exists packages;
create table packages(
	packageId int auto_increment not null primary key
	,insurerId int not null
	,name varchar(32) not null
	,descr varchar(255)
	,constraint uniq_name unique(insurerId, name)
	,constraint foreign key(insurerId) references insurers(insurerId) on delete cascade
) ENGINE=InnoDB;

-- Entity: Coverage

drop table if exists coverages;
create table coverages(
		coverageId int auto_increment not null primary key
		,catId int not null
		,packageId int not null
		,amount decimal(8,2)
		,percentage decimal(3,2)
		,constraint uniq_catid unique(catid,packageId)
		,constraint check_values check(amount is not null or percentage is not null) /* use trigger; mysql doesnt do check */
		,constraint foreign key(catId) references product_categories(catId) on delete cascade
		,constraint foreign key(packageId) references packages(packageId) on delete cascade
) ENGINE=InnoDB;

-- Entity: ExcludedProductCategory

drop table if exists excluded_categories;
create table excluded_categories(
	catId int not null
	,insurerId int not null
	,primary key(catId, insurerId)
	,constraint foreign key(insurerId) references insurers(insurerId) on delete cascade
	,constraint foreign key(catId) references product_categories(catId) on delete cascade

) ENGINE=InnoDB;

-- Entity: Beneficiary
drop table if exists beneficiaries;
create table beneficiaries(
	benId varchar(32) not null primary key -- constructed from cardholder Id and insurerId
	,surname varchar(64) not null
	,lastname varchar(64)
	,sex char(1) not null
	,dob date not null
	,insurerId int not null -- insurer
	,orgId int not null 	-- service provider
	,packageId int -- read package name from smartcard; use it to find packageId
	,constraint foreign key(insurerId) references sp_affiliations(insurerId) on delete cascade
	,constraint foreign key(orgId) references sp_affiliations(orgId) on delete cascade
	,constraint foreign key(packageId) references packages(packageId) on delete no action
	,constraint fk_sex foreign key(sex) references gender_types(sex) on delete no action
) ENGINE=InnoDB;

-- Entity: Visit

drop table if exists visits;
create table visits(
		visitId int auto_increment not null primary key
		,benId varchar(32)  not null
		,visitTime  timestamp not null default current_timestamp
		,visitEnd	timestamp null
		,visitTypeId char(5) not null
		,veri_type_id  char(5) not null
		,remote_verif bool default false comment 'true if remote verification was used'
		,userId int not null
		,foreign key(visitTypeId) references visit_types(visit_type_id) on delete no action
		,foreign key(veri_type_id) references verification_types(veri_type_id) on delete no action
		,foreign key(benId) references beneficiaries(benId) on delete no action
) ENGINE=InnoDB;

-- Entity: Exception

drop table if exists visit_exceptions;
create table visit_exceptions(
		ex_Id int auto_increment not null primary key
		,visitId int not null
		,code varchar(8) not null
		,at timestamp not null default current_timestamp
		,details varchar(255)
		,foreign key(code) references exception_types(ex_code) on delete no action
		,foreign key(visitId) references visits(visitId) on delete cascade
) ENGINE=InnoDB;

-- Entity: Dispensation

drop table if exists dispensation;
create table dispensation(
		dispId int auto_increment not null primary key
		,visitId int not null
		,productId int not null
		,qty float not null
		,unitcost decimal not null
		,totalcost decimal not null
		,insurer_discount decimal default 0 comment 'discount to the insurer_cost'
		,insurer_cost decimal not null comment 'cost to the insurer'
		,remark varchar(255)
		,createdAt timestamp not null default current_timestamp
		,createdBy int not null
		,modifieddAt timestamp on update current_timestamp
		,modifiedBy int
--		,constraint uniq_q unique(visitId, productId)
		,constraint foreign key(createdBy) references users(userId) on delete no action
		,constraint foreign key(productId) references products(productId) on delete no action
		,constraint foreign key(visitId) references visits(visitId) on delete cascade
) ENGINE=InnoDB;

-- Entity: ItemDetail

drop table if exists itemdetails;
create table itemdetails(
		dispId int not null
		,detail_type_id int not null
		,value varchar(255) not null -- if number then stored as text
		,primary key(detail_type_id, dispId)
		-- use trigger to check that detail type matches product category! see detailMatchesCatl().
		,constraint foreign key(detail_type_id) references productcat_detail_types(detail_type_id)  on delete no action
		,constraint foreign key(dispId) references dispensation(dispId) on delete cascade
) ENGINE=InnoDB;


-- Entity: DispensationState

drop table if exists dispensation_states;
create table dispensation_states(
		recId int auto_increment not null primary key
		,dispId int not null
		,disp_state_id char(5) not null
		,remark varchar(255)
		,createdAt timestamp not null default current_timestamp
		,constraint foreign key(dispId) references dispensation(dispId) on delete cascade
		,constraint foreign key(disp_state_id) references dispensation_state_types(disp_state_id) on delete no action
) ENGINE=InnoDB;

--Entity: Approval Payload

drop table if exists approval_payloads;
create table approval_payloads(
		dispId int not null primary key
		,payload varchar(160) not null -- limit to size of an SMS
		,createdAt timestamp not null default current_timestamp
		,constraint foreign key(dispId) references dispensation(dispId) on delete cascade
);

-- Entity: Approval Request

drop table if exists approval_reqs;
create table approval_reqs(
		dispId int not null primary key -- we'll overwrite (update) if resending the request
		,payload varchar(160) not null -- limit to size of an SMS
		,approverId int not null
		,TxAt timestamp -- time request was transmitted. null: not yet send
		,constraint foreign key(dispId) references approval_payloads(dispId) on delete cascade
		,constraint foreign key(approverId) references approvers(approverId) on delete no action
) ENGINE=InnoDB;


drop table if exists approval_responses;
create table approval_responses(
		dispId int not null primary key -- update if already exists
		,approverId int not null
		,payload varchar(160) not null
		,resp_group_id char(5) not null
		,RxAt timestamp not null default current_timestamp
		,constraint foreign key(resp_group_id) references approval_resp_groups(resp_group_id) on delete no action
		,constraint foreign key(dispId) references dispensation(dispId) on delete cascade
	--	,constraint foreign key(TxMode) references transmission_modes(tx_mode_id) on delete no action
		,constraint foreign key(approverId) references approvers(approverId) on delete no action
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

