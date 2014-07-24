<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');
    include_once($BASE_DIR . 'database/payers.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $type = $_POST['payerType'];

    if ($type !== 'None') {
        $name = $_POST['name'];
        $nif = $_POST['nif'];
        $valueperk = $_POST['valuePerK'];
        if (!$valueperk) $valueperk = null;
        $accountId = $_SESSION['idaccount'];

        if (!$_POST['name']) $_SESSION['field_errors']['name'] = 'Nome é obrigatório';
        if (!$_POST['nif']) $_SESSION['field_errors']['nif'] = 'NIF é obrigatório';

        if ($_SESSION['field_erors'][0]) {
            $_SESSION['error_messages'][] = 'Alguns campos em falta';
            $_SESSION['form_values'] = $_POST;

            header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
            exit;
        }

        if (checkDuplicateEntityName($accountId, $name)) {
            $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
            $_SESSION['field_errors']['name'] = 'Nome já existe';
            $_SESSION['form_values'] = $_POST;

            header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
            exit;
        }

        if ($type === 'Private') {
            try {
                createPrivatePayer($name, $accountId, $nif, $valueperk);
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'validnif') !== false) {
                    $_SESSION['error_messages'][] = 'NIF inválido';
                    $_SESSION['field_errors']['nif'] = 'NIF inválido';
                } else $_SESSION['error_messages'][] = 'Erro a criar entidade ' . $e->getMessage();

                $_SESSION['form_values'] = $_POST;

                header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
                exit;
            }

            $_SESSION['success_messages'][] = 'Entidade adicionada com sucesso';

            header("Location: $BASE_URL" . 'pages/payers/payers.php');
            exit;
        }

        if (checkDuplicateEntityName($_SESSION['idaccount'], $name)) {
            $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
            $_SESSION['field_errors']['name'] = 'Nome já existe';
            $_SESSION['form_values'] = $_POST;

            header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
            exit;
        }

        $contractstart = $_POST['contractstart'];
        if (!$contractstart) $contractstart = null;
        $contractend = $_POST['contractend'];
        if (!$contractend) $contractend = null;

        if ($contractstart > $contractend && $contractend) {
            $_SESSION['error_messages'][] = 'Data do contrato não é coerente';
            $_SESSION['form_values'] = $_POST;

            header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
            exit;
        }

        try {
            createEntityPayer($name, $contractstart, $contractend, $type, $nif, $valueperk, $accountId);
        } catch (PDOException $e) {

            if (strpos($e->getMessage(), 'validnif') !== false) {
                $_SESSION['error_messages'][] = 'NIF inválido';
                $_SESSION['field_errors']['nif'] = 'NIF inválido';
            } else $_SESSION['error_messages'][] = 'Erro a criar entidade ' . $e->getMessage();

            $_SESSION['form_values'] = $_POST;

            header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
            exit;
        }
    }

    $wasAssistant = $_POST['function'] != 'Principal';
    $idAccount = $_SESSION['idaccount'];
    if ($wasAssistant) $wasAssistant = 'true'; else
        $wasAssistant = 'false';

    for ($i = 1; $i <= $_POST['nSubProcedures']; $i++) {
        $subProcedures[] = $_POST["subProcedure$i"];
    }

    $idProcedure = addProcedure($idAccount, $_POST['status'], $_POST['date'], $wasAssistant, $_POST['totalRemun'], $_POST['personalRemun'], $_POST['valuePerK']);

    if (count($subProcedures) > 0) {
        addSubProcedures($idProcedure, $subProcedures);
    }

    addProcedureToAccount($idProcedure, $idAccount);

    $_SESSION['success_messages'][] = 'Procedimento adicionado com sucesso';

    header("Location: $BASE_URL" . 'pages/procedures/procedures.php');
