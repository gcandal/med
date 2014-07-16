<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');
    include_once($BASE_DIR . 'database/users.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $idAccount = $_SESSION['idaccount'];
    $username = getUserById($idAccount);
    $openProcedures = getNumberOfOpenProcedures($idAccount);
    $procedures = getProcedures($idAccount);

    $smarty->assign('USERNAME', $username);
    $smarty->assign('OPENPROCEDURES', $openProcedures);
    $smarty->assign('PROCEDURES', $procedures);
    $smarty->display('procedures/procedures.tpl');


