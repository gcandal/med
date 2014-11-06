<?php

include_once('../../config/init.php');
include_once($BASE_DIR . 'database/professionals.php');

if (isset($_SESSION['idprofessional'])) {
    $idprofessional = $_SESSION['idprofessional'];
    unset($_SESSION['idprofessional']);
} else
    $idprofessional = $_GET['idprofessional'];

$professional = getProfessional($_SESSION['idaccount'], $idprofessional);
$specialities = getSpecialities();

$smarty->assign('SPECIALITIES', $specialities);
$smarty->assign('professional', $professional);
$smarty->display('professionals/editprofessional.tpl');