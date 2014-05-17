<?php
$name = $_POST['name'];

if($name) {
    if (checkDuplicateEntityName($_SESSION['idaccount'], $name)) {
        $_SESSION['error_messages'][] = 'Entidade com este nome duplicada';
        $_SESSION['field_errors']['name'] = 'Nome já existe';
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addpayer.php');
        exit;
    }


}

$contractstart = $_POST['contractstart'];
if (!$contractstart)
    $contractstart = NULL;
$contractend = $_POST['contractend'];
if (!$contractend)
    $contractend = NULL;
$type = $_POST['type'];
$nif = $_POST['nif'];
$valueperk = $_POST['valueperk'];
if (!$valueperk)
    $valueperk = NULL;
$accountId = $_SESSION['idaccount'];


$_SESSION['success_messages'][] = 'Entidade editada com sucesso';

header("Location: $BASE_URL" . "pages/procedures/payers.php");
?>