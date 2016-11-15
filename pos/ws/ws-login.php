<?php
/* webservice for user authentication
 *
 *
 * fotang, Fri Nov  4 14:17:54 WAT 2016
 * 
 * op		params
 * login	uName=<username>, orgId=<orgid>,magik=<system magic>,remHost=,machineID=, machineIDType
 * logout	uName=<appId>
 * */

ini_set('session.save_path', '../tmp');
session_start();
include_once('connection.php');



$op = php_noquote_NVL('op', 'post');
if($op === NULL)
	$op = php_noquote_NVL('op', 'get');
if($op === NULL) {
    send_error('Missing operation', '',  WS_ERR_PARAM);
}

/*
if(!isset($ops[$op])){
    send_error("Unknown operation: {$op}", '', WS_ERR_PARAM);
}
 */
$conn = $dbinst->getConnection();
$uName = mysqlvarval_NVL('uName', $conn);// connection id for logoutUser
if($uName == 'NULL')
	send_error('Missing arg -- username', '', WS_ERR_MISSING);
if($op == 'login'){
	$pass=mysqlvarval_NVL('pass', $conn, 'post');
	if($pass == 'NULL')
		send_error('Missing arg -- password', '', WS_ERR_MISSING);
	$orgId = mysqlvarval_NVL('orgID', $conn);
	$magik = mysqlvarval_NVL('magik', $conn);
	$remHost = mysqlvarval_NVL('remHost', $conn);
	$machineID = mysqlvarval_NVL('machineID', $conn);
	$machineIDType = mysqlvarval_NVL('machineIDType', $conn);
	$proc = 'loginUser';
	$params = $uName . ",". $orgId . "," . $pass . "," . $machineID . "," . $machineIDType . "," . $remHost . "," . $magik;
//	die($params);
}else if($op == 'logout'){
	$remHost = client_ip_address(); 
	$proc = 'logoutUser';
	$params = $uName;
}else{
	send_error("Operation not implemented -- ${op}", '', WS_ERR_NOTIMPL);
}
try{
	$result = $dbinst->procCall($proc, $params);
	if($op == 'login'){
		$_SESSION['username'] = $_POST['uName'];
		$_SESSION['loggedIn'] = true;
		$_SESSION['userDetails'] = $result[0][0];
		$_SESSION['userid'] = $_SESSION['userDetails']['USERID'];
		$_SESSION['appid'] = $_SESSION['userDetails']['APPID'];
		$perm_array=array();
		foreach ($result[1] as $p)
			$perm_array[]= $p['MODE'];
		$_SESSION['perms']=$perm_array;
	}else if($op == 'logout'){
		session_destroy();
	}
	send_result(make_result($result));
}catch(exception $e){
	if($op == 'logout')
		session_destroy();
	send_error($e->getMessage(), $proc, 100);
}
?>
