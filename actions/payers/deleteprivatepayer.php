<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/payers.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $accountId = $_SESSION['idaccount'];
    $idprivatepayer = $_POST['idprivatepayer'];

    if (!deletePrivatePayer($accountId, $idprivatepayer)) {
        $_SESSION['error_messages'][] = 'Este pagador não pode ser apagado porque está associado a um procedimento';
    }

    header("Location: $BASE_URL" . "pages/payers/payers.php");

?>