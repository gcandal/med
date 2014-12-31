<?php

include_once('../../config/init.php');
include_once($BASE_DIR . 'database/patients.php');

if (isset($_SESSION['idpatient'])) {
    $idpatient = $_SESSION['idpatient'];
    unset($_SESSION['idpatient']);
} else
    $idpatient = $_GET['idpatient'];

$patient = getPatient($idpatient);
$smarty->assign('patient', $patient);
$smarty->display('patients/editpatient.tpl');
