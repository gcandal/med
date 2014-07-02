<?php
include_once('../../config/init.php');

if (isset($_SESSION['identitypayer'])) {
    $identitypayer = $_SESSION['identitypayer'];
    unset($_SESSION['identitypayer']);
} else
    $identitypayer = $_POST['identitypayer'];

$smarty->assign('identitypayer', $identitypayer);
$smarty->display('procedures/editentitypayer.tpl');
?>