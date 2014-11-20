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

$idprivatepayer = NULL;
if ($type === 'Private' || $type === 'NewPrivate')
    $idprivatepayer = $_POST['privateName'];

$identitypayer = NULL;
if ($type === 'Entity' || $type === 'NewEntity')
    $identitypayer = $_POST['entityName'];

if ($type === 'NewPrivate' || $type === 'NewEntity') {
    if ($type === 'NewPrivate')
        $suffix = 'Private';
    else
        $suffix = 'Entity';

    $name = $_POST['name' . $suffix];
    $nif = $_POST['nif' . $suffix];
    if(!$nif)
        $nif = null;
    $valueperk = $_POST['valuePerK'];
    if (!$valueperk) $valueperk = null;
    $accountId = $_SESSION['idaccount'];

    if (!$_POST['name' . $suffix]) $_SESSION['field_errors']['name' . $suffix] = 'Nome é obrigatório';

    if ($_SESSION['field_erors'][0]) {
        $_SESSION['error_messages'][] = 'Alguns campos em falta';
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
        exit;
    }

    if (checkDuplicateEntityName($accountId, $name)) {
        $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
        $_SESSION['field_errors']['name' . $suffix] = 'Nome já existe';
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
        exit;
    }

    if ($type === 'NewPrivate') {
        try {
            $idprivatepayer = createPrivatePayer($name, $accountId, $nif, $valueperk);
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'validnif') !== false) {
                $_SESSION['error_messages'][] = 'NIF inválido';
                $_SESSION['field_errors']['nif' . $suffix] = 'NIF inválido';
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
                $_SESSION['error_messages'][] = 'NIF inválido';
                $_SESSION['field_errors']['nif' . $suffix] = 'NIF inválido';
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
$idAccount = $_SESSION['idaccount'];

for ($i = 1; $i <= $_POST['nSubProcedures']; $i++) {
    $subProcedures[] = $_POST["subProcedure$i"];
}

try {
    global $conn;
    $conn->beginTransaction();

    $role = $_POST['role'];

    switch($role) {
        case 'General':
            $personalRemun = $_POST['generalRemun'];
            break;
        case'FirstAssistant':
            $personalRemun = $_POST['firstAssistantRemun'];
            break;
        case 'SecondAssistant':
            $personalRemun = $_POST['secondAssistantRemun'];
            break;
        case'Instrumentist':
            $personalRemun = $_POST['instrumentistRemun'];
            break;
        case 'Anesthetist':
            $personalRemun = $_POST['anesthetistRemun'];
            break;
        default:
            $personalRemun = 0;
    }

    $hasManualK = $_POST['totalType'] === 'manual';

    $idProcedure = addProcedure($idAccount, $_POST['status'], $_POST['date'], $_POST['totalRemun'], $_POST['valuePerK'],
        $idprivatepayer, $identitypayer, $role, $personalRemun, $_POST['anesthetistK'], $hasManualK);

    if (count($subProcedures) > 0) {
        addSubProcedures($idProcedure, $subProcedures);
    }

    if ($_POST['generalName'] !== "" && $role !== 'General') {
        $idProf = addProfessional($_POST['generalName'], $_POST['generalNIF'], $idAccount, $_POST['generalLicenseId'], "", NULL);
        addGeneral($idProf, $idProcedure);
    }

    if ($_POST['firstAssistantName'] !== "" && $role !== 'FirstAssistant') {
        $idProf = addProfessional($_POST['firstAssistantName'], $_POST['firstAssistantNIF'], $idAccount, $_POST['firstAssistantLicenseId'], "", NULL);
        addFirstAssistant($idProf, $idProcedure);
    }

    if ($_POST['secondAssistantName'] !== "" && $role !== 'SecondAssistant') {
        $idProf = addProfessional($_POST['secondAssistantName'], $_POST['secondAssistantNIF'], $idAccount, $_POST['secondAssistantLicenseId'], "", NULL);
        addSecondAssistant($idProf, $idProcedure);
    }

    if ($_POST['instrumentistName'] !== "" && $role !== 'Instrumentist') {
        $idProf = addProfessional($_POST['instrumentistName'], $_POST['instrumentistNIF'], $idAccount, $_POST['instrumentistLicenseId'], "", 2);
        addInstrumentist($idProf, $idProcedure);
    }

    if ($_POST['anesthetistName'] !== "" && $role !== 'Anesthetist') {
        $idProf = addProfessional($_POST['anesthetistName'], $_POST['anesthetistNIF'], $idAccount, $_POST['anesthetistLicenseId'], "", 1);
        addAnesthetist($idProf, $idProcedure);
    }

    $conn->commit();
} catch (PDOException $e) {
    $_SESSION['error_messages'][] = 'Erro a adicionar registo ' . $e->getMessage();
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
    exit;
}

$_SESSION['success_messages'][] = 'Registo adicionado com sucesso';

header("Location: $BASE_URL" . 'pages/procedures/procedures.php');
