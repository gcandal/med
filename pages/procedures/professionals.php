<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$idAccount = $_SESSION['idaccount'];
$idProcedure = $_GET['idProcedure'];

$professionals = getProcedureProfessionals($idAccount, $idProcedure);

$smarty->assign('professionals', $professionals);
//$smarty->display('procedures/showTeam.tpl');

var_dump($professionals);


