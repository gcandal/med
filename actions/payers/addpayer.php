<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/payers.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$name = $_POST['name'];
$valueperk = $_POST['valueperk'];
if (!$valueperk) $valueperk = null;
$accountId = $_SESSION['idaccount'];

if (!$_POST['name']) $_SESSION['field_errors']['name'] = 'Nome é obrigatório';

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

try {
    createPrivatePayer($name, $accountId, $valueperk);
} catch (PDOException $e) {
    $_SESSION['error_messages'][] = 'Erro a criar entidade ' . $e->getMessage();
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/payers/addpayer.php');
    exit;
}

$_SESSION['success_messages'][] = 'Entidade adicionada com sucesso';

header("Location: $BASE_URL" . 'pages/payers/payers.php');
exit;
