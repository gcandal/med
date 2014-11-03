<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/professionals.php');
header('Content-type: application/json');

if (!$_SESSION['email'] || !isset($_GET['speciality']) || !isset($_GET['name'])) {
    echo json_encode(array("status" => "error", "message" => "Not all fields were supplied"));

    exit;
}

$idaccount = $_SESSION['idaccount'];
$speciality = $_GET['speciality'];
$name = $_GET['name'];

echo json_encode(getRecentProfessionals($idaccount, $speciality, $name));
?>