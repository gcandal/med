<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

if ($_POST['idinvitingaccount'] && $_POST['idorganization'] && $_POST['orgauthorization']) {
    $licenseIdInvited = $_SESSION['licenseid'];
    $idOrganization = $_POST['idorganization'];
    $idInvitingAccount = $_POST['idinvitingaccount'];
    $idAccount = $_SESSION['idaccount'];
    $orgauthorization = $_POST['orgauthorization'];

    try {
        acceptInvite($idOrganization, $idInvitingAccount, $licenseIdInvited, $idAccount, $orgauthorization);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a aceitar convite ';// . $e->getMessage();

        header("Location: $BASE_URL" . 'pages/organizations/invites.php');
        exit;
    }

    $_SESSION['success_messages'][] = 'Convite aceite com sucesso';
}

header("Location: $BASE_URL" . 'pages/organizations/invites.php');