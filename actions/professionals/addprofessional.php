<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/professionals.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

if(!$_POST['name']) {
    $_SESSION['error_messages'][] = 'Nome é obrigatório';
    header('Location: ' . $BASE_URL);

    exit;
}

$idAccount = $_SESSION['idaccount'];

try {
    addProfessional($_POST['name'], $_POST['nif'], $idAccount, $_POST['licenseId'], "", 0, $_POST['speciality']);
} catch (PDOException $e) {
    $_SESSION['error_messages'][] = 'Erro a criar profissional ' . $e->getMessage();
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/professionals/addprofessional.php');
    exit;
}

header("Location: $BASE_URL" . 'pages/professionals/professionals.php');