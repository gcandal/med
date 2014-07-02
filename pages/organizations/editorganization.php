<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');

if (isset($_SESSION['idorganization'])) {
    $organization = getOrganization($_SESSION['idaccount'], $_SESSION['idorganization']);
    unset($_SESSION['idorganization']);
} else
    $organization = getOrganization($_SESSION['idaccount'], $_POST['idorganization']);

$smarty->assign('idorganization', $organization['idorganization']);
$smarty->display('organizations/editorganization.tpl');
?>