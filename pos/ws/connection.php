<?php
	include_once('util2.php');
	include_once('MysqlConnection.php');
    try{
        $dbinst = new MysqlConnection();
    }catch(exception $e){
        send_error($e->getMessage(), '', 100);
    }
	
?>
