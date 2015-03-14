<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');
//include_once($BASE_DIR . 'mail/mail.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$licenseid = $_POST['licenseid'];
if (!$licenseid)
    $licenseid = 'all';
$idinviting = $_SESSION['idaccount'];
$idprocedure = $_POST['idprocedure'];

try {
    shareProcedure($idprocedure, $idinviting, $licenseid);
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'procedureinvitation_pkey') !== false) {
        $_SESSION['error_messages'][] = 'Já enviou um convite para esse membro.';
    } else  $_SESSION['error_messages'][] = 'Erro a partilhar registo ';// . $e->getMessage();

    header("Location: $BASE_URL" . 'pages/procedures/procedures.php');
    exit;
}
/*
    $invitedUser = getNameAndEmailFromLicenseId($licenseid);
    $invitedName = $invitedUser['name'];
    $invitedEmail = $invitedUser['email'];

    if ($invitedName) {
        /*
        $invitedEmail = 'gabrielcandal@gmail.com';
        notifySharedProcedure($nameInvited, $invitedEmail, $_SESSION['name']);
        */
//    }


$_SESSION['success_messages'][] = 'Registo partilhado com sucesso';

header("Location: $BASE_URL" . 'pages/procedures/procedures.php');