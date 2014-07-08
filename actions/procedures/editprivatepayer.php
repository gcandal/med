<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$idprivatepayer = $_POST['idprivatepayer'];
$name = $_POST['name'];
$nif = $_POST['nif'];
$accountId = $_SESSION['idaccount'];

if ($name) {
    if (checkDuplicateEntityName($accountId, $name)) {
        $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
        $_SESSION['field_errors']['name'] = 'Nome já existe';
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idprivatepayer'] = $idprivatepayer;

        header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
        exit;
    }

    try {
        editPrivatePayerName($accountId, $name, $idprivatepayer);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar entidade ' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idprivatepayer'] = $idprivatepayer;

        header("Location: $BASE_URL" . 'pages/procedures/editprivatepayer.php');
        exit;
    }
}

if ($nif) {
    try {
        editPrivatePayerNIF($accountId, $idprivatepayer, $nif);
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'validnif') !== false) {
            $_SESSION['error_messages'][] = 'NIF inválido';
            $_SESSION['field_errors']['nif'] = 'NIF inválido';
        } else $_SESSION['error_messages'][] = $e->getMessage();

        $_SESSION['form_values'] = $_POST;

        $_SESSION['idprivatepayer'] = $idprivatepayer;

        header("Location: $BASE_URL" . 'pages/procedures/editprivatepayer.php');
        exit;
    }

}

$_SESSION['success_messages'][] = 'Entidade editada com sucesso';

header("Location: $BASE_URL" . "pages/procedures/payers.php");
?>