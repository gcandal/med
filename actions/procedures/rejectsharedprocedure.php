<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

if ($_POST['idinvitingaccount'] && $_POST['idprocedure']) {
    $licenseIdInvited = $_SESSION['licenseid'];
    $idProcedure = $_POST['idprocedure'];
    $idInvitingAccount = $_POST['idinvitingaccount'];

    try {
        rejectShared($idProcedure, $idInvitingAccount, $licenseIdInvited);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a rejeitar convite ';// . $e->getMessage();

        header("Location: $BASE_URL" . 'pages/procedures/invites.php');
        exit;
    }
}

$_SESSION['success_messages'][] = 'Convite rejeitado com sucesso';

header("Location: $BASE_URL" . 'pages/procedures/invites.php');
?>