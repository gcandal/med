<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

if ($_POST['idinvitingaccount'] && $_POST['idorganization']) {
    $licenseIdInvited = $_SESSION['licenseid'];
    $idOrganization = $_POST['idorganization'];
    $idInvitingAccount = $_POST['idinvitingaccount'];

    try {
        rejectInvite($idOrganization, $idInvitingAccount, $licenseIdInvited);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a rejeitar convite ';// . $e->getMessage();

        header("Location: $BASE_URL" . 'pages/organizations/invites.php');
        exit;
    }
}

$_SESSION['success_messages'][] = 'Convite rejeitado com sucesso';

header("Location: $BASE_URL" . 'pages/organizations/invites.php');
?>