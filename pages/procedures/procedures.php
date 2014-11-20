<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');
include_once($BASE_DIR . 'database/payers.php');
include_once($BASE_DIR . 'database/users.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$idAccount = $_SESSION['idaccount'];

$openProcedures = getNumberOfOpenProcedures($idAccount);
$procedures = getProcedures($idAccount);

foreach ($procedures as $key => $procedure) {
    $procedures[$key]["subprocedures"] = getSubProcedures($procedure['idprocedure']);
}

$smarty->assign('OPENPROCEDURES', $openProcedures);
$smarty->assign('PROCEDURES', $procedures);
$smarty->display('procedures/procedures.tpl');


