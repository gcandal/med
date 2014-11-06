<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/professionals.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$accountId = $_SESSION['idaccount'];
$idprofessional = $_POST['idprofessional'];

try {
    deleteProfessional($accountId, $idprofessional);
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'is still referenced') !== false)
        $_SESSION['error_messages'][] = 'Este profissional está em uso, não pode ser apagado';
    else $_SESSION['error_messages'][] = 'Erro a apagar profissional ' . $e->getMessage();
}

header("Location: $BASE_URL" . "pages/professionals/professionals.php");

