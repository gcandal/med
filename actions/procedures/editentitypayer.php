<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $name = $_POST['name'];
    $identitypayer = $_POST['identitypayer'];

    if ($name) {
        $_SESSION['error_messages'][] = -1;
        if (checkDuplicateEntityName($_SESSION['idaccount'], $name)) {
            $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
            $_SESSION['field_errors']['name'] = 'Nome já existe';
            $_SESSION['form_values'] = $_POST;

            $_SESSION['identitypayer'] = $identitypayer;

            header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
            exit;
        }
    }

    $contractstart = $_POST['contractstart'];
    $contractend = $_POST['contractend'];
    $nif = $_POST['nif'];
    $valueperk = $_POST['valueperk'];
    $accountId = $_SESSION['idaccount'];

    if ($contractstart > $contractend && $contractend) {
        $_SESSION['error_messages'][] = 'Data do contrato não é coerente';
        $_SESSION['form_values'] = $_POST;

        $_SESSION['identitypayer'] = $identitypayer;

        header("Location: $BASE_URL" . 'pages/procedures/editentitypayer.php');
        exit;
    }

    if ($name) {
        try {
            editEntityPayerName($accountId, $identitypayer, $name);
        } catch (PDOException $e) {
            $_SESSION['error_messages'][] = $e->getMessage();
            $_SESSION['form_values'] = $_POST;

            $_SESSION['identitypayer'] = $identitypayer;

            header("Location: $BASE_URL" . 'pages/procedures/editentitypayer.php');
            exit;
        }
    }
    if ($nif) {
        try {
            editEntityPayerNIF($accountId, $identitypayer, $nif);
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'validnif') !== false) {
                $_SESSION['error_messages'][] = 'NIF inválido';
                $_SESSION['field_errors']['nif'] = 'NIF inválido';
            } else $_SESSION['error_messages'][] = $e->getMessage();

            $_SESSION['form_values'] = $_POST;

            $_SESSION['identitypayer'] = $identitypayer;

            header("Location: $BASE_URL" . 'pages/procedures/editentitypayer.php');
            exit;
        }
    }

    if ($contractstart) {
        try {
            editEntityPayerContractStart($accountId, $identitypayer, $contractstart);
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'entitypayer_check') !== false) {
                $_SESSION['error_messages'][] = 'Data do contrato não é coerente';
                $_SESSION['field_errors']['name'] = 'Data do contrato não é coerente';
            } else $_SESSION['error_messages'][] = $e->getMessage();
            $_SESSION['form_values'] = $_POST;

            $_SESSION['identitypayer'] = $identitypayer;

            header("Location: $BASE_URL" . 'pages/procedures/editentitypayer.php');
            exit;
        }
    }

    if ($contractend) {
        try {
            editEntityPayerContractEnd($accountId, $identitypayer, $contractend);
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'entitypayer_check') !== false) {
                $_SESSION['error_messages'][] = 'Data do contrato não é coerente';
                $_SESSION['field_errors']['name'] = 'Data do contrato não é coerente';
            } else $_SESSION['error_messages'][] = $e->getMessage();
            $_SESSION['form_values'] = $_POST;

            $_SESSION['identitypayer'] = $identitypayer;

            header("Location: $BASE_URL" . 'pages/procedures/editentitypayer.php');
            exit;
        }
    }

    if ($valueperk) {
        try {
            editEntityPayerValuePerK($accountId, $identitypayer, intval($valueperk));
        } catch (PDOException $e) {
            $_SESSION['error_messages'][] = $e->getMessage();
            $_SESSION['form_values'] = $_POST;

            $_SESSION['identitypayer'] = $identitypayer;

            header("Location: $BASE_URL" . 'pages/procedures/editentitypayer.php');
            exit;
        }
    }

    $_SESSION['success_messages'][] = 'Entidade editada com sucesso';

    header("Location: $BASE_URL" . "pages/procedures/payers.php");
?>