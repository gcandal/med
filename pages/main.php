<?php
include_once('../config/init.php');
include_once($BASE_DIR . 'database/users.php');

$token = $_GET['token'];
$email = getEmailFromToken($token);

$smarty->assign('EMAIL_TOKEN', $email);
$smarty->assign('TOKEN', $token);
$smarty->display('main.tpl');