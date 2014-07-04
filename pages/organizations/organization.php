<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/organizations.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $idaccount = $_SESSION['idaccount'];
    $idorganization = $_GET['idorganization'];

    if (!isMember($idaccount, $idorganization)) {
        $_SESSION['error_messages'][] = 'Tem que ser membro de uma organização para ver os seus detalhes';
        header('Location: ' . $BASE_URL . 'pages/organizations/organizations.php');

        exit;
    }

    $organization = getOrganization($idaccount, $idorganization);
    $organization['members'] = getMembersFromOrganization($idorganization);

    $smarty->assign('organization', $organization);
    $smarty->display('organizations/organization.tpl');
?>