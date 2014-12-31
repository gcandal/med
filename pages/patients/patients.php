<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/patients.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$patients = getPatients($_SESSION['idaccount']);

$smarty->assign('PATIENTS', $patients);
$smarty->display('patients/patients.tpl');
