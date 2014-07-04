<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/organizations.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $accountId = $_SESSION['idaccount'];
    $idorganization = $_POST['idorganization'];

    try {
        if (!isAdministrator($accountId, $idorganization)) {
            $_SESSION['error_messages'][] = 'Só os administradores podem apagar uma organização';

            header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
            exit;
        }
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a apagar organização' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
        exit;
    }

    try {
        deleteOrganization($idorganization);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a apagar a organização ' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
        exit;
    }

    $_SESSION['success_messages'][] = 'Organização apagada com sucesso';

    header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
?>