<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');

if (!$_SESSION['email']) {
    $_SESSION['error_messages'][] = 'Tem que fazer login';
    header('Location: ' . $BASE_URL);

    exit;
}

$licenseid = $_SESSION['licenseid'];
$invites = getInvites($licenseid);
$sent = getSentInvites($_SESSION['idaccount']);

$smarty->assign('INVITES', $invites);
$smarty->assign('SENT', $sent);
$smarty->display('organizations/invites.tpl');
?>