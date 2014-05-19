<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$accountId = $_SESSION['idaccount'];
$idprivatepayer = $_POST['idprivatepayer'];

if(!deletePrivatePayer($accountId, $idprivatepayer)) {
    $_SESSION['error_messages'][] = 'Esta entidade não pode ser apagada porque está associada a um procedimento';
}

header("Location: $BASE_URL" . "pages/procedures/payers.php");

?>