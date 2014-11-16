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
    $idAccount = $_SESSION['idaccount'];

    try {
        acceptShared($idProcedure, $idInvitingAccount, $licenseIdInvited, $idAccount);
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'procedureaccount_pkey') !== false) {
            $_SESSION['error_messages'][] = 'Já tinha adicionado este registo';
            rejectShared($idProcedure, $idInvitingAccount, $licenseIdInvited);
        } else $_SESSION['error_messages'][] = 'Erro a aceitar partilha ' . $e->getMessage();

        header("Location: $BASE_URL" . 'pages/procedures/invites.php');
        exit;
    }

    $_SESSION['success_messages'][] = 'Partilha aceite com sucesso';
}

header("Location: $BASE_URL" . 'pages/procedures/invites.php');
?>