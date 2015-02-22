<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');
include_once($BASE_DIR . 'database/professionals.php');
include_once($BASE_DIR . 'database/payers.php');
include_once($BASE_DIR . 'database/patients.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$_SESSION['freeregisters'] = getFreeRegisters($_SESSION['idaccount']);
if (!$_SESSION['freeregisters']) {
    $_SESSION['freeregisters'] = 0;
    $_SESSION['error_messages'][] = 'Não pode fazer mais registos';
    header('Location: ' . $BASE_URL);

    exit;
}

$idprivatepayer = $_POST['idPrivatePayer'];

if ($idprivatepayer === 'NewPrivate') {
    $name = $_POST['namePrivate'];
    $nif = $_POST['nifPrivate'];
    if (!$nif)
        $nif = null;
    $valueperk = $_POST['valuePerK'];
    if (!$valueperk) $valueperk = null;
    $accountId = $_SESSION['idaccount'];

    if (!$_POST['namePrivate']) $_SESSION['field_errors']['namePrivate'] = 'Nome é obrigatório';

    if ($_SESSION['field_erors'][0]) {
        $_SESSION['error_messages'][] = 'Alguns campos em falta';
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
        exit;
    }

    if (checkDuplicateEntityName($accountId, $name)) {
        $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
        $_SESSION['field_errors']['namePrivate'] = 'Nome já existe';
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
        exit;
    }

    try {
        $idprivatepayer = createPrivatePayer($name, $accountId, $nif, $valueperk);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a criar entidade ' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
        exit;
    }
}

if (isset($_POST['idPatient'])) {
    if ($_POST['idPatient'] == -2) {
        $name = $_POST['namePatient'];
        $nif = $_POST['nifPatient'];
        if (!$nif) $nif = null;
        $cellphone = $_POST['cellphonePatient'];
        if (!$cellphone) $cellphone = null;
        $beneficiarynr = $_POST['beneficiaryNrPatient'];
        if (!$beneficiarynr) $beneficiarynr = null;
        $accountId = $_SESSION['idaccount'];

        if (!$_POST['name']) $_SESSION['field_errors']['name'] = 'Nome é obrigatório';

        if ($_SESSION['field_erors'][0]) {
            $_SESSION['error_messages'][] = 'Alguns campos em falta';
            $_SESSION['form_values'] = $_POST;

            header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
            exit;
        }

        try {
            $idpatient = createPatient($name, $accountId, $nif, $cellphone, $beneficiarynr);
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'validnif') !== false) {
                $_SESSION['error_messages'][] = 'NIF inválido';
                $_SESSION['field_errors']['nif'] = 'NIF inválido';
            } else $_SESSION['error_messages'][] = 'Erro a criar paciente ' . $e->getMessage();

            $_SESSION['form_values'] = $_POST;

            header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
            exit;
        }
    } else $idpatient = $_POST['idPatient'];
} else $idpatient = false;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

$idAccount = $_SESSION['idaccount'];
$role = $_POST['role'];
$hasManualK = $_POST['totalType'] === 'manual';
$localAnesthesia = $_POST['localanesthesia'] === 'on';

if ($localAnesthesia)
    $localAnesthesia = 'true';
else
    $localAnesthesia = 'false';

for ($i = 1; $i <= $_POST['nSubProcedures']; $i++) {
    $subProcedures[] = $_POST["subProcedure$i"];
}

switch ($role) {
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

try {
    global $conn;
    $conn->beginTransaction();

    $idProcedure = addProcedure($idAccount, $_POST['status'], $_POST['date'], $_POST['totalRemun'], $_POST['valuePerK'],
        $idprivatepayer, $role, $_POST['anesthetistK'], $hasManualK, $localAnesthesia, $personalRemun,
        $_POST['generalRemun'], $_POST['firstAssistantRemun'], $_POST['secondAssistantRemun'],
        $_POST['anesthetistRemun'], $_POST['instrumentistRemun']);

    if (count($subProcedures) > 0) {
        addSubProcedures($idProcedure, $subProcedures);
    }

    if ($_POST['generalName'] !== "" && $role !== 'General') {
        $idProf = addProfessional($_POST['generalName'], $_POST['generalNIF'], $idAccount, $_POST['generalLicenseId'], "", NULL);
        addProfessionalToProcedure($idProf, $idProcedure, "general");
    }

    if ($_POST['firstAssistantName'] !== "" && $role !== 'FirstAssistant') {
        $idProf = addProfessional($_POST['firstAssistantName'], $_POST['firstAssistantNIF'], $idAccount, $_POST['firstAssistantLicenseId'], "", NULL);
        addProfessionalToProcedure($idProf, $idProcedure, "firstassistant");
    }

    if ($_POST['secondAssistantName'] !== "" && $role !== 'SecondAssistant') {
        $idProf = addProfessional($_POST['secondAssistantName'], $_POST['secondAssistantNIF'], $idAccount, $_POST['secondAssistantLicenseId'], "", NULL);
        addProfessionalToProcedure($idProf, $idProcedure, "secondassistant");
    }

    if ($_POST['instrumentistName'] !== "" && $role !== 'Instrumentist') {
        $idProf = addProfessional($_POST['instrumentistName'], $_POST['instrumentistNIF'], $idAccount, $_POST['instrumentistLicenseId'], "", 2);
        addProfessionalToProcedure($idProf, $idProcedure, "instrumentist");
    }

    if ($_POST['anesthetistName'] !== "" && $role !== 'Anesthetist') {
        $idProf = addProfessional($_POST['anesthetistName'], $_POST['anesthetistNIF'], $idAccount, $_POST['anesthetistLicenseId'], "", 1);
        addProfessionalToProcedure($idProf, $idProcedure, "anesthetist");
    }

    if ($_POST['organization'] >= 0) {
        addProcedureToOrganization($idProcedure, $_POST['organization'], $idAccount);
    }

    if ($idpatient) {
        editProcedurePatient($idProcedure, $idpatient);
    }

    $conn->commit();
} catch (PDOException $e) {
    $_SESSION['error_messages'][] = 'Erro a adicionar registo ' . $e->getMessage();
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/procedures/addprocedure.php');
    exit;
}

$_SESSION['freeregisters'] = getFreeRegisters($idAccount);
$_SESSION['success_messages'][] = 'Registo adicionado com sucesso';

header("Location: $BASE_URL" . 'pages/procedures/procedures.php');
