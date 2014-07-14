<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/organizations.php');
header('Content-type: application/json');

if (!$_SESSION['email'] || !isset($_GET['name'])) {
    echo json_encode(array("status" => "error", "message" => "Not all fields were supplied"));

    exit;
}

$name = $_GET['name'];

echo json_encode(array("exists" => checkOrganizationName($name)));

?>