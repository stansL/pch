delete from exception_types;
insert into exception_types(ex_code, name, descr) values
('nomatch', 'ex_match_failed', 'Biometric verification failed'),
('scstale','ex_card_is_stale','Card needs to be updated'),
('rvfail','ex_remote_verif_failed', 'Remote verification failed'),
('rcufail','ex_remote_sc_upd_failed', 'Remote smart card update failed'),
('scinval', 'ex_card_invalid', 'Card data is corrupt'),
('noresume', 'ex_cant_resume', 'Cannot resume visit (e.g. because verification failed)'),
('timeout', 'ex_visit_timdeout', 'Visit timed out (e.g. open for too long)');

delete from verification_types;
insert into verification_types(veri_type_id, name, descr) values
('fp', 'veri_fprint', 'Fingerprint verification'),
('face', 'veri_facial_recog', 'Facial recognition'),
('iris', 'veri_iris_auth', 'Iris-pattern authentication');

delete from visit_types;
insert into visit_types(visit_type_id, name, descr) values
('new', 'vis_fresh_visit', 'Fresh, new visit'),
('folup', 'vis_follow_up_visit', 'Follup up visit'),
('other','vis_other_visit', 'Other type of visit');

delete from dispensation_state_types;
insert into dispensation_state_types(disp_state_id, name, descr) values
('init','disp_started', 'Started'),
('done', 'disp_completed', 'Completed'),
('ok','disp_ok', 'Approval not required'),
('pendi','disp_apprvl_pending', 'Approval pending'),
('abort','disp_abandoned', 'Abandoned')
/*,('approved','disp_approved', 'Approved')
(',rejected','disp_rejected', 'Not approved--rejected')*/;

delete from approval_resp_groups;
insert into approval_resp_groups(resp_group_id, name, descr) values
('app','app_res_approved','Approved'),
('rej','app_res_rejected','Rejected'),
('retry','app_res_delay', 'Rejected now, but try later');

delete from transmission_modes;
insert into transmission_modes(tx_mode_id,  name, descr) values
('sms','tx_sms', 'SMS'),
('email','tx_email', 'E-mail')
/*,('other','tx_other' ,'Other')*/
;

delete from datatypes;
insert into datatypes(datatype, name, descr) values
('text','datatype_text','text'),
('int','datatype_int','whole number'),
('float','datatype_float','decimal number');

delete from productcat_detail_types;
insert into productcat_detail_types(name, datatype, descr) values
('prod_unit_price', 'float','unit price'),
('prod_unit_qty', 'float', 'quantity');

delete from product_categories;
insert into product_categories(catId, name, descr, sorter) values
(11000,'cat_drugs', 'Drugs', 1),
(12000,'cat_material', 'Material', 25),
(13000,'cat_vaccine', 'Vaccination',40),
(21000,'cat_consultation', 'Consultation', 5),
(22000,'cat_lab_test', 'Laboratory test', 10),
(24000,'cat_hospital', 'Hospitalisation',15),
(25000,'cat_delivery', 'Child delivery',20),
(90000,'cat_others', 'Other Services',999);

delete from units;
insert into units(unitId, name, descr) values
('none','unit_none','NA'),
('tabs', 'unit_tablet', 'tablet'),
('pack','unit_packet','packet'),
('l','unit_litre','litre'),
('kg','unit_kg','kg'),
('day', 'unit_day','day'),
('other','unit_other','other');

-- seek approval if...
delete from approval_reqmt_types;
insert into approval_reqmt_types(reqtypeId, name, descr) values
('cost', 'apreq_cost', 'total cost exceeds threshold'),
('qty', 'apreq_quantity', 'quantity exceeds threshold');
-- approval is independent of the caps

delete from insurer_status_types;
insert into insurer_status_types(typeId, name, descr) values
('act','ins_status_active', 'Active'),
('inact', 'ins_status_inactive', 'Disabled'),
('expir','ins_status_expired','Expired');


