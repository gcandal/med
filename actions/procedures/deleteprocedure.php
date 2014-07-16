<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');

if (!$_SESSION['email'] || !$_POST['idprocedure']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login e fornecer os dados necessários';
    header('Location: ' . $BASE_URL);

    exit;
}

$idaccount = $_SESSION['idaccount'];
$idprocedure = $_POST['idprocedure'];

try {
    deleteProcedure($idprocedure, $idaccount);
} catch (PDOException $e) {
    $_SESSION['error_messages'][] = 'Erro a apagar procedimento ' . $e->getMessage();

    header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
    exit;
}

$_SESSION['success_messages'][] = 'Procedimento apagado com sucesso';
header("Location: $BASE_URL" . "pages/procedures/procedures.php");
?>