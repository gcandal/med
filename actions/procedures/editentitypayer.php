<?php

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$name = $_POST['name'];

if($name) {
    if (checkDuplicateEntityName($_SESSION['idaccount'], $name)) {
        $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
        $_SESSION['field_errors']['name'] = 'Nome já existe';
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
        exit;
    }
}

$identitypayer = $_POST['identitypayer'];
$contractstart = $_POST['contractstart'];
$contractend = $_POST['contractend'];
$type = $_POST['type'];
$nif = $_POST['nif'];
$valueperk = $_POST['valueperk'];
$accountId = $_SESSION['idaccount'];

if($contractstart > $contractend && $contractend) {
    $_SESSION['error_messages'][] = 'Data do contrato não é coerente';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/procedures/editentitypayer.php');
    exit;
}

if($contractend) {

}

$_SESSION['success_messages'][] = 'Entidade editada com sucesso';

header("Location: $BASE_URL" . "pages/procedures/payers.php");
?>