<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

if ($_POST['licenseidinvited'] && $_POST['idorganization']) {
    $licenseIdInvited = $_POST['licenseidinvited'];
    $idOrganization = $_POST['idorganization'];
    $idInvitingAccount = $_SESSION['idaccount'];

    try {
        deleteInvite($idOrganization, $idInvitingAccount, $licenseIdInvited);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a apagar convite ';// . $e->getMessage();

        header("Location: $BASE_URL" . 'pages/organizations/invites.php');
        exit;
    }
}

$_SESSION['success_messages'][] = 'Convite apagado com sucesso';

header("Location: $BASE_URL" . 'pages/organizations/invites.php');