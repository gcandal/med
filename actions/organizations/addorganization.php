<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

if (!$_POST['name']) $_SESSION['field_errors']['name'] = 'Nome é obrigatório';

if ($_SESSION['field_erors'][0]) {
    $_SESSION['error_messages'][] = 'Alguns campos em falta';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/organizations/addorganization.php');
    exit;
}

$name = $_POST['name'];
$accountId = $_SESSION['idaccount'];

try {
    createOrganization($name, $accountId);
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'organization_name_key') !== false) {
        $_SESSION['error_messages'][] = 'Já existe uma Organização com este nome';
        $_SESSION['field_errors']['name'] = 'Já existe uma Organização com este nome';
    } else $_SESSION['error_messages'][] = 'Erro a criar organização ';// . $e->getMessage();

    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/organizations/addorganization.php');
    exit;
}

$_SESSION['success_messages'][] = 'Entidade adicionada com sucesso';

header("Location: $BASE_URL" . 'pages/organizations/organizations.php');