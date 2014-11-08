<?php
include_once('../../config/init.php');
include_once($BASE_DIR . 'database/procedures.php');
header('Content-type: application/json');

if (!$_SESSION['email']) {
    echo json_encode(array("status" => "error", "message" => "Not all fields were supplied"));

    exit;
}

echo json_encode(getProcedureTypesForAutocomplete());