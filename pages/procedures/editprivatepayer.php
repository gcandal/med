<?php
    include_once('../../config/init.php');

    if (isset($_SESSION['idprivatepayer'])) {
        $idprivatepayer = $_SESSION['idprivatepayer'];
        unset($_SESSION['idprivatepayer']);
    } else
        $idprivatepayer = $_POST['idprivatepayer'];

    $smarty->assign('idprivatepayer', $idprivatepayer);
    $smarty->display('procedures/editprivatepayer.tpl');
?>