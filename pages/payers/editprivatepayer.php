<?php

include_once('../../config/init.php');
include_once($BASE_DIR . 'database/payers.php');

if (isset($_SESSION['idprivatepayer'])) {
    $idprivatepayer = $_SESSION['idprivatepayer'];
    unset($_SESSION['idprivatepayer']);
} else
    $idprivatepayer = $_GET['idprivatepayer'];


$privatepayer = getPrivatePayer($idprivatepayer);
$smarty->assign('privatepayer', $privatepayer);
$smarty->display('payers/editprivatepayer.tpl');
