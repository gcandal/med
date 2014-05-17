<?php
include_once('../../config/init.php');

$smarty->assign('identitypayer', $_POST['identitypayer']);
$smarty->display('procedures/editentitypayer.tpl');
?>