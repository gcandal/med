<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    if ($_POST['name']) {
        $name = $_POST['name'];
        $accountId = $_SESSION['idaccount'];
        $idprivatepayer = $_POST['idprivatepayer'];

        if (checkDuplicateEntityName($accountId, $name)) {
            $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
            $_SESSION['field_errors']['name'] = 'Nome já existe';
            $_SESSION['form_values'] = $_POST;

            $_SESSION['identitypayer'] = $identitypayer;

            header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
            exit;
        }

        try {
            editPrivatePayerName($accountId, $name, $idprivatepayer);
        } catch (PDOException $e) {
            $_SESSION['error_messages'][] = 'Erro a editar entidade ' . $e->getMessage();
            $_SESSION['form_values'] = $_POST;

            $_SESSION['identitypayer'] = $identitypayer;

            header("Location: $BASE_URL" . 'pages/procedures/editprivatepayer.php');
            exit;
        }
    }

    $_SESSION['success_messages'][] = 'Entidade editada com sucesso';

    header("Location: $BASE_URL" . "pages/procedures/payers.php");
?>