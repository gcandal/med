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

if(isReadOnly($_POST['idprocedure'], $_SESSION['idaccount'])) {
    $_SESSION['error_messages'][] = 'Não tem permissão para editar este procedimento';

    header("Location: $BASE_URL" . 'pages/procedures/.php');
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

        header("Location: $BASE_URL" . 'pages/procedures/procedure.php' . "?idprocedure=" . $idProcedure);
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

            header("Location: $BASE_URL" . 'pages/procedures/procedure.php' . "?idprocedure=" . $idProcedure);
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

            header("Location: $BASE_URL" . 'pages/procedures/procedure.php' . "?idprocedure=" . $idProcedure);
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

            header("Location: $BASE_URL" . 'pages/procedures/procedure.php' . "?idprocedure=" . $idProcedure);
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
$idProcedure = $_POST['idprocedure'];
$role = $_POST['role'];

for ($i = 1; $i <= $_POST['nSubProcedures']; $i++) {
    $current_subProcedure = $_POST["subProcedure$i"];

    if($current_subProcedure)
        $subProcedures[] = $current_subProcedure;
}

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

try {
    global $conn;
    $conn->beginTransaction();

    $hasManualK = $_POST['totalType'] === 'manual';
    editProcedure($idAccount, $idProcedure, $_POST['status'], $_POST['date'], $_POST['totalRemun'], $_POST['valuePerK'],
        $idprivatepayer, $identitypayer, $role, $_POST['anesthetistK'], $hasManualK, $personalRemun,
        $_POST['generalRemun'], $_POST['firstAssistantRemun'], $_POST['secondAssistantRemun'],
        $_POST['anesthetistRemun'], $_POST['instrumentistRemun']);


    if (count($subProcedures) > 0) {
        editSubProcedures($idProcedure, $subProcedures);
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

    $conn->commit();
} catch (PDOException $e) {
    $_SESSION['error_messages'][] = 'Erro a editar registo ' . $e->getMessage();
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/procedures/procedure.php' . "?idprocedure=" . $idProcedure);
    exit;
}

$_SESSION['success_messages'][] = 'Registo editado com sucesso';

header("Location: $BASE_URL" . 'pages/procedures/procedure.php' . "?idprocedure=" . $idProcedure);