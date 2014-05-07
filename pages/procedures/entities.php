<?php
include_once('../../config/init.php');
include_once($BASE_DIR.'database/procedures.php');

if(!$_SESSION['email']) {
    header("Location: $BASE_URL" . 'pages/main.php');

    exit;
}

$email = $_SESSION['email'];
$entities['Resto'] = getAllEntities($email);
$entities['Privado'] = getAllPrivateEntities($email);
$smarty->assign('ENTITIES', $entities);

$smarty->display('procedures/entities.tpl');
?>