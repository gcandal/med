<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');
include_once($BASE_DIR . 'database/organizations.php');
include_once($BASE_DIR . 'database/payers.php');
include_once($BASE_DIR . 'database/patients.php');


if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$idAccount = $_SESSION['idaccount'];
$idProcedure = $_GET['idprocedure'];
$procedure = getProcedure($idAccount, $idProcedure);

if (!$procedure) {
    $_SESSION['error_messages'][] = 'Não tem permissão para editar este registo';
    header('Location: ' . $BASE_URL);

    exit;
}

$procedure["subprocedures"] = getSubProceduresIds($procedure['idprocedure']);
$procedure["professionals"] = getProcedureProfessionals($idAccount, $idProcedure);
$entities['Privado'] = getPrivatePayers($idAccount);
$patients = getPatients($idAccount);
$organizations = getOrganizations($idAccount);
$procedureTypes = getProcedureTypes();
$smarty->assign('ENTITIES', $entities);
$smarty->assign('ORGANIZATIONS', $organizations);
$smarty->assign('PROCEDURETYPES', $procedureTypes);
$smarty->assign('PROCEDURE', $procedure);
$smarty->assign('PATIENTS', $patients);

$smarty->display('procedures/procedure.tpl');


