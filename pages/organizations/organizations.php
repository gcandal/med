<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/organizations.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $idaccount = $_SESSION['idaccount'];
    $organizations = getOrganizations($idaccount);
    $merged = array();

    foreach ($organizations as $organization) {
        $idorganization = $organization['idorganization'];
        $organization['members'] = getMembersFromOrganization($idorganization);

        array_push($merged, $organization);
    }

    $smarty->assign('ORGANIZATIONS', $merged);
    $smarty->display('organizations/organizations.tpl');
?>