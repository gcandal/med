<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/organizations.php');

    if (isset($_SESSION['idorganization'])) {
        $idorganization = $_SESSION['idorganization'];
        unset($_SESSION['idorganization']);
    } else
        $idorganization = $_POST['idorganization'];

    $organization = getOrganization($_SESSION['idaccount'], $idorganization);

    $smarty->assign('idorganization', $organization['idorganization']);
    $smarty->display('organizations/editorganization.tpl');
?>