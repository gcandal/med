<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}


if ($_POST['name']) {
    $name = $_POST['name'];
    $accountId = $_SESSION['idaccount'];
    $idorganization = $_POST['idorganization'];

    try {
        if (!isAdministrator($accountId, $idorganization)) {
            $_SESSION['error_messages'][] = 'Só os administradores podem editar uma organização';

            header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
            exit;
        }
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar entidade ' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;
        $_SESSION['idorganization'] = $idorganization;

        header("Location: $BASE_URL" . 'pages/organizations/editorganization.php');
        exit;
    }

    try {
        editOrganizationName($name, $idorganization);
    } catch (PDOException $e) {

        if (strpos($e->getMessage(), 'organization_name_key') !== false) {
            $_SESSION['error_messages'][] = 'Já existe uma organização com este nome.';
            $_SESSION['field_errors']['name'] = 'Já existe uma organização com este nome.';
        } else $_SESSION['error_messages'][] = 'Erro a editar entidade ' . $e->getMessage();

        $_SESSION['form_values'] = $_POST;
        $_SESSION['idorganization'] = $idorganization;

        header("Location: $BASE_URL" . 'pages/organizations/editorganization.php');
        exit;
    }
}

$_SESSION['success_messages'][] = 'Entidade editada com sucesso';

header("Location: $BASE_URL" . 'pages/organizations/organizations.php');
?>