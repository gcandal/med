<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/professionals.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$idaccount = $_SESSION['idaccount'];
$professionals = getProfessionals($idaccount);

$smarty->assign('PROFESSIONALS', $professionals);
$smarty->display('professionals/professionals.tpl');
