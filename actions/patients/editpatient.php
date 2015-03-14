<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/patients.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$idpatient = $_POST['idpatient'];
$name = $_POST['name'];
$nif = $_POST['nif'];
if (!$nif) $nif = null;
$cellphone = $_POST['cellphone'];
if (!$cellphone) $cellphone = null;
$beneficiarynr = $_POST['beneficiarynr'];
if (!$beneficiarynr) $beneficiarynr = null;
$accountId = $_SESSION['idaccount'];

if ($name) {
    try {
        editPatientName($accountId, $name, $idpatient);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar paciente ';// . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idpatient'] = $idpatient;

        header("Location: $BASE_URL" . 'pages/patients/editpatient.php');
        exit;
    }
}

if ($nif) {
    try {
        editPatientNif($accountId, $nif, $idpatient);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar paciente ';// . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idpatient'] = $idpatient;

        header("Location: $BASE_URL" . 'pages/patients/editpatient.php');
        exit;
    }
}

if ($cellphone) {
    try {
        editPatientCellphone($accountId, $cellphone, $idpatient);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar paciente ';// . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idpatient'] = $idpatient;

        header("Location: $BASE_URL" . 'pages/patients/editpatient.php');
        exit;
    }
}

if ($beneficiarynr) {
    try {
        editPatientBeneficiaryNr($accountId, $beneficiarynr, $idpatient);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar paciente ';// . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idpatient'] = $idpatient;

        header("Location: $BASE_URL" . 'pages/patients/editpatient.php');
        exit;
    }
}

$_SESSION['success_messages'][] = 'Paciente editado com sucesso';

header("Location: $BASE_URL" . "pages/patients/patients.php");