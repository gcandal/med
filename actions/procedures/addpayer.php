<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');

if(!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

if (!$_POST['type']) {
    $_SESSION['error_messages'][] = 'Tipo indefinido';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
    exit;
}

if ($_POST['type'] === 'Privado') {
    if (!$_POST['name']) {
        $_SESSION['error_messages'][] = 'Alguns campos em falta';
        $_SESSION['field_errors']['name'] = 'Nome é obrigatório';
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
        exit;
    }

    $name = $_POST['name'];
    $accountId = $_SESSION['idaccount'];

    if(checkDuplicateEntityName($accountId, $name)) {
        $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
        $_SESSION['field_errors']['name'] = 'Nome já existe';
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
        exit;
    }

    try {
        createPrivatePayer($name, $accountId);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a criar entidade ' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
        exit;
    }

    $_SESSION['success_messages'][] = 'Entidade adicionada com sucesso';

    header("Location: $BASE_URL");
    exit;
}

if (!$_POST['name'])
    $_SESSION['field_errors']['name'] = 'Nome é obrigatório';
if (!$_POST['nif'])
    $_SESSION['field_errors']['nif'] = 'NIF é obrigatório';

if($_SESSION['field_erors'][0]) {
    $_SESSION['error_messages'][] = 'Alguns campos em falta';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
    exit;
}

$name = $_POST['name'];
if(checkDuplicateEntityName($_SESSION['idaccount'], $name)) {
    $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
    $_SESSION['field_errors']['name'] = 'Nome já existe';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
    exit;
}

$contractstart = $_POST['contractstart'];
if(!$contractstart)
    $contractstart = NULL;
$contractend = $_POST['contractend'];
if(!$contractend)
    $contractend = NULL;
$type = $_POST['type'];
$nif = $_POST['nif'];
$valueperk = $_POST['valueperk'];
if(!$valueperk)
    $valueperk = NULL;
$accountId = $_SESSION['idaccount'];

if($contractstart > $contractend && $contractend) {
    $_SESSION['error_messages'][] = 'Data do contrato não é coerente';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
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

    header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
    exit;
}


$_SESSION['success_messages'][] = 'Entidade adicionada com sucesso';

header("Location: $BASE_URL" . 'pages/procedures/payers.php');

?>