<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/payers.php');

    if (isset($_SESSION['identitypayer'])) {
        $identitypayer = $_SESSION['identitypayer'];
        unset($_SESSION['identitypayer']);
    } else
        $identitypayer = $_POST['identitypayer'];

    $entitypayer = getEntityPayer($identitypayer);
    $smarty->assign('entitypayer', $entitypayer);
    $smarty->display('payers/editentitypayer.tpl');
?>