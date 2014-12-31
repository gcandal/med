<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/patients.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$name = $_POST['name'];
$nif = $_POST['nif'];
if (!$nif) $nif = null;
$cellphone = $_POST['cellphone'];
if (!$cellphone) $cellphone = null;
$beneficiarynr = $_POST['beneficiarynr'];
if (!$beneficiarynr) $beneficiarynr = null;
$accountId = $_SESSION['idaccount'];

if (!$_POST['name']) $_SESSION['field_errors']['name'] = 'Nome é obrigatório';

if ($_SESSION['field_erors'][0]) {
    $_SESSION['error_messages'][] = 'Alguns campos em falta';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/patients/addpatient.php');
    exit;
}

try {
    createPatient($name, $accountId, $nif, $cellphone, $beneficiarynr);
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'validnif') !== false) {
        $_SESSION['error_messages'][] = 'NIF inválido';
        $_SESSION['field_errors']['nif'] = 'NIF inválido';
    } else $_SESSION['error_messages'][] = 'Erro a criar paciente ' . $e->getMessage();

    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/patients/addpatient.php');
    exit;
}

$_SESSION['success_messages'][] = 'Paciente adicionado com sucesso';
header("Location: $BASE_URL" . 'pages/patients/patients.php');