insert into exception_types(ex_code, name, descr) values
('nomatch', 'ex_match_failed', 'Biometric verification failed'),
('scstale','ex_card_is_stale','Card needs to be updated'),
('rvfail','ex_remote_verif_failed', 'Remote verification failed'),
('rcufail','ex_remote_sc_upd_failed', 'Remote smart card update failed'),
('scinval', 'ex_card_invalid', 'Card data is corrupt'),
('noresume', 'ex_cant_resume', 'Cannot resume visit (e.g. because verification failed)'),
('exvisit', 'ex_visit_timdeout', 'Visit timed out');

insert into verification_types(veri_type_id, name, descr) values
('fprint', 'veri_fingerprint_verif', 'Fingerprint verification'),
('face', 'veri_facial_recog', 'Facial recognition'),
('iris', 'veri_iris_auth', 'Iris-pattern authentication');

insert into visit_types(visit_type_id, name, descr) values
('new', 'vis_fresh_visit', 'Fresh, new visit'),
('folup', 'vis_follow_up_visit', 'Follup up visit'),
('other','vis_other_visit', 'Other type of visit');

insert into dispensation_state_types(disp_state_id, name, descr) values
('init','disp_started', 'Started'),
('done', 'disp_completed', 'Completed'),
('ok','disp_ok', 'Approval not required'),
('pending','disp_approval_pending', 'Approval pending')
/*,('approved','disp_approved', 'Approved')
(',rejected','disp_rejected', 'Not approved--rejected')*/;

insert into approval_resp_groups(resp_group_id, name, descr) values
('approved','app_res_approved','Approved'),
('rejected','app_res_rejected','Rejected'),
('tryagain','app_res_delay', 'Rejected now, but try later');

insert into transmission_modes(tx_mode_id,  name, descr) values
('sms','tx_sms', 'SMS'),
('email','tx_email', 'E-mail')
/*,('other','tx_other' ,'Other')*/
;

insert into datatypes(datatype, name, descr) values
('text','datatype_text','text'),
('int','datatype_int','whole number'),
('float','datatype_float','decimal number');

insert into productcat_detail_types(name, datatype, descr) values
('uprice','prod_unit_price','unit price'),
('qty', 'prod_unit_qty', 'quantity');

insert into product_categories(catId, name, descr) values
('drug', 'cat_drus', 'Drugs'),
('consult','cat_consultation', 'Consultation'),
('mat','cat_material', 'Material'),
('lab','cat_lab_test', 'Laboratory test'),
('deliv','cat_delivery', 'Child delivery'),
('vac','cat_vaccine', 'Vaccination'),
('os','cat_others', 'Other Services');

insert into units(unitId, name, descr) values
('none','unit_none','NA'),
('tabs', 'unit_tablet', 'tablet'),
('packet','unit_packet','packet'),
('l','unit_litre','litre'),
('kg','unit_kg','kg'),
('day', 'unit_day','day'),
('other','unit_other','other');

-- seek approval if...
insert into approval_reqmt_types(reqtypeId, name, descr) values
('cost', 'apreq_cost', 'total cost exceeds threshold'),
('qty', 'apreq_quantity', 'quantity exceeds threshold');
-- approval is independent of the caps

insert into insurer_status_types(typeId, name, descr) values
('active','ins_status_active', 'Active'),
('inact', 'ins_status_inactive', 'Disabled'),
('expired','ins_status_expired','Expired');


