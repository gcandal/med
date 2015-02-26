<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');
include_once($BASE_DIR . 'database/professionals.php');
include_once($BASE_DIR . 'database/organizations.php');
include_once($BASE_DIR . 'database/users.php');
include_once($BASE_DIR . 'database/payers.php');
include_once($BASE_DIR . 'database/patients.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$_SESSION['freeregisters'] = getFreeRegisters($_SESSION['idaccount']);
if (!$_SESSION['freeregisters'] || $_SESSION['freeregisters'] < -1) {
    $_SESSION['freeregisters'] = 0;
    $_SESSION['error_messages'][] = 'Não pode fazer mais registos';
    header('Location: ' . $BASE_URL);

    exit;
}

$idaccount = $_SESSION['idaccount'];
$username = getUserById($idaccount);
$organizations = getOrganizations($idaccount);
$patients = getOrganizations($idaccount);
$entities['Privado'] = getPrivatePayers($idaccount);
$patients = getPatients($idaccount);
$smarty->assign('USERNAME', $username);
$smarty->assign('ENTITIES', $entities);
$smarty->assign('PATIENTS', $patients);
$smarty->assign('ORGANIZATIONS', $organizations);
$_SESSION['entityType'] = "Private";
$smarty->assign('ENTITYTYPE', $_SESSION['entityType']);

$smarty->display('procedures/addprocedure.tpl');