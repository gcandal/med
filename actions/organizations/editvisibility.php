<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

if ($_POST['visibility']) {
    $visibility = $_POST['visibility'];
    $accountId = $_SESSION['idaccount'];
    $idorganization = $_POST['idorganization'];
/*
    try {
        if (isAdministrator($accountId, $idorganization)) {
            $_SESSION['error_messages'][] = 'Os administradores não podem alterar a sua visibilidade';

            header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
            exit;
        }
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a alterar a visibilidade ' . $e->getMessage();

        header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
        exit;
    }
*/
    try {
        editOrganizationVisibility($idorganization, $accountId, $visibility);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a alterar a visibilidade ' . $e->getMessage();

        header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
        exit;
    }
}

$_SESSION['success_messages'][] = 'Visibilidade alterada com sucesso';

header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
?>