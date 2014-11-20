<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');
include_once($BASE_DIR . 'database/payers.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$idAccount = $_SESSION['idaccount'];
$idProcedure = $_POST['idprocedure'];
$procedure = getProcedure($idAccount, $idProcedure);

if (!$procedure) {
    $_SESSION['error_messages'][] = 'Não tem permissão para editar este registo';
    header('Location: ' . $BASE_URL);

    exit;
}

if($procedure['readonly']) {
    $_SESSION['error_messages'][] = 'Não tem permissão para editar este registo 0';
    header('Location: ' . $BASE_URL);

    exit;
}

$procedure["subprocedures"] = getSubProceduresIds($procedure['idprocedure']);
$procedure["professionals"] = getProcedureProfessionals($idAccount, $idProcedure);
$entities['Entidade'] = getEntityPayers($idAccount);
$entities['Privado'] = getPrivatePayers($idAccount);
$procedureTypes = getProcedureTypes();
$smarty->assign('ENTITIES', $entities);
$smarty->assign('PROCEDURETYPES', $procedureTypes);
$smarty->assign('PROCEDURE', $procedure);

$smarty->display('procedures/editprocedure.tpl');


