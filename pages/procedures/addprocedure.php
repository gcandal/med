<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');
include_once($BASE_DIR . 'database/professionals.php');
include_once($BASE_DIR . 'database/organizations.php');
include_once($BASE_DIR . 'database/users.php');
include_once($BASE_DIR . 'database/payers.php');

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
$entities['Entidade'] = getEntityPayers($idaccount);
$entities['Privado'] = getPrivatePayers($idaccount);
$procedureTypes = getProcedureTypes();
$smarty->assign('USERNAME', $username);
$smarty->assign('ENTITIES', $entities);
$smarty->assign('ORGANIZATIONS', $organizations);
$smarty->assign('PROCEDURETYPES', $procedureTypes);

$_SESSION['entityType'] = "Private";
$smarty->assign('ENTITYTYPE', $_SESSION['entityType']);

$smarty->display('procedures/addprocedure.tpl');