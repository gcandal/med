<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');
header('Content-type: application/json');

if (!$_SESSION['email'] || !isset($_GET['licenseid']) || !isset($_GET['idorganization'])) {
    echo json_encode(array("status" => "error", "message" => "Not all fields were supplied"));

    exit;
}

$idinviting = $_SESSION['idaccount'];
$idorganization = $_GET['idorganization'];
$licenseid = $_GET['licenseid'];

try {
    if (!isAdministrator($idinviting, $idorganization)) {
        echo json_encode(array("status" => "error", "message" => "Só os administradores podem convidar para uma organização"));

        exit;
    }
} catch (PDOException $e) {
    echo json_encode(array("status" => "error", "message" => "Erro a verificar convite"));

    exit;
}


echo json_encode(array("exists" => checkInviteForOrganization($idorganization, $licenseid)));

?>