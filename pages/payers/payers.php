<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/payers.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $idaccount = $_SESSION['idaccount'];
    $entities['Privado'] = getPrivatePayers($idaccount);

    $smarty->assign('ENTITIES', $entities);
    $smarty->display('payers/payers.tpl');