<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/payers.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

if (!$_POST['type']) {
    $_SESSION['error_messages'][] = 'Tipo indefinido';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/payers/addpayer.php');
    exit;
}

$name = $_POST['name'];
$nif = $_POST['nif'];
$valueperk = $_POST['valueperk'];
if (!$valueperk) $valueperk = null;
$accountId = $_SESSION['idaccount'];
$type = $_POST['type'];

if (!$_POST['name']) $_SESSION['field_errors']['name'] = 'Nome é obrigatório';
if (!$_POST['nif']) $_SESSION['field_errors']['nif'] = 'NIF é obrigatório';

if ($_SESSION['field_erors'][0]) {
    $_SESSION['error_messages'][] = 'Alguns campos em falta';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/payers/addpayer.php');
    exit;
}

if (checkDuplicateEntityName($accountId, $name)) {
    $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
    $_SESSION['field_errors']['name'] = 'Nome já existe';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/payers/addpayer.php');
    exit;
}

if ($type === 'Private') {
    try {
        createPrivatePayer($name, $accountId, $nif, $valueperk);
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'validnif') !== false) {
            $_SESSION['error_messages'][] = 'NIF inválido';
            $_SESSION['field_errors']['nif'] = 'NIF inválido';
        } else $_SESSION['error_messages'][] = 'Erro a criar entidade ' . $e->getMessage();

        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/payers/addpayer.php');
        exit;
    }

    $_SESSION['success_messages'][] = 'Entidade adicionada com sucesso';

    header("Location: $BASE_URL" . 'pages/payers/payers.php');
    exit;
}

if (checkDuplicateEntityName($_SESSION['idaccount'], $name)) {
    $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
    $_SESSION['field_errors']['name'] = 'Nome já existe';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/payers/addpayer.php');
    exit;
}

$contractstart = $_POST['contractstart'];
if (!$contractstart) $contractstart = null;
$contractend = $_POST['contractend'];
if (!$contractend) $contractend = null;

if ($contractstart > $contractend && $contractend) {
    $_SESSION['error_messages'][] = 'Data do contrato não é coerente';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/payers/addpayer.php');
    exit;
}

try {
    createEntityPayer($name, $contractstart, $contractend, $type, $nif, $valueperk, $accountId);
} catch (PDOException $e) {

    if (strpos($e->getMessage(), 'validnif') !== false) {
        $_SESSION['error_messages'][] = 'NIF inválido';
        $_SESSION['field_errors']['nif'] = 'NIF inválido';
    } else $_SESSION['error_messages'][] = 'Erro a criar entidade ' . $e->getMessage();

    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/payers/addpayer.php');
    exit;
}

$_SESSION['success_messages'][] = 'Entidade adicionada com sucesso';

header("Location: $BASE_URL" . 'pages/payers/payers.php');

?>