<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/professionals.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$idprofessional = $_POST['idprofessional'];
$name = $_POST['name'];
$nif = $_POST['nif'];
$licenseid = $_POST['licenseid'];
$speciality = $_POST['speciality'];
$accountId = $_SESSION['idaccount'];

if ($name) {
    try {
        editProfessionalName($accountId, $idprofessional, $name);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar profissional ' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idprofessional'] = $idprofessional;

        header("Location: $BASE_URL" . 'pages/professionals/professionals.php');
        exit;
    }
}

if ($nif) {
    try {
        editProfessionalNif($accountId, $idprofessional, $nif);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar profissional ' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idprofessional'] = $idprofessional;

        header("Location: $BASE_URL" . 'pages/professionals/professionals.php');
        exit;
    }
}

if ($licenseid) {
    try {
        editProfessionalLicenseId($accountId, $idprofessional, $licenseid);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar profissional ' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idprofessional'] = $idprofessional;

        header("Location: $BASE_URL" . 'pages/professionals/professionals.php');
        exit;
    }
}

if ($speciality) {
    try {
        editProfessionalSpeciality($accountId, $idprofessional, $speciality);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = 'Erro a editar profissional ' . $e->getMessage();
        $_SESSION['form_values'] = $_POST;

        $_SESSION['idprofessional'] = $idprofessional;

        header("Location: $BASE_URL" . 'pages/professionals/professionals.php');
        exit;
    }
}

$_SESSION['success_messages'][] = 'Profissional editado com sucesso';

header("Location: $BASE_URL" . "pages/professionals/professionals.php");
