<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$licenseid = $_SESSION['licenseid'];
$invites = getProcedureInvites($licenseid);

$smarty->assign('INVITES', $invites);
$smarty->display('procedures/invites.tpl');
