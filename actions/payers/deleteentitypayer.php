<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/payers.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $accountId = $_SESSION['idaccount'];
    $identitypayer = $_POST['identitypayer'];

    if (!deleteEntityPayer($accountId, $identitypayer)) {
        $_SESSION['error_messages'][] = 'Esta entidade não pode ser apagada porque está associada a um procedimento';
    }

    header("Location: $BASE_URL" . "pages/payers/payers.php");

?>