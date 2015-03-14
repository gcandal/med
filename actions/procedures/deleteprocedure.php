<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');

if (!$_SESSION['email'] || !$_POST['idprocedure']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';

    header('Location: ' . $BASE_URL);
    exit;
}

$idaccount = $_SESSION['idaccount'];
$idprocedure = $_POST['idprocedure'];

try {
    deleteProcedure($idprocedure, $idaccount);
} catch (PDOException $e) {
    $_SESSION['error_messages'][] = 'Erro a apagar registo ';// . $e->getMessage();

    header("Location: $BASE_URL" . 'pages/procedures/procedures.php');
    exit;
}

$_SESSION['freeregisters'] = getFreeRegisters($idaccount);
$_SESSION['success_messages'][] = 'Registo apagado com sucesso';

header("Location: $BASE_URL" . "pages/procedures/procedures.php");