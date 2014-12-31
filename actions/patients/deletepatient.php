<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/patients.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$accountId = $_SESSION['idaccount'];
$idpatient = $_POST['idpatient'];

try {
    deletePatient($accountId, $idpatient);
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'is still referenced') !== false)
        $_SESSION['error_messages'][] = 'Este paciente está em uso, não pode ser apagado';
    else $_SESSION['error_messages'][] = 'Erro a apagar pagador ' . $e->getMessage();
}

header("Location: $BASE_URL" . "pages/patients/patients.php");
