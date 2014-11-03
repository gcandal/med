<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');
    include_once($BASE_DIR . 'database/professionals.php');
    include_once($BASE_DIR . 'database/payers.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $type = $_POST['payerType'];
    $_SESSION['entityType'] = $type;

    if ($type === 'NewPrivate' || $type === 'NewEntity') {
        if($type === 'NewPrivate')
            $suffix = 'Private';
        else
            $suffix = 'Entity';

        $name = $_POST['name'.$suffix];
        $nif = $_POST['nif'.$suffix];
        $valueperk = $_POST['valuePerK'];
        if (!$valueperk) $valueperk = null;
        $accountId = $_SESSION['idaccount'];

        if (!$_POST['name'.$suffix]) $_SESSION['field_errors']['name'.$suffix] = 'Nome é obrigatório';
        if (!$_POST['nif'.$suffix]) $_SESSION['field_errors']['nif'.$suffix] = 'NIF é obrigatório';

        if ($_SESSION['field_erors'][0]) {
            $_SESSION['error_messages'][] = 'Alguns campos em falta';
            $_SESSION['form_values'] = $_POST;

            header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
            exit;
        }

        if (checkDuplicateEntityName($accountId, $name)) {
            $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
            $_SESSION['field_errors']['name'.$suffix] = 'Nome já existe';
            $_SESSION['form_values'] = $_POST;

            header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
            exit;
        }

        if ($type === 'NewPrivate') {
            try {
                $idprivatepayer = createPrivatePayer($name, $accountId, $nif, $valueperk);
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'validnif') !== false) {
                    $_SESSION['error_messages'][] = 'NIF inválido 1';
                    $_SESSION['field_errors']['nif'.$suffix] = 'NIF inválido';
                } else $_SESSION['error_messages'][] = 'Erro a criar entidade ' . $e->getMessage();

                $_SESSION['form_values'] = $_POST;

                header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
                exit;
            }
        } else {
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
                $identitypayer = createEntityPayer($name, $contractstart, $contractend, $type, $nif, $valueperk, $accountId);
            } catch (PDOException $e) {

                if (strpos($e->getMessage(), 'validnif') !== false) {
                    $_SESSION['error_messages'][] = 'NIF inválido 2';
                    $_SESSION['field_errors']['nif'.$suffix] = 'NIF inválido';
                } else $_SESSION['error_messages'][] = 'Erro a criar entidade ' . $e->getMessage();

                $_SESSION['form_values'] = $_POST;

                header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
                exit;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    $wasAssistant = $_POST['function'] != 'Principal';
    $idAccount = $_SESSION['idaccount'];

    $idprivatepayer = NULL;
    if($type === 'Private' || $type === 'NewPrivate')
        $idprivatepayer = $_POST['privateName'];

    $identitypayer = NULL;
    if($type === 'Entity' || $type === 'NewEntity')
        $identitypayer = $_POST['entityName'];

    if (!$wasAssistant) {
        $wasAssistant = 'false';

        for ($i = 1; $i <= $_POST['nSubProcedures']; $i++) {
            $subProcedures[] = $_POST["subProcedure$i"];
        }

        $idProcedure = addProcedure($idAccount, $_POST['status'], $_POST['date'], $wasAssistant, $_POST['totalRemun'], $_POST['personalRemun'], $_POST['valuePerK'], $idprivatepayer, $identitypayer);

        if (count($subProcedures) > 0) {
            addSubProcedures($idProcedure, $subProcedures);
        }

        if ($_POST['firstAssistantName'] != "") {
            $idProf = addProfessional($_POST['firstAssistantName'], $_POST['firstAssistantNIF'], $idAccount, $_POST['firstAssistantLicenseId'], "", "", $_POST['firstAssistantRemun'], $_POST['firstAssistantSpecialityId']);
            addFirstAssistant($idProf, $idProcedure);
        }

        if ($_POST['secondAssistantName'] != "") {
            $idProf = addProfessional($_POST['secondAssistantName'], $_POST['secondAssistantNIF'], $idAccount, $_POST['secondAssistantLicenseId'], "", "", $_POST['secondAssistantRemun'], $_POST['firstAssistantSpecialityId']);
            addSecondAssistant($idProf, $idProcedure);
        }

        if ($_POST['instrumentistName'] != "") {
            $idProf = addProfessional($_POST['instrumentistName'], $_POST['instrumentistNIF'], $idAccount, $_POST['instrumentistLicenseId'], "", "", $_POST['instrumentistRemun'], 0);
            addInstrumentist($idProf, $idProcedure);
        }

        if ($_POST['anesthetistName'] != "") {
            echo "cenas";
            $idProf = addProfessional($_POST['anesthetistName'], $_POST['anesthetistNIF'], $idAccount, $_POST['anesthetistLicenseId'], "", "", $_POST['anesthetistRemun'], 0);
            addAnesthetist($idProf, $idProcedure);
        }

    } else {
        $wasAssistant = 'true';

        $idProcedure = addProcedure($idAccount, $_POST['status'], $_POST['date'], $wasAssistant, 0.0, $_POST['personalRemun'], NULL, NULL, NULL);

        if ($_POST['masterName'] != "") {
            $idProf = addProfessional($_POST['masterName'], $_POST['masterNIF'], $idAccount, $_POST['masterLicense'], $_POST['masterEmail'], $_POST['masterPhone'], 0, "");
            addMaster($idProf, $idProcedure);
        }
    }

    $_SESSION['success_messages'][] = 'Procedimento adicionado com sucesso';

    header("Location: $BASE_URL" . 'pages/procedures/procedures.php');
