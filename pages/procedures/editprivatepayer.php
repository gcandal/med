<?php
include_once('../../config/init.php');

$smarty->assign('idprivatepayer', $_POST['idprivatepayer']);
$smarty->display('procedures/editprivatepayer.tpl');
?>