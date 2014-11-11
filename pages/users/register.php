<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/professionals.php');

$specialities = getSpecialities();

$smarty->assign('SPECIALITIES', $specialities);
$smarty->display('users/register.tpl');