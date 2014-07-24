<?php

    function getSpecialities()
    {
        global $conn;
        $stmt = $conn->prepare("SELECT * FROM SPECIALITY");
        $stmt->execute();

        return $stmt->fetchAll();
    }

    function getProcedures($idAccount)
    {
        global $conn;
        $stmt = $conn->prepare("SELECT * FROM PROCEDURE NATURAL JOIN PROCEDUREACCOUNT WHERE idAccount = ? ORDER BY date DESC");
        $stmt->execute(array($idAccount));

        $procedures = $stmt->fetchAll();

        foreach ($procedures as &$procedure) {
            if ($procedure['idprivatepayer'] != 0) {
                $tmp = getPrivatePayer($procedure['idprivatepayer']);
                $procedure['payerName'] = $tmp['name'];
                $procedure['idpayer'] = $tmp['idprivatepayer'];
            } else if ($procedure['identitypayer'] != 0) {
                $tmp = getEntityPayer($procedure['identitypayer']);
                $procedure['payerName'] = $tmp['name'];
                $procedure['idpayer'] = $tmp['identitypayer'];
            } else {
                $procedure['payerName'] = 'Não Definido';
                $procedure['idpayer'] = 0;
            }
        }

        return $procedures;
    }

    function getNumberOfOpenProcedures($idAccount)
    {
        global $conn;
        $stmt = $conn->prepare("SELECT COUNT(*) AS number FROM  PROCEDURE NATURAL JOIN PROCEDUREACCOUNT WHERE idAccount = ?
                                AND (paymentstatus = 'Recebi' OR paymentstatus = 'Pendente');");
        $stmt->execute(array($idAccount));

        return $stmt->fetch();
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

    function addProcedure($idAccount, $paymentStatus, $date, $wasAssistant, $totalRemun, $personalRemun, $valuePerK)
    {
        global $conn;

        $conn->beginTransaction();

        //$code = hash('sha256', $paymentStatus + date('Y-m-d H:i:s')); // NEEDS TO BE CHANGED

        if (strtotime($date)) {
            $stmt = $conn->prepare("INSERT INTO PROCEDURE(paymentstatus, date, wasassistant)
                            VALUES(:paymentStatus, :date, :wasassistant);");
            $stmt->execute(array("paymentStatus" => $paymentStatus, "date" => $date, "wasassistant" => $wasAssistant));
        } else {
            $stmt = $conn->prepare("INSERT INTO PROCEDURE(paymentstatus, date, wasassistant)
                            VALUES(:paymentStatus, CURRENT_TIMESTAMP, :wasassistant);");

            $stmt->execute(array("paymentStatus" => $paymentStatus, "wasassistant" => $wasAssistant));
        }

        $id = $conn->lastInsertId('procedure_idprocedure_seq');

        echo "Id do procedimento acabado de inserir: " + $id;

        if (isset($totalRemun)) {
            $stmt = $conn->prepare("UPDATE PROCEDURE SET totalremun = :totalremun WHERE idprocedure = :idprocedure;");

            $stmt->execute(array("totalremun" => $totalRemun, "idprocedure" => $id));
        }

        if (isset($personalRemun)) {
            $stmt = $conn->prepare("UPDATE PROCEDURE SET personalremun = :personalremun WHERE idprocedure = :idprocedure;");

            $stmt->execute(array("personalremun" => $personalRemun, "idprocedure" => $id));
        }

        if (isset($valuePerK)) {
            $stmt = $conn->prepare("UPDATE PROCEDURE SET valueperk = :valueperk WHERE idprocedure = :idprocedure;");

            $stmt->execute(array("valueperk" => $valuePerK, "idprocedure" => $id));
        }

        if ($conn->commit()) {
            return $id;
        } else {
            return 0;
        }

    }

    function addSubProcedures($idProcedure, $subProcedures)
    {
        global $conn;

        $conn->beginTransaction();

        if (isset($subProcedures)) {
            foreach ($subProcedures as $subProcedure) {
                $stmt = $conn->prepare("INSERT INTO PROCEDUREPROCEDURETYPE(idprocedure, idproceduretype)
                          VALUES(:idProcedure, :idProcedureType)");

                $stmt->execute(array(":idProcedure" => $idProcedure, ":idProcedureType" => $subProcedure));
            }
        }

        return $conn->commit();
    }

    function addProcedureToAccount($idProcedure, $idAccount)
    {
        global $conn;

        $stmt = $conn->prepare("INSERT INTO PROCEDUREACCOUNT VALUES(:idprocedure, :idaccount)");
        $stmt->execute(array("idprocedure" => $idProcedure, "idaccount" => $idAccount));

        return $stmt->fetch();
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

    function deleteProcedure($idProcedure, $idAccount)
    {
        global $conn;
        $stmt = $conn->prepare("DELETE FROM ProcedureAccount WHERE idprocedure = :idprocedure
                             AND idaccount = :idaccount");
        $stmt->execute(array("idprocedure" => $idProcedure, "idaccount" => $idAccount));
    }

    function getProcedureTypes()
    {
        global $conn;

        $stmt = $conn->prepare("SELECT * FROM PROCEDURETYPE");

        $stmt->execute();

        return $stmt->fetchAll();
    }

    function addProfessionals($professionals)
    {
        global $conn;

        $conn->beginTransaction();

        foreach ($professionals as $professional) {
            if (isset($professional['nonDefault'])) {
                $stmt = $conn->prepare("INSERT INTO PROCEDUREPROFESSIONAL(idprocedure, idprofessional, nondefault)
                                    VALUES(:idProcedure, :idProfessional, :nonDefault)");
                $stmt->execute(array(":idProcedure" => $professional['idProcedure'], ":idProfessional" => $professional['idProfessional'], ":nonDefault" => $professional['nonDefault']));

            } else {
                $stmt = $conn->prepare("INSERT INTO PROCEDUREPROFESSIONAL(idprocedure, idprofessional)
                                    VALUES(:idProcedure, :idProfessional)");
                $stmt->execute(array(":idProcedure" => $professional['idProcedure'], ":idProfessional" => $professional['idProfessional']));
            }

        }

        return $conn->commit() == true;
    }

    function getRecentProfessionals($idaccount, $speciality, $name)
    {
        global $conn;
        if ($speciality == 'any') {
            $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, Professional.idProfessional
                            FROM Professional
                            WHERE Professional . idAccount = :idAccount AND Professional . name LIKE :name
                            ORDER BY Professional . createdOn DESC
                            LIMIT 3");

            $stmt->execute(array("idAccount" => $idaccount, "name" => $name . '%'));

        } else {
            $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, Professional.idProfessional
                            FROM Speciality, Professional
                            WHERE Speciality . name = :speciality AND Professional . idSpeciality = Speciality . idSpeciality AND Professional . idAccount = :idAccount AND Professional . name LIKE :name
                            ORDER BY Professional . createdOn DESC
                            LIMIT 3");

            $stmt->execute(array("idAccount" => $idaccount, "speciality" => $speciality, "name" => $name . '%'));

        }

        return $stmt->fetchAll();
    }

    function shareProcedure($idprocedure, $idinviting, $licenseid)
    {
        global $conn;
        echo 3;
        if ($licenseid === 'all') {
            echo 1;
            $stmt = $conn->prepare("SELECT share_procedure_with_all(:idprocedure, :idaccount)");
            $stmt->execute(array("idprocedure" => $idprocedure, "idaccount" => $idinviting));
        } else {
            echo 2;
            $stmt = $conn->prepare("INSERT INTO ProcedureInvitation(idProcedure, idInvitingAccount, licenseIdInvited)
                                VALUES (:idprocedure, :idaccount, :licenseid)");

            $stmt->execute(array("idprocedure" => $idprocedure, "idaccount" => $idinviting, "licenseid" => $licenseid));
        }
    }

    function getInvites($licenseid)
    {
        global $conn;

        $stmt = $conn->prepare("SELECT Account.name invitingName,
                            ProcedureInvitation.idProcedure, ProcedureInvitation.idInvitingAccount, wasRejected
                            FROM ProcedureInvitation, Account
                            WHERE ProcedureInvitation.licenseIdInvited = :licenseId
                            AND ProcedureInvitation.idInvitingAccount = Account.idAccount");
        $stmt->execute(array("licenseId" => $licenseid));

        return $stmt->fetchAll();
    }

    function rejectShared($idProcedure, $idInvitingAccount, $licenseIdInvited)
    {
        global $conn;

        $stmt = $conn->prepare("UPDATE ProcedureInvitation SET wasRejected = TRUE
                            WHERE idProcedure = :idProcedure
                            AND idInvitingAccount = :idInvitingAccount
                            AND licenseIdInvited = :licenseIdInvited");

        $stmt->execute(array("idProcedure" => $idProcedure, "idInvitingAccount" => $idInvitingAccount, "licenseIdInvited" => $licenseIdInvited));
    }

    function deleteShared($idProcedure, $idInvitingAccount, $licenseIdInvited)
    {
        global $conn;

        $stmt = $conn->prepare("DELETE FROM ProcedureInvitation
                            WHERE idProcedure = :idProcedure
                            AND idInvitingAccount = :idInvitingAccount
                            AND licenseIdInvited = :licenseIdInvited");

        $stmt->execute(array("idProcedure" => $idProcedure, "idInvitingAccount" => $idInvitingAccount, "licenseIdInvited" => $licenseIdInvited));
    }

    function acceptShared($idProcedure, $idInvitingAccount, $licenseIdInvited, $idAccount)
    {
        global $conn;

        $stmt = $conn->prepare("INSERT INTO ProcedureAccount(idProcedure, idAccount)
                            VALUES (:idProcedure, :idAccount)");

        $stmt->execute(array("idProcedure" => $idProcedure, "idAccount" => $idAccount));

        deleteShared($idProcedure, $idInvitingAccount, $licenseIdInvited);
    }

    function cleanShareds()
    {
        global $conn;

        $stmt = $conn->prepare("DELETE FROM ProcedureInvitation
                            WHERE date < CURRENT_TIMESTAMP - INTERVAL '7 days'");

        $stmt->execute();
    }

?>