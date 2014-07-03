<?php

    function getProcedures($idAccount)
    {
        global $conn;
        $stmt = $conn->prepare("SELECT * FROM PROCEDURE WHERE idAccount = ?");
        $stmt->execute(array($idAccount));

        return $stmt->fetchAll();
    }

    function isProcedure($idProcedure)
    {
        global $conn;
        $stmt = $conn->prepare("SELECT * FROM PROCEDURE WHERE idProcedure = ?");
        $stmt->execute(array($idProcedure));

        return $stmt->fetch() == true;
    }

    function isEntityPayer($idEntityPayer)
    {
        global $conn;
        $stmt = $conn->prepare("SELECT * FROM ENTITYPAYER WHERE idEntityPayer = ?");
        $stmt->execute(array($idEntityPayer));

        return $stmt->fetch() == true;
    }

    function isPrivatePayer($idPrivatePayer)
    {
        global $conn;
        $stmt = $conn->prepare("SELECT * FROM PRIVATEPAYER WHERE idPrivatePayer = ?");
        $stmt->execute(array($idPrivatePayer));

        return $stmt->fetch() == true;
    }

    function getProcedureCollaborators($idProcedure)
    {
        global $conn;
        $stmt = $conn->prepare("SELECT * FROM PROCEDUREPROFESSIONAL WHERE idProcedure = ?");
        $stmt->execute(array($idProcedure));

        return $stmt->fetchAll();
    }

    function createProcedure($paymentStatus, $idPrivatePayer, $idEntityPayer)
    {
        global $conn;
        if ($idPrivatePayer == 0 && $idEntityPayer != 0) {
            $code = hash('sha256', $paymentStatus + $idEntityPayer + date('Y-m-d H:i:s')); // NEEDS TO BE CHANGED
            $stmt = $conn->prepare("INSERT INTO PROCEDURE (paymentstatus, idEntityPayer, date, code)
                            VALUES (:paymentStatus, :idEntityPayer, CURRENT_TIMESTAMP, :code);");
            $stmt->execute(array(":paymentStatus" => $paymentStatus, ":idEntityPayer" => $idEntityPayer, ":code" => $code));
        } else if ($idPrivatePayer != 0 && $idEntityPayer == 0) {
            $code = hash('sha256', $paymentStatus + $idPrivatePayer + date('Y-m-d H:i:s')); // NEEDS TO BE CHANGED
            $stmt = $conn->prepare("INSERT INTO PROCEDURE (paymentstatus, idPrivatePayer, date, code)
                            VALUES (:paymentStatus, :idEntityPayer, CURRENT_TIMESTAMP, :code);");
            $stmt->execute(array(":paymentStatus" => $paymentStatus, ":idEntityPayer" => $idEntityPayer, ":code" => $code));
        }

        return $stmt->fetch() == true;
    }

    function deleteProcedure($idProcedure)
    {
        global $conn;
        $stmt = $conn->prepare("DELETE FROM Procedure WHERE idprocedure = ?;");
        $stmt->execute(array($idProcedure));

        return $stmt->fetch() == true;
    }

    function editProcedurePaymentStatus($idProcedure, $paymentStatus)
    {
        global $conn;

        $stmt = $conn->prepare("UPDATE PROCEDURE SET paymentstatus = ?
                                WHERE $idProcedure = ?;");
        $stmt->execute(array($paymentStatus, $idProcedure));

        return $stmt->fetch() == true;
    }

    function editProcedurePrivatePayer($idProcedure, $idPrivatePayer)
    {
        global $conn;

        $stmt = $conn->prepare("UPDATE PROCEDURE SET idprivatepayer = ?
                                WHERE $idProcedure = ?;");
        $stmt->execute(array($idPrivatePayer, $idProcedure));

        return $stmt->fetch() == true;
    }

    function editProcedureEntityPayer($idProcedure, $idEntityPayer)
    {
        global $conn;

        $stmt = $conn->prepare("UPDATE PROCEDURE SET identitypayer = ?
                                WHERE $idProcedure = ?;");
        $stmt->execute(array($idEntityPayer, $idProcedure));

        return $stmt->fetch() == true;
    }

    function editProcedureDate($idProcedure, $date)
    {
        global $conn;

        $stmt = $conn->prepare("UPDATE PROCEDURE SET date = ?
                                WHERE $idProcedure = ?;");
        $stmt->execute(array($date, $idProcedure));

        return $stmt->fetch() == true;
    }

    function editProcedureTotalValue($idProcedure, $totalValue)
    {
        global $conn;

        $stmt = $conn->prepare("UPDATE PROCEDURE SET totalValue = ?
                                WHERE $idProcedure = ?;");
        $stmt->execute(array($totalValue, $idProcedure));

        return $stmt->fetch() == true;
    }

    function removeSubProcedure($idProcedure, $idProcedureType)
    {
        global $conn;

        $stmt = $conn->prepare("DELETE FROM PROCEDUREPROCEDURETYPE WHERE idprocedure = ? AND idproceduretype = ?");

        $stmt->execute(array($idProcedure, $idProcedureType));

        return $stmt->fetch();
    }

    function removeProfessionalFromProcedure($idProcedure, $idProfessional)
    {
        global $conn;

        $stmt = $conn->prepare("DELETE FROM PROCEDUREPROFESSIONAL WHERE idprocedure = ? AND idprofessional = ?");

        $stmt->execute(array($idProcedure, $idProfessional));

        return $stmt->fetch();
    }

    function getProcedureTypes()
    {
        global $conn;

        $stmt = $conn->prepare("SELECT * FROM PROCEDURETYPE");

        $stmt->execute();

        return $stmt->fetchAll();
    }

    function addSubProcedures($subProcedures)
    {
        global $conn;

        $conn->beginTransaction();

        foreach ($subProcedures as $subProcedure) {
            $stmt = $conn->prepare("INSERT INTO PROCEDUREPROCEDURETYPE (idprocedure, idproceduretype)
                              VALUES (:idProcedure, :idProcedureType)");

            $stmt->execute(array(":idProcedure" => $subProcedure['idProcedure'], ":idProcedureType" => $subProcedure["idProcedureType"]));
        }

        return $conn->commit() == true;
    }

    function addProfessionals($professionals)
    {
        global $conn;

        $conn->beginTransaction();

        foreach ($professionals as $professional) {
            if (isset($professional['nonDefault'])) {
                $stmt = $conn->prepare("INSERT INTO PROCEDUREPROFESSIONAL(idprocedure, idprofessional, nondefault)
                                    VALUES (:idProcedure, :idProfessional, :nonDefault)");
                $stmt->execute(array(":idProcedure" => $professional['idProcedure'], ":idProfessional" => $professional['idProfessional'], ":nonDefault" => $professional['nonDefault']));

            } else {
                $stmt = $conn->prepare("INSERT INTO PROCEDUREPROFESSIONAL(idprocedure, idprofessional)
                                    VALUES (:idProcedure, :idProfessional)");
                $stmt->execute(array(":idProcedure" => $professional['idProcedure'], ":idProfessional" => $professional['idProfessional']));
            }

        }

        return $conn->commit() == true;
    }

    function createEntityPayer($name, $contractstart, $contractend, $type, $nif, $valueperk, $idaccount)
    {
        global $conn;
        $stmt = $conn->prepare("INSERT INTO EntityPayer(name, contractstart, contractend, type, nif, valueperk, idaccount)
                            VALUES (:name, :contractstart, :contractend, :type, :nif, :valueperk, :idaccount)");

        $stmt->execute(array("name" => $name, "contractstart" => $contractstart, "contractend" => $contractend, "type" => $type, "nif" => $nif, "valueperk" => $valueperk, "idaccount" => $idaccount));

        return $stmt->fetch() == true;
    }

    function createPrivatePayer($name, $accountId)
    {
        global $conn;
        $stmt = $conn->prepare("INSERT INTO PrivatePayer(name, idaccount) VALUES (:name, :accountId)");
        $stmt->execute(array("name" => $name, "accountId" => $accountId));

        return $stmt->fetch() == true;
    }

    function getEntityPayers($idAccount)
    {
        global $conn;

        $stmt = $conn->prepare("SELECT *
                            FROM entitypayer
                            WHERE idaccount = :idAccount ORDER BY name");
        $stmt->execute(array("idAccount" => $idAccount));

        return $stmt->fetchAll();
    }

    function getPrivatePayers($idAccount)
    {
        global $conn;

        $stmt = $conn->prepare("SELECT *
                            FROM privatepayer
                            WHERE idaccount = :idAccount ORDER BY name");
        $stmt->execute(array("idAccount" => $idAccount));

        return $stmt->fetchAll();
    }

    function checkDuplicateEntityName($idaccount, $name)
    {
        global $conn;

        $stmt = $conn->prepare("SELECT name FROM privatepayer
                            WHERE idaccount = :idaccount AND name=:name");
        $stmt->execute(array("idaccount" => $idaccount, "name" => $name));

        if (count($stmt->fetchAll()) > 0) return true;

        $stmt = $conn->prepare("SELECT name FROM entitypayer
                            WHERE idaccount = :idaccount AND name=:name");
        $stmt->execute(array("idaccount" => $idaccount, "name" => $name));

        return count($stmt->fetchAll()) > 0;
    }

    function editPrivatePayerName($accountid, $name, $idprivatepayer)
    {
        global $conn;
        $stmt = $conn->prepare("UPDATE privatepayer SET name = :name
                            WHERE idaccount = :accountid AND idprivatepayer = :idprivatepayer");
        $stmt->execute(array("name" => $name, "accountid" => $accountid, "idprivatepayer" => $idprivatepayer));

        return $stmt->fetch() == true;
    }

    function editEntityPayerName($accountid, $identitypayer, $name)
    {
        global $conn;
        $stmt = $conn->prepare("UPDATE entitypayer SET name = :name
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
        $stmt->execute(array("name" => $name, "accountid" => $accountid, "identitypayer" => $identitypayer));

        return $stmt->fetch() == true;
    }

    function editEntityPayerNIF($accountid, $identitypayer, $nif)
    {
        global $conn;
        $stmt = $conn->prepare("UPDATE entitypayer SET nif = :nif
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
        $stmt->execute(array("nif" => $nif, "accountid" => $accountid, "identitypayer" => $identitypayer));

        return $stmt->fetch() == true;
    }

    function editEntityPayerContractStart($accountid, $identitypayer, $contractstart)
    {
        global $conn;
        $stmt = $conn->prepare("UPDATE entitypayer SET contractstart = :contractstart
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
        $stmt->execute(array("contractstart" => $contractstart, "accountid" => $accountid, "identitypayer" => $identitypayer));

        return $stmt->fetch() == true;
    }

    function editEntityPayerContractEnd($accountid, $identitypayer, $contractend)
    {
        global $conn;
        $stmt = $conn->prepare("UPDATE entitypayer SET contractend = :contractend
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
        $stmt->execute(array("contractend" => $contractend, "accountid" => $accountid, "identitypayer" => $identitypayer));

        return $stmt->fetch() == true;
    }

    function editEntityPayerValuePerK($accountid, $identitypayer, $valueperk)
    {
        global $conn;
        $stmt = $conn->prepare("UPDATE entitypayer SET valueperk = :valueperk
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
        $stmt->execute(array("valueperk" => $valueperk, "accountid" => $accountid, "identitypayer" => $identitypayer));

        return $stmt->fetch() == true;
    }

    function deleteEntityPayer($accountid, $identitypayer)
    {
        global $conn;
        $stmt = $conn->prepare("DELETE FROM entitypayer WHERE identitypayer NOT IN (
                              SELECT
                                identitypayer
                              FROM procedure
                              WHERE idaccount = :accountid
                            ) AND identitypayer = :identitypayer");
        $stmt->execute(array("accountid" => $accountid, "identitypayer" => $identitypayer));

        return $stmt->rowCount() > 0;
    }

    function deletePrivatePayer($accountid, $idprivatepayer)
    {
        global $conn;
        $stmt = $conn->prepare("DELETE FROM privatepayer WHERE idprivatepayer NOT IN (
                              SELECT
                                idprivatepayer
                              FROM procedure
                              WHERE idaccount = :accountid
                            ) AND idprivatepayer = :idprivatepayer");
        $stmt->execute(array("accountid" => $accountid, "idprivatepayer" => $idprivatepayer));

        return $stmt->rowCount() > 0;
    }

    function checkBrute($idAccount)
    {
        global $conn;
        $valid_attempts = time() - (2 * 60 * 60); // All login attempts since 2 hours ago

        $stmt = $conn->prepare("SELECT time
                            FROM loginattempts
                            WHERE idaccount = :idAccount
                            AND time > :time");
        $stmt->execute(array("idAccount" => $idAccount, "time" => $valid_attempts));

        return count($stmt->fetchAll()) > 5;
    }

?>