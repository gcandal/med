<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $idAccount = $_SESSION['idaccount'];
    $subProcedures = getSubProcedures($idAccount, $_GET['idProcedure']);

    if (is_string($subProcedures)) {
        $_SESSION['error_messages'][] = $subProcedures;
        header('Location: ' . $BASE_URL + 'pages/procedures.php');

        exit;
    }

    $smarty->assign('SUBPROCEDURES', $subProcedures);
    $smarty->display('procedures/viewSubProcedures.tpl');

