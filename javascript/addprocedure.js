var subProcedures = 0;
const valuePerK = $('#valuePerK');
const anesthetistRemun = $('#anesthetistRemun');
const totalRemun = $('#totalRemun');
const totalType = $('#totalType');
const payerType = $("#payerType");
const privatePayer = $("#privatePayer");
const entityPayer = $("#entityPayer");
const newEntityPayer = $("#newEntityPayer");
const newPrivatePayer = $("#newPrivatePayer");
const namePrivate = $("#namePrivate");
const nifPrivate = $("#nifPrivate");
const nameEntity = $("#nameEntity");
const nifEntity = $("#nifEntity");
const generalRemun = $("#generalRemun");
const firstAssistantRemun = $('#firstAssistantRemun');
const firstAssistantName = $('#firstAssistantName');
const secondAssistantRemun = $('#secondAssistantRemun');
const secondAssistantName = $('#secondAssistantName');
const instrumentistRemun = $('#instrumentistRemun');
const instrumentistName = $('#instrumentistName');
const anesthetistName = $('#anesthetistName');
const anesthetistK = $('#anesthetistK');
const generalK = $('#generalK');
const nSubProcedures = $('#nSubProcedures');
const submitButton = $("#submitButton");
const role = $('#role');
const idPatient = $("#idPatient");
const patientForm = $("#patientForm");
const namePatient = $("#namePatient");
const nifPatient = $("#nifPatient");
const cellphonePatient = $("#cellphonePatient");
const beneficiaryNrPatient = $("#beneficiaryNrPatient");
const errorMessageNifPatient = $("#errorMessageNifPatient");
const errorMessageNamePatient = $("#errorMessageNamePatient");
const errorMessageCellphonePatient = $("#errorMessageCellphonePatient");
const subProcedureTemplate = Handlebars.compile($('#subProcedure-template').html());

var enableField = function (field, disable) {
    field.prop('readonly', disable);
    if (disable)
        field.css('background-color', "lightgrey");
    else
        field.css('background-color', "");
};

$(document).ready(function () {
    updatePayerVisibility();

    $('#addSubProcedure').click(function () {
        addSubProcedure();
    });

    totalType.change(function () {
        if (totalType.val() == 'auto') {
            enableField(totalRemun, true);

            updateRemunerations();
        } else {
            enableField(totalRemun, false);
        }
    });

    totalRemun.bind("paste drop input change cut", function () {
        updateRemunerations();
    });

    entityType.change(function () {
        updatePayerVisibility();
        updateRemunerations();
    });

    idPatient.change(function () {
        updatePatientInfo();
    });
    updatePatientInfo();

    fillProfessionalRow(role.val());
    role.change(function () {
        fillProfessionalRow($(this).val());
    });


    $("#entityName").change(function () {
        updatePayerVisibility();
        updateRemunerations();
    });

    $("#privateName").change(function () {
        updatePayerVisibility();
        updateRemunerations();
    });

    const subProcedures = $("#subProcedures");
    subProcedures.on('change', '.subProcedure', function () {
        updateRemunerations();
        $($(this).siblings()[0]).val($(this).find(":selected").text());
        $($(this).siblings()[1]).val(subProceduresList[$(this).val() - 1].k);
        $($(this).siblings()[2]).val(subProceduresList[$(this).val() - 1].c);
        $($(this).siblings()[3]).val(subProceduresList[$(this).val() - 1].code);
    });

    subProcedures.on('click', '.removeSubProcedureButton', function (e) {
        e.preventDefault();
        removeSubProcedure($(this).parent().attr("id").split("subProcedure")[1]);
    });

    valuePerK.bind("paste drop input change cut", function () {
        updateRemunerations();
    });

    firstAssistantName.bind("paste drop input change cut", function () {
        fillFirstAssistantRemuneration();
        fillGeneralRemuneration();
    });

    secondAssistantName.bind("paste drop input change cut", function () {
        fillSecondAssistantRemuneration();
        fillGeneralRemuneration();
    });

    instrumentistName.bind("paste drop input change cut", function () {
        fillInstrumentistRemuneration();
        fillGeneralRemuneration();
    });

    anesthetistName.bind("paste drop input change cut", function () {
        fillAnesthetistRemuneration();
        fillGeneralRemuneration();
    });

    anesthetistK.change(function () {
        updateRemunerations();
    });

    if (method === "editProcedure") {
        var editProcedurePayerType = editProcedurePayer['payerType'];
        entityType.val(editProcedurePayerType);
        $("#" + editProcedurePayerType.toLowerCase() + "name").val(editProcedurePayer['idpayer']);
        updatePayerVisibility();

        $.each(editSubProcedures, function (i, v) {
            addNSubProcedureById(v['idproceduretype'], v['quantity']);
        });

        if (anesthetistName.val() !== "")
            anesthetistK.val(editAnesthetistK);

        if (editHasManualK) {
            totalType.val("manual");
            enableField(totalRemun, false);
        }

        updateRemunerations();
    }

    $.ajax({
        url: baseUrl + "actions/professionals/getrecentprofessionals.php",
        dataType: "json",
        data: {speciality: -1},
        type: 'GET',
        success: function (data) {
            var recentProfessionals = $.map(data, function (item) {
                return {
                    label: item.name,
                    nif: item['nif'],
                    licenseid: item['licenseid'],
                    idspeciality: item['idspeciality'],
                    id: item['idprofessional']
                };
            });

            $('.professionalName').autocomplete({
                source: recentProfessionals,
                minLength: 3,
                select: function (event, ui) {
                    if (ui.item) {
                        $(this).parent().siblings().first().next().children().first().val(ui.item.licenseid);
                    }
                }
            });
        },
        error: function (a, b, c) {
            console.log(a);
            console.log(b);
            console.log(c);
        }
    });
});

var previousRole = '';
var fillProfessionalRow = function (roleName) {
    var currentRoleFields = $("#" + roleName + "Row");
    var currentRoleName = currentRoleFields.children().first().children().first();
    var currentRoleLicenseId = currentRoleFields.children().first().next().next().children().first();

    currentRoleName.val(myName);
    enableField(currentRoleName, true);
    currentRoleLicenseId.val(myLicenseId);
    enableField(currentRoleLicenseId, true);

    var previousRoleFields = $("#" + previousRole + "Row");
    var previousRoleName = previousRoleFields.children().first().children().first();
    var previousRoleLicenseId = previousRoleFields.children().first().next().next().children().first();

    previousRoleName.val("");
    enableField(previousRoleName, false);
    previousRoleLicenseId.val("");
    enableField(previousRoleLicenseId, false);

    previousRole = roleName;
};

var getSubProcedureTypes = function () {
    var result = "";
    for (var i = 0; i < subProcedureTypes.length; i++) {
        result += '<option value = "' + subProcedureTypes[i].idproceduretype + '">' + subProcedureTypes[i].name + '</option>';
    }
    return result;
};

var addSubProcedure = function () {
    nSubProcedures.val(++subProcedures);
    $(subProcedureTemplate({number: subProcedures, type: getSubProcedureTypes()}))
        .fadeIn('slow').appendTo('#subProcedures');

    updateRemunerations();
};

var addNSubProcedureById = function (id, n) {
    if (n <= 0) {
        updateRemunerations();
        return;
    }

    nSubProcedures.val(++subProcedures);
    var newSubP = $(subProcedureTemplate({number: subProcedures, type: getSubProcedureTypes()}));

    newSubP.appendTo('#subProcedures');
    var newSubPInfo = subProceduresList[id - 1];
    $(newSubP.children().first()).val(id);
    $(newSubP.children().first().next()).val(newSubPInfo['k']);
    $(newSubP.children().first().next().next()).val(newSubPInfo['label']);

    addNSubProcedureById(id, n - 1);
};

var updatePatientInfo = function () {
    var id = idPatient.val();

    switch (id) {
        //Novo
        case "-2":
            disablePatientForm(false);
            erasePatientForm();
            disablePatientValidations(false);

            break;
        //Nenhum
        case "-1":
            disablePatientForm(true);
            erasePatientForm();
            disablePatientValidations(true);

            break;
        //Já existente
        default:
            fillPatientForm(id);
            disablePatientForm(true);
            disablePatientValidations(true);

            break;
    }
};

var disablePatientForm = function (disable) {
    patientForm.find("input").attr("disabled", disable);
};

var disablePatientValidations = function (disable) {
    if (disable) {
        errorMessageNifPatient.text("");
        errorMessageNamePatient.text("");
        errorMessageCellphonePatient.text("");
        patientForm.find("input").css("border", "");
    } else {
        if (!isEdit) {
            isInvalidPatient(namePatient, "Nome obrigatório", errorMessageNamePatient);
        } else {
            isValidPatient(namePatient, errorMessageNamePatient);
        }

        isValidPatient(nifPatient, errorMessageNifPatient);
        isValidPatient(cellphonePatient, errorMessageCellphonePatient);
    }
};

var fillPatientForm = function (id) {
    var patient = getPatient(id);

    namePatient.val(patient.name);
    nifPatient.val(patient.nif);
    cellphonePatient.val(patient.cellphone);
    beneficiaryNrPatient.val(patient.beneficiarynr);
};

var erasePatientForm = function () {
    patientForm.find("input").val("");
};

var fillValuePerK = function (type) {
    var curreantPayerValuePerK;
    switch (type) {
        case 'private':
            curreantPayerValuePerK = getPrivateValuePerK();
            break;
        case 'entity':
            curreantPayerValuePerK = getEntityValuePerK();
            break;
        case 'none':
            curreantPayerValuePerK = 0;
            break;
        default:
            break;
    }

    valuePerK.val(curreantPayerValuePerK);

    if (curreantPayerValuePerK === 0)
        enableField(valuePerK, false);
};

var getPrivateValuePerK = function () {
    for (var i = 0; i < privatePayers.length; i++) {
        if (privatePayers[i].idprivatepayer == $('#privateName').val()) {
            if (isNumeric(privatePayers[i].valueperk)) {
                return privatePayers[i].valueperk;
            } else return 0;
        }
    }

    return 0;
};

var getEntityValuePerK = function () {
    for (var i = 0; i < entityPayers.length; i++) {
        if (entityPayers[i].identitypayer == $('#entityName').val()) {
            if (isNumeric(entityPayers[i].valueperk)) {
                return entityPayers[i].valueperk;
            } else return 0;
        }
    }

    return 0;
};

var getPatient = function (id) {
    for (var i = 0; i < patients.length; i++) {
        if (patients[i].idpatient == id) {
            return patients[i];
        }
    }

    return false;
};

var updateRemunerations = function () {
    fillTotalRemuneration();
    fillFirstAssistantRemuneration();
    fillSecondAssistantRemuneration();
    fillInstrumentistRemuneration();
    fillAnesthetistRemuneration();
    fillGeneralRemuneration();
};

var fillGeneralRemuneration = function () {
    var total = totalRemun.val();

    if (thereIsAFirstAssistant()) {
        total -= firstAssistantRemun.val();
    }

    if (thereIsASecondAssistant()) {
        total -= secondAssistantRemun.val();
    }

    if (thereIsAnInstrumentist()) {
        total -= instrumentistRemun.val();
    }

    if (thereIsAnAnesthetist()) {
        total -= anesthetistRemun.val();
    }

    if (totalRemun.val() > 0)
        generalK.text(Math.floor((total / totalRemun.val()) * 100) + '%');

    generalRemun.val(total);
};

var fillFirstAssistantRemuneration = function () {
    if (thereIsAFirstAssistant()) {
        var remun = totalRemun.val() * 0.2;
        firstAssistantRemun.val(remun);
    } else {
        firstAssistantRemun.val(0);
    }
};

var fillSecondAssistantRemuneration = function () {
    if (thereIsASecondAssistant()) {
        var remun = totalRemun.val() * 0.1;
        secondAssistantRemun.val(remun);
    } else {
        secondAssistantRemun.val(0);
    }
};

var fillInstrumentistRemuneration = function () {
    if (thereIsAnInstrumentist()) {
        var remun = totalRemun.val() * 0.1;
        instrumentistRemun.val(remun);
    } else {
        instrumentistRemun.val(0);
    }
};

var fillAnesthetistRemuneration = function () {
    var remun;
    if (thereIsAnAnesthetist()) {
        switch (anesthetistK.val()) {
            case "25":
                remun = totalRemun.val() * 0.25;
                break;
            case "30":
                remun = totalRemun.val() * 0.30;
                break;
            case "table":
                var totalK = getTotalK();
                var k;
                if (totalK < 101) {
                    k = 27;
                } else if (totalK < 121) {
                    k = 33;
                } else if (totalK < 141) {
                    k = 39;
                } else if (totalK < 161) {
                    k = 45;
                } else if (totalK < 181) {
                    k = 51;
                } else if (totalK < 201) {
                    k = 57;
                } else if (totalK < 241) {
                    k = 66;
                } else if (totalK < 281) {
                    k = 78;
                } else if (totalK < 301) {
                    k = 87;
                } else if (totalK < 341) {
                    k = 95;
                } else if (totalK < 401) {
                    k = 110;
                } else if (totalK < 421) {
                    k = 120;
                } else if (totalK < 461) {
                    k = 130;
                } else if (totalK < 481) {
                    k = 140;
                } else if (totalK < 511) {
                    k = 150;
                } else if (totalK < 561) {
                    k = 160;
                } else if (totalK < 601) {
                    k = 175;
                } else if (totalK < 701) {
                    k = 195;
                } else if (totalK < 801) {
                    k = 225;
                } else if (totalK < 901) {
                    k = 255;
                } else {
                    k = 300;
                }

                remun = k * valuePerK.val();

                break;
        }
        anesthetistRemun.val(remun);
    } else {
        anesthetistRemun.val(0);
    }
};

var removeSubProcedure = function (subProcedureNr) {
    $("#subProcedure" + subProcedureNr).remove();

    //Commented out due to how add/edit procedure works
    //subProcedures--;
    //nSubProcedures.val(subProcedures);

    updateRemunerations();
};

var fillTotalRemuneration = function () {
    if (totalType.val() == 'auto') {
        var total = 0.0;

        if (isNumeric(valuePerK.val())) {
            $('.subProcedure').each(function () {
                for (var i = 0; i < subProcedureTypes.length; i++) {
                    if ($(this).val() == subProcedureTypes[i].idproceduretype) {
                        total = total + parseInt(subProcedureTypes[i].k);
                    }
                }
            });
        }
        total *= valuePerK.val();
        totalRemun.val(total);
    }
};


function getTotalK() {
    var total = 0;

    if (isNumeric($('input[name=valuePerK]').val())) {
        $('.subProcedure').each(function () {
            for (var i = 0; i < subProcedureTypes.length; i++) {
                if ($(this).val() == subProcedureTypes[i].idproceduretype) {
                    total += parseInt(subProcedureTypes[i].k);
                }
            }
        });

        return total;
    }

    return 0;
}

var updatePayerVisibility = function () {
    switch (entityType.val()) {
        case 'Private':
            privatePayer.show();
            entityPayer.hide();
            newEntityPayer.hide();
            newPrivatePayer.hide();

            enableField(valuePerK, true);
            fillValuePerK('private');
            payerType.val("Private");

            checkSubmitButton();
            break;
        case 'Entity':
            privatePayer.hide();
            entityPayer.show();
            newEntityPayer.hide();
            newPrivatePayer.hide();

            enableField(valuePerK, true);
            fillValuePerK('entity');
            payerType.val("Entity");

            checkSubmitButton();
            break;
        case 'NewPrivate':
            privatePayer.hide();
            entityPayer.hide();
            newEntityPayer.hide();
            newPrivatePayer.show();

            enableField(valuePerK, false);
            fillValuePerK('none');
            payerType.val("NewPrivate");

            checkSubmitButton();
            break;
        case 'NewEntity':
            privatePayer.hide();
            entityPayer.hide();
            newEntityPayer.show();
            newPrivatePayer.hide();

            enableField(valuePerK, false);
            fillValuePerK('none');
            payerType.val("NewEntity");

            checkSubmitButton();
            break;
        default:
            break;
    }
};

var thereIsAFirstAssistant = function () {
    return firstAssistantName.val() != "";
};

var thereIsASecondAssistant = function () {
    return secondAssistantName.val() != "";
};

var thereIsAnInstrumentist = function () {
    return instrumentistName.val() != "";
};

var thereIsAnAnesthetist = function () {
    return anesthetistName.val() != "";
};

var isNumeric = function (n) {
    return !isNaN(parseFloat(n)) && isFinite(n);
};

var noErrorMessages = function () {
    return $('.errorMessage, .errorMessage' + payerType.val().slice(3)).text() === '';
};

var checkSubmitButton = function () {
    submitButton.attr('disabled', !noErrorMessages());
};

$(document).on("focus", ".subProcedureName:not(.ui-autocomplete-input)", function () {
    $(this).autocomplete({
        source: subProceduresList,
        select: function (event, ui) {
            if (ui.item) {
                $(this).siblings().first().val(ui.item.id);
            }
        }
    });
}).on("focus", ".subProcedureCode:not(.ui-autocomplete-input)", function () {
    $(this).autocomplete({
        source: function (request, response) {
            response(subProceduresList2.filter(function (e) {
                return new RegExp('^' + request.term).test(e.label);
            }));
        },
        select: function (event, ui) {
            if (ui.item) {
                $(this).siblings().first().val(ui.item.id);
            }
        }
    });
});

const subProceduresList2 = [{"id": 1, "label": "01.00.00.01"}, {"id": 2, "label": "01.00.00.02"}, {
    "id": 3,
    "label": "01.00.00.03"
}, {"id": 4, "label": "01.00.00.04"}, {"id": 5, "label": "01.00.00.05"}, {"id": 6, "label": "01.00.00.06"}, {
    "id": 7,
    "label": "01.01.00.01"
}, {"id": 8, "label": "01.01.00.02"}, {"id": 9, "label": "01.01.00.03"}, {"id": 10, "label": "01.01.00.04"}, {
    "id": 11,
    "label": "01.01.00.05"
}, {"id": 12, "label": "01.01.00.06"}, {"id": 13, "label": "01.02.00.01"}, {
    "id": 14,
    "label": "01.02.00.02"
}, {"id": 15, "label": "01.02.00.03"}, {"id": 16, "label": "01.02.00.04"}, {
    "id": 17,
    "label": "01.02.00.05"
}, {"id": 18, "label": "01.02.00.06"}, {"id": 19, "label": "01.03.00.02"}, {
    "id": 20,
    "label": "01.03.00.03"
}, {"id": 21, "label": "01.03.00.04"}, {"id": 22, "label": "01.03.00.05"}, {
    "id": 23,
    "label": "01.03.00.06"
}, {"id": 24, "label": "01.03.00.07"}, {"id": 25, "label": "01.03.00.08"}, {
    "id": 26,
    "label": "01.03.00.09"
}, {"id": 27, "label": "01.03.00.10"}, {"id": 28, "label": "01.03.00.11"}, {
    "id": 29,
    "label": "01.03.00.12"
}, {"id": 30, "label": "02.00.00.01"}, {"id": 31, "label": "02.00.00.02"}, {
    "id": 32,
    "label": "02.00.00.03"
}, {"id": 33, "label": "02.00.00.04"}, {"id": 34, "label": "02.00.00.05"}, {
    "id": 35,
    "label": "02.00.00.06"
}, {"id": 36, "label": "02.00.00.07"}, {"id": 37, "label": "02.00.00.08"}, {
    "id": 38,
    "label": "02.00.00.09"
}, {"id": 39, "label": "02.00.00.10"}, {"id": 40, "label": "02.00.00.11"}, {
    "id": 41,
    "label": "02.00.00.12"
}, {"id": 42, "label": "02.00.00.13"}, {"id": 43, "label": "02.00.00.14"}, {
    "id": 44,
    "label": "02.00.00.15"
}, {"id": 45, "label": "02.00.00.16"}, {"id": 46, "label": "02.00.00.17"}, {
    "id": 47,
    "label": "02.00.00.18"
}, {"id": 48, "label": "02.00.00.19"}, {"id": 49, "label": "02.00.00.20"}, {
    "id": 50,
    "label": "02.00.00.21"
}, {"id": 51, "label": "02.00.00.22"}, {"id": 52, "label": "02.00.00.23"}, {
    "id": 53,
    "label": "02.00.00.24"
}, {"id": 54, "label": "02.00.00.25"}, {"id": 55, "label": "02.00.00.26"}, {
    "id": 56,
    "label": "03.00.00.01"
}, {"id": 57, "label": "03.00.00.02"}, {"id": 58, "label": "03.00.00.03"}, {
    "id": 59,
    "label": "03.00.00.04"
}, {"id": 60, "label": "03.00.00.05"}, {"id": 61, "label": "04.00.00.01"}, {
    "id": 62,
    "label": "04.00.00.02"
}, {"id": 63, "label": "04.00.00.03"}, {"id": 64, "label": "04.00.00.04"}, {
    "id": 65,
    "label": "04.00.00.05"
}, {"id": 66, "label": "04.00.00.06"}, {"id": 67, "label": "05.00.00.01"}, {
    "id": 68,
    "label": "05.00.00.02"
}, {"id": 69, "label": "05.00.00.03"}, {"id": 70, "label": "05.00.00.04"}, {
    "id": 71,
    "label": "05.00.00.05"
}, {"id": 72, "label": "05.00.00.06"}, {"id": 73, "label": "05.00.00.07"}, {
    "id": 74,
    "label": "05.00.00.08"
}, {"id": 75, "label": "05.00.00.09"}, {"id": 76, "label": "06.00.00.01"}, {
    "id": 77,
    "label": "06.00.00.02"
}, {"id": 78, "label": "06.00.00.03"}, {"id": 79, "label": "06.00.00.04"}, {
    "id": 80,
    "label": "06.00.00.05"
}, {"id": 81, "label": "06.00.00.06"}, {"id": 82, "label": "06.00.00.07"}, {
    "id": 83,
    "label": "06.00.00.08"
}, {"id": 84, "label": "06.00.00.09"}, {"id": 85, "label": "06.00.00.10"}, {
    "id": 86,
    "label": "06.00.00.11"
}, {"id": 87, "label": "06.00.00.12"}, {"id": 88, "label": "06.00.00.13"}, {
    "id": 89,
    "label": "06.00.00.14"
}, {"id": 90, "label": "06.00.00.15"}, {"id": 91, "label": "06.00.00.16"}, {
    "id": 92,
    "label": "06.00.00.17"
}, {"id": 93, "label": "06.00.00.18"}, {"id": 94, "label": "06.00.00.19"}, {
    "id": 95,
    "label": "06.00.00.20"
}, {"id": 96, "label": "06.00.00.21"}, {"id": 97, "label": "06.00.00.22"}, {
    "id": 98,
    "label": "06.00.00.23"
}, {"id": 99, "label": "06.00.00.24"}, {"id": 100, "label": "06.00.00.25"}, {
    "id": 101,
    "label": "06.00.00.26"
}, {"id": 102, "label": "06.00.00.27"}, {"id": 103, "label": "06.00.00.28"}, {
    "id": 104,
    "label": "06.00.00.29"
}, {"id": 105, "label": "06.00.00.30"}, {"id": 106, "label": "06.00.00.31"}, {
    "id": 107,
    "label": "06.00.00.32"
}, {"id": 108, "label": "06.00.00.33"}, {"id": 109, "label": "06.00.00.34"}, {
    "id": 110,
    "label": "06.00.00.35"
}, {"id": 111, "label": "07.00.00.01"}, {"id": 112, "label": "07.00.00.02"}, {
    "id": 113,
    "label": "07.00.00.03"
}, {"id": 114, "label": "07.00.00.04"}, {"id": 115, "label": "07.00.00.05"}, {
    "id": 116,
    "label": "07.00.00.06"
}, {"id": 117, "label": "07.00.00.07"}, {"id": 118, "label": "07.00.00.08"}, {
    "id": 119,
    "label": "07.00.00.09"
}, {"id": 120, "label": "07.00.00.10"}, {"id": 121, "label": "07.00.00.11"}, {
    "id": 122,
    "label": "07.00.00.12"
}, {"id": 123, "label": "07.00.00.13"}, {"id": 124, "label": "07.00.00.14"}, {
    "id": 125,
    "label": "07.00.00.15"
}, {"id": 126, "label": "07.00.00.16"}, {"id": 127, "label": "07.00.00.17"}, {
    "id": 128,
    "label": "07.00.00.18"
}, {"id": 129, "label": "07.00.00.19"}, {"id": 130, "label": "07.00.00.20"}, {
    "id": 131,
    "label": "07.00.00.21"
}, {"id": 132, "label": "07.00.00.22"}, {"id": 133, "label": "07.00.00.23"}, {
    "id": 134,
    "label": "07.00.00.24"
}, {"id": 135, "label": "07.00.00.25"}, {"id": 136, "label": "07.00.00.26"}, {
    "id": 137,
    "label": "07.00.00.27"
}, {"id": 138, "label": "07.00.00.28"}, {"id": 139, "label": "07.00.00.29"}, {
    "id": 140,
    "label": "07.00.00.30"
}, {"id": 141, "label": "07.00.00.31"}, {"id": 142, "label": "07.00.00.32"}, {
    "id": 143,
    "label": "07.00.00.33"
}, {"id": 144, "label": "07.00.00.34"}, {"id": 145, "label": "07.00.00.35"}, {
    "id": 146,
    "label": "07.00.00.36"
}, {"id": 434, "label": "10.04.00.03"}, {"id": 147, "label": "07.00.00.37"}, {
    "id": 148,
    "label": "07.00.00.38"
}, {"id": 149, "label": "07.00.00.39"}, {"id": 150, "label": "07.00.00.40"}, {
    "id": 151,
    "label": "07.00.00.41"
}, {"id": 152, "label": "07.00.00.42"}, {"id": 153, "label": "07.00.00.43"}, {
    "id": 154,
    "label": "07.00.00.44"
}, {"id": 155, "label": "07.00.00.45"}, {"id": 156, "label": "07.00.00.46"}, {
    "id": 157,
    "label": "07.00.00.47"
}, {"id": 158, "label": "07.00.00.48"}, {"id": 159, "label": "07.00.00.49"}, {
    "id": 160,
    "label": "07.00.00.50"
}, {"id": 161, "label": "07.00.00.51"}, {"id": 162, "label": "07.00.00.52"}, {
    "id": 163,
    "label": "07.00.00.53"
}, {"id": 164, "label": "07.00.00.54"}, {"id": 165, "label": "07.00.00.55"}, {
    "id": 166,
    "label": "08.00.00.01"
}, {"id": 167, "label": "08.00.00.02"}, {"id": 168, "label": "08.00.00.03"}, {
    "id": 169,
    "label": "08.00.00.04"
}, {"id": 170, "label": "08.00.00.05"}, {"id": 171, "label": "08.00.00.06"}, {
    "id": 172,
    "label": "08.00.00.07"
}, {"id": 173, "label": "08.01.00.01"}, {"id": 174, "label": "08.01.00.02"}, {
    "id": 175,
    "label": "08.01.00.03"
}, {"id": 176, "label": "08.01.00.04"}, {"id": 177, "label": "08.02.00.01"}, {
    "id": 178,
    "label": "08.02.00.02"
}, {"id": 179, "label": "08.02.00.03"}, {"id": 180, "label": "08.02.00.04"}, {
    "id": 181,
    "label": "08.02.00.05"
}, {"id": 182, "label": "08.02.00.06"}, {"id": 183, "label": "08.02.00.07"}, {
    "id": 184,
    "label": "08.03.00.01"
}, {"id": 185, "label": "08.03.00.02"}, {"id": 186, "label": "08.03.00.03"}, {
    "id": 187,
    "label": "08.03.00.04"
}, {"id": 188, "label": "08.03.00.05"}, {"id": 189, "label": "08.03.00.06"}, {
    "id": 190,
    "label": "08.03.00.07"
}, {"id": 191, "label": "08.03.00.08"}, {"id": 192, "label": "08.04.00.01"}, {
    "id": 193,
    "label": "08.04.00.02"
}, {"id": 194, "label": "08.04.00.03"}, {"id": 195, "label": "08.04.00.04"}, {
    "id": 196,
    "label": "08.04.00.05"
}, {"id": 197, "label": "08.04.00.06"}, {"id": 198, "label": "08.05.00.01"}, {
    "id": 199,
    "label": "08.05.00.02"
}, {"id": 200, "label": "08.06.00.01"}, {"id": 201, "label": "08.06.00.02"}, {
    "id": 202,
    "label": "08.06.00.03"
}, {"id": 203, "label": "08.06.00.04"}, {"id": 204, "label": "08.07.00.01"}, {
    "id": 205,
    "label": "08.08.00.01"
}, {"id": 206, "label": "08.08.00.02"}, {"id": 207, "label": "08.09.00.01"}, {
    "id": 208,
    "label": "08.09.00.02"
}, {"id": 209, "label": "08.09.00.03"}, {"id": 210, "label": "09.00.00.01"}, {
    "id": 211,
    "label": "09.00.00.02"
}, {"id": 212, "label": "09.00.00.03"}, {"id": 213, "label": "09.00.00.04"}, {
    "id": 256,
    "label": "09.02.00.06"
}, {"id": 214, "label": "09.00.00.05"}, {"id": 215, "label": "09.00.00.06"}, {
    "id": 216,
    "label": "09.00.00.07"
}, {"id": 217, "label": "09.00.00.08"}, {"id": 218, "label": "09.00.00.09"}, {
    "id": 219,
    "label": "09.00.00.10"
}, {"id": 220, "label": "09.00.00.11"}, {"id": 221, "label": "09.00.01.01"}, {
    "id": 222,
    "label": "09.00.02.01"
}, {"id": 223, "label": "09.00.02.02"}, {"id": 224, "label": "09.00.03.01"}, {
    "id": 225,
    "label": "09.00.03.02"
}, {"id": 226, "label": "09.00.03.03"}, {"id": 227, "label": "09.00.03.04"}, {
    "id": 228,
    "label": "09.00.03.05"
}, {"id": 229, "label": "09.01.00.01"}, {"id": 230, "label": "09.01.00.02"}, {
    "id": 231,
    "label": "09.01.00.03"
}, {"id": 232, "label": "09.01.00.04"}, {"id": 233, "label": "09.01.00.05"}, {
    "id": 234,
    "label": "09.01.00.06"
}, {"id": 235, "label": "09.01.00.07"}, {"id": 236, "label": "09.01.00.08"}, {
    "id": 237,
    "label": "09.01.00.09"
}, {"id": 238, "label": "09.01.00.10"}, {"id": 239, "label": "09.01.00.11"}, {
    "id": 240,
    "label": "09.01.01.01"
}, {"id": 241, "label": "09.01.02.01"}, {"id": 242, "label": "09.01.02.02"}, {
    "id": 243,
    "label": "09.01.03.01"
}, {"id": 244, "label": "09.01.03.02"}, {"id": 245, "label": "09.01.03.03"}, {
    "id": 246,
    "label": "09.01.03.04"
}, {"id": 247, "label": "09.01.03.05"}, {"id": 248, "label": "09.01.03.06"}, {
    "id": 249,
    "label": "09.01.03.07"
}, {"id": 250, "label": "09.01.03.08"}, {"id": 251, "label": "09.02.00.01"}, {
    "id": 252,
    "label": "09.02.00.02"
}, {"id": 253, "label": "09.02.00.03"}, {"id": 254, "label": "09.02.00.04"}, {
    "id": 255,
    "label": "09.02.00.05"
}, {"id": 309, "label": "09.03.02.03"}, {"id": 257, "label": "09.02.00.07"}, {
    "id": 258,
    "label": "09.02.00.08"
}, {"id": 259, "label": "09.02.00.09"}, {"id": 260, "label": "09.02.00.10"}, {
    "id": 261,
    "label": "09.02.00.11"
}, {"id": 262, "label": "09.02.00.12"}, {"id": 263, "label": "09.02.00.13"}, {
    "id": 264,
    "label": "09.02.00.14"
}, {"id": 265, "label": "09.02.00.15"}, {"id": 266, "label": "09.02.00.16"}, {
    "id": 267,
    "label": "09.02.01.01"
}, {"id": 268, "label": "09.02.01.02"}, {"id": 269, "label": "09.02.01.03"}, {
    "id": 270,
    "label": "09.02.01.04"
}, {"id": 271, "label": "09.02.01.05"}, {"id": 272, "label": "09.02.01.06"}, {
    "id": 273,
    "label": "09.02.01.07"
}, {"id": 274, "label": "09.02.01.08"}, {"id": 275, "label": "09.02.01.09"}, {
    "id": 276,
    "label": "09.02.01.10"
}, {"id": 277, "label": "09.02.01.11"}, {"id": 278, "label": "09.02.02.01"}, {
    "id": 279,
    "label": "09.02.02.02"
}, {"id": 280, "label": "09.02.02.03"}, {"id": 281, "label": "09.03.00.01"}, {
    "id": 282,
    "label": "09.03.00.02"
}, {"id": 283, "label": "09.03.00.03"}, {"id": 284, "label": "09.03.00.04"}, {
    "id": 285,
    "label": "09.03.00.05"
}, {"id": 286, "label": "09.03.00.06"}, {"id": 287, "label": "09.03.00.07"}, {
    "id": 288,
    "label": "09.03.00.08"
}, {"id": 289, "label": "09.03.00.09"}, {"id": 290, "label": "09.03.00.10"}, {
    "id": 291,
    "label": "09.03.00.11"
}, {"id": 292, "label": "09.03.00.12"}, {"id": 293, "label": "09.03.00.13"}, {
    "id": 294,
    "label": "09.03.00.14"
}, {"id": 295, "label": "09.03.00.15"}, {"id": 296, "label": "09.03.00.16"}, {
    "id": 297,
    "label": "09.03.00.17"
}, {"id": 298, "label": "09.03.01.01"}, {"id": 299, "label": "09.03.01.02"}, {
    "id": 300,
    "label": "09.03.01.03"
}, {"id": 301, "label": "09.03.01.04"}, {"id": 302, "label": "09.03.01.05"}, {
    "id": 303,
    "label": "09.03.01.06"
}, {"id": 304, "label": "09.03.01.07"}, {"id": 305, "label": "09.03.01.08"}, {
    "id": 306,
    "label": "09.03.01.09"
}, {"id": 307, "label": "09.03.02.01"}, {"id": 308, "label": "09.03.02.02"}, {
    "id": 310,
    "label": "09.04.00.01"
}, {"id": 311, "label": "09.04.00.02"}, {"id": 312, "label": "09.04.00.03"}, {
    "id": 313,
    "label": "09.04.00.04"
}, {"id": 314, "label": "09.04.00.05"}, {"id": 315, "label": "09.04.01.01"}, {
    "id": 316,
    "label": "09.04.01.02"
}, {"id": 317, "label": "09.04.01.03"}, {"id": 318, "label": "09.04.01.04"}, {
    "id": 319,
    "label": "09.04.01.05"
}, {"id": 320, "label": "09.04.01.06"}, {"id": 321, "label": "09.04.01.07"}, {
    "id": 322,
    "label": "09.04.02.01"
}, {"id": 323, "label": "09.04.02.02"}, {"id": 324, "label": "09.04.02.03"}, {
    "id": 325,
    "label": "09.04.02.04"
}, {"id": 326, "label": "09.04.02.05"}, {"id": 327, "label": "09.04.02.06"}, {
    "id": 328,
    "label": "09.04.02.07"
}, {"id": 329, "label": "09.04.02.08"}, {"id": 330, "label": "09.04.02.09"}, {
    "id": 331,
    "label": "09.04.02.10"
}, {"id": 332, "label": "09.04.02.11"}, {"id": 333, "label": "09.04.02.12"}, {
    "id": 334,
    "label": "09.04.02.13"
}, {"id": 335, "label": "09.04.03.01"}, {"id": 336, "label": "09.04.03.02"}, {
    "id": 337,
    "label": "09.04.03.03"
}, {"id": 338, "label": "09.04.04.01"}, {"id": 339, "label": "09.04.04.02"}, {
    "id": 340,
    "label": "09.04.04.03"
}, {"id": 341, "label": "09.04.04.04"}, {"id": 342, "label": "09.04.04.05"}, {
    "id": 343,
    "label": "09.04.04.06"
}, {"id": 344, "label": "09.04.04.07"}, {"id": 345, "label": "09.04.04.08"}, {
    "id": 346,
    "label": "09.04.04.09"
}, {"id": 347, "label": "09.04.04.10"}, {"id": 348, "label": "09.04.04.11"}, {
    "id": 349,
    "label": "09.04.04.12"
}, {"id": 350, "label": "09.04.05.01"}, {"id": 351, "label": "09.04.05.02"}, {
    "id": 352,
    "label": "09.04.05.03"
}, {"id": 353, "label": "09.04.05.04"}, {"id": 354, "label": "09.04.05.05"}, {
    "id": 355,
    "label": "09.04.05.06"
}, {"id": 356, "label": "09.04.05.07"}, {"id": 357, "label": "09.04.06.01"}, {
    "id": 358,
    "label": "09.04.06.02"
}, {"id": 359, "label": "09.05.00.01"}, {"id": 360, "label": "09.05.00.02"}, {
    "id": 361,
    "label": "09.05.00.03"
}, {"id": 362, "label": "09.05.00.04"}, {"id": 363, "label": "09.05.00.05"}, {
    "id": 364,
    "label": "09.05.01.01"
}, {"id": 365, "label": "09.05.01.02"}, {"id": 366, "label": "09.05.01.03"}, {
    "id": 367,
    "label": "09.05.01.04"
}, {"id": 368, "label": "09.05.01.05"}, {"id": 369, "label": "09.05.01.06"}, {
    "id": 370,
    "label": "09.05.01.07"
}, {"id": 371, "label": "09.05.01.08"}, {"id": 372, "label": "09.05.01.09"}, {
    "id": 373,
    "label": "09.05.01.10"
}, {"id": 374, "label": "09.05.01.11"}, {"id": 375, "label": "09.05.01.12"}, {
    "id": 376,
    "label": "09.05.02.01"
}, {"id": 377, "label": "09.05.02.02"}, {"id": 378, "label": "09.05.02.03"}, {
    "id": 379,
    "label": "09.05.03.01"
}, {"id": 380, "label": "09.05.03.02"}, {"id": 381, "label": "09.05.03.03"}, {
    "id": 382,
    "label": "09.05.03.04"
}, {"id": 383, "label": "09.05.03.05"}, {"id": 384, "label": "09.05.03.06"}, {
    "id": 385,
    "label": "09.05.03.07"
}, {"id": 386, "label": "09.05.03.08"}, {"id": 387, "label": "09.05.03.09"}, {
    "id": 388,
    "label": "09.05.03.10"
}, {"id": 389, "label": "09.05.03.11"}, {"id": 390, "label": "09.05.03.12"}, {
    "id": 391,
    "label": "09.05.04.01"
}, {"id": 392, "label": "09.05.04.02"}, {"id": 393, "label": "09.05.04.03"}, {
    "id": 394,
    "label": "09.05.04.04"
}, {"id": 395, "label": "09.05.04.05"}, {"id": 396, "label": "09.05.04.06"}, {
    "id": 397,
    "label": "09.05.04.07"
}, {"id": 398, "label": "09.05.05.01"}, {"id": 399, "label": "09.05.05.02"}, {
    "id": 400,
    "label": "10.00.00.01"
}, {"id": 401, "label": "10.00.00.02"}, {"id": 402, "label": "10.00.00.03"}, {
    "id": 403,
    "label": "10.00.00.04"
}, {"id": 404, "label": "10.00.00.05"}, {"id": 405, "label": "10.01.00.01"}, {
    "id": 406,
    "label": "10.01.00.02"
}, {"id": 407, "label": "10.01.00.03"}, {"id": 408, "label": "10.01.00.04"}, {
    "id": 409,
    "label": "10.01.00.05"
}, {"id": 410, "label": "10.01.00.06"}, {"id": 411, "label": "10.01.00.07"}, {
    "id": 412,
    "label": "10.01.00.08"
}, {"id": 413, "label": "10.01.00.09"}, {"id": 414, "label": "10.01.00.10"}, {
    "id": 415,
    "label": "10.01.00.11"
}, {"id": 416, "label": "10.01.00.12"}, {"id": 417, "label": "10.02.00.01"}, {
    "id": 418,
    "label": "10.02.00.02"
}, {"id": 419, "label": "10.02.00.03"}, {"id": 420, "label": "10.02.00.04"}, {
    "id": 421,
    "label": "10.02.00.05"
}, {"id": 422, "label": "10.02.00.06"}, {"id": 423, "label": "10.02.00.07"}, {
    "id": 424,
    "label": "10.03.00.01"
}, {"id": 425, "label": "10.03.00.02"}, {"id": 426, "label": "10.03.00.03"}, {
    "id": 427,
    "label": "10.03.00.04"
}, {"id": 428, "label": "10.03.00.05"}, {"id": 429, "label": "10.03.00.06"}, {
    "id": 430,
    "label": "10.03.00.07"
}, {"id": 431, "label": "10.03.00.08"}, {"id": 432, "label": "10.04.00.01"}, {
    "id": 433,
    "label": "10.04.00.02"
}, {"id": 435, "label": "10.04.00.04"}, {"id": 436, "label": "10.05.00.01"}, {
    "id": 437,
    "label": "10.05.00.02"
}, {"id": 438, "label": "10.05.00.03"}, {"id": 439, "label": "10.05.00.04"}, {
    "id": 440,
    "label": "10.05.00.05"
}, {"id": 441, "label": "10.05.00.06"}, {"id": 442, "label": "11.00.00.01"}, {
    "id": 443,
    "label": "11.00.00.02"
}, {"id": 444, "label": "11.00.00.03"}, {"id": 445, "label": "11.00.00.04"}, {
    "id": 446,
    "label": "11.01.00.01"
}, {"id": 447, "label": "11.01.00.02"}, {"id": 448, "label": "11.02.00.01"}, {
    "id": 449,
    "label": "11.02.00.02"
}, {"id": 450, "label": "11.03.00.01"}, {"id": 451, "label": "11.04.00.01"}, {
    "id": 452,
    "label": "11.05.00.01"
}, {"id": 453, "label": "11.05.00.02"}, {"id": 454, "label": "11.05.00.03"}, {
    "id": 455,
    "label": "11.05.00.04"
}, {"id": 456, "label": "11.05.00.05"}, {"id": 457, "label": "11.05.00.06"}, {
    "id": 458,
    "label": "11.05.00.07"
}, {"id": 459, "label": "11.05.00.08"}, {"id": 460, "label": "11.06.00.01"}, {
    "id": 461,
    "label": "11.07.00.01"
}, {"id": 462, "label": "12.00.00.01"}, {"id": 463, "label": "12.00.00.02"}, {
    "id": 464,
    "label": "12.00.00.03"
}, {"id": 465, "label": "12.00.00.04"}, {"id": 466, "label": "12.00.00.05"}, {
    "id": 467,
    "label": "12.00.00.06"
}, {"id": 468, "label": "12.00.00.07"}, {"id": 469, "label": "12.00.00.08"}, {
    "id": 470,
    "label": "12.00.00.09"
}, {"id": 471, "label": "12.00.00.10"}, {"id": 472, "label": "12.00.00.11"}, {
    "id": 473,
    "label": "12.00.00.12"
}, {"id": 474, "label": "12.00.00.13"}, {"id": 475, "label": "13.00.00.01"}, {
    "id": 476,
    "label": "13.00.00.02"
}, {"id": 477, "label": "13.00.00.03"}, {"id": 478, "label": "13.00.00.04"}, {
    "id": 479,
    "label": "13.00.00.05"
}, {"id": 480, "label": "13.00.00.06"}, {"id": 481, "label": "13.00.00.07"}, {
    "id": 482,
    "label": "13.00.00.08"
}, {"id": 483, "label": "13.00.00.09"}, {"id": 484, "label": "14.00.00.01"}, {
    "id": 485,
    "label": "14.00.00.02"
}, {"id": 486, "label": "14.00.00.03"}, {"id": 487, "label": "14.00.00.04"}, {
    "id": 488,
    "label": "14.00.00.05"
}, {"id": 489, "label": "14.00.00.06"}, {"id": 490, "label": "14.00.00.07"}, {
    "id": 491,
    "label": "14.00.00.08"
}, {"id": 492, "label": "14.00.00.09"}, {"id": 493, "label": "14.00.00.10"}, {
    "id": 494,
    "label": "14.00.00.11"
}, {"id": 495, "label": "14.00.00.12"}, {"id": 496, "label": "14.00.00.13"}, {
    "id": 497,
    "label": "14.00.00.14"
}, {"id": 498, "label": "14.00.00.15"}, {"id": 499, "label": "14.01.00.01"}, {
    "id": 500,
    "label": "14.01.00.02"
}, {"id": 501, "label": "14.01.00.03"}, {"id": 502, "label": "14.01.00.04"}, {
    "id": 503,
    "label": "14.01.00.05"
}, {"id": 504, "label": "14.01.00.06"}, {"id": 505, "label": "14.01.00.07"}, {
    "id": 506,
    "label": "14.01.00.08"
}, {"id": 507, "label": "14.02.00.01"}, {"id": 508, "label": "14.02.00.02"}, {
    "id": 509,
    "label": "14.02.00.03"
}, {"id": 510, "label": "14.02.00.04"}, {"id": 511, "label": "14.03.00.01"}, {
    "id": 512,
    "label": "14.03.00.02"
}, {"id": 513, "label": "14.04.00.01"}, {"id": 514, "label": "15.00.00.01"}, {
    "id": 515,
    "label": "15.00.00.02"
}, {"id": 516, "label": "15.00.00.03"}, {"id": 517, "label": "15.00.00.04"}, {
    "id": 518,
    "label": "15.00.00.05"
}, {"id": 519, "label": "15.00.00.06"}, {"id": 520, "label": "15.00.00.07"}, {
    "id": 521,
    "label": "15.00.00.08"
}, {"id": 522, "label": "15.00.00.09"}, {"id": 523, "label": "15.00.00.10"}, {
    "id": 524,
    "label": "15.00.00.11"
}, {"id": 525, "label": "15.00.00.12"}, {"id": 526, "label": "15.00.00.13"}, {
    "id": 527,
    "label": "15.00.00.14"
}, {"id": 528, "label": "15.00.00.15"}, {"id": 529, "label": "15.00.00.16"}, {
    "id": 530,
    "label": "15.00.00.17"
}, {"id": 531, "label": "15.00.00.18"}, {"id": 532, "label": "15.00.00.19"}, {
    "id": 533,
    "label": "15.00.00.20"
}, {"id": 534, "label": "16.00.00.01"}, {"id": 535, "label": "16.00.00.02"}, {
    "id": 536,
    "label": "16.00.00.03"
}, {"id": 537, "label": "16.00.00.04"}, {"id": 538, "label": "16.00.00.05"}, {
    "id": 539,
    "label": "16.01.00.01"
}, {"id": 540, "label": "16.01.00.02"}, {"id": 541, "label": "16.01.00.03"}, {
    "id": 542,
    "label": "16.01.00.04"
}, {"id": 543, "label": "16.01.00.05"}, {"id": 544, "label": "16.01.00.06"}, {
    "id": 545,
    "label": "16.02.00.01"
}, {"id": 546, "label": "16.02.00.02"}, {"id": 547, "label": "16.02.00.03"}, {
    "id": 548,
    "label": "16.02.00.04"
}, {"id": 549, "label": "16.02.00.05"}, {"id": 550, "label": "16.02.00.06"}, {
    "id": 551,
    "label": "16.02.00.07"
}, {"id": 552, "label": "17.00.00.01"}, {"id": 553, "label": "17.00.00.02"}, {
    "id": 554,
    "label": "17.00.00.03"
}, {"id": 555, "label": "17.00.00.04"}, {"id": 556, "label": "17.00.00.05"}, {
    "id": 557,
    "label": "17.00.00.06"
}, {"id": 558, "label": "17.00.00.07"}, {"id": 559, "label": "17.00.00.08"}, {
    "id": 560,
    "label": "17.00.00.09"
}, {"id": 561, "label": "17.01.00.01"}, {"id": 562, "label": "17.01.00.02"}, {
    "id": 563,
    "label": "17.01.00.03"
}, {"id": 564, "label": "17.01.00.04"}, {"id": 565, "label": "17.01.00.05"}, {
    "id": 566,
    "label": "17.01.00.06"
}, {"id": 567, "label": "17.01.00.07"}, {"id": 568, "label": "17.01.00.08"}, {
    "id": 569,
    "label": "17.01.00.09"
}, {"id": 570, "label": "17.02.00.01"}, {"id": 571, "label": "17.02.00.02"}, {
    "id": 572,
    "label": "17.02.00.03"
}, {"id": 573, "label": "17.02.00.04"}, {"id": 574, "label": "17.02.00.05"}, {
    "id": 575,
    "label": "17.02.00.06"
}, {"id": 576, "label": "17.03.00.01"}, {"id": 577, "label": "17.03.00.02"}, {
    "id": 578,
    "label": "17.03.00.03"
}, {"id": 579, "label": "17.03.00.04"}, {"id": 580, "label": "17.03.00.05"}, {
    "id": 581,
    "label": "17.03.00.06"
}, {"id": 582, "label": "17.04.00.01"}, {"id": 583, "label": "18.00.00.01"}, {
    "id": 584,
    "label": "18.00.00.02"
}, {"id": 585, "label": "18.00.00.03"}, {"id": 586, "label": "18.00.00.04"}, {
    "id": 587,
    "label": "18.00.00.05"
}, {"id": 588, "label": "18.00.00.06"}, {"id": 589, "label": "18.00.00.07"}, {
    "id": 590,
    "label": "18.00.00.08"
}, {"id": 591, "label": "18.00.00.09"}, {"id": 592, "label": "18.00.00.10"}, {
    "id": 593,
    "label": "18.00.00.11"
}, {"id": 594, "label": "18.00.00.12"}, {"id": 595, "label": "18.00.00.13"}, {
    "id": 596,
    "label": "18.00.00.14"
}, {"id": 597, "label": "18.00.00.15"}, {"id": 598, "label": "18.00.00.16"}, {
    "id": 599,
    "label": "18.00.00.17"
}, {"id": 600, "label": "18.00.00.18"}, {"id": 601, "label": "18.00.00.19"}, {
    "id": 602,
    "label": "18.00.00.20"
}, {"id": 603, "label": "18.00.00.21"}, {"id": 604, "label": "18.00.00.22"}, {
    "id": 605,
    "label": "18.00.00.23"
}, {"id": 606, "label": "18.00.00.24"}, {"id": 607, "label": "18.00.00.25"}, {
    "id": 608,
    "label": "18.00.00.26"
}, {"id": 609, "label": "18.00.00.27"}, {"id": 610, "label": "18.00.00.28"}, {
    "id": 611,
    "label": "19.00.00.01"
}, {"id": 612, "label": "19.00.00.02"}, {"id": 613, "label": "19.00.00.03"}, {
    "id": 614,
    "label": "19.00.00.04"
}, {"id": 615, "label": "19.00.00.05"}, {"id": 616, "label": "19.00.00.06"}, {
    "id": 617,
    "label": "19.00.00.07"
}, {"id": 618, "label": "19.00.00.08"}, {"id": 619, "label": "19.00.00.09"}, {
    "id": 620,
    "label": "19.00.00.10"
}, {"id": 621, "label": "19.00.00.11"}, {"id": 622, "label": "19.00.00.12"}, {
    "id": 623,
    "label": "19.00.00.13"
}, {"id": 624, "label": "19.00.00.14"}, {"id": 625, "label": "19.00.00.15"}, {
    "id": 626,
    "label": "19.00.00.16"
}, {"id": 627, "label": "19.00.00.17"}, {"id": 628, "label": "19.00.00.18"}, {
    "id": 629,
    "label": "19.01.00.01"
}, {"id": 630, "label": "19.01.00.02"}, {"id": 631, "label": "19.01.00.03"}, {
    "id": 632,
    "label": "19.01.00.04"
}, {"id": 633, "label": "19.01.00.05"}, {"id": 634, "label": "19.01.00.06"}, {
    "id": 635,
    "label": "19.01.00.07"
}, {"id": 636, "label": "20.00.00.01"}, {"id": 637, "label": "20.00.00.02"}, {
    "id": 638,
    "label": "20.00.00.03"
}, {"id": 639, "label": "20.00.00.04"}, {"id": 640, "label": "20.00.00.05"}, {
    "id": 641,
    "label": "20.00.00.06"
}, {"id": 642, "label": "20.00.00.07"}, {"id": 643, "label": "20.00.00.08"}, {
    "id": 644,
    "label": "20.00.00.09"
}, {"id": 645, "label": "21.00.00.01"}, {"id": 646, "label": "21.00.00.02"}, {
    "id": 647,
    "label": "21.00.00.03"
}, {"id": 648, "label": "21.00.00.04"}, {"id": 649, "label": "21.00.00.05"}, {
    "id": 650,
    "label": "21.00.00.06"
}, {"id": 651, "label": "21.00.00.07"}, {"id": 652, "label": "21.00.00.08"}, {
    "id": 653,
    "label": "21.00.00.09"
}, {"id": 654, "label": "21.00.00.10"}, {"id": 655, "label": "21.00.00.11"}, {
    "id": 656,
    "label": "21.00.00.12"
}, {"id": 657, "label": "21.00.00.13"}, {"id": 658, "label": "21.00.00.14"}, {
    "id": 659,
    "label": "21.00.00.15"
}, {"id": 660, "label": "21.00.00.16"}, {"id": 661, "label": "21.00.00.17"}, {
    "id": 662,
    "label": "21.00.00.18"
}, {"id": 663, "label": "21.00.00.19"}, {"id": 664, "label": "21.00.00.20"}, {
    "id": 665,
    "label": "21.00.00.21"
}, {"id": 666, "label": "21.00.00.22"}, {"id": 667, "label": "21.00.00.23"}, {
    "id": 668,
    "label": "21.00.00.24"
}, {"id": 669, "label": "21.00.00.25"}, {"id": 670, "label": "21.00.00.26"}, {
    "id": 671,
    "label": "21.00.00.27"
}, {"id": 672, "label": "21.00.00.28"}, {"id": 673, "label": "21.00.00.29"}, {
    "id": 674,
    "label": "21.00.00.30"
}, {"id": 675, "label": "21.00.00.31"}, {"id": 676, "label": "21.00.00.32"}, {
    "id": 677,
    "label": "21.00.00.33"
}, {"id": 678, "label": "21.00.00.34"}, {"id": 679, "label": "21.00.00.35"}, {
    "id": 680,
    "label": "21.00.00.36"
}, {"id": 681, "label": "21.00.00.37"}, {"id": 682, "label": "21.00.00.38"}, {
    "id": 683,
    "label": "21.00.00.39"
}, {"id": 684, "label": "21.00.00.40"}, {"id": 685, "label": "30.00.00.01"}, {
    "id": 686,
    "label": "30.00.00.02"
}, {"id": 687, "label": "30.00.00.03"}, {"id": 688, "label": "30.00.00.04"}, {
    "id": 689,
    "label": "30.00.00.05"
}, {"id": 690, "label": "30.00.00.06"}, {"id": 691, "label": "30.00.00.07"}, {
    "id": 692,
    "label": "30.00.00.08"
}, {"id": 693, "label": "30.00.00.09"}, {"id": 694, "label": "30.00.00.10"}, {
    "id": 695,
    "label": "30.00.00.11"
}, {"id": 696, "label": "30.00.00.12"}, {"id": 697, "label": "30.00.00.13"}, {
    "id": 698,
    "label": "30.00.00.14"
}, {"id": 699, "label": "30.00.00.15"}, {"id": 700, "label": "30.00.00.16"}, {
    "id": 701,
    "label": "30.00.00.17"
}, {"id": 702, "label": "30.00.00.18"}, {"id": 703, "label": "30.00.00.19"}, {
    "id": 704,
    "label": "30.00.00.20"
}, {"id": 705, "label": "30.00.00.21"}, {"id": 706, "label": "30.00.00.22"}, {
    "id": 707,
    "label": "30.00.00.23"
}, {"id": 708, "label": "30.00.00.24"}, {"id": 709, "label": "30.00.00.25"}, {
    "id": 710,
    "label": "30.00.00.26"
}, {"id": 711, "label": "30.00.00.27"}, {"id": 712, "label": "30.00.00.28"}, {
    "id": 713,
    "label": "30.00.00.29"
}, {"id": 714, "label": "30.00.00.30"}, {"id": 715, "label": "30.00.00.31"}, {
    "id": 716,
    "label": "30.01.00.01"
}, {"id": 717, "label": "30.01.00.02"}, {"id": 718, "label": "30.01.00.03"}, {
    "id": 719,
    "label": "30.01.00.04"
}, {"id": 720, "label": "30.01.00.05"}, {"id": 721, "label": "30.01.00.06"}, {
    "id": 722,
    "label": "30.01.00.07"
}, {"id": 723, "label": "30.01.00.08"}, {"id": 724, "label": "30.01.00.09"}, {
    "id": 725,
    "label": "30.01.00.10"
}, {"id": 726, "label": "30.01.00.11"}, {"id": 727, "label": "30.01.00.12"}, {
    "id": 728,
    "label": "30.01.00.13"
}, {"id": 729, "label": "30.01.00.14"}, {"id": 730, "label": "30.01.00.15"}, {
    "id": 731,
    "label": "30.01.00.16"
}, {"id": 732, "label": "30.02.00.01"}, {"id": 733, "label": "30.02.00.02"}, {
    "id": 734,
    "label": "30.02.00.03"
}, {"id": 735, "label": "30.02.00.04"}, {"id": 736, "label": "30.02.00.05"}, {
    "id": 737,
    "label": "30.02.00.06"
}, {"id": 738, "label": "30.02.00.07"}, {"id": 739, "label": "30.02.00.08"}, {
    "id": 740,
    "label": "30.02.00.09"
}, {"id": 741, "label": "30.02.00.10"}, {"id": 742, "label": "30.02.00.11"}, {
    "id": 743,
    "label": "30.02.00.12"
}, {"id": 744, "label": "30.02.00.13"}, {"id": 745, "label": "30.02.00.14"}, {
    "id": 746,
    "label": "30.02.00.15"
}, {"id": 747, "label": "30.02.00.16"}, {"id": 748, "label": "30.02.00.17"}, {
    "id": 749,
    "label": "30.02.00.18"
}, {"id": 750, "label": "30.02.00.19"}, {"id": 751, "label": "30.02.00.20"}, {
    "id": 752,
    "label": "30.02.00.21"
}, {"id": 753, "label": "30.02.00.22"}, {"id": 754, "label": "30.02.00.23"}, {
    "id": 755,
    "label": "30.02.00.24"
}, {"id": 756, "label": "30.02.00.25"}, {"id": 757, "label": "30.02.00.26"}, {
    "id": 758,
    "label": "30.02.00.27"
}, {"id": 759, "label": "30.02.00.28"}, {"id": 760, "label": "30.02.00.29"}, {
    "id": 761,
    "label": "30.02.00.30"
}, {"id": 762, "label": "30.02.00.31"}, {"id": 763, "label": "30.02.00.32"}, {
    "id": 764,
    "label": "30.02.00.33"
}, {"id": 765, "label": "30.02.00.34"}, {"id": 766, "label": "30.02.00.35"}, {
    "id": 767,
    "label": "30.02.00.36"
}, {"id": 768, "label": "30.02.00.37"}, {"id": 769, "label": "30.02.00.38"}, {
    "id": 770,
    "label": "30.02.00.39"
}, {"id": 771, "label": "30.02.00.40"}, {"id": 772, "label": "30.02.00.41"}, {
    "id": 773,
    "label": "30.02.00.42"
}, {"id": 774, "label": "30.02.00.43"}, {"id": 775, "label": "30.02.00.44"}, {
    "id": 776,
    "label": "30.02.00.45"
}, {"id": 777, "label": "30.02.00.46"}, {"id": 778, "label": "30.02.00.47"}, {
    "id": 779,
    "label": "30.02.00.48"
}, {"id": 780, "label": "30.02.00.49"}, {"id": 781, "label": "30.02.00.50"}, {
    "id": 782,
    "label": "30.02.00.51"
}, {"id": 783, "label": "30.02.00.52"}, {"id": 784, "label": "30.02.00.53"}, {
    "id": 785,
    "label": "30.02.00.54"
}, {"id": 786, "label": "30.02.00.55"}, {"id": 787, "label": "30.02.00.56"}, {
    "id": 788,
    "label": "30.03.00.01"
}, {"id": 789, "label": "30.03.00.02"}, {"id": 790, "label": "30.03.00.03"}, {
    "id": 791,
    "label": "30.03.00.04"
}, {"id": 792, "label": "30.03.00.05"}, {"id": 793, "label": "30.03.00.06"}, {
    "id": 794,
    "label": "30.03.00.07"
}, {"id": 795, "label": "30.03.00.08"}, {"id": 796, "label": "30.03.00.09"}, {
    "id": 797,
    "label": "30.03.00.10"
}, {"id": 798, "label": "30.03.00.11"}, {"id": 799, "label": "30.03.00.12"}, {
    "id": 800,
    "label": "30.03.00.13"
}, {"id": 801, "label": "30.03.00.14"}, {"id": 802, "label": "30.03.00.15"}, {
    "id": 870,
    "label": "33.00.00.09"
}, {"id": 803, "label": "30.03.00.16"}, {"id": 804, "label": "30.03.00.17"}, {
    "id": 805,
    "label": "30.03.00.18"
}, {"id": 806, "label": "30.03.00.19"}, {"id": 807, "label": "30.03.00.20"}, {
    "id": 808,
    "label": "30.03.00.21"
}, {"id": 809, "label": "30.03.00.22"}, {"id": 810, "label": "30.03.00.23"}, {
    "id": 811,
    "label": "30.03.00.24"
}, {"id": 812, "label": "30.03.00.25"}, {"id": 813, "label": "30.03.00.26"}, {
    "id": 814,
    "label": "30.03.00.27"
}, {"id": 815, "label": "30.03.00.28"}, {"id": 816, "label": "30.03.00.29"}, {
    "id": 817,
    "label": "30.03.00.30"
}, {"id": 818, "label": "30.03.00.31"}, {"id": 819, "label": "30.03.00.32"}, {
    "id": 820,
    "label": "30.03.00.33"
}, {"id": 821, "label": "30.03.00.34"}, {"id": 822, "label": "30.04.00.01"}, {
    "id": 823,
    "label": "30.04.00.02"
}, {"id": 824, "label": "30.04.00.03"}, {"id": 825, "label": "30.04.00.04"}, {
    "id": 826,
    "label": "31.00.00.01"
}, {"id": 827, "label": "31.00.00.02"}, {"id": 828, "label": "31.00.00.03"}, {
    "id": 829,
    "label": "31.00.00.04"
}, {"id": 830, "label": "31.00.00.05"}, {"id": 831, "label": "31.00.00.06"}, {
    "id": 832,
    "label": "31.00.00.07"
}, {"id": 833, "label": "31.00.00.08"}, {"id": 834, "label": "31.00.00.09"}, {
    "id": 835,
    "label": "31.00.00.10"
}, {"id": 836, "label": "31.00.00.11"}, {"id": 837, "label": "31.00.00.12"}, {
    "id": 838,
    "label": "31.00.00.13"
}, {"id": 839, "label": "31.00.00.14"}, {"id": 840, "label": "31.00.00.15"}, {
    "id": 841,
    "label": "31.00.00.16"
}, {"id": 842, "label": "31.00.00.17"}, {"id": 843, "label": "31.00.00.18"}, {
    "id": 844,
    "label": "31.00.00.19"
}, {"id": 845, "label": "31.00.00.20"}, {"id": 846, "label": "31.00.00.21"}, {
    "id": 847,
    "label": "31.00.00.22"
}, {"id": 848, "label": "31.00.00.23"}, {"id": 849, "label": "31.00.00.24"}, {
    "id": 850,
    "label": "31.00.00.25"
}, {"id": 851, "label": "31.00.00.26"}, {"id": 852, "label": "31.00.00.27"}, {
    "id": 853,
    "label": "31.00.00.28"
}, {"id": 854, "label": "31.00.00.29"}, {"id": 855, "label": "31.00.00.30"}, {
    "id": 856,
    "label": "32.00.00.01"
}, {"id": 857, "label": "32.00.00.02"}, {"id": 858, "label": "32.00.00.03"}, {
    "id": 859,
    "label": "32.00.00.04"
}, {"id": 860, "label": "32.00.00.05"}, {"id": 861, "label": "32.00.00.06"}, {
    "id": 862,
    "label": "33.00.00.01"
}, {"id": 863, "label": "33.00.00.02"}, {"id": 864, "label": "33.00.00.03"}, {
    "id": 865,
    "label": "33.00.00.04"
}, {"id": 866, "label": "33.00.00.05"}, {"id": 867, "label": "33.00.00.06"}, {
    "id": 868,
    "label": "33.00.00.07"
}, {"id": 869, "label": "33.00.00.08"}, {"id": 871, "label": "33.00.00.10"}, {
    "id": 872,
    "label": "33.00.00.11"
}, {"id": 873, "label": "33.00.00.12"}, {"id": 874, "label": "33.00.00.13"}, {
    "id": 875,
    "label": "33.00.00.14"
}, {"id": 876, "label": "33.00.00.15"}, {"id": 877, "label": "33.00.00.16"}, {
    "id": 878,
    "label": "33.00.00.17"
}, {"id": 879, "label": "33.00.00.18"}, {"id": 880, "label": "33.00.00.19"}, {
    "id": 881,
    "label": "33.00.00.20"
}, {"id": 882, "label": "33.00.00.21"}, {"id": 883, "label": "33.00.00.22"}, {
    "id": 884,
    "label": "33.00.00.23"
}, {"id": 885, "label": "33.00.00.24"}, {"id": 886, "label": "33.00.00.25"}, {
    "id": 887,
    "label": "33.00.00.26"
}, {"id": 888, "label": "33.00.00.27"}, {"id": 889, "label": "33.00.00.28"}, {
    "id": 890,
    "label": "33.00.00.29"
}, {"id": 891, "label": "33.00.00.30"}, {"id": 892, "label": "33.00.00.31"}, {
    "id": 893,
    "label": "33.00.00.32"
}, {"id": 894, "label": "33.00.00.33"}, {"id": 895, "label": "33.00.00.34"}, {
    "id": 896,
    "label": "33.00.00.35"
}, {"id": 897, "label": "33.00.01.01"}, {"id": 898, "label": "33.00.01.02"}, {
    "id": 899,
    "label": "33.00.01.03"
}, {"id": 900, "label": "33.00.01.04"}, {"id": 901, "label": "33.00.01.05"}, {
    "id": 902,
    "label": "33.00.01.06"
}, {"id": 903, "label": "33.00.01.07"}, {"id": 904, "label": "33.00.01.08"}, {
    "id": 905,
    "label": "33.00.01.09"
}, {"id": 906, "label": "33.00.01.10"}, {"id": 907, "label": "33.00.01.11"}, {
    "id": 908,
    "label": "33.00.01.12"
}, {"id": 909, "label": "33.00.01.13"}, {"id": 910, "label": "33.00.01.14"}, {
    "id": 911,
    "label": "33.00.01.15"
}, {"id": 912, "label": "33.00.01.16"}, {"id": 913, "label": "33.00.01.17"}, {
    "id": 914,
    "label": "33.00.01.18"
}, {"id": 915, "label": "33.00.01.19"}, {"id": 916, "label": "33.00.01.20"}, {
    "id": 917,
    "label": "33.00.01.21"
}, {"id": 918, "label": "33.00.01.22"}, {"id": 919, "label": "33.00.01.23"}, {
    "id": 920,
    "label": "33.00.01.24"
}, {"id": 921, "label": "33.00.01.25"}, {"id": 922, "label": "33.00.01.26"}, {
    "id": 923,
    "label": "33.01.00.01"
}, {"id": 924, "label": "33.01.00.02"}, {"id": 925, "label": "33.01.00.03"}, {
    "id": 926,
    "label": "33.01.00.04"
}, {"id": 927, "label": "33.01.00.05"}, {"id": 928, "label": "33.01.00.06"}, {
    "id": 929,
    "label": "33.01.00.07"
}, {"id": 930, "label": "33.01.00.08"}, {"id": 931, "label": "33.01.00.09"}, {
    "id": 932,
    "label": "33.01.00.10"
}, {"id": 933, "label": "33.01.00.11"}, {"id": 934, "label": "33.02.00.01"}, {
    "id": 935,
    "label": "33.02.00.02"
}, {"id": 936, "label": "33.02.00.03"}, {"id": 937, "label": "33.02.00.04"}, {
    "id": 938,
    "label": "33.02.00.05"
}, {"id": 939, "label": "33.03.00.01"}, {"id": 940, "label": "33.03.00.02"}, {
    "id": 941,
    "label": "33.03.00.03"
}, {"id": 942, "label": "33.03.00.04"}, {"id": 943, "label": "33.03.01.01"}, {
    "id": 944,
    "label": "33.03.01.02"
}, {"id": 945, "label": "33.03.01.03"}, {"id": 946, "label": "33.03.01.04"}, {
    "id": 947,
    "label": "33.03.01.05"
}, {"id": 948, "label": "33.03.01.06"}, {"id": 949, "label": "33.03.01.07"}, {
    "id": 950,
    "label": "33.03.01.08"
}, {"id": 951, "label": "33.03.01.09"}, {"id": 952, "label": "33.03.01.10"}, {
    "id": 953,
    "label": "33.03.01.11"
}, {"id": 954, "label": "33.03.01.12"}, {"id": 955, "label": "33.03.01.13"}, {
    "id": 956,
    "label": "33.03.01.14"
}, {"id": 957, "label": "33.03.01.15"}, {"id": 958, "label": "33.03.01.16"}, {
    "id": 959,
    "label": "33.03.01.17"
}, {"id": 960, "label": "33.03.01.18"}, {"id": 961, "label": "33.03.01.19"}, {
    "id": 962,
    "label": "33.03.01.20"
}, {"id": 963, "label": "33.03.01.21"}, {"id": 964, "label": "33.03.01.22"}, {
    "id": 965,
    "label": "33.03.01.23"
}, {"id": 966, "label": "33.03.01.24"}, {"id": 967, "label": "33.03.01.25"}, {
    "id": 968,
    "label": "33.03.01.26"
}, {"id": 969, "label": "33.03.01.27"}, {"id": 970, "label": "33.03.01.28"}, {
    "id": 971,
    "label": "33.03.01.29"
}, {"id": 972, "label": "33.03.01.30"}, {"id": 973, "label": "33.03.01.31"}, {
    "id": 974,
    "label": "33.03.01.32"
}, {"id": 975, "label": "33.03.01.33"}, {"id": 976, "label": "33.03.01.34"}, {
    "id": 977,
    "label": "33.03.01.35"
}, {"id": 978, "label": "33.03.01.36"}, {"id": 979, "label": "33.03.01.37"}, {
    "id": 980,
    "label": "33.03.01.38"
}, {"id": 981, "label": "33.03.01.39"}, {"id": 982, "label": "33.03.01.40"}, {
    "id": 983,
    "label": "33.03.01.41"
}, {"id": 984, "label": "33.03.01.42"}, {"id": 985, "label": "33.03.01.43"}, {
    "id": 986,
    "label": "33.03.01.44"
}, {"id": 987, "label": "33.03.01.45"}, {"id": 988, "label": "33.03.01.46"}, {
    "id": 989,
    "label": "33.03.01.47"
}, {"id": 990, "label": "33.03.01.48"}, {"id": 991, "label": "33.03.01.49"}, {
    "id": 992,
    "label": "33.03.01.50"
}, {"id": 993, "label": "33.03.01.51"}, {"id": 994, "label": "33.04.00.01"}, {
    "id": 995,
    "label": "33.04.00.02"
}, {"id": 996, "label": "33.04.00.03"}, {"id": 997, "label": "33.04.00.04"}, {
    "id": 998,
    "label": "33.04.00.05"
}, {"id": 999, "label": "33.04.00.06"}, {"id": 1000, "label": "33.04.00.07"}, {
    "id": 1001,
    "label": "33.04.00.08"
}, {"id": 1002, "label": "33.04.00.09"}, {"id": 1003, "label": "33.04.01.01"}, {
    "id": 1004,
    "label": "33.04.01.02"
}, {"id": 1005, "label": "33.04.01.03"}, {"id": 1006, "label": "33.04.01.04"}, {
    "id": 1007,
    "label": "33.04.01.05"
}, {"id": 1008, "label": "33.04.01.06"}, {"id": 1009, "label": "33.04.01.07"}, {
    "id": 1010,
    "label": "33.04.01.08"
}, {"id": 1011, "label": "33.04.01.09"}, {"id": 1012, "label": "33.04.01.10"}, {
    "id": 1013,
    "label": "33.04.01.11"
}, {"id": 1014, "label": "33.04.01.12"}, {"id": 1015, "label": "33.04.01.13"}, {
    "id": 1016,
    "label": "33.04.01.14"
}, {"id": 1017, "label": "33.04.01.15"}, {"id": 1018, "label": "33.04.01.16"}, {
    "id": 1019,
    "label": "33.04.01.17"
}, {"id": 1020, "label": "33.04.01.18"}, {"id": 1021, "label": "33.04.01.19"}, {
    "id": 1022,
    "label": "33.04.01.20"
}, {"id": 1023, "label": "33.04.01.21"}, {"id": 1024, "label": "33.04.01.22"}, {
    "id": 1025,
    "label": "33.04.01.23"
}, {"id": 1026, "label": "33.04.01.24"}, {"id": 1027, "label": "33.04.01.25"}, {
    "id": 1028,
    "label": "33.04.01.26"
}, {"id": 1029, "label": "33.04.01.27"}, {"id": 1030, "label": "33.04.01.28"}, {
    "id": 1031,
    "label": "33.04.01.29"
}, {"id": 1032, "label": "33.04.01.30"}, {"id": 1033, "label": "33.04.01.31"}, {
    "id": 1034,
    "label": "33.04.01.32"
}, {"id": 1035, "label": "33.04.01.33"}, {"id": 1036, "label": "33.04.02.01"}, {
    "id": 1037,
    "label": "33.04.02.02"
}, {"id": 1038, "label": "33.04.02.03"}, {"id": 1039, "label": "33.04.02.04"}, {
    "id": 1040,
    "label": "33.04.02.05"
}, {"id": 1041, "label": "33.04.02.06"}, {"id": 1042, "label": "33.04.02.07"}, {
    "id": 1043,
    "label": "33.04.02.08"
}, {"id": 1044, "label": "33.04.02.09"}, {"id": 1045, "label": "33.04.02.10"}, {
    "id": 1046,
    "label": "33.04.02.11"
}, {"id": 1047, "label": "33.04.02.12"}, {"id": 1048, "label": "33.04.02.13"}, {
    "id": 1049,
    "label": "33.04.02.14"
}, {"id": 1050, "label": "33.05.00.01"}, {"id": 1051, "label": "33.05.00.02"}, {
    "id": 1052,
    "label": "33.05.00.03"
}, {"id": 1053, "label": "33.05.00.04"}, {"id": 1054, "label": "33.05.00.05"}, {
    "id": 1055,
    "label": "33.05.00.06"
}, {"id": 1056, "label": "33.05.00.07"}, {"id": 1057, "label": "33.05.00.08"}, {
    "id": 1058,
    "label": "33.05.00.09"
}, {"id": 1059, "label": "33.05.00.10"}, {"id": 1060, "label": "33.05.00.11"}, {
    "id": 1061,
    "label": "33.05.01.01"
}, {"id": 1062, "label": "33.05.01.02"}, {"id": 1063, "label": "33.05.01.03"}, {
    "id": 1064,
    "label": "33.05.01.04"
}, {"id": 1065, "label": "33.05.01.05"}, {"id": 1066, "label": "33.05.01.06"}, {
    "id": 1067,
    "label": "33.05.01.07"
}, {"id": 1068, "label": "33.05.01.08"}, {"id": 1069, "label": "33.05.01.09"}, {
    "id": 1070,
    "label": "33.05.01.10"
}, {"id": 1071, "label": "33.05.01.11"}, {"id": 1072, "label": "33.05.01.12"}, {
    "id": 1073,
    "label": "33.05.01.13"
}, {"id": 1074, "label": "33.05.01.14"}, {"id": 1075, "label": "33.05.01.15"}, {
    "id": 1076,
    "label": "33.05.01.16"
}, {"id": 1077, "label": "33.05.01.17"}, {"id": 1078, "label": "33.05.01.18"}, {
    "id": 1079,
    "label": "33.05.01.19"
}, {"id": 1080, "label": "33.05.01.20"}, {"id": 1081, "label": "33.05.01.21"}, {
    "id": 1082,
    "label": "33.05.01.22"
}, {"id": 1083, "label": "33.05.01.23"}, {"id": 1084, "label": "33.05.01.24"}, {
    "id": 1085,
    "label": "33.05.01.25"
}, {"id": 1086, "label": "33.05.01.26"}, {"id": 1087, "label": "33.05.01.27"}, {
    "id": 1088,
    "label": "33.05.01.28"
}, {"id": 1089, "label": "33.05.01.29"}, {"id": 1090, "label": "33.05.01.30"}, {
    "id": 1091,
    "label": "33.05.01.31"
}, {"id": 1092, "label": "33.05.01.32"}, {"id": 1093, "label": "33.05.01.33"}, {
    "id": 1094,
    "label": "33.05.01.34"
}, {"id": 1095, "label": "33.05.01.35"}, {"id": 1096, "label": "33.05.01.36"}, {
    "id": 1097,
    "label": "33.05.01.37"
}, {"id": 1098, "label": "33.05.01.38"}, {"id": 1099, "label": "33.05.02.01"}, {
    "id": 1100,
    "label": "33.05.02.02"
}, {"id": 1101, "label": "33.05.02.03"}, {"id": 1102, "label": "33.05.02.04"}, {
    "id": 1103,
    "label": "33.05.02.05"
}, {"id": 1104, "label": "33.05.02.06"}, {"id": 1105, "label": "33.05.02.07"}, {
    "id": 1106,
    "label": "33.05.02.08"
}, {"id": 1107, "label": "33.06.00.01"}, {"id": 1108, "label": "33.06.00.02"}, {
    "id": 1109,
    "label": "33.06.00.03"
}, {"id": 1110, "label": "33.06.00.04"}, {"id": 1111, "label": "33.06.00.05"}, {
    "id": 1112,
    "label": "33.06.00.06"
}, {"id": 1113, "label": "33.06.00.07"}, {"id": 1114, "label": "33.06.00.08"}, {
    "id": 1115,
    "label": "33.06.00.09"
}, {"id": 1116, "label": "33.06.00.10"}, {"id": 1117, "label": "33.06.01.01"}, {
    "id": 1118,
    "label": "33.06.01.02"
}, {"id": 1119, "label": "33.06.01.03"}, {"id": 1120, "label": "33.06.01.04"}, {
    "id": 1121,
    "label": "33.06.01.05"
}, {"id": 1122, "label": "33.06.01.06"}, {"id": 1123, "label": "33.06.01.07"}, {
    "id": 1124,
    "label": "33.06.01.08"
}, {"id": 1125, "label": "33.06.01.09"}, {"id": 1126, "label": "33.06.01.10"}, {
    "id": 1127,
    "label": "33.06.01.11"
}, {"id": 1128, "label": "33.06.01.12"}, {"id": 1129, "label": "33.06.01.13"}, {
    "id": 1130,
    "label": "33.06.01.14"
}, {"id": 1131, "label": "33.06.01.15"}, {"id": 1132, "label": "33.06.01.16"}, {
    "id": 1133,
    "label": "33.06.01.17"
}, {"id": 1134, "label": "33.06.01.18"}, {"id": 1135, "label": "33.06.01.19"}, {
    "id": 1136,
    "label": "33.06.01.20"
}, {"id": 1137, "label": "33.06.01.21"}, {"id": 1138, "label": "33.06.01.22"}, {
    "id": 1139,
    "label": "33.06.01.23"
}, {"id": 1140, "label": "33.06.01.24"}, {"id": 1141, "label": "33.06.01.25"}, {
    "id": 1142,
    "label": "33.06.01.26"
}, {"id": 1143, "label": "33.06.01.27"}, {"id": 1144, "label": "33.06.01.28"}, {
    "id": 1145,
    "label": "33.06.01.29"
}, {"id": 1146, "label": "33.06.01.30"}, {"id": 1147, "label": "33.06.01.31"}, {
    "id": 1148,
    "label": "33.06.01.32"
}, {"id": 1149, "label": "33.06.01.33"}, {"id": 1150, "label": "33.06.01.34"}, {
    "id": 1151,
    "label": "33.06.01.35"
}, {"id": 1152, "label": "33.06.01.36"}, {"id": 1153, "label": "33.06.01.37"}, {
    "id": 1154,
    "label": "33.06.01.38"
}, {"id": 1155, "label": "33.06.01.39"}, {"id": 1156, "label": "33.06.01.40"}, {
    "id": 1157,
    "label": "33.06.01.41"
}, {"id": 1158, "label": "33.06.01.42"}, {"id": 1159, "label": "33.06.01.43"}, {
    "id": 1160,
    "label": "33.06.01.44"
}, {"id": 1161, "label": "33.06.01.45"}, {"id": 1162, "label": "33.06.01.46"}, {
    "id": 1163,
    "label": "33.06.01.47"
}, {"id": 1164, "label": "33.06.01.48"}, {"id": 1165, "label": "33.06.01.49"}, {
    "id": 1166,
    "label": "33.06.01.50"
}, {"id": 1167, "label": "33.06.01.51"}, {"id": 1168, "label": "33.06.01.52"}, {
    "id": 1169,
    "label": "33.06.02.01"
}, {"id": 1170, "label": "33.06.02.02"}, {"id": 1171, "label": "33.06.02.03"}, {
    "id": 1172,
    "label": "33.06.02.04"
}, {"id": 1173, "label": "33.06.02.05"}, {"id": 1174, "label": "33.06.02.06"}, {
    "id": 1175,
    "label": "33.06.02.07"
}, {"id": 1176, "label": "33.06.02.08"}, {"id": 1177, "label": "33.06.02.09"}, {
    "id": 1178,
    "label": "33.06.02.10"
}, {"id": 1179, "label": "33.06.02.11"}, {"id": 1180, "label": "33.06.02.12"}, {
    "id": 1181,
    "label": "33.06.02.13"
}, {"id": 1182, "label": "33.06.02.14"}, {"id": 1183, "label": "33.06.02.15"}, {
    "id": 1184,
    "label": "33.06.02.16"
}, {"id": 1185, "label": "33.06.02.17"}, {"id": 1186, "label": "33.06.02.18"}, {
    "id": 1187,
    "label": "33.06.02.19"
}, {"id": 1188, "label": "33.06.02.20"}, {"id": 1189, "label": "33.06.02.21"}, {
    "id": 1190,
    "label": "33.06.02.22"
}, {"id": 1191, "label": "33.06.02.23"}, {"id": 1192, "label": "33.06.02.24"}, {
    "id": 1193,
    "label": "33.06.02.25"
}, {"id": 1194, "label": "33.06.02.26"}, {"id": 1195, "label": "33.06.02.27"}, {
    "id": 1196,
    "label": "33.06.02.28"
}, {"id": 1197, "label": "33.06.02.29"}, {"id": 1198, "label": "33.06.02.30"}, {
    "id": 1199,
    "label": "33.06.02.31"
}, {"id": 1200, "label": "33.06.02.32"}, {"id": 1201, "label": "33.06.02.33"}, {
    "id": 1202,
    "label": "33.06.02.34"
}, {"id": 1203, "label": "33.06.02.35"}, {"id": 1204, "label": "33.06.02.36"}, {
    "id": 1205,
    "label": "33.06.02.37"
}, {"id": 1206, "label": "33.06.02.38"}, {"id": 1207, "label": "33.06.02.39"}, {
    "id": 1208,
    "label": "33.06.02.40"
}, {"id": 1209, "label": "33.06.02.41"}, {"id": 1210, "label": "33.06.02.42"}, {
    "id": 1211,
    "label": "33.06.02.43"
}, {"id": 1212, "label": "33.06.02.44"}, {"id": 1213, "label": "33.06.02.45"}, {
    "id": 1214,
    "label": "33.06.02.46"
}, {"id": 1215, "label": "33.06.02.47"}, {"id": 1216, "label": "33.06.02.48"}, {
    "id": 1217,
    "label": "33.06.02.49"
}, {"id": 1218, "label": "33.06.02.50"}, {"id": 1219, "label": "33.06.02.51"}, {
    "id": 1220,
    "label": "33.06.02.52"
}, {"id": 1221, "label": "33.06.02.53"}, {"id": 1222, "label": "33.06.02.54"}, {
    "id": 1223,
    "label": "33.07.00.01"
}, {"id": 1224, "label": "33.07.00.02"}, {"id": 1225, "label": "33.07.00.03"}, {
    "id": 1226,
    "label": "33.07.00.04"
}, {"id": 1227, "label": "33.07.00.05"}, {"id": 1228, "label": "33.07.00.06"}, {
    "id": 1229,
    "label": "33.07.00.07"
}, {"id": 1230, "label": "33.07.01.01"}, {"id": 1231, "label": "33.07.01.02"}, {
    "id": 1232,
    "label": "33.07.01.03"
}, {"id": 1233, "label": "33.07.01.04"}, {"id": 1234, "label": "33.07.01.05"}, {
    "id": 1235,
    "label": "33.07.01.06"
}, {"id": 1236, "label": "33.07.01.07"}, {"id": 1237, "label": "33.07.01.08"}, {
    "id": 1238,
    "label": "33.07.01.09"
}, {"id": 1239, "label": "33.07.01.10"}, {"id": 1240, "label": "33.07.01.11"}, {
    "id": 1241,
    "label": "33.07.01.12"
}, {"id": 1242, "label": "33.07.01.13"}, {"id": 1243, "label": "33.07.01.14"}, {
    "id": 1244,
    "label": "33.07.01.15"
}, {"id": 1245, "label": "33.07.01.16"}, {"id": 1246, "label": "33.07.01.17"}, {
    "id": 1247,
    "label": "33.07.01.18"
}, {"id": 1248, "label": "33.07.01.19"}, {"id": 1249, "label": "33.07.01.20"}, {
    "id": 1250,
    "label": "33.07.01.21"
}, {"id": 1251, "label": "33.07.01.22"}, {"id": 1252, "label": "33.07.01.23"}, {
    "id": 1253,
    "label": "33.07.01.24"
}, {"id": 1254, "label": "33.07.01.25"}, {"id": 1255, "label": "33.07.01.26"}, {
    "id": 1256,
    "label": "33.07.01.27"
}, {"id": 1257, "label": "33.07.01.28"}, {"id": 1258, "label": "33.07.01.29"}, {
    "id": 1259,
    "label": "33.07.01.30"
}, {"id": 1260, "label": "33.07.01.31"}, {"id": 1261, "label": "33.07.01.32"}, {
    "id": 1262,
    "label": "33.07.01.33"
}, {"id": 1263, "label": "33.07.02.01"}, {"id": 1264, "label": "33.07.02.02"}, {
    "id": 1265,
    "label": "33.07.02.03"
}, {"id": 1266, "label": "33.07.02.04"}, {"id": 1267, "label": "33.07.02.05"}, {
    "id": 1268,
    "label": "33.07.02.06"
}, {"id": 1269, "label": "33.07.02.07"}, {"id": 1270, "label": "33.07.02.08"}, {
    "id": 1271,
    "label": "33.07.02.09"
}, {"id": 1272, "label": "33.07.02.10"}, {"id": 1273, "label": "33.07.02.11"}, {
    "id": 1274,
    "label": "33.08.00.01"
}, {"id": 1275, "label": "33.08.00.02"}, {"id": 1276, "label": "33.08.00.03"}, {
    "id": 1277,
    "label": "33.08.00.04"
}, {"id": 1278, "label": "33.08.00.05"}, {"id": 1279, "label": "33.08.00.06"}, {
    "id": 1280,
    "label": "33.08.00.07"
}, {"id": 1281, "label": "33.08.01.01"}, {"id": 1282, "label": "33.08.01.02"}, {
    "id": 1283,
    "label": "33.08.01.03"
}, {"id": 1284, "label": "33.08.01.04"}, {"id": 1285, "label": "33.08.01.05"}, {
    "id": 1286,
    "label": "33.08.01.06"
}, {"id": 1287, "label": "33.08.01.07"}, {"id": 1288, "label": "33.08.01.08"}, {
    "id": 1289,
    "label": "33.08.01.09"
}, {"id": 1290, "label": "33.08.01.10"}, {"id": 1291, "label": "33.08.01.11"}, {
    "id": 1292,
    "label": "33.08.01.12"
}, {"id": 1293, "label": "33.08.01.13"}, {"id": 1294, "label": "33.08.01.14"}, {
    "id": 1295,
    "label": "33.08.01.15"
}, {"id": 1368, "label": "33.09.01.19"}, {"id": 1296, "label": "33.08.01.16"}, {
    "id": 1297,
    "label": "33.08.01.17"
}, {"id": 1298, "label": "33.08.01.18"}, {"id": 1299, "label": "33.08.01.19"}, {
    "id": 1300,
    "label": "33.08.01.20"
}, {"id": 1301, "label": "33.08.01.21"}, {"id": 1302, "label": "33.08.01.22"}, {
    "id": 1303,
    "label": "33.08.01.23"
}, {"id": 1304, "label": "33.08.01.24"}, {"id": 1305, "label": "33.08.01.25"}, {
    "id": 1306,
    "label": "33.08.01.26"
}, {"id": 1307, "label": "33.08.01.27"}, {"id": 1308, "label": "33.08.01.28"}, {
    "id": 1309,
    "label": "33.08.01.29"
}, {"id": 1310, "label": "33.08.01.30"}, {"id": 1311, "label": "33.08.01.31"}, {
    "id": 1312,
    "label": "33.08.01.32"
}, {"id": 1313, "label": "33.08.01.33"}, {"id": 1314, "label": "33.08.02.01"}, {
    "id": 1315,
    "label": "33.08.02.02"
}, {"id": 1316, "label": "33.08.02.03"}, {"id": 1317, "label": "33.08.02.04"}, {
    "id": 1318,
    "label": "33.08.03.01"
}, {"id": 1319, "label": "33.08.03.02"}, {"id": 1320, "label": "33.08.03.03"}, {
    "id": 1321,
    "label": "33.08.03.04"
}, {"id": 1322, "label": "33.08.04.01"}, {"id": 1323, "label": "33.08.04.02"}, {
    "id": 1324,
    "label": "33.08.04.03"
}, {"id": 1325, "label": "33.08.04.04"}, {"id": 1326, "label": "33.08.04.05"}, {
    "id": 1327,
    "label": "33.08.04.06"
}, {"id": 1328, "label": "33.08.04.07"}, {"id": 1329, "label": "33.08.04.08"}, {
    "id": 1330,
    "label": "33.08.04.09"
}, {"id": 1331, "label": "33.08.04.10"}, {"id": 1332, "label": "33.08.04.11"}, {
    "id": 1333,
    "label": "33.08.05.01"
}, {"id": 1334, "label": "33.08.05.02"}, {"id": 1335, "label": "33.08.05.03"}, {
    "id": 1336,
    "label": "33.08.05.04"
}, {"id": 1337, "label": "33.08.05.05"}, {"id": 1338, "label": "33.08.05.06"}, {
    "id": 1339,
    "label": "33.08.05.07"
}, {"id": 1340, "label": "33.09.00.01"}, {"id": 1341, "label": "33.09.00.02"}, {
    "id": 1342,
    "label": "33.09.00.03"
}, {"id": 1343, "label": "33.09.00.04"}, {"id": 1344, "label": "33.09.00.05"}, {
    "id": 1345,
    "label": "33.09.00.06"
}, {"id": 1346, "label": "33.09.00.07"}, {"id": 1347, "label": "33.09.00.08"}, {
    "id": 1348,
    "label": "33.09.00.09"
}, {"id": 1349, "label": "33.09.00.10"}, {"id": 1350, "label": "33.09.01.01"}, {
    "id": 1351,
    "label": "33.09.01.02"
}, {"id": 1352, "label": "33.09.01.03"}, {"id": 1353, "label": "33.09.01.04"}, {
    "id": 1354,
    "label": "33.09.01.05"
}, {"id": 1355, "label": "33.09.01.06"}, {"id": 1356, "label": "33.09.01.07"}, {
    "id": 1357,
    "label": "33.09.01.08"
}, {"id": 1358, "label": "33.09.01.09"}, {"id": 1359, "label": "33.09.01.10"}, {
    "id": 1360,
    "label": "33.09.01.11"
}, {"id": 1361, "label": "33.09.01.12"}, {"id": 1362, "label": "33.09.01.13"}, {
    "id": 1363,
    "label": "33.09.01.14"
}, {"id": 1364, "label": "33.09.01.15"}, {"id": 1365, "label": "33.09.01.16"}, {
    "id": 1366,
    "label": "33.09.01.17"
}, {"id": 1367, "label": "33.09.01.18"}, {"id": 1369, "label": "33.09.01.20"}, {
    "id": 1370,
    "label": "33.09.01.21"
}, {"id": 1371, "label": "33.09.01.22"}, {"id": 1372, "label": "33.09.01.23"}, {
    "id": 1373,
    "label": "33.09.01.24"
}, {"id": 1374, "label": "33.09.01.25"}, {"id": 1375, "label": "33.09.01.26"}, {
    "id": 1376,
    "label": "33.09.01.27"
}, {"id": 1377, "label": "33.09.01.28"}, {"id": 1378, "label": "33.09.01.29"}, {
    "id": 1379,
    "label": "33.09.01.30"
}, {"id": 1380, "label": "33.09.02.01"}, {"id": 1381, "label": "33.09.02.02"}, {
    "id": 1382,
    "label": "33.09.02.03"
}, {"id": 1383, "label": "33.09.02.04"}, {"id": 1384, "label": "33.09.02.05"}, {
    "id": 1385,
    "label": "33.09.02.06"
}, {"id": 1386, "label": "33.09.02.07"}, {"id": 1387, "label": "33.09.02.08"}, {
    "id": 1388,
    "label": "33.10.00.01"
}, {"id": 1389, "label": "33.10.00.02"}, {"id": 1390, "label": "33.10.00.03"}, {
    "id": 1391,
    "label": "33.10.00.04"
}, {"id": 1392, "label": "33.10.00.05"}, {"id": 1393, "label": "33.10.00.06"}, {
    "id": 1394,
    "label": "33.10.00.07"
}, {"id": 1395, "label": "33.10.00.08"}, {"id": 1396, "label": "33.10.00.09"}, {
    "id": 1397,
    "label": "33.10.01.01"
}, {"id": 1398, "label": "33.10.01.02"}, {"id": 1399, "label": "33.10.01.03"}, {
    "id": 1400,
    "label": "33.10.01.04"
}, {"id": 1401, "label": "33.10.01.05"}, {"id": 1402, "label": "33.10.01.06"}, {
    "id": 1403,
    "label": "33.10.01.07"
}, {"id": 1404, "label": "33.10.01.08"}, {"id": 1405, "label": "33.10.01.09"}, {
    "id": 1406,
    "label": "33.10.01.10"
}, {"id": 1407, "label": "33.10.01.11"}, {"id": 1408, "label": "33.10.01.12"}, {
    "id": 1409,
    "label": "33.10.01.13"
}, {"id": 1410, "label": "33.10.01.14"}, {"id": 1411, "label": "33.10.01.15"}, {
    "id": 1412,
    "label": "33.10.01.16"
}, {"id": 1413, "label": "33.10.01.17"}, {"id": 1414, "label": "33.10.01.18"}, {
    "id": 1415,
    "label": "33.10.01.19"
}, {"id": 1416, "label": "33.10.01.20"}, {"id": 1417, "label": "33.10.01.21"}, {
    "id": 1418,
    "label": "33.10.01.22"
}, {"id": 1419, "label": "33.10.01.23"}, {"id": 1420, "label": "33.10.01.24"}, {
    "id": 1421,
    "label": "33.10.01.25"
}, {"id": 1422, "label": "33.10.01.26"}, {"id": 1423, "label": "33.10.01.27"}, {
    "id": 1424,
    "label": "33.10.01.28"
}, {"id": 1425, "label": "33.10.01.29"}, {"id": 1426, "label": "33.10.01.30"}, {
    "id": 1427,
    "label": "33.10.01.31"
}, {"id": 1428, "label": "33.10.01.32"}, {"id": 1429, "label": "33.10.01.33"}, {
    "id": 1430,
    "label": "33.10.01.34"
}, {"id": 1431, "label": "33.10.01.35"}, {"id": 1432, "label": "33.10.01.36"}, {
    "id": 1433,
    "label": "33.10.01.37"
}, {"id": 1434, "label": "33.10.01.38"}, {"id": 1435, "label": "33.10.02.01"}, {
    "id": 1436,
    "label": "33.10.02.02"
}, {"id": 1437, "label": "33.10.02.03"}, {"id": 1438, "label": "33.10.02.04"}, {
    "id": 1439,
    "label": "33.10.02.05"
}, {"id": 1507, "label": "34.00.00.22"}, {"id": 1440, "label": "33.10.02.06"}, {
    "id": 1441,
    "label": "33.10.02.07"
}, {"id": 1442, "label": "33.10.02.08"}, {"id": 1443, "label": "33.10.02.09"}, {
    "id": 1444,
    "label": "33.10.02.10"
}, {"id": 1445, "label": "33.10.02.11"}, {"id": 1446, "label": "33.10.02.12"}, {
    "id": 1447,
    "label": "33.10.02.13"
}, {"id": 1448, "label": "33.10.02.14"}, {"id": 1449, "label": "33.10.02.15"}, {
    "id": 1450,
    "label": "33.10.02.16"
}, {"id": 1451, "label": "33.10.02.17"}, {"id": 1452, "label": "33.10.02.18"}, {
    "id": 1453,
    "label": "33.10.02.19"
}, {"id": 1454, "label": "33.10.03.01"}, {"id": 1455, "label": "33.10.03.02"}, {
    "id": 1456,
    "label": "33.10.03.03"
}, {"id": 1457, "label": "33.10.03.04"}, {"id": 1458, "label": "33.10.03.05"}, {
    "id": 1459,
    "label": "33.10.03.06"
}, {"id": 1460, "label": "33.10.03.07"}, {"id": 1461, "label": "33.10.03.08"}, {
    "id": 1462,
    "label": "33.10.03.09"
}, {"id": 1463, "label": "33.10.03.10"}, {"id": 1464, "label": "33.10.03.11"}, {
    "id": 1465,
    "label": "33.10.03.12"
}, {"id": 1466, "label": "33.10.03.13"}, {"id": 1467, "label": "33.10.04.01"}, {
    "id": 1468,
    "label": "33.10.04.02"
}, {"id": 1469, "label": "33.10.04.03"}, {"id": 1470, "label": "33.10.04.04"}, {
    "id": 1471,
    "label": "33.10.04.05"
}, {"id": 1472, "label": "33.11.00.01"}, {"id": 1473, "label": "33.11.00.02"}, {
    "id": 1474,
    "label": "33.11.00.03"
}, {"id": 1475, "label": "33.11.00.04"}, {"id": 1476, "label": "33.11.00.06"}, {
    "id": 1477,
    "label": "33.11.00.07"
}, {"id": 1478, "label": "33.11.01.  "}, {"id": 1479, "label": "33.11.01.01"}, {
    "id": 1480,
    "label": "33.11.01.02"
}, {"id": 1481, "label": "33.11.01.05"}, {"id": 1482, "label": "33.11.02.01"}, {
    "id": 1483,
    "label": "33.11.03.01"
}, {"id": 1484, "label": "33.11.03.02"}, {"id": 1485, "label": "33.11.03.03"}, {
    "id": 1486,
    "label": "34.00.00.01"
}, {"id": 1487, "label": "34.00.00.02"}, {"id": 1488, "label": "34.00.00.03"}, {
    "id": 1489,
    "label": "34.00.00.04"
}, {"id": 1490, "label": "34.00.00.05"}, {"id": 1491, "label": "34.00.00.06"}, {
    "id": 1492,
    "label": "34.00.00.07"
}, {"id": 1493, "label": "34.00.00.08"}, {"id": 1494, "label": "34.00.00.09"}, {
    "id": 1495,
    "label": "34.00.00.10"
}, {"id": 1496, "label": "34.00.00.11"}, {"id": 1497, "label": "34.00.00.12"}, {
    "id": 1498,
    "label": "34.00.00.13"
}, {"id": 1499, "label": "34.00.00.14"}, {"id": 1500, "label": "34.00.00.15"}, {
    "id": 1501,
    "label": "34.00.00.16"
}, {"id": 1502, "label": "34.00.00.17"}, {"id": 1503, "label": "34.00.00.18"}, {
    "id": 1504,
    "label": "34.00.00.19"
}, {"id": 1505, "label": "34.00.00.20"}, {"id": 1506, "label": "34.00.00.21"}, {
    "id": 1508,
    "label": "34.00.00.23"
}, {"id": 1509, "label": "34.00.00.24"}, {"id": 1510, "label": "34.00.00.25"}, {
    "id": 1511,
    "label": "34.00.00.26"
}, {"id": 1512, "label": "34.00.00.27"}, {"id": 1513, "label": "34.00.00.28"}, {
    "id": 1514,
    "label": "34.00.00.29"
}, {"id": 1515, "label": "34.00.00.30"}, {"id": 1516, "label": "34.00.00.31"}, {
    "id": 1517,
    "label": "34.00.00.32"
}, {"id": 1518, "label": "34.00.00.33"}, {"id": 1519, "label": "34.00.00.34"}, {
    "id": 1520,
    "label": "34.00.00.35"
}, {"id": 1521, "label": "34.00.00.36"}, {"id": 1522, "label": "34.00.00.37"}, {
    "id": 1523,
    "label": "34.00.00.38"
}, {"id": 1524, "label": "34.00.00.39"}, {"id": 1525, "label": "34.00.00.40"}, {
    "id": 1526,
    "label": "34.00.00.41"
}, {"id": 1527, "label": "34.00.00.42"}, {"id": 1528, "label": "34.00.00.43"}, {
    "id": 1529,
    "label": "34.00.00.44"
}, {"id": 1530, "label": "34.00.00.45"}, {"id": 1531, "label": "34.00.00.46"}, {
    "id": 1532,
    "label": "34.00.00.47"
}, {"id": 1533, "label": "34.00.00.48"}, {"id": 1534, "label": "34.01.00.01"}, {
    "id": 1535,
    "label": "34.01.00.02"
}, {"id": 1536, "label": "34.01.00.03"}, {"id": 1537, "label": "34.01.00.04"}, {
    "id": 1538,
    "label": "34.01.00.05"
}, {"id": 1539, "label": "34.01.00.06"}, {"id": 1540, "label": "34.01.00.07"}, {
    "id": 1541,
    "label": "34.01.00.08"
}, {"id": 1542, "label": "34.01.00.09"}, {"id": 1543, "label": "34.01.00.10"}, {
    "id": 1544,
    "label": "34.01.00.11"
}, {"id": 1545, "label": "34.01.00.12"}, {"id": 1546, "label": "34.01.00.13"}, {
    "id": 1547,
    "label": "34.01.00.14"
}, {"id": 1548, "label": "34.01.00.15"}, {"id": 1549, "label": "34.02.00.01"}, {
    "id": 1550,
    "label": "34.02.00.02"
}, {"id": 1551, "label": "34.02.00.03"}, {"id": 1552, "label": "34.02.00.04"}, {
    "id": 1553,
    "label": "34.02.00.05"
}, {"id": 1554, "label": "34.02.00.06"}, {"id": 1555, "label": "34.02.00.07"}, {
    "id": 1556,
    "label": "34.02.00.08"
}, {"id": 1557, "label": "34.02.00.09"}, {"id": 1558, "label": "34.02.00.10"}, {
    "id": 1559,
    "label": "34.02.00.11"
}, {"id": 1560, "label": "34.03.00.01"}, {"id": 1561, "label": "34.03.00.02"}, {
    "id": 1562,
    "label": "34.03.00.03"
}, {"id": 1563, "label": "34.03.00.04"}, {"id": 1564, "label": "34.03.00.05"}, {
    "id": 1565,
    "label": "34.03.00.06"
}, {"id": 1566, "label": "34.03.00.07"}, {"id": 1567, "label": "34.03.00.08"}, {
    "id": 1568,
    "label": "34.03.00.09"
}, {"id": 1569, "label": "34.03.00.10"}, {"id": 1570, "label": "34.03.00.11"}, {
    "id": 1571,
    "label": "34.03.00.12"
}, {"id": 1572, "label": "34.03.00.13"}, {"id": 1573, "label": "34.03.00.14"}, {
    "id": 1574,
    "label": "34.03.00.15"
}, {"id": 1575, "label": "34.03.00.16"}, {"id": 1576, "label": "34.03.00.17"}, {
    "id": 1577,
    "label": "34.03.00.18"
}, {"id": 1578, "label": "35.00.00.01"}, {"id": 1579, "label": "35.00.00.02"}, {
    "id": 1580,
    "label": "35.00.00.03"
}, {"id": 1581, "label": "35.00.00.04"}, {"id": 1582, "label": "35.00.00.05"}, {
    "id": 1583,
    "label": "35.00.00.06"
}, {"id": 1584, "label": "35.00.00.07"}, {"id": 1585, "label": "35.00.00.08"}, {
    "id": 1586,
    "label": "35.00.00.09"
}, {"id": 1587, "label": "35.00.00.10"}, {"id": 1588, "label": "35.00.00.11"}, {
    "id": 1589,
    "label": "35.00.00.12"
}, {"id": 1590, "label": "35.00.00.13"}, {"id": 1591, "label": "35.00.00.14"}, {
    "id": 1592,
    "label": "35.00.00.15"
}, {"id": 1593, "label": "35.00.00.16"}, {"id": 1594, "label": "35.00.00.17"}, {
    "id": 1595,
    "label": "35.00.00.18"
}, {"id": 1596, "label": "35.00.00.19"}, {"id": 1597, "label": "35.00.00.20"}, {
    "id": 1598,
    "label": "35.00.00.21"
}, {"id": 1599, "label": "35.00.00.22"}, {"id": 1600, "label": "35.00.00.23"}, {
    "id": 1601,
    "label": "35.00.00.24"
}, {"id": 1602, "label": "35.00.00.25"}, {"id": 1603, "label": "35.00.00.26"}, {
    "id": 1604,
    "label": "35.00.00.27"
}, {"id": 1605, "label": "35.00.00.28"}, {"id": 1606, "label": "35.00.00.29"}, {
    "id": 1607,
    "label": "35.00.00.30"
}, {"id": 1608, "label": "35.00.00.31"}, {"id": 1609, "label": "35.00.00.32"}, {
    "id": 1610,
    "label": "35.00.00.33"
}, {"id": 1611, "label": "35.00.00.34"}, {"id": 1612, "label": "35.00.00.35"}, {
    "id": 1613,
    "label": "35.00.00.36"
}, {"id": 1614, "label": "35.00.00.37"}, {"id": 1615, "label": "35.00.00.38"}, {
    "id": 1616,
    "label": "35.00.00.39"
}, {"id": 1617, "label": "35.00.00.40"}, {"id": 1618, "label": "35.01.00.01"}, {
    "id": 1619,
    "label": "35.01.00.02"
}, {"id": 1620, "label": "35.01.00.03"}, {"id": 1621, "label": "35.01.00.04"}, {
    "id": 1622,
    "label": "35.01.00.05"
}, {"id": 1623, "label": "35.01.01.01"}, {"id": 1624, "label": "35.01.01.02"}, {
    "id": 1625,
    "label": "35.01.01.03"
}, {"id": 1626, "label": "35.01.01.04"}, {"id": 1627, "label": "35.01.01.05"}, {
    "id": 1628,
    "label": "35.01.01.06"
}, {"id": 1629, "label": "35.01.01.07"}, {"id": 1630, "label": "35.01.01.08"}, {
    "id": 1631,
    "label": "35.01.01.09"
}, {"id": 1632, "label": "35.01.01.10"}, {"id": 1633, "label": "35.01.01.11"}, {
    "id": 1634,
    "label": "35.01.01.12"
}, {"id": 1635, "label": "35.01.01.13"}, {"id": 1636, "label": "35.01.01.14"}, {
    "id": 1637,
    "label": "35.01.01.15"
}, {"id": 1638, "label": "35.01.01.16"}, {"id": 1639, "label": "35.01.01.17"}, {
    "id": 1640,
    "label": "35.01.02.01"
}, {"id": 1641, "label": "35.01.02.02"}, {"id": 1642, "label": "35.01.02.03"}, {
    "id": 1643,
    "label": "35.01.02.04"
}, {"id": 1644, "label": "35.01.02.05"}, {"id": 1645, "label": "35.01.02.06"}, {
    "id": 1646,
    "label": "35.01.02.07"
}, {"id": 1647, "label": "35.01.02.08"}, {"id": 1648, "label": "35.01.02.09"}, {
    "id": 1649,
    "label": "35.01.02.10"
}, {"id": 1650, "label": "35.01.02.11"}, {"id": 1651, "label": "35.01.02.12"}, {
    "id": 1652,
    "label": "35.01.02.13"
}, {"id": 1653, "label": "35.01.02.14"}, {"id": 1654, "label": "35.01.02.15"}, {
    "id": 1655,
    "label": "35.01.02.16"
}, {"id": 1656, "label": "35.01.02.17"}, {"id": 1657, "label": "35.01.02.18"}, {
    "id": 1658,
    "label": "35.01.02.19"
}, {"id": 1659, "label": "35.01.02.20"}, {"id": 1660, "label": "35.01.02.21"}, {
    "id": 1661,
    "label": "35.01.02.22"
}, {"id": 1662, "label": "35.01.02.23"}, {"id": 1663, "label": "35.01.02.24"}, {
    "id": 1664,
    "label": "35.01.02.25"
}, {"id": 1665, "label": "35.01.02.26"}, {"id": 1666, "label": "35.01.03.01"}, {
    "id": 1667,
    "label": "35.01.03.02"
}, {"id": 1668, "label": "35.01.03.03"}, {"id": 1669, "label": "35.01.03.04"}, {
    "id": 1670,
    "label": "35.01.03.05"
}, {"id": 1671, "label": "35.01.03.06"}, {"id": 1672, "label": "35.01.03.07"}, {
    "id": 1673,
    "label": "35.01.03.08"
}, {"id": 1674, "label": "35.01.03.09"}, {"id": 1675, "label": "35.01.03.10"}, {
    "id": 1676,
    "label": "35.01.03.11"
}, {"id": 1677, "label": "35.01.03.12"}, {"id": 1678, "label": "35.01.03.13"}, {
    "id": 1679,
    "label": "35.01.03.14"
}, {"id": 1680, "label": "35.01.03.15"}, {"id": 1681, "label": "35.01.03.16"}, {
    "id": 1682,
    "label": "35.01.03.17"
}, {"id": 1683, "label": "35.01.03.18"}, {"id": 1684, "label": "35.01.04.01"}, {
    "id": 1685,
    "label": "35.01.04.02"
}, {"id": 1686, "label": "35.01.04.03"}, {"id": 1687, "label": "35.01.04.04"}, {
    "id": 1688,
    "label": "35.01.04.05"
}, {"id": 1689, "label": "35.01.04.06"}, {"id": 1690, "label": "35.01.04.07"}, {
    "id": 1691,
    "label": "35.01.04.08"
}, {"id": 1692, "label": "35.01.05.01"}, {"id": 1693, "label": "35.01.05.02"}, {
    "id": 1694,
    "label": "35.01.05.03"
}, {"id": 1695, "label": "35.01.05.04"}, {"id": 1696, "label": "35.01.05.05"}, {
    "id": 1697,
    "label": "35.01.06.01"
}, {"id": 1698, "label": "35.01.06.02"}, {"id": 1699, "label": "35.01.06.03"}, {
    "id": 1700,
    "label": "35.01.06.04"
}, {"id": 1701, "label": "35.01.07.01"}, {"id": 1702, "label": "35.01.07.02"}, {
    "id": 1703,
    "label": "35.01.07.03"
}, {"id": 1704, "label": "35.01.07.04"}, {"id": 1705, "label": "35.01.07.05"}, {
    "id": 1706,
    "label": "35.01.07.06"
}, {"id": 1707, "label": "35.01.07.07"}, {"id": 1708, "label": "35.01.07.08"}, {
    "id": 1709,
    "label": "35.01.07.09"
}, {"id": 1710, "label": "35.02.00.01"}, {"id": 1711, "label": "35.02.00.02"}, {
    "id": 1712,
    "label": "35.02.00.03"
}, {"id": 1713, "label": "35.02.00.05"}, {"id": 1714, "label": "35.02.00.06"}, {
    "id": 1715,
    "label": "35.03.00.01"
}, {"id": 1716, "label": "35.03.00.02"}, {"id": 1717, "label": "35.03.00.03"}, {
    "id": 1718,
    "label": "35.03.00.04"
}, {"id": 1719, "label": "35.03.01.01"}, {"id": 1720, "label": "35.03.01.02"}, {
    "id": 1721,
    "label": "35.03.01.03"
}, {"id": 1722, "label": "35.03.01.04"}, {"id": 1723, "label": "35.03.01.05"}, {
    "id": 1724,
    "label": "35.03.01.06"
}, {"id": 1725, "label": "35.03.01.07"}, {"id": 1726, "label": "35.03.01.08"}, {
    "id": 1727,
    "label": "35.03.02.01"
}, {"id": 1728, "label": "35.03.02.02"}, {"id": 1729, "label": "35.03.02.03"}, {
    "id": 1730,
    "label": "35.03.02.04"
}, {"id": 1731, "label": "35.03.03.01"}, {"id": 1732, "label": "35.03.03.02"}, {
    "id": 1733,
    "label": "35.03.03.03"
}, {"id": 1734, "label": "35.03.03.04"}, {"id": 1735, "label": "35.03.03.05"}, {
    "id": 1736,
    "label": "35.03.03.06"
}, {"id": 1737, "label": "35.03.03.07"}, {"id": 2259, "label": "40.01.00.18"}, {
    "id": 1738,
    "label": "35.03.03.08"
}, {"id": 1739, "label": "35.03.03.09"}, {"id": 1740, "label": "35.03.03.10"}, {
    "id": 1741,
    "label": "35.03.03.11"
}, {"id": 1742, "label": "35.03.03.12"}, {"id": 1743, "label": "35.03.03.13"}, {
    "id": 1744,
    "label": "35.03.03.14"
}, {"id": 1745, "label": "35.03.03.15"}, {"id": 1746, "label": "35.03.04.01"}, {
    "id": 1747,
    "label": "35.03.04.02"
}, {"id": 1748, "label": "35.03.04.03"}, {"id": 1749, "label": "35.03.04.04"}, {
    "id": 1750,
    "label": "35.03.04.05"
}, {"id": 1751, "label": "35.03.04.06"}, {"id": 1752, "label": "35.03.04.07"}, {
    "id": 1753,
    "label": "35.03.04.08"
}, {"id": 1754, "label": "35.03.04.09"}, {"id": 1755, "label": "35.03.04.10"}, {
    "id": 1756,
    "label": "35.03.04.11"
}, {"id": 1757, "label": "35.03.04.12"}, {"id": 1758, "label": "35.03.04.13"}, {
    "id": 1759,
    "label": "35.03.04.14"
}, {"id": 1760, "label": "35.03.04.15"}, {"id": 1761, "label": "35.03.04.16"}, {
    "id": 1762,
    "label": "35.03.04.17"
}, {"id": 1763, "label": "35.04.00.01"}, {"id": 1764, "label": "35.04.00.02"}, {
    "id": 1765,
    "label": "35.04.00.03"
}, {"id": 1766, "label": "35.04.00.04"}, {"id": 1767, "label": "35.04.00.05"}, {
    "id": 1768,
    "label": "35.04.00.06"
}, {"id": 1769, "label": "35.04.01.01"}, {"id": 1770, "label": "35.04.01.02"}, {
    "id": 1771,
    "label": "35.04.01.03"
}, {"id": 1772, "label": "35.04.02.01"}, {"id": 1773, "label": "35.04.02.02"}, {
    "id": 1774,
    "label": "35.05.00.01"
}, {"id": 1775, "label": "35.05.00.02"}, {"id": 1776, "label": "35.05.00.03"}, {
    "id": 1777,
    "label": "35.05.00.04"
}, {"id": 1778, "label": "35.05.00.05"}, {"id": 1779, "label": "35.05.00.06"}, {
    "id": 1780,
    "label": "35.05.00.07"
}, {"id": 1781, "label": "35.06.00.01"}, {"id": 1782, "label": "35.06.00.02"}, {
    "id": 1783,
    "label": "35.06.00.03"
}, {"id": 1784, "label": "35.06.00.04"}, {"id": 1785, "label": "35.07.00.01"}, {
    "id": 1786,
    "label": "35.07.00.02"
}, {"id": 1787, "label": "35.07.00.03"}, {"id": 1788, "label": "35.07.00.04"}, {
    "id": 1789,
    "label": "35.07.00.05"
}, {"id": 1790, "label": "35.07.00.06"}, {"id": 1791, "label": "35.07.00.07"}, {
    "id": 1792,
    "label": "35.07.00.08"
}, {"id": 1793, "label": "35.07.01.01"}, {"id": 1794, "label": "35.07.01.02"}, {
    "id": 1795,
    "label": "35.07.01.03"
}, {"id": 1796, "label": "35.07.01.04"}, {"id": 1797, "label": "35.07.02.01"}, {
    "id": 1798,
    "label": "35.07.02.02"
}, {"id": 1799, "label": "35.07.03.01"}, {"id": 1800, "label": "35.07.03.02"}, {
    "id": 1801,
    "label": "36.00.00.01"
}, {"id": 1802, "label": "36.01.00.01"}, {"id": 1803, "label": "36.01.00.02"}, {
    "id": 1804,
    "label": "36.01.00.03"
}, {"id": 1805, "label": "36.01.00.04"}, {"id": 1806, "label": "36.01.00.05"}, {
    "id": 1807,
    "label": "36.01.00.06"
}, {"id": 1808, "label": "36.01.00.07"}, {"id": 1809, "label": "36.01.00.08"}, {
    "id": 1810,
    "label": "36.01.00.09"
}, {"id": 1811, "label": "36.01.00.10"}, {"id": 2404, "label": "40.04.00.25"}, {
    "id": 1812,
    "label": "36.01.00.11"
}, {"id": 1813, "label": "36.01.00.12"}, {"id": 1814, "label": "36.01.00.13"}, {
    "id": 1815,
    "label": "36.01.00.14"
}, {"id": 1816, "label": "36.01.00.15"}, {"id": 1817, "label": "36.01.00.16"}, {
    "id": 1818,
    "label": "36.01.00.17"
}, {"id": 1819, "label": "37.00.00.01"}, {"id": 1820, "label": "37.00.00.02"}, {
    "id": 1821,
    "label": "37.00.00.03"
}, {"id": 1822, "label": "37.00.00.04"}, {"id": 1823, "label": "37.00.00.05"}, {
    "id": 1824,
    "label": "37.00.00.06"
}, {"id": 1825, "label": "37.00.00.07"}, {"id": 1826, "label": "37.00.00.08"}, {
    "id": 1827,
    "label": "37.00.00.09"
}, {"id": 1828, "label": "37.00.00.10"}, {"id": 1829, "label": "37.00.00.11"}, {
    "id": 1830,
    "label": "38.00.00.01"
}, {"id": 1831, "label": "38.00.00.02"}, {"id": 1832, "label": "38.00.00.03"}, {
    "id": 1833,
    "label": "38.00.00.04"
}, {"id": 1834, "label": "38.00.00.05"}, {"id": 1835, "label": "38.00.01.01"}, {
    "id": 1836,
    "label": "38.00.01.02"
}, {"id": 1837, "label": "38.00.01.03"}, {"id": 1838, "label": "38.00.01.04"}, {
    "id": 1839,
    "label": "38.00.01.05"
}, {"id": 1840, "label": "38.00.01.06"}, {"id": 1841, "label": "38.01.00.01"}, {
    "id": 1842,
    "label": "38.01.00.02"
}, {"id": 1843, "label": "38.01.00.03"}, {"id": 1844, "label": "38.01.00.04"}, {
    "id": 1845,
    "label": "38.01.00.05"
}, {"id": 1846, "label": "38.01.00.06"}, {"id": 1847, "label": "38.01.00.07"}, {
    "id": 1848,
    "label": "38.01.01.01"
}, {"id": 1849, "label": "38.02.00.01"}, {"id": 1850, "label": "38.02.00.02"}, {
    "id": 1851,
    "label": "38.02.00.03"
}, {"id": 1852, "label": "38.02.00.04"}, {"id": 1853, "label": "38.02.00.05"}, {
    "id": 1854,
    "label": "38.02.00.06"
}, {"id": 1855, "label": "38.02.00.07"}, {"id": 1856, "label": "38.02.00.08"}, {
    "id": 1857,
    "label": "38.02.00.09"
}, {"id": 1858, "label": "38.02.00.10"}, {"id": 1859, "label": "38.02.00.11"}, {
    "id": 1860,
    "label": "38.02.00.12"
}, {"id": 1861, "label": "38.02.00.13"}, {"id": 1862, "label": "38.02.00.14"}, {
    "id": 1863,
    "label": "38.02.00.15"
}, {"id": 1864, "label": "38.02.00.16"}, {"id": 1865, "label": "38.02.00.17"}, {
    "id": 1866,
    "label": "38.02.00.18"
}, {"id": 1867, "label": "38.02.00.19"}, {"id": 1868, "label": "38.02.00.20"}, {
    "id": 1869,
    "label": "38.02.00.21"
}, {"id": 1870, "label": "38.02.00.22"}, {"id": 1871, "label": "38.02.00.23"}, {
    "id": 1872,
    "label": "38.02.00.24"
}, {"id": 1873, "label": "38.02.00.25"}, {"id": 1874, "label": "38.02.00.26"}, {
    "id": 1875,
    "label": "38.03.00.01"
}, {"id": 1876, "label": "38.03.00.02"}, {"id": 1877, "label": "38.03.00.03"}, {
    "id": 1878,
    "label": "38.03.00.04"
}, {"id": 1879, "label": "38.04.00.01"}, {"id": 1880, "label": "38.04.00.02"}, {
    "id": 1881,
    "label": "38.04.00.03"
}, {"id": 1882, "label": "38.04.00.04"}, {"id": 1883, "label": "38.04.00.05"}, {
    "id": 1884,
    "label": "38.04.00.06"
}, {"id": 1885, "label": "38.04.00.07"}, {"id": 1886, "label": "38.04.00.08"}, {
    "id": 1887,
    "label": "38.04.00.09"
}, {"id": 1888, "label": "38.04.00.10"}, {"id": 1889, "label": "38.05.00.01"}, {
    "id": 1890,
    "label": "38.05.00.02"
}, {"id": 1891, "label": "38.05.00.03"}, {"id": 1892, "label": "38.05.00.04"}, {
    "id": 1893,
    "label": "38.05.00.05"
}, {"id": 1894, "label": "38.05.00.06"}, {"id": 1895, "label": "38.05.00.07"}, {
    "id": 1896,
    "label": "38.05.00.08"
}, {"id": 1897, "label": "38.05.00.09"}, {"id": 1898, "label": "38.05.01.01"}, {
    "id": 1899,
    "label": "38.05.01.02"
}, {"id": 1900, "label": "38.05.01.03"}, {"id": 1901, "label": "38.05.01.04"}, {
    "id": 1902,
    "label": "38.05.01.05"
}, {"id": 1903, "label": "38.05.01.06"}, {"id": 1904, "label": "38.05.01.07"}, {
    "id": 1905,
    "label": "38.05.01.08"
}, {"id": 1906, "label": "38.05.01.09"}, {"id": 1907, "label": "38.05.01.10"}, {
    "id": 1908,
    "label": "38.05.01.11"
}, {"id": 1909, "label": "38.05.01.12"}, {"id": 1910, "label": "38.05.01.13"}, {
    "id": 1911,
    "label": "38.05.01.14"
}, {"id": 1912, "label": "38.05.01.15"}, {"id": 1913, "label": "38.05.02.01"}, {
    "id": 1914,
    "label": "38.05.02.02"
}, {"id": 1915, "label": "38.05.02.03"}, {"id": 1916, "label": "38.05.02.04"}, {
    "id": 1917,
    "label": "38.05.02.05"
}, {"id": 1918, "label": "38.05.02.06"}, {"id": 1919, "label": "38.05.02.07"}, {
    "id": 1920,
    "label": "38.05.02.08"
}, {"id": 1921, "label": "38.05.02.09"}, {"id": 1922, "label": "38.05.02.10"}, {
    "id": 1923,
    "label": "38.05.02.11"
}, {"id": 1924, "label": "38.05.02.12"}, {"id": 1925, "label": "38.05.02.13"}, {
    "id": 1926,
    "label": "38.05.02.14"
}, {"id": 1927, "label": "38.05.03.01"}, {"id": 1928, "label": "38.05.03.02"}, {
    "id": 1929,
    "label": "38.05.03.03"
}, {"id": 1930, "label": "38.05.03.04"}, {"id": 1931, "label": "38.05.03.05"}, {
    "id": 1932,
    "label": "38.05.03.06"
}, {"id": 1933, "label": "38.05.03.07"}, {"id": 1934, "label": "38.05.03.08"}, {
    "id": 1935,
    "label": "38.05.03.09"
}, {"id": 1936, "label": "38.05.03.10"}, {"id": 1937, "label": "38.06.00.01"}, {
    "id": 1938,
    "label": "38.06.00.02"
}, {"id": 1939, "label": "38.06.00.03"}, {"id": 1940, "label": "38.06.00.04"}, {
    "id": 1941,
    "label": "38.06.00.05"
}, {"id": 1942, "label": "38.06.00.06"}, {"id": 1943, "label": "38.06.00.07"}, {
    "id": 1944,
    "label": "38.06.00.08"
}, {"id": 1945, "label": "38.06.00.09"}, {"id": 1946, "label": "38.06.00.10"}, {
    "id": 1947,
    "label": "38.06.00.11"
}, {"id": 1948, "label": "38.06.00.12"}, {"id": 1949, "label": "38.06.00.13"}, {
    "id": 1950,
    "label": "38.06.00.14"
}, {"id": 1951, "label": "38.06.00.15"}, {"id": 1952, "label": "38.07.00.01"}, {
    "id": 1953,
    "label": "38.07.00.02"
}, {"id": 1954, "label": "38.07.00.03"}, {"id": 1955, "label": "38.07.00.04"}, {
    "id": 1956,
    "label": "38.07.00.05"
}, {"id": 1957, "label": "38.08.00.01"}, {"id": 1958, "label": "38.08.00.02"}, {
    "id": 1959,
    "label": "39.00.00.01"
}, {"id": 1960, "label": "39.00.00.02"}, {"id": 1961, "label": "39.00.00.03"}, {
    "id": 1962,
    "label": "39.00.00.04"
}, {"id": 1963, "label": "39.00.00.05"}, {"id": 1964, "label": "39.00.00.06"}, {
    "id": 2405,
    "label": "40.04.00.26"
}, {"id": 1965, "label": "39.00.00.07"}, {"id": 1966, "label": "39.00.00.08"}, {
    "id": 1967,
    "label": "39.00.00.09"
}, {"id": 1968, "label": "39.00.00.10"}, {"id": 1969, "label": "39.00.00.11"}, {
    "id": 1970,
    "label": "39.00.00.12"
}, {"id": 1971, "label": "39.00.00.13"}, {"id": 1972, "label": "39.01.00.01"}, {
    "id": 1973,
    "label": "39.01.00.02"
}, {"id": 1974, "label": "39.01.00.03"}, {"id": 1975, "label": "39.01.00.04"}, {
    "id": 1976,
    "label": "39.01.00.05"
}, {"id": 1977, "label": "39.01.00.06"}, {"id": 1978, "label": "39.01.00.07"}, {
    "id": 1979,
    "label": "39.02.00.01"
}, {"id": 1980, "label": "39.02.00.02"}, {"id": 1981, "label": "39.02.00.03"}, {
    "id": 1982,
    "label": "39.02.00.04"
}, {"id": 1983, "label": "39.02.00.05"}, {"id": 1984, "label": "39.02.00.06"}, {
    "id": 1985,
    "label": "39.02.00.07"
}, {"id": 1986, "label": "39.02.00.08"}, {"id": 1987, "label": "39.02.00.09"}, {
    "id": 1988,
    "label": "39.02.00.10"
}, {"id": 1989, "label": "39.02.00.11"}, {"id": 1990, "label": "39.02.00.12"}, {
    "id": 1991,
    "label": "39.02.00.13"
}, {"id": 1992, "label": "39.02.00.14"}, {"id": 1993, "label": "39.02.00.15"}, {
    "id": 1994,
    "label": "39.02.00.16"
}, {"id": 1995, "label": "39.02.00.17"}, {"id": 1996, "label": "39.03.00.01"}, {
    "id": 1997,
    "label": "39.03.00.02"
}, {"id": 1998, "label": "39.03.00.03"}, {"id": 1999, "label": "39.03.00.04"}, {
    "id": 2000,
    "label": "39.03.00.05"
}, {"id": 2001, "label": "39.03.00.06"}, {"id": 2002, "label": "39.03.00.07"}, {
    "id": 2003,
    "label": "39.03.00.08"
}, {"id": 2004, "label": "39.03.00.09"}, {"id": 2005, "label": "39.03.00.10"}, {
    "id": 2006,
    "label": "39.03.00.11"
}, {"id": 2007, "label": "39.03.00.12"}, {"id": 2008, "label": "39.04.00.01"}, {
    "id": 2009,
    "label": "39.04.00.02"
}, {"id": 2010, "label": "39.04.00.03"}, {"id": 2011, "label": "39.04.00.04"}, {
    "id": 2012,
    "label": "39.04.00.05"
}, {"id": 2013, "label": "39.04.00.06"}, {"id": 2014, "label": "39.04.00.07"}, {
    "id": 2015,
    "label": "39.04.00.08"
}, {"id": 2016, "label": "39.04.00.09"}, {"id": 2017, "label": "39.04.00.10"}, {
    "id": 2018,
    "label": "39.04.00.11"
}, {"id": 2019, "label": "39.04.00.12"}, {"id": 2020, "label": "39.04.00.13"}, {
    "id": 2021,
    "label": "39.04.00.14"
}, {"id": 2022, "label": "39.04.00.15"}, {"id": 2023, "label": "39.04.00.16"}, {
    "id": 2024,
    "label": "39.04.00.17"
}, {"id": 2025, "label": "39.04.00.18"}, {"id": 2026, "label": "39.04.00.19"}, {
    "id": 2027,
    "label": "39.04.00.20"
}, {"id": 2028, "label": "39.05.00.01"}, {"id": 2029, "label": "39.05.00.02"}, {
    "id": 2030,
    "label": "39.05.00.03"
}, {"id": 2031, "label": "39.05.00.04"}, {"id": 2032, "label": "39.05.00.05"}, {
    "id": 2033,
    "label": "39.05.00.06"
}, {"id": 2034, "label": "39.05.00.07"}, {"id": 2035, "label": "39.05.00.08"}, {
    "id": 2036,
    "label": "39.05.00.09"
}, {"id": 2037, "label": "39.05.00.10"}, {"id": 2038, "label": "39.05.00.11"}, {
    "id": 2039,
    "label": "39.05.00.12"
}, {"id": 2040, "label": "39.06.00.01"}, {"id": 2041, "label": "39.06.00.02"}, {
    "id": 2042,
    "label": "39.06.00.03"
}, {"id": 2043, "label": "39.06.00.04"}, {"id": 2044, "label": "39.06.00.05"}, {
    "id": 2045,
    "label": "39.06.00.06"
}, {"id": 2046, "label": "39.06.00.07"}, {"id": 2047, "label": "39.06.00.08"}, {
    "id": 2048,
    "label": "39.06.00.09"
}, {"id": 2049, "label": "39.06.00.10"}, {"id": 2050, "label": "39.06.00.11"}, {
    "id": 2051,
    "label": "39.06.00.12"
}, {"id": 2052, "label": "39.06.00.13"}, {"id": 2053, "label": "39.07.00.01"}, {
    "id": 2054,
    "label": "39.07.00.02"
}, {"id": 2055, "label": "39.07.00.03"}, {"id": 2056, "label": "39.07.00.04"}, {
    "id": 2057,
    "label": "39.07.00.05"
}, {"id": 2058, "label": "39.07.00.06"}, {"id": 2059, "label": "39.07.00.07"}, {
    "id": 2060,
    "label": "39.07.00.08"
}, {"id": 2061, "label": "39.07.00.09"}, {"id": 2062, "label": "39.07.00.10"}, {
    "id": 2063,
    "label": "39.07.00.11"
}, {"id": 2064, "label": "39.07.00.12"}, {"id": 2065, "label": "39.07.00.13"}, {
    "id": 2066,
    "label": "39.07.00.14"
}, {"id": 2067, "label": "39.08.00.01"}, {"id": 2068, "label": "39.08.00.02"}, {
    "id": 2069,
    "label": "39.08.00.03"
}, {"id": 2070, "label": "39.08.00.04"}, {"id": 2071, "label": "39.08.00.05"}, {
    "id": 2072,
    "label": "39.08.00.06"
}, {"id": 2073, "label": "39.08.00.07"}, {"id": 2074, "label": "39.08.00.08"}, {
    "id": 2075,
    "label": "39.08.00.09"
}, {"id": 2076, "label": "39.08.00.10"}, {"id": 2077, "label": "39.08.00.11"}, {
    "id": 2078,
    "label": "39.08.00.12"
}, {"id": 2079, "label": "39.08.00.13"}, {"id": 2080, "label": "39.08.00.14"}, {
    "id": 2081,
    "label": "39.08.00.15"
}, {"id": 2082, "label": "39.08.00.16"}, {"id": 2083, "label": "39.08.00.17"}, {
    "id": 2084,
    "label": "39.08.00.20"
}, {"id": 2085, "label": "39.08.00.21"}, {"id": 2086, "label": "39.08.00.22"}, {
    "id": 2087,
    "label": "39.08.00.23"
}, {"id": 2088, "label": "39.08.00.24"}, {"id": 2089, "label": "39.08.00.25"}, {
    "id": 2090,
    "label": "39.08.00.26"
}, {"id": 2091, "label": "39.08.00.27"}, {"id": 2092, "label": "39.08.00.28"}, {
    "id": 2093,
    "label": "39.08.00.29"
}, {"id": 2094, "label": "39.08.00.30"}, {"id": 2095, "label": "39.09.00.01"}, {
    "id": 2096,
    "label": "39.09.00.02"
}, {"id": 2097, "label": "39.09.00.03"}, {"id": 2098, "label": "39.09.00.04"}, {
    "id": 2099,
    "label": "39.09.00.05"
}, {"id": 2100, "label": "39.09.00.06"}, {"id": 2101, "label": "39.10.00.01"}, {
    "id": 2102,
    "label": "39.10.00.02"
}, {"id": 2103, "label": "39.10.00.03"}, {"id": 2104, "label": "39.10.00.04"}, {
    "id": 2105,
    "label": "39.10.00.05"
}, {"id": 2106, "label": "39.10.00.06"}, {"id": 2107, "label": "39.10.00.07"}, {
    "id": 2108,
    "label": "39.10.00.08"
}, {"id": 2109, "label": "39.10.00.09"}, {"id": 2110, "label": "39.10.00.10"}, {
    "id": 2111,
    "label": "39.10.00.11"
}, {"id": 2112, "label": "39.11.00.01"}, {"id": 2113, "label": "39.11.00.02"}, {
    "id": 2114,
    "label": "39.11.00.03"
}, {"id": 2115, "label": "39.11.00.04"}, {"id": 2116, "label": "39.11.00.05"}, {
    "id": 2117,
    "label": "39.11.00.06"
}, {"id": 2118, "label": "39.11.00.07"}, {"id": 2119, "label": "39.11.00.08"}, {
    "id": 2120,
    "label": "39.11.00.09"
}, {"id": 2121, "label": "39.11.00.10"}, {"id": 2122, "label": "39.11.00.11"}, {
    "id": 2123,
    "label": "39.11.00.12"
}, {"id": 2124, "label": "39.11.00.13"}, {"id": 2125, "label": "39.12.00.01"}, {
    "id": 2126,
    "label": "39.12.00.02"
}, {"id": 2127, "label": "39.12.00.03"}, {"id": 2128, "label": "39.12.00.04"}, {
    "id": 2129,
    "label": "39.12.00.05"
}, {"id": 2130, "label": "39.12.00.06"}, {"id": 2131, "label": "39.12.00.07"}, {
    "id": 2132,
    "label": "39.12.00.08"
}, {"id": 2133, "label": "39.12.00.09"}, {"id": 2134, "label": "39.12.00.10"}, {
    "id": 2135,
    "label": "39.13.00.01"
}, {"id": 2136, "label": "39.13.00.02"}, {"id": 2137, "label": "39.13.00.03"}, {
    "id": 2138,
    "label": "39.13.00.04"
}, {"id": 2139, "label": "39.13.00.05"}, {"id": 2140, "label": "39.13.00.06"}, {
    "id": 2141,
    "label": "39.13.00.07"
}, {"id": 2142, "label": "39.13.00.08"}, {"id": 2143, "label": "39.13.00.09"}, {
    "id": 2144,
    "label": "39.13.00.10"
}, {"id": 2145, "label": "39.13.00.11"}, {"id": 2146, "label": "39.13.00.12"}, {
    "id": 2147,
    "label": "39.13.00.13"
}, {"id": 2148, "label": "39.13.00.14"}, {"id": 2149, "label": "39.13.00.15"}, {
    "id": 2150,
    "label": "39.13.00.16"
}, {"id": 2151, "label": "39.14.00.01"}, {"id": 2152, "label": "39.14.00.02"}, {
    "id": 2153,
    "label": "39.14.00.03"
}, {"id": 2154, "label": "39.14.00.04"}, {"id": 2155, "label": "39.14.00.05"}, {
    "id": 2156,
    "label": "39.14.00.06"
}, {"id": 2157, "label": "39.14.00.07"}, {"id": 2158, "label": "39.14.00.08"}, {
    "id": 2159,
    "label": "39.15.00.01"
}, {"id": 2160, "label": "39.15.00.02"}, {"id": 2161, "label": "39.15.00.03"}, {
    "id": 2162,
    "label": "39.15.00.04"
}, {"id": 2163, "label": "39.15.00.05"}, {"id": 2164, "label": "39.15.00.06"}, {
    "id": 2165,
    "label": "39.15.00.07"
}, {"id": 2166, "label": "39.15.00.08"}, {"id": 2167, "label": "39.15.00.09"}, {
    "id": 2168,
    "label": "39.15.00.10"
}, {"id": 2169, "label": "39.15.00.11"}, {"id": 2170, "label": "39.15.00.12"}, {
    "id": 2171,
    "label": "39.15.00.13"
}, {"id": 2172, "label": "39.15.00.14"}, {"id": 2173, "label": "39.15.00.15"}, {
    "id": 2174,
    "label": "39.15.00.16"
}, {"id": 2175, "label": "39.15.00.17"}, {"id": 2176, "label": "39.15.00.18"}, {
    "id": 2177,
    "label": "39.15.00.19"
}, {"id": 2178, "label": "39.15.00.20"}, {"id": 2179, "label": "39.15.00.21"}, {
    "id": 2180,
    "label": "40.00.00.01"
}, {"id": 2181, "label": "40.00.00.02"}, {"id": 2182, "label": "40.00.00.03"}, {
    "id": 2183,
    "label": "40.00.00.04"
}, {"id": 2184, "label": "40.00.00.05"}, {"id": 2185, "label": "40.00.00.06"}, {
    "id": 2186,
    "label": "40.00.00.07"
}, {"id": 2187, "label": "40.00.00.08"}, {"id": 2188, "label": "40.00.00.09"}, {
    "id": 2189,
    "label": "40.00.00.10"
}, {"id": 2190, "label": "40.00.00.11"}, {"id": 2191, "label": "40.00.00.12"}, {
    "id": 2192,
    "label": "40.00.00.13"
}, {"id": 2193, "label": "40.00.00.14"}, {"id": 2194, "label": "40.00.00.15"}, {
    "id": 2195,
    "label": "40.00.00.16"
}, {"id": 2196, "label": "40.00.00.17"}, {"id": 2197, "label": "40.00.00.18"}, {
    "id": 2198,
    "label": "40.00.00.19"
}, {"id": 2199, "label": "40.00.00.20"}, {"id": 2200, "label": "40.00.00.21"}, {
    "id": 2201,
    "label": "40.00.00.22"
}, {"id": 2202, "label": "40.00.00.23"}, {"id": 2203, "label": "40.00.00.24"}, {
    "id": 2204,
    "label": "40.00.00.25"
}, {"id": 2205, "label": "40.00.00.26"}, {"id": 2206, "label": "40.00.00.27"}, {
    "id": 2207,
    "label": "40.00.00.28"
}, {"id": 2208, "label": "40.00.00.29"}, {"id": 2209, "label": "40.00.00.30"}, {
    "id": 2210,
    "label": "40.00.00.31"
}, {"id": 2211, "label": "40.00.00.32"}, {"id": 2212, "label": "40.00.00.33"}, {
    "id": 2213,
    "label": "40.00.00.34"
}, {"id": 2214, "label": "40.00.00.35"}, {"id": 2215, "label": "40.00.00.36"}, {
    "id": 2216,
    "label": "40.00.00.37"
}, {"id": 2217, "label": "40.00.00.38"}, {"id": 2218, "label": "40.00.00.39"}, {
    "id": 2219,
    "label": "40.00.00.40"
}, {"id": 2220, "label": "40.00.00.41"}, {"id": 2221, "label": "40.00.00.42"}, {
    "id": 2222,
    "label": "40.00.00.43"
}, {"id": 2223, "label": "40.00.00.44"}, {"id": 2224, "label": "40.00.00.45"}, {
    "id": 2225,
    "label": "40.00.00.46"
}, {"id": 2226, "label": "40.00.00.47"}, {"id": 2227, "label": "40.00.00.48"}, {
    "id": 2228,
    "label": "40.00.00.49"
}, {"id": 2229, "label": "40.00.00.50"}, {"id": 2230, "label": "40.00.00.51"}, {
    "id": 2231,
    "label": "40.00.00.52"
}, {"id": 2232, "label": "40.00.00.53"}, {"id": 2233, "label": "40.00.00.54"}, {
    "id": 2234,
    "label": "40.00.00.55"
}, {"id": 2235, "label": "40.00.00.56"}, {"id": 2236, "label": "40.00.00.57"}, {
    "id": 2237,
    "label": "40.00.00.58"
}, {"id": 2238, "label": "40.00.00.59"}, {"id": 2239, "label": "40.00.00.60"}, {
    "id": 2240,
    "label": "40.00.00.61"
}, {"id": 2241, "label": "40.00.00.62"}, {"id": 2242, "label": "40.01.00.01"}, {
    "id": 2243,
    "label": "40.01.00.02"
}, {"id": 2244, "label": "40.01.00.03"}, {"id": 2245, "label": "40.01.00.04"}, {
    "id": 2246,
    "label": "40.01.00.05"
}, {"id": 2247, "label": "40.01.00.06"}, {"id": 2248, "label": "40.01.00.07"}, {
    "id": 2249,
    "label": "40.01.00.08"
}, {"id": 2250, "label": "40.01.00.09"}, {"id": 2251, "label": "40.01.00.10"}, {
    "id": 2252,
    "label": "40.01.00.11"
}, {"id": 2253, "label": "40.01.00.12"}, {"id": 2254, "label": "40.01.00.13"}, {
    "id": 2255,
    "label": "40.01.00.14"
}, {"id": 2256, "label": "40.01.00.15"}, {"id": 2257, "label": "40.01.00.16"}, {
    "id": 2258,
    "label": "40.01.00.17"
}, {"id": 2260, "label": "40.01.00.19"}, {"id": 2261, "label": "40.01.00.20"}, {
    "id": 2262,
    "label": "40.01.00.21"
}, {"id": 2263, "label": "40.01.00.22"}, {"id": 2264, "label": "40.01.00.23"}, {
    "id": 2265,
    "label": "40.01.00.24"
}, {"id": 2266, "label": "40.01.00.25"}, {"id": 2267, "label": "40.01.00.26"}, {
    "id": 2268,
    "label": "40.01.00.27"
}, {"id": 2269, "label": "40.01.00.28"}, {"id": 2270, "label": "40.01.00.29"}, {
    "id": 2271,
    "label": "40.01.00.30"
}, {"id": 2272, "label": "40.01.00.31"}, {"id": 2273, "label": "40.01.00.32"}, {
    "id": 2274,
    "label": "40.01.00.33"
}, {"id": 2275, "label": "40.01.00.34"}, {"id": 2276, "label": "40.01.00.35"}, {
    "id": 2277,
    "label": "40.01.00.36"
}, {"id": 2278, "label": "40.01.00.37"}, {"id": 2279, "label": "40.01.00.38"}, {
    "id": 2280,
    "label": "40.01.00.39"
}, {"id": 2281, "label": "40.01.00.40"}, {"id": 2282, "label": "40.01.00.41"}, {
    "id": 2283,
    "label": "40.01.00.42"
}, {"id": 2284, "label": "40.01.00.43"}, {"id": 2285, "label": "40.01.00.44"}, {
    "id": 2286,
    "label": "40.01.00.45"
}, {"id": 2287, "label": "40.01.00.46"}, {"id": 2288, "label": "40.01.00.47"}, {
    "id": 2289,
    "label": "40.01.00.48"
}, {"id": 2290, "label": "40.01.00.49"}, {"id": 2291, "label": "40.01.00.50"}, {
    "id": 2292,
    "label": "40.01.00.51"
}, {"id": 2293, "label": "40.01.00.52"}, {"id": 2294, "label": "40.01.00.53"}, {
    "id": 2295,
    "label": "40.01.00.54"
}, {"id": 2296, "label": "40.01.00.55"}, {"id": 2297, "label": "40.01.00.56"}, {
    "id": 2298,
    "label": "40.01.00.57"
}, {"id": 2299, "label": "40.01.00.58"}, {"id": 2300, "label": "40.01.00.59"}, {
    "id": 2301,
    "label": "40.01.00.60"
}, {"id": 2302, "label": "40.01.00.61"}, {"id": 2303, "label": "40.02.00.01"}, {
    "id": 2304,
    "label": "40.02.00.02"
}, {"id": 2305, "label": "40.02.00.03"}, {"id": 2306, "label": "40.02.00.04"}, {
    "id": 2307,
    "label": "40.02.00.05"
}, {"id": 2308, "label": "40.02.00.06"}, {"id": 2309, "label": "40.02.00.07"}, {
    "id": 2310,
    "label": "40.02.00.08"
}, {"id": 2311, "label": "40.02.00.09"}, {"id": 2312, "label": "40.02.00.10"}, {
    "id": 2313,
    "label": "40.02.00.11"
}, {"id": 2314, "label": "40.02.00.12"}, {"id": 2315, "label": "40.02.00.13"}, {
    "id": 2316,
    "label": "40.02.00.14"
}, {"id": 2317, "label": "40.02.00.15"}, {"id": 2318, "label": "40.02.00.16"}, {
    "id": 2319,
    "label": "40.02.00.17"
}, {"id": 2320, "label": "40.02.00.18"}, {"id": 2321, "label": "40.02.00.19"}, {
    "id": 2322,
    "label": "40.02.00.20"
}, {"id": 2323, "label": "40.02.00.21"}, {"id": 2324, "label": "40.02.00.22"}, {
    "id": 2325,
    "label": "40.02.00.23"
}, {"id": 2326, "label": "40.02.00.24"}, {"id": 2327, "label": "40.02.00.25"}, {
    "id": 2328,
    "label": "40.02.00.26"
}, {"id": 2329, "label": "40.02.00.27"}, {"id": 2330, "label": "40.02.00.28"}, {
    "id": 2331,
    "label": "40.02.00.29"
}, {"id": 2332, "label": "40.02.00.30"}, {"id": 2333, "label": "40.02.00.31"}, {
    "id": 2334,
    "label": "40.02.00.32"
}, {"id": 2335, "label": "40.02.00.33"}, {"id": 2336, "label": "40.02.00.34"}, {
    "id": 2337,
    "label": "40.02.00.35"
}, {"id": 2338, "label": "40.02.00.36"}, {"id": 2339, "label": "40.02.00.37"}, {
    "id": 2340,
    "label": "40.02.00.38"
}, {"id": 2341, "label": "40.02.00.39"}, {"id": 2342, "label": "40.02.00.40"}, {
    "id": 2343,
    "label": "40.02.00.41"
}, {"id": 2344, "label": "40.02.00.42"}, {"id": 2345, "label": "40.02.00.43"}, {
    "id": 2346,
    "label": "40.02.00.44"
}, {"id": 2347, "label": "40.02.00.45"}, {"id": 2348, "label": "40.02.00.46"}, {
    "id": 2349,
    "label": "40.02.00.47"
}, {"id": 2350, "label": "40.02.00.48"}, {"id": 2351, "label": "40.02.00.49"}, {
    "id": 2352,
    "label": "40.02.00.50"
}, {"id": 2353, "label": "40.02.00.51"}, {"id": 2354, "label": "40.02.00.52"}, {
    "id": 2355,
    "label": "40.02.00.53"
}, {"id": 2356, "label": "40.02.00.54"}, {"id": 2357, "label": "40.02.00.55"}, {
    "id": 2358,
    "label": "40.02.00.56"
}, {"id": 2359, "label": "40.03.00.01"}, {"id": 2360, "label": "40.03.00.02"}, {
    "id": 2361,
    "label": "40.03.00.03"
}, {"id": 2362, "label": "40.03.00.04"}, {"id": 2363, "label": "40.03.00.05"}, {
    "id": 2364,
    "label": "40.03.00.06"
}, {"id": 2365, "label": "40.03.00.07"}, {"id": 2366, "label": "40.03.00.08"}, {
    "id": 2367,
    "label": "40.03.00.09"
}, {"id": 2368, "label": "40.03.00.10"}, {"id": 2369, "label": "40.03.00.11"}, {
    "id": 2370,
    "label": "40.03.00.12"
}, {"id": 2371, "label": "40.03.00.13"}, {"id": 2372, "label": "40.03.00.14"}, {
    "id": 2373,
    "label": "40.03.00.15"
}, {"id": 2374, "label": "40.03.00.16"}, {"id": 2375, "label": "40.03.00.17"}, {
    "id": 2376,
    "label": "40.03.00.18"
}, {"id": 2377, "label": "40.03.00.19"}, {"id": 2378, "label": "40.03.00.20"}, {
    "id": 2379,
    "label": "40.03.00.21"
}, {"id": 2380, "label": "40.04.00.01"}, {"id": 2381, "label": "40.04.00.02"}, {
    "id": 2382,
    "label": "40.04.00.03"
}, {"id": 2383, "label": "40.04.00.04"}, {"id": 2384, "label": "40.04.00.05"}, {
    "id": 2385,
    "label": "40.04.00.06"
}, {"id": 2386, "label": "40.04.00.07"}, {"id": 2387, "label": "40.04.00.08"}, {
    "id": 2388,
    "label": "40.04.00.09"
}, {"id": 2389, "label": "40.04.00.10"}, {"id": 2390, "label": "40.04.00.11"}, {
    "id": 2391,
    "label": "40.04.00.12"
}, {"id": 2392, "label": "40.04.00.13"}, {"id": 2393, "label": "40.04.00.14"}, {
    "id": 2394,
    "label": "40.04.00.15"
}, {"id": 2395, "label": "40.04.00.16"}, {"id": 2396, "label": "40.04.00.17"}, {
    "id": 2397,
    "label": "40.04.00.18"
}, {"id": 2398, "label": "40.04.00.19"}, {"id": 2399, "label": "40.04.00.20"}, {
    "id": 2400,
    "label": "40.04.00.21"
}, {"id": 2401, "label": "40.04.00.22"}, {"id": 2402, "label": "40.04.00.23"}, {
    "id": 2403,
    "label": "40.04.00.24"
}, {"id": 2406, "label": "40.04.00.27"}, {"id": 2407, "label": "40.04.00.28"}, {
    "id": 2408,
    "label": "40.04.00.29"
}, {"id": 2409, "label": "40.04.00.30"}, {"id": 2410, "label": "40.04.00.31"}, {
    "id": 2411,
    "label": "40.04.00.32"
}, {"id": 2412, "label": "40.04.00.33"}, {"id": 2413, "label": "40.04.00.34"}, {
    "id": 2414,
    "label": "40.04.00.35"
}, {"id": 2415, "label": "40.04.00.36"}, {"id": 2416, "label": "40.04.00.37"}, {
    "id": 2417,
    "label": "40.04.00.38"
}, {"id": 2418, "label": "40.04.00.39"}, {"id": 2419, "label": "40.04.00.40"}, {
    "id": 2420,
    "label": "40.04.00.41"
}, {"id": 2421, "label": "40.04.00.42"}, {"id": 2422, "label": "41.00.00.01"}, {
    "id": 2423,
    "label": "41.00.00.02"
}, {"id": 2424, "label": "41.00.00.03"}, {"id": 2425, "label": "41.00.00.04"}, {
    "id": 2426,
    "label": "41.00.00.05"
}, {"id": 2427, "label": "41.00.00.06"}, {"id": 2428, "label": "41.00.00.07"}, {
    "id": 2429,
    "label": "41.00.00.08"
}, {"id": 2430, "label": "41.00.00.09"}, {"id": 2431, "label": "41.00.00.10"}, {
    "id": 2432,
    "label": "41.00.00.11"
}, {"id": 2433, "label": "41.00.00.12"}, {"id": 2434, "label": "41.00.00.13"}, {
    "id": 2435,
    "label": "41.00.00.14"
}, {"id": 2436, "label": "41.00.00.15"}, {"id": 2437, "label": "41.00.00.16"}, {
    "id": 2438,
    "label": "41.00.00.17"
}, {"id": 2439, "label": "41.00.00.18"}, {"id": 2440, "label": "41.00.00.19"}, {
    "id": 2441,
    "label": "41.00.00.20"
}, {"id": 2442, "label": "41.00.00.21"}, {"id": 2443, "label": "41.00.00.22"}, {
    "id": 2444,
    "label": "41.00.00.23"
}, {"id": 2445, "label": "41.00.00.24"}, {"id": 2446, "label": "41.00.00.25"}, {
    "id": 2447,
    "label": "41.00.00.26"
}, {"id": 2448, "label": "41.00.00.27"}, {"id": 2449, "label": "41.00.00.28"}, {
    "id": 2450,
    "label": "41.00.00.29"
}, {"id": 2451, "label": "41.00.00.30"}, {"id": 2452, "label": "41.00.00.31"}, {
    "id": 2453,
    "label": "41.00.00.32"
}, {"id": 2454, "label": "41.00.00.33"}, {"id": 2455, "label": "41.00.00.34"}, {
    "id": 2456,
    "label": "41.00.00.35"
}, {"id": 2457, "label": "41.00.00.36"}, {"id": 2458, "label": "41.00.00.37"}, {
    "id": 2459,
    "label": "41.00.00.38"
}, {"id": 2460, "label": "41.00.00.39"}, {"id": 2461, "label": "41.00.00.40"}, {
    "id": 2462,
    "label": "41.00.00.41"
}, {"id": 2463, "label": "41.00.00.42"}, {"id": 2464, "label": "41.00.00.43"}, {
    "id": 2465,
    "label": "41.00.00.44"
}, {"id": 2466, "label": "41.00.00.45"}, {"id": 2467, "label": "41.00.00.46"}, {
    "id": 2468,
    "label": "41.00.00.47"
}, {"id": 2469, "label": "41.00.00.48"}, {"id": 2470, "label": "41.00.00.49"}, {
    "id": 2471,
    "label": "41.00.00.50"
}, {"id": 2472, "label": "41.00.00.51"}, {"id": 2473, "label": "41.00.00.52"}, {
    "id": 2474,
    "label": "41.00.00.53"
}, {"id": 2475, "label": "41.00.00.54"}, {"id": 2476, "label": "41.00.00.55"}, {
    "id": 2477,
    "label": "41.00.00.56"
}, {"id": 2478, "label": "41.00.00.57"}, {"id": 2479, "label": "41.00.00.58"}, {
    "id": 2480,
    "label": "42.00.00.01"
}, {"id": 2481, "label": "42.00.00.02"}, {"id": 2482, "label": "42.00.00.03"}, {
    "id": 2483,
    "label": "42.01.00.01"
}, {"id": 2484, "label": "42.01.00.02"}, {"id": 2485, "label": "42.01.00.03"}, {
    "id": 2486,
    "label": "42.01.00.04"
}, {"id": 2487, "label": "42.01.00.05"}, {"id": 2488, "label": "42.01.00.06"}, {
    "id": 2489,
    "label": "42.01.00.07"
}, {"id": 2490, "label": "42.01.00.08"}, {"id": 2491, "label": "42.01.00.09"}, {
    "id": 2492,
    "label": "42.01.00.10"
}, {"id": 2493, "label": "42.01.00.11"}, {"id": 2494, "label": "42.01.00.12"}, {
    "id": 2495,
    "label": "42.01.00.13"
}, {"id": 2496, "label": "42.02.00.01"}, {"id": 2497, "label": "42.02.00.02"}, {
    "id": 2498,
    "label": "42.02.00.03"
}, {"id": 2499, "label": "42.02.00.04"}, {"id": 2500, "label": "42.02.00.05"}, {
    "id": 2501,
    "label": "42.02.00.06"
}, {"id": 2502, "label": "42.02.00.07"}, {"id": 2503, "label": "42.02.00.08"}, {
    "id": 2504,
    "label": "42.02.00.09"
}, {"id": 2505, "label": "42.02.00.10"}, {"id": 2506, "label": "42.02.00.11"}, {
    "id": 2507,
    "label": "42.02.00.12"
}, {"id": 2508, "label": "42.02.00.13"}, {"id": 2509, "label": "42.02.00.14"}, {
    "id": 2510,
    "label": "42.02.00.15"
}, {"id": 2511, "label": "42.02.00.16"}, {"id": 2512, "label": "42.02.00.17"}, {
    "id": 2513,
    "label": "42.02.00.18"
}, {"id": 2514, "label": "42.02.00.19"}, {"id": 2515, "label": "42.02.00.20"}, {
    "id": 2516,
    "label": "42.03.00.01"
}, {"id": 2517, "label": "42.03.00.02"}, {"id": 2518, "label": "42.03.00.03"}, {
    "id": 2519,
    "label": "42.03.00.04"
}, {"id": 2520, "label": "42.03.00.05"}, {"id": 2521, "label": "42.03.00.06"}, {
    "id": 2522,
    "label": "42.03.00.07"
}, {"id": 2523, "label": "42.03.00.08"}, {"id": 2524, "label": "42.03.00.09"}, {
    "id": 2525,
    "label": "42.04.00.01"
}, {"id": 2526, "label": "42.04.00.02"}, {"id": 2527, "label": "42.04.00.03"}, {
    "id": 2528,
    "label": "42.04.00.04"
}, {"id": 2529, "label": "42.04.00.05"}, {"id": 2530, "label": "42.04.00.06"}, {
    "id": 2531,
    "label": "42.04.00.07"
}, {"id": 2532, "label": "42.04.00.08"}, {"id": 2533, "label": "42.04.00.09"}, {
    "id": 2534,
    "label": "42.04.00.10"
}, {"id": 2535, "label": "42.04.00.11"}, {"id": 2536, "label": "42.04.00.12"}, {
    "id": 2537,
    "label": "42.04.00.13"
}, {"id": 2538, "label": "42.04.00.14"}, {"id": 2539, "label": "42.04.00.15"}, {
    "id": 2540,
    "label": "42.04.00.16"
}, {"id": 2541, "label": "42.04.00.17"}, {"id": 2542, "label": "42.04.00.18"}, {
    "id": 2543,
    "label": "42.04.00.19"
}, {"id": 2544, "label": "42.04.00.20"}, {"id": 2545, "label": "42.04.00.21"}, {
    "id": 2546,
    "label": "42.04.00.22"
}, {"id": 2547, "label": "42.05.00.01"}, {"id": 2548, "label": "42.05.00.02"}, {
    "id": 2549,
    "label": "42.05.00.03"
}, {"id": 2550, "label": "42.05.00.04"}, {"id": 2551, "label": "42.05.00.05"}, {
    "id": 2552,
    "label": "42.05.00.06"
}, {"id": 2553, "label": "42.05.00.07"}, {"id": 2554, "label": "42.05.00.08"}, {
    "id": 2555,
    "label": "42.06.00.01"
}, {"id": 2556, "label": "42.06.00.02"}, {"id": 2557, "label": "42.06.00.03"}, {
    "id": 2558,
    "label": "42.06.00.04"
}, {"id": 2559, "label": "42.06.00.05"}, {"id": 2560, "label": "42.06.00.06"}, {
    "id": 2561,
    "label": "42.07.00.01"
}, {"id": 2562, "label": "43.00.00.01"}, {"id": 2563, "label": "43.00.00.02"}, {
    "id": 2564,
    "label": "43.00.00.03"
}, {"id": 2565, "label": "43.00.00.04"}, {"id": 2566, "label": "43.00.00.05"}, {
    "id": 2567,
    "label": "43.01.00.01"
}, {"id": 2568, "label": "43.01.00.02"}, {"id": 2569, "label": "43.01.00.03"}, {
    "id": 2570,
    "label": "43.01.00.04"
}, {"id": 2571, "label": "43.01.00.05"}, {"id": 2572, "label": "43.01.00.06"}, {
    "id": 2573,
    "label": "43.02.00.01"
}, {"id": 2574, "label": "43.02.00.02"}, {"id": 2575, "label": "43.02.00.03"}, {
    "id": 2576,
    "label": "44.00.00.01"
}, {"id": 2577, "label": "44.00.00.02"}, {"id": 2578, "label": "44.00.00.03"}, {
    "id": 2579,
    "label": "44.00.00.04"
}, {"id": 2580, "label": "44.00.00.05"}, {"id": 2581, "label": "44.00.00.06"}, {
    "id": 2582,
    "label": "44.00.00.07"
}, {"id": 2583, "label": "44.00.00.08"}, {"id": 2584, "label": "44.00.00.09"}, {
    "id": 2585,
    "label": "44.00.00.10"
}, {"id": 2586, "label": "44.00.00.11"}, {"id": 2587, "label": "44.00.00.12"}, {
    "id": 2588,
    "label": "44.00.00.13"
}, {"id": 2589, "label": "44.00.00.14"}, {"id": 2590, "label": "45.00.00.01"}, {
    "id": 2591,
    "label": "45.00.00.02"
}, {"id": 2592, "label": "45.00.00.03"}, {"id": 2593, "label": "45.00.00.04"}, {
    "id": 2594,
    "label": "45.00.00.05"
}, {"id": 2595, "label": "45.00.00.06"}, {"id": 2596, "label": "45.00.00.07"}, {
    "id": 2597,
    "label": "45.01.00.01"
}, {"id": 2598, "label": "45.01.00.02"}, {"id": 2599, "label": "45.01.00.03"}, {
    "id": 2600,
    "label": "45.01.00.04"
}, {"id": 2601, "label": "45.01.00.05"}, {"id": 2602, "label": "45.01.00.06"}, {
    "id": 2603,
    "label": "45.01.00.07"
}, {"id": 2604, "label": "45.01.00.08"}, {"id": 2605, "label": "45.01.00.09"}, {
    "id": 2606,
    "label": "45.02.00.01"
}, {"id": 2607, "label": "45.02.00.02"}, {"id": 2608, "label": "45.02.00.03"}, {
    "id": 2609,
    "label": "45.02.00.04"
}, {"id": 2610, "label": "45.02.00.05"}, {"id": 2611, "label": "45.02.00.06"}, {
    "id": 2612,
    "label": "45.02.00.07"
}, {"id": 2613, "label": "45.02.00.08"}, {"id": 2614, "label": "45.03.00.01"}, {
    "id": 2615,
    "label": "45.03.00.02"
}, {"id": 2616, "label": "45.04.00.01"}, {"id": 2617, "label": "45.04.00.02"}, {
    "id": 2618,
    "label": "45.04.00.03"
}, {"id": 2619, "label": "45.04.00.04"}, {"id": 2620, "label": "45.04.00.05"}, {
    "id": 2621,
    "label": "45.04.00.06"
}, {"id": 2622, "label": "45.04.00.07"}, {"id": 2623, "label": "45.04.00.08"}, {
    "id": 2624,
    "label": "45.04.00.09"
}, {"id": 2625, "label": "45.04.00.10"}, {"id": 2626, "label": "45.04.00.11"}, {
    "id": 2627,
    "label": "45.04.00.12"
}, {"id": 2628, "label": "45.04.00.13"}, {"id": 2629, "label": "45.04.00.14"}, {
    "id": 2630,
    "label": "45.05.00.01"
}, {"id": 2631, "label": "45.05.00.02"}, {"id": 2632, "label": "45.05.00.03"}, {
    "id": 2633,
    "label": "45.05.00.04"
}, {"id": 2634, "label": "45.05.00.05"}, {"id": 2635, "label": "45.05.00.06"}, {
    "id": 2636,
    "label": "45.05.00.07"
}, {"id": 2637, "label": "45.05.00.08"}, {"id": 2638, "label": "45.06.00.01"}, {
    "id": 2639,
    "label": "45.06.00.02"
}, {"id": 2640, "label": "45.06.00.03"}, {"id": 2641, "label": "45.06.00.04"}, {
    "id": 2642,
    "label": "45.06.00.05"
}, {"id": 2643, "label": "45.06.00.06"}, {"id": 2644, "label": "45.06.00.07"}, {
    "id": 2645,
    "label": "45.06.00.08"
}, {"id": 2646, "label": "45.06.00.09"}, {"id": 2647, "label": "45.07.00.01"}, {
    "id": 2648,
    "label": "45.07.00.02"
}, {"id": 2649, "label": "45.07.00.03"}, {"id": 2650, "label": "45.07.00.04"}, {
    "id": 2651,
    "label": "45.07.00.05"
}, {"id": 2652, "label": "45.07.00.06"}, {"id": 2653, "label": "45.07.00.07"}, {
    "id": 2654,
    "label": "45.08.00.01"
}, {"id": 2655, "label": "45.08.00.02"}, {"id": 2656, "label": "45.08.00.03"}, {
    "id": 2657,
    "label": "45.08.00.04"
}, {"id": 2658, "label": "45.08.00.05"}, {"id": 2659, "label": "45.08.00.06"}, {
    "id": 2660,
    "label": "45.08.00.07"
}, {"id": 2661, "label": "45.08.00.08"}, {"id": 2662, "label": "45.08.00.09"}, {
    "id": 2663,
    "label": "45.08.00.10"
}, {"id": 2664, "label": "45.08.00.11"}, {"id": 2665, "label": "45.08.00.12"}, {
    "id": 2666,
    "label": "45.09.00.01"
}, {"id": 2667, "label": "45.09.00.02"}, {"id": 2668, "label": "45.09.00.03"}, {
    "id": 2669,
    "label": "45.09.00.04"
}, {"id": 2670, "label": "45.09.00.05"}, {"id": 2671, "label": "45.09.00.06"}, {
    "id": 2672,
    "label": "45.09.00.07"
}, {"id": 2673, "label": "45.09.00.08"}, {"id": 2674, "label": "45.09.00.09"}, {
    "id": 2675,
    "label": "45.09.00.10"
}, {"id": 2676, "label": "45.09.00.11"}, {"id": 2677, "label": "45.09.00.12"}, {
    "id": 2678,
    "label": "45.09.00.13"
}, {"id": 2679, "label": "46.00.00.01"}, {"id": 2680, "label": "46.00.00.02"}, {
    "id": 2681,
    "label": "46.00.00.03"
}, {"id": 2682, "label": "46.00.00.04"}, {"id": 2683, "label": "46.00.00.05"}, {
    "id": 2684,
    "label": "46.00.00.06"
}, {"id": 2685, "label": "46.00.00.07"}, {"id": 2686, "label": "46.01.00.01"}, {
    "id": 2687,
    "label": "46.01.00.02"
}, {"id": 2688, "label": "46.01.00.03"}, {"id": 2689, "label": "46.01.00.04"}, {
    "id": 2690,
    "label": "46.01.00.05"
}, {"id": 2691, "label": "46.01.00.06"}, {"id": 2692, "label": "46.01.00.07"}, {
    "id": 2693,
    "label": "46.01.00.08"
}, {"id": 2694, "label": "46.01.00.09"}, {"id": 2695, "label": "46.01.00.10"}, {
    "id": 2696,
    "label": "46.01.00.11"
}, {"id": 2697, "label": "46.01.00.12"}, {"id": 2698, "label": "46.01.00.13"}, {
    "id": 2699,
    "label": "46.01.00.14"
}, {"id": 2700, "label": "46.01.00.15"}, {"id": 2701, "label": "46.01.00.16"}, {
    "id": 2702,
    "label": "46.01.00.17"
}, {"id": 2703, "label": "46.01.00.18"}, {"id": 2704, "label": "46.01.00.19"}, {
    "id": 2705,
    "label": "46.01.00.20"
}, {"id": 2706, "label": "46.01.00.21"}, {"id": 2707, "label": "46.01.00.22"}, {
    "id": 2708,
    "label": "46.01.00.23"
}, {"id": 2709, "label": "46.02.00.01"}, {"id": 2710, "label": "46.02.00.02"}, {
    "id": 2711,
    "label": "46.02.00.03"
}, {"id": 2712, "label": "46.02.00.04"}, {"id": 2713, "label": "46.02.00.05"}, {
    "id": 2714,
    "label": "46.02.00.06"
}, {"id": 2715, "label": "46.02.00.07"}, {"id": 2716, "label": "46.02.00.08"}, {
    "id": 2717,
    "label": "46.02.00.09"
}, {"id": 2718, "label": "46.02.00.10"}, {"id": 2719, "label": "46.02.00.11"}, {
    "id": 2720,
    "label": "46.02.00.12"
}, {"id": 2721, "label": "46.02.00.13"}, {"id": 2722, "label": "46.02.00.14"}, {
    "id": 2723,
    "label": "46.02.00.15"
}, {"id": 2724, "label": "46.03.00.01"}, {"id": 2725, "label": "46.03.00.02"}, {
    "id": 2726,
    "label": "46.03.00.03"
}, {"id": 2727, "label": "46.03.00.04"}, {"id": 2728, "label": "46.03.00.05"}, {
    "id": 2729,
    "label": "46.03.00.06"
}, {"id": 2730, "label": "46.03.00.07"}, {"id": 2731, "label": "46.03.00.08"}, {
    "id": 2732,
    "label": "46.03.00.09"
}, {"id": 2733, "label": "46.03.00.10"}, {"id": 2734, "label": "46.03.00.11"}, {
    "id": 2735,
    "label": "46.04.00.01"
}, {"id": 2736, "label": "46.04.00.02"}, {"id": 2737, "label": "46.04.00.03"}, {
    "id": 2738,
    "label": "46.04.00.04"
}, {"id": 2739, "label": "46.04.00.05"}, {"id": 2740, "label": "46.04.00.06"}, {
    "id": 2741,
    "label": "46.04.00.07"
}, {"id": 2742, "label": "46.04.00.08"}, {"id": 2743, "label": "46.04.00.09"}, {
    "id": 2744,
    "label": "46.04.00.10"
}, {"id": 2745, "label": "46.04.00.11"}, {"id": 2746, "label": "46.05.00.01"}, {
    "id": 2747,
    "label": "46.05.00.02"
}, {"id": 2748, "label": "46.05.00.03"}, {"id": 2749, "label": "46.05.00.04"}, {
    "id": 2750,
    "label": "46.05.00.05"
}, {"id": 2751, "label": "46.05.00.06"}, {"id": 2752, "label": "46.05.00.07"}, {
    "id": 2753,
    "label": "46.05.00.08"
}, {"id": 2754, "label": "46.05.00.09"}, {"id": 2755, "label": "46.05.00.10"}, {
    "id": 2756,
    "label": "46.05.00.11"
}, {"id": 2757, "label": "46.05.00.12"}, {"id": 2758, "label": "46.05.00.13"}, {
    "id": 2759,
    "label": "46.05.00.14"
}, {"id": 2760, "label": "46.05.00.15"}, {"id": 2761, "label": "46.06.00.01"}, {
    "id": 2762,
    "label": "46.06.00.02"
}, {"id": 2763, "label": "46.06.00.03"}, {"id": 2764, "label": "46.06.00.04"}, {
    "id": 2765,
    "label": "46.06.00.05"
}, {"id": 2766, "label": "46.06.00.06"}, {"id": 2767, "label": "46.06.00.07"}, {
    "id": 2768,
    "label": "46.06.00.08"
}, {"id": 2769, "label": "46.06.00.09"}, {"id": 2770, "label": "46.06.00.10"}, {
    "id": 2771,
    "label": "46.06.00.11"
}, {"id": 2772, "label": "46.06.00.12"}, {"id": 2773, "label": "46.06.00.13"}, {
    "id": 2774,
    "label": "46.07.00.01"
}, {"id": 2775, "label": "46.07.00.02"}, {"id": 2776, "label": "46.07.00.03"}, {
    "id": 2777,
    "label": "46.07.00.04"
}, {"id": 2778, "label": "46.07.00.05"}, {"id": 2779, "label": "46.07.00.06"}, {
    "id": 2780,
    "label": "46.07.00.07"
}, {"id": 2781, "label": "46.07.00.08"}, {"id": 2782, "label": "46.07.00.09"}, {
    "id": 2783,
    "label": "46.07.00.10"
}, {"id": 2784, "label": "46.07.00.11"}, {"id": 2785, "label": "46.07.00.12"}, {
    "id": 2786,
    "label": "46.07.00.13"
}, {"id": 2787, "label": "46.07.00.14"}, {"id": 2788, "label": "46.07.00.15"}, {
    "id": 2789,
    "label": "46.07.00.16"
}, {"id": 2790, "label": "46.07.00.17"}, {"id": 2791, "label": "46.08.00.01"}, {
    "id": 2792,
    "label": "46.08.00.02"
}, {"id": 2793, "label": "46.08.01.01"}, {"id": 2794, "label": "46.08.01.02"}, {
    "id": 2795,
    "label": "46.08.01.03"
}, {"id": 2796, "label": "46.08.01.04"}, {"id": 2797, "label": "46.08.01.05"}, {
    "id": 2798,
    "label": "46.08.01.06"
}, {"id": 2799, "label": "46.08.01.07"}, {"id": 2800, "label": "46.08.01.08"}, {
    "id": 2801,
    "label": "46.08.01.09"
}, {"id": 2802, "label": "46.08.01.10"}, {"id": 2803, "label": "46.08.01.11"}, {
    "id": 2804,
    "label": "46.08.01.12"
}, {"id": 2805, "label": "46.08.01.13"}, {"id": 2806, "label": "46.08.01.14"}, {
    "id": 2807,
    "label": "46.08.01.15"
}, {"id": 2808, "label": "46.08.01.16"}, {"id": 2809, "label": "46.08.01.17"}, {
    "id": 2810,
    "label": "46.08.01.18"
}, {"id": 2811, "label": "46.08.01.19"}, {"id": 2812, "label": "46.08.01.20"}, {
    "id": 2813,
    "label": "46.08.01.21"
}, {"id": 2814, "label": "46.09.00.01"}, {"id": 2815, "label": "46.09.00.02"}, {
    "id": 2816,
    "label": "46.09.00.03"
}, {"id": 2817, "label": "46.09.00.04"}, {"id": 2818, "label": "46.09.01.01"}, {
    "id": 2819,
    "label": "46.09.01.02"
}, {"id": 2820, "label": "46.09.01.03"}, {"id": 2821, "label": "46.09.01.04"}, {
    "id": 2822,
    "label": "46.09.02.01"
}, {"id": 2823, "label": "46.09.03.01"}, {"id": 2824, "label": "46.09.03.02"}, {
    "id": 2825,
    "label": "46.09.03.03"
}, {"id": 2826, "label": "46.09.03.04"}, {"id": 2827, "label": "46.10.00.01"}, {
    "id": 2828,
    "label": "46.10.00.02"
}, {"id": 2829, "label": "46.10.00.03"}, {"id": 2830, "label": "46.10.00.04"}, {
    "id": 2831,
    "label": "46.10.00.05"
}, {"id": 2832, "label": "46.10.00.06"}, {"id": 2833, "label": "46.10.00.07"}, {
    "id": 2834,
    "label": "46.10.00.08"
}, {"id": 2835, "label": "46.10.00.09"}, {"id": 2836, "label": "46.10.00.10"}, {
    "id": 2837,
    "label": "46.10.00.11"
}, {"id": 2838, "label": "46.10.00.12"}, {"id": 2839, "label": "46.10.00.13"}, {
    "id": 2840,
    "label": "46.10.00.14"
}, {"id": 2841, "label": "46.10.00.15"}, {"id": 2842, "label": "46.10.00.16"}, {
    "id": 2843,
    "label": "46.10.00.17"
}, {"id": 2844, "label": "46.10.00.18"}, {"id": 2845, "label": "46.10.00.19"}, {
    "id": 2846,
    "label": "46.10.00.20"
}, {"id": 2847, "label": "46.10.00.21"}, {"id": 2848, "label": "46.10.00.22"}, {
    "id": 2849,
    "label": "46.10.00.23"
}, {"id": 2850, "label": "46.10.00.24"}, {"id": 2851, "label": "46.11.00.01"}, {
    "id": 2852,
    "label": "46.11.00.02"
}, {"id": 2853, "label": "46.11.00.03"}, {"id": 2854, "label": "46.11.00.04"}, {
    "id": 2855,
    "label": "46.11.00.05"
}, {"id": 2856, "label": "46.11.00.06"}, {"id": 2857, "label": "46.11.00.07"}, {
    "id": 2858,
    "label": "46.11.00.08"
}, {"id": 2859, "label": "46.11.00.09"}, {"id": 2860, "label": "46.11.00.10"}, {
    "id": 2861,
    "label": "46.11.00.11"
}, {"id": 2862, "label": "46.12.00.01"}, {"id": 2863, "label": "46.12.00.02"}, {
    "id": 2864,
    "label": "46.12.00.03"
}, {"id": 2865, "label": "46.12.00.04"}, {"id": 2866, "label": "46.12.00.05"}, {
    "id": 2867,
    "label": "46.12.00.06"
}, {"id": 2868, "label": "46.12.00.07"}, {"id": 2869, "label": "46.12.00.08"}, {
    "id": 2870,
    "label": "46.12.00.09"
}, {"id": 2871, "label": "46.12.00.10"}, {"id": 2872, "label": "46.12.00.11"}, {
    "id": 2873,
    "label": "46.12.00.12"
}, {"id": 2874, "label": "46.12.00.13"}, {"id": 2875, "label": "46.12.00.14"}, {
    "id": 2876,
    "label": "47.00.00.01"
}, {"id": 2877, "label": "47.00.00.02"}, {"id": 2878, "label": "47.00.00.03"}, {
    "id": 2879,
    "label": "47.00.00.04"
}, {"id": 2880, "label": "47.00.00.05"}, {"id": 2881, "label": "47.00.00.06"}, {
    "id": 2882,
    "label": "47.00.00.07"
}, {"id": 2883, "label": "47.00.00.08"}, {"id": 2884, "label": "47.00.00.09"}, {
    "id": 2885,
    "label": "47.00.00.10"
}, {"id": 2886, "label": "47.00.00.11"}, {"id": 2887, "label": "47.00.00.12"}, {
    "id": 2888,
    "label": "47.00.00.13"
}, {"id": 2889, "label": "47.00.00.14"}, {"id": 2890, "label": "47.00.00.15"}, {
    "id": 2891,
    "label": "47.00.00.16"
}, {"id": 2892, "label": "47.00.00.17"}, {"id": 2893, "label": "47.00.00.18"}, {
    "id": 2894,
    "label": "47.00.00.19"
}, {"id": 2895, "label": "47.00.00.20"}, {"id": 2896, "label": "47.00.00.21"}, {
    "id": 2897,
    "label": "47.00.00.22"
}, {"id": 2898, "label": "47.00.00.23"}, {"id": 2899, "label": "47.00.00.24"}, {
    "id": 2900,
    "label": "47.00.00.25"
}, {"id": 2901, "label": "47.00.00.26"}, {"id": 2902, "label": "47.00.00.27"}, {
    "id": 2903,
    "label": "47.00.00.28"
}, {"id": 2904, "label": "47.00.00.29"}, {"id": 2905, "label": "47.00.00.30"}, {
    "id": 2906,
    "label": "47.00.00.31"
}, {"id": 2907, "label": "47.00.00.32"}, {"id": 2908, "label": "47.00.00.33"}, {
    "id": 2909,
    "label": "47.00.00.34"
}, {"id": 2910, "label": "47.00.00.35"}, {"id": 2911, "label": "47.00.00.36"}, {
    "id": 2912,
    "label": "47.00.00.37"
}, {"id": 2913, "label": "47.00.00.38"}, {"id": 2914, "label": "47.00.00.39"}, {
    "id": 2915,
    "label": "47.00.00.40"
}, {"id": 2916, "label": "47.00.00.41"}, {"id": 2917, "label": "47.00.00.42"}, {
    "id": 2918,
    "label": "48.00.00.01"
}, {"id": 2919, "label": "48.00.00.02"}, {"id": 2920, "label": "48.00.00.03"}, {
    "id": 2921,
    "label": "48.00.00.04"
}, {"id": 2922, "label": "48.00.00.05"}, {"id": 2923, "label": "48.00.00.06"}, {
    "id": 2924,
    "label": "48.00.00.07"
}, {"id": 2925, "label": "48.00.00.08"}, {"id": 2926, "label": "48.00.00.09"}, {
    "id": 2927,
    "label": "48.00.00.10"
}, {"id": 2928, "label": "48.00.00.11"}, {"id": 2929, "label": "48.00.00.12"}, {
    "id": 2930,
    "label": "48.00.00.13"
}, {"id": 2931, "label": "48.00.00.14"}, {"id": 2932, "label": "50.00.00.01"}, {
    "id": 2933,
    "label": "50.00.00.02"
}, {"id": 2934, "label": "50.00.00.03"}, {"id": 2935, "label": "50.00.00.04"}, {
    "id": 2936,
    "label": "50.00.00.05"
}, {"id": 2937, "label": "50.00.00.06"}, {"id": 2938, "label": "50.00.00.07"}, {
    "id": 2939,
    "label": "50.00.00.08"
}, {"id": 2940, "label": "50.00.00.09"}, {"id": 2941, "label": "50.00.00.10"}, {
    "id": 2942,
    "label": "50.00.00.11"
}, {"id": 2943, "label": "50.00.00.12"}, {"id": 2944, "label": "50.00.00.13"}, {
    "id": 2945,
    "label": "50.00.00.14"
}, {"id": 2946, "label": "50.00.00.15"}, {"id": 2947, "label": "50.00.00.16"}, {
    "id": 2948,
    "label": "50.00.00.17"
}, {"id": 2949, "label": "50.00.00.18"}, {"id": 2950, "label": "50.00.00.19"}, {
    "id": 2951,
    "label": "50.00.00.20"
}, {"id": 2952, "label": "50.00.00.21"}, {"id": 2953, "label": "50.00.00.22"}, {
    "id": 2954,
    "label": "50.01.00.01"
}, {"id": 2955, "label": "50.01.00.02"}, {"id": 2956, "label": "50.01.00.03"}, {
    "id": 2957,
    "label": "50.01.00.04"
}, {"id": 2958, "label": "50.01.00.05"}, {"id": 2959, "label": "50.01.00.06"}, {
    "id": 2960,
    "label": "50.01.00.07"
}, {"id": 2961, "label": "50.01.00.08"}, {"id": 2962, "label": "50.02.00.01"}, {
    "id": 2963,
    "label": "50.02.00.02"
}, {"id": 2964, "label": "50.02.00.03"}, {"id": 2965, "label": "50.02.00.04"}, {
    "id": 2966,
    "label": "50.02.00.05"
}, {"id": 2967, "label": "50.02.00.06"}, {"id": 2968, "label": "50.02.01.01"}, {
    "id": 2969,
    "label": "50.02.01.02"
}, {"id": 2970, "label": "50.02.01.03"}, {"id": 2971, "label": "50.02.01.04"}, {
    "id": 2972,
    "label": "50.02.02.01"
}, {"id": 2973, "label": "50.02.02.02"}, {"id": 2974, "label": "50.02.03.01"}, {
    "id": 2975,
    "label": "50.02.03.02"
}, {"id": 2976, "label": "50.02.03.03"}, {"id": 2977, "label": "50.02.04.01"}, {
    "id": 2978,
    "label": "50.02.04.02"
}, {"id": 2979, "label": "50.02.04.03"}, {"id": 2980, "label": "50.02.04.04"}, {
    "id": 2981,
    "label": "50.02.04.05"
}, {"id": 2982, "label": "50.02.04.06"}, {"id": 2983, "label": "50.02.04.07"}, {
    "id": 2984,
    "label": "50.02.04.08"
}, {"id": 2985, "label": "50.02.04.09"}, {"id": 2986, "label": "50.03.00.01"}, {
    "id": 2987,
    "label": "50.03.00.02"
}, {"id": 2988, "label": "50.03.00.03"}, {"id": 2989, "label": "50.03.01.01"}, {
    "id": 2990,
    "label": "50.03.01.02"
}, {"id": 2991, "label": "50.03.01.03"}, {"id": 2992, "label": "60.00.00.01"}, {
    "id": 2993,
    "label": "60.00.00.02"
}, {"id": 2994, "label": "60.00.00.03"}, {"id": 2995, "label": "60.00.00.04"}, {
    "id": 2996,
    "label": "60.00.00.05"
}, {"id": 2997, "label": "60.00.00.06"}, {"id": 2998, "label": "60.00.00.07"}, {
    "id": 2999,
    "label": "60.00.00.08"
}, {"id": 3000, "label": "60.00.00.09"}, {"id": 3001, "label": "60.00.00.10"}, {
    "id": 3002,
    "label": "60.00.00.11"
}, {"id": 3003, "label": "60.00.00.12"}, {"id": 3004, "label": "60.00.00.13"}, {
    "id": 3005,
    "label": "60.00.00.14"
}, {"id": 3006, "label": "60.00.00.15"}, {"id": 3007, "label": "60.00.00.16"}, {
    "id": 3008,
    "label": "60.00.00.17"
}, {"id": 3009, "label": "60.00.00.18"}, {"id": 3010, "label": "60.00.00.19"}, {
    "id": 3011,
    "label": "60.00.00.20"
}, {"id": 3012, "label": "60.00.00.21"}, {"id": 3013, "label": "60.00.00.22"}, {
    "id": 3014,
    "label": "60.00.00.23"
}, {"id": 3015, "label": "60.00.00.24"}, {"id": 3016, "label": "60.00.00.25"}, {
    "id": 3017,
    "label": "60.01.00.01"
}, {"id": 3018, "label": "60.01.00.02"}, {"id": 3019, "label": "60.01.00.03"}, {
    "id": 3020,
    "label": "60.01.00.04"
}, {"id": 3021, "label": "60.02.00.01"}, {"id": 3022, "label": "60.02.00.02"}, {
    "id": 3023,
    "label": "60.02.00.03"
}, {"id": 3024, "label": "60.02.00.04"}, {"id": 3025, "label": "60.02.00.05"}, {
    "id": 3026,
    "label": "60.02.00.06"
}, {"id": 3027, "label": "60.02.00.07"}, {"id": 3028, "label": "60.02.00.08"}, {
    "id": 3029,
    "label": "60.02.00.09"
}, {"id": 3030, "label": "60.02.00.10"}, {"id": 3031, "label": "60.02.00.11"}, {
    "id": 3032,
    "label": "60.02.00.12"
}, {"id": 3033, "label": "60.02.00.13"}, {"id": 3034, "label": "60.02.00.14"}, {
    "id": 3035,
    "label": "60.03.00.01"
}, {"id": 3036, "label": "60.03.00.02"}, {"id": 3037, "label": "60.03.00.03"}, {
    "id": 3038,
    "label": "60.03.00.04"
}, {"id": 3039, "label": "60.03.00.05"}, {"id": 3040, "label": "60.03.00.06"}, {
    "id": 3041,
    "label": "60.03.00.07"
}, {"id": 3042, "label": "60.03.00.08"}, {"id": 3043, "label": "60.03.00.09"}, {
    "id": 3044,
    "label": "60.03.00.10"
}, {"id": 3045, "label": "60.03.00.11"}, {"id": 3046, "label": "60.03.00.12"}, {
    "id": 3047,
    "label": "60.03.00.13"
}, {"id": 3048, "label": "60.03.00.14"}, {"id": 3049, "label": "60.03.00.15"}, {
    "id": 3050,
    "label": "60.03.00.16"
}, {"id": 3051, "label": "60.03.00.17"}, {"id": 3052, "label": "60.03.00.18"}, {
    "id": 3053,
    "label": "60.03.00.19"
}, {"id": 3054, "label": "60.03.00.20"}, {"id": 3055, "label": "60.03.00.21"}, {
    "id": 3056,
    "label": "60.03.00.22"
}, {"id": 3057, "label": "60.03.00.23"}, {"id": 3058, "label": "60.03.00.24"}, {
    "id": 3059,
    "label": "60.03.00.25"
}, {"id": 3060, "label": "60.03.00.26"}, {"id": 3061, "label": "60.03.00.27"}, {
    "id": 3062,
    "label": "60.03.00.28"
}, {"id": 3063, "label": "60.03.00.29"}, {"id": 3064, "label": "60.03.00.30"}, {
    "id": 3065,
    "label": "60.03.00.31"
}, {"id": 3066, "label": "60.03.00.32"}, {"id": 3067, "label": "60.03.00.33"}, {
    "id": 3068,
    "label": "60.03.00.34"
}, {"id": 3069, "label": "60.03.00.35"}, {"id": 3070, "label": "60.03.00.36"}, {
    "id": 3071,
    "label": "60.03.00.37"
}, {"id": 3072, "label": "60.03.00.38"}, {"id": 3073, "label": "60.03.00.39"}, {
    "id": 3074,
    "label": "60.03.00.40"
}, {"id": 3075, "label": "60.03.00.41"}, {"id": 3076, "label": "60.03.00.42"}, {
    "id": 3077,
    "label": "60.03.00.43"
}, {"id": 3078, "label": "60.03.00.44"}, {"id": 3079, "label": "60.03.00.45"}, {
    "id": 3080,
    "label": "60.03.00.46"
}, {"id": 3081, "label": "60.03.00.47"}, {"id": 3082, "label": "60.03.00.48"}, {
    "id": 3083,
    "label": "60.03.00.49"
}, {"id": 3084, "label": "60.04.00.01"}, {"id": 3085, "label": "60.04.00.02"}, {
    "id": 3086,
    "label": "60.04.00.03"
}, {"id": 3087, "label": "60.04.00.04"}, {"id": 3088, "label": "60.04.00.05"}, {
    "id": 3089,
    "label": "60.04.00.06"
}, {"id": 3090, "label": "60.04.00.07"}, {"id": 3091, "label": "60.04.00.08"}, {
    "id": 3092,
    "label": "60.04.00.09"
}, {"id": 3093, "label": "60.04.00.10"}, {"id": 3094, "label": "60.04.00.11"}, {
    "id": 3095,
    "label": "60.04.00.12"
}, {"id": 3096, "label": "60.04.00.13"}, {"id": 3097, "label": "60.04.00.14"}, {
    "id": 3098,
    "label": "60.04.00.15"
}, {"id": 3099, "label": "60.04.00.16"}, {"id": 3100, "label": "60.04.00.17"}, {
    "id": 3101,
    "label": "60.04.00.18"
}, {"id": 3102, "label": "60.04.00.19"}, {"id": 3103, "label": "60.04.00.20"}, {
    "id": 3104,
    "label": "60.04.00.21"
}, {"id": 3105, "label": "60.04.00.22"}, {"id": 3106, "label": "60.04.00.23"}, {
    "id": 3107,
    "label": "60.05.00.01"
}, {"id": 3108, "label": "60.05.00.02"}, {"id": 3109, "label": "60.05.00.03"}, {
    "id": 3110,
    "label": "60.05.00.04"
}, {"id": 3111, "label": "60.06.00.01"}, {"id": 3112, "label": "60.06.00.02"}, {
    "id": 3113,
    "label": "60.06.00.03"
}, {"id": 3114, "label": "60.06.00.04"}, {"id": 3115, "label": "60.06.00.05"}, {
    "id": 3116,
    "label": "60.06.00.06"
}, {"id": 3117, "label": "60.06.00.07"}, {"id": 3118, "label": "60.06.00.08"}, {
    "id": 3119,
    "label": "60.07.00.01"
}, {"id": 3120, "label": "60.07.00.02"}, {"id": 3121, "label": "60.07.00.03"}, {
    "id": 3122,
    "label": "60.07.00.04"
}, {"id": 3123, "label": "60.07.00.05"}, {"id": 3124, "label": "60.07.00.06"}, {
    "id": 3125,
    "label": "60.07.00.07"
}, {"id": 3126, "label": "60.07.00.08"}, {"id": 3127, "label": "60.07.00.09"}, {
    "id": 3128,
    "label": "60.07.00.10"
}, {"id": 3129, "label": "60.07.00.11"}, {"id": 3130, "label": "60.07.00.12"}, {
    "id": 3131,
    "label": "60.08.00.01"
}, {"id": 3132, "label": "60.08.00.02"}, {"id": 3133, "label": "60.08.00.03"}, {
    "id": 3134,
    "label": "60.08.00.04"
}, {"id": 3135, "label": "60.08.00.05"}, {"id": 3136, "label": "60.08.00.06"}, {
    "id": 3137,
    "label": "60.09.00.01"
}, {"id": 3138, "label": "60.09.00.02"}, {"id": 3139, "label": "60.09.00.03"}, {
    "id": 3140,
    "label": "60.09.00.04"
}, {"id": 3141, "label": "60.09.00.05"}, {"id": 3142, "label": "61.00.00.01"}, {
    "id": 3143,
    "label": "61.00.00.02"
}, {"id": 3144, "label": "61.00.00.03"}, {"id": 3145, "label": "61.00.00.04"}, {
    "id": 3146,
    "label": "61.00.00.05"
}, {"id": 3147, "label": "61.00.00.06"}, {"id": 3148, "label": "61.01.00.01"}, {
    "id": 3149,
    "label": "61.01.00.02"
}, {"id": 3150, "label": "61.01.00.03"}, {"id": 3151, "label": "61.01.00.04"}, {
    "id": 3152,
    "label": "61.02.00.01"
}, {"id": 3153, "label": "61.02.00.02"}, {"id": 3154, "label": "61.02.00.03"}, {
    "id": 3155,
    "label": "61.02.00.04"
}, {"id": 3156, "label": "61.02.00.05"}, {"id": 3157, "label": "61.02.00.06"}, {
    "id": 3158,
    "label": "61.02.00.07"
}, {"id": 3159, "label": "61.03.00.01"}, {"id": 3160, "label": "61.03.00.02"}, {
    "id": 3161,
    "label": "61.03.00.03"
}, {"id": 3162, "label": "61.03.00.04"}, {"id": 3163, "label": "61.03.00.05"}, {
    "id": 3164,
    "label": "61.03.00.06"
}, {"id": 3165, "label": "61.03.00.07"}, {"id": 3166, "label": "61.03.00.08"}, {
    "id": 3167,
    "label": "61.03.00.09"
}, {"id": 3168, "label": "61.03.00.10"}, {"id": 3169, "label": "61.03.00.11"}, {
    "id": 3170,
    "label": "61.03.00.12"
}, {"id": 3171, "label": "61.03.00.13"}, {"id": 3172, "label": "61.03.00.14"}, {
    "id": 3173,
    "label": "61.03.00.15"
}, {"id": 3174, "label": "61.03.00.16"}, {"id": 3175, "label": "61.03.00.17"}, {
    "id": 3176,
    "label": "61.03.00.18"
}, {"id": 3177, "label": "61.03.00.19"}, {"id": 3178, "label": "61.04.00.01"}, {
    "id": 3179,
    "label": "61.04.00.02"
}, {"id": 3180, "label": "61.04.00.03"}, {"id": 3181, "label": "61.04.00.04"}, {
    "id": 3182,
    "label": "61.04.00.05"
}, {"id": 3183, "label": "61.04.00.06"}, {"id": 3184, "label": "61.04.00.07"}, {
    "id": 3185,
    "label": "61.04.00.08"
}, {"id": 3186, "label": "61.04.00.09"}, {"id": 3187, "label": "61.04.00.10"}, {
    "id": 3188,
    "label": "61.05.00.01"
}, {"id": 3189, "label": "61.05.00.02"}, {"id": 3190, "label": "61.05.00.03"}, {
    "id": 3191,
    "label": "61.05.00.04"
}, {"id": 3192, "label": "61.05.00.05"}, {"id": 3193, "label": "61.05.00.06"}, {
    "id": 3194,
    "label": "61.05.00.07"
}, {"id": 3195, "label": "61.06.00.01"}, {"id": 3196, "label": "61.06.00.02"}, {
    "id": 3197,
    "label": "61.06.00.03"
}, {"id": 3198, "label": "61.06.00.04"}, {"id": 3199, "label": "61.06.00.05"}, {
    "id": 3281,
    "label": "65.00.00.03"
}, {"id": 3200, "label": "61.06.00.06"}, {"id": 3201, "label": "61.06.00.07"}, {
    "id": 3202,
    "label": "61.07.00.01"
}, {"id": 3203, "label": "61.07.00.02"}, {"id": 3204, "label": "61.07.00.03"}, {
    "id": 3205,
    "label": "61.07.00.04"
}, {"id": 3206, "label": "61.08.00.01"}, {"id": 3207, "label": "61.08.00.02"}, {
    "id": 3208,
    "label": "61.08.00.03"
}, {"id": 3209, "label": "61.08.00.04"}, {"id": 3210, "label": "61.09.00.01"}, {
    "id": 3211,
    "label": "61.09.00.02"
}, {"id": 3212, "label": "61.09.00.03"}, {"id": 3213, "label": "61.09.00.04"}, {
    "id": 3214,
    "label": "61.09.00.05"
}, {"id": 3215, "label": "61.09.00.06"}, {"id": 3216, "label": "61.09.00.07"}, {
    "id": 3217,
    "label": "61.09.00.08"
}, {"id": 3218, "label": "61.09.00.09"}, {"id": 3219, "label": "61.09.00.10"}, {
    "id": 3220,
    "label": "61.09.00.11"
}, {"id": 3221, "label": "61.09.00.12"}, {"id": 3222, "label": "61.09.00.13"}, {
    "id": 3223,
    "label": "61.09.00.14"
}, {"id": 3224, "label": "61.09.00.15"}, {"id": 3225, "label": "61.10.00.01"}, {
    "id": 3226,
    "label": "61.10.00.03"
}, {"id": 3227, "label": "61.10.00.04"}, {"id": 3228, "label": "61.10.00.05"}, {
    "id": 3229,
    "label": "61.10.00.06"
}, {"id": 3230, "label": "61.10.00.07"}, {"id": 3231, "label": "61.10.00.08"}, {
    "id": 3232,
    "label": "61.10.00.09"
}, {"id": 3233, "label": "61.10.00.10"}, {"id": 3234, "label": "61.10.00.11"}, {
    "id": 3235,
    "label": "61.10.00.12"
}, {"id": 3236, "label": "61.10.00.13"}, {"id": 3237, "label": "62.00.00.01"}, {
    "id": 3238,
    "label": "62.00.00.04"
}, {"id": 3239, "label": "62.00.00.05"}, {"id": 3240, "label": "62.00.00.06"}, {
    "id": 3241,
    "label": "62.00.00.07"
}, {"id": 3242, "label": "62.00.00.08"}, {"id": 3243, "label": "62.00.00.09"}, {
    "id": 3244,
    "label": "62.00.00.10"
}, {"id": 3245, "label": "62.00.00.11"}, {"id": 3246, "label": "62.00.00.12"}, {
    "id": 3247,
    "label": "62.00.00.13"
}, {"id": 3248, "label": "62.00.00.14"}, {"id": 3249, "label": "62.00.00.15"}, {
    "id": 3250,
    "label": "62.00.00.16"
}, {"id": 3251, "label": "62.00.00.17"}, {"id": 3252, "label": "62.00.00.18"}, {
    "id": 3253,
    "label": "62.00.00.19"
}, {"id": 3254, "label": "62.00.00.20"}, {"id": 3255, "label": "62.00.00.21"}, {
    "id": 3256,
    "label": "62.00.00.22"
}, {"id": 3257, "label": "62.00.00.23"}, {"id": 3258, "label": "62.00.00.24"}, {
    "id": 3259,
    "label": "62.00.00.25"
}, {"id": 3260, "label": "62.00.00.26"}, {"id": 3261, "label": "62.00.00.27"}, {
    "id": 3262,
    "label": "62.00.00.28"
}, {"id": 3263, "label": "62.00.00.29"}, {"id": 3264, "label": "62.00.00.30"}, {
    "id": 3265,
    "label": "62.00.00.31"
}, {"id": 3266, "label": "62.00.00.32"}, {"id": 3267, "label": "62.00.00.33"}, {
    "id": 3268,
    "label": "62.00.00.34"
}, {"id": 3269, "label": "62.00.00.35"}, {"id": 3270, "label": "62.00.00.36"}, {
    "id": 3271,
    "label": "62.00.00.37"
}, {"id": 3272, "label": "64.00.00.01"}, {"id": 3273, "label": "64.00.00.02"}, {
    "id": 3274,
    "label": "64.00.00.03"
}, {"id": 3275, "label": "64.00.00.04"}, {"id": 3276, "label": "64.00.00.05"}, {
    "id": 3277,
    "label": "64.00.00.06"
}, {"id": 3278, "label": "64.00.00.07"}, {"id": 3279, "label": "65.00.00.01"}, {
    "id": 3280,
    "label": "65.00.00.02"
}, {"id": 3282, "label": "65.00.00.04"}, {"id": 3283, "label": "65.00.00.05"}, {
    "id": 3284,
    "label": "65.00.00.06"
}, {"id": 3285, "label": "65.00.00.07"}, {"id": 3286, "label": "65.00.00.08"}, {
    "id": 3287,
    "label": "65.00.00.09"
}, {"id": 3288, "label": "65.00.00.10"}, {"id": 3289, "label": "65.00.00.11"}, {
    "id": 3290,
    "label": "65.00.00.12"
}, {"id": 3291, "label": "65.00.00.13"}, {"id": 3292, "label": "65.00.00.14"}, {
    "id": 3293,
    "label": "65.00.00.15"
}, {"id": 3294, "label": "65.00.00.16"}, {"id": 3295, "label": "65.00.00.17"}, {
    "id": 3296,
    "label": "65.00.00.18"
}, {"id": 3297, "label": "65.00.00.19"}, {"id": 3298, "label": "65.00.00.20"}, {
    "id": 3299,
    "label": "65.00.00.21"
}, {"id": 3300, "label": "65.00.00.22"}, {"id": 3301, "label": "65.01.00.01"}, {
    "id": 3302,
    "label": "65.01.00.02"
}, {"id": 3303, "label": "65.01.00.03"}, {"id": 3304, "label": "65.01.00.04"}, {
    "id": 3305,
    "label": "65.01.00.05"
}, {"id": 3306, "label": "65.01.00.06"}, {"id": 3307, "label": "65.01.00.07"}, {
    "id": 3308,
    "label": "65.01.00.08"
}, {"id": 3309, "label": "65.01.00.09"}, {"id": 3310, "label": "65.01.00.10"}, {
    "id": 3311,
    "label": "65.01.00.11"
}, {"id": 3312, "label": "65.01.00.12"}, {"id": 3313, "label": "65.01.00.13"}, {
    "id": 3314,
    "label": "66.00.00.01"
}, {"id": 3315, "label": "66.00.00.02"}, {"id": 3316, "label": "66.00.00.03"}, {
    "id": 3317,
    "label": "66.00.00.04"
}, {"id": 3318, "label": "66.00.00.05"}, {"id": 3319, "label": "66.00.00.06"}, {
    "id": 3320,
    "label": "66.00.00.07"
}, {"id": 3321, "label": "66.00.00.08"}, {"id": 3322, "label": "66.00.00.09"}, {
    "id": 3323,
    "label": "66.00.00.10"
}, {"id": 3324, "label": "66.00.00.11"}, {"id": 3325, "label": "66.00.00.12"}, {
    "id": 3326,
    "label": "66.00.00.13"
}, {"id": 3327, "label": "66.00.00.14"}, {"id": 3328, "label": "66.00.00.15"}, {
    "id": 3329,
    "label": "66.00.00.16"
}, {"id": 3330, "label": "66.00.00.17"}, {"id": 3331, "label": "66.00.00.18"}, {
    "id": 3332,
    "label": "66.00.00.19"
}, {"id": 3333, "label": "66.01.00.01"}, {"id": 3334, "label": "66.01.00.02"}, {
    "id": 3335,
    "label": "66.01.00.03"
}, {"id": 3336, "label": "66.01.00.04"}, {"id": 3337, "label": "66.01.00.05"}, {
    "id": 3338,
    "label": "66.01.00.06"
}, {"id": 3339, "label": "66.01.00.07"}, {"id": 3340, "label": "66.01.00.08"}, {
    "id": 3341,
    "label": "66.01.00.09"
}, {"id": 3342, "label": "66.01.00.10"}, {"id": 3343, "label": "66.01.00.11"}, {
    "id": 3344,
    "label": "66.01.00.12"
}, {"id": 3345, "label": "66.01.00.13"}, {"id": 3346, "label": "66.01.00.14"}, {
    "id": 3347,
    "label": "66.01.00.15"
}, {"id": 3348, "label": "66.01.00.16"}, {"id": 3349, "label": "66.01.00.17"}, {
    "id": 3350,
    "label": "66.01.00.18"
}, {"id": 3351, "label": "66.01.00.19"}, {"id": 3352, "label": "66.01.00.20"}, {
    "id": 3353,
    "label": "66.01.00.21"
}, {"id": 3354, "label": "66.01.00.22"}, {"id": 3355, "label": "66.01.00.23"}, {
    "id": 3356,
    "label": "66.02.00.01"
}, {"id": 3357, "label": "66.02.00.02"}, {"id": 3358, "label": "66.02.00.03"}, {
    "id": 3359,
    "label": "66.02.00.04"
}, {"id": 3360, "label": "66.02.00.05"}, {"id": 3361, "label": "66.02.00.06"}, {
    "id": 3362,
    "label": "66.02.00.07"
}, {"id": 3363, "label": "66.02.00.08"}, {"id": 3364, "label": "66.02.00.09"}, {
    "id": 3365,
    "label": "66.02.00.10"
}, {"id": 3366, "label": "66.02.00.11"}, {"id": 3367, "label": "66.02.01.01"}, {
    "id": 3368,
    "label": "66.02.01.02"
}, {"id": 3369, "label": "66.03.00.01"}, {"id": 3370, "label": "66.03.00.02"}, {
    "id": 3371,
    "label": "66.03.00.03"
}, {"id": 3372, "label": "66.03.00.04"}, {"id": 3373, "label": "66.03.01.01"}, {
    "id": 3374,
    "label": "66.03.01.02"
}, {"id": 3375, "label": "66.03.02.01"}, {"id": 3376, "label": "66.03.03.01"}, {
    "id": 3377,
    "label": "66.03.03.02"
}, {"id": 3378, "label": "66.03.03.03"}, {"id": 3379, "label": "66.03.03.04"}, {
    "id": 3380,
    "label": "66.03.03.05"
}, {"id": 3381, "label": "66.03.03.06"}, {"id": 3382, "label": "66.04.00.01"}, {
    "id": 3383,
    "label": "66.04.00.02"
}, {"id": 3384, "label": "66.04.00.03"}, {"id": 3385, "label": "66.04.00.04"}, {
    "id": 3386,
    "label": "66.04.00.05"
}, {"id": 3387, "label": "66.04.00.06"}, {"id": 3388, "label": "66.04.00.07"}, {
    "id": 3389,
    "label": "66.04.00.08"
}, {"id": 3390, "label": "66.04.00.09"}, {"id": 3391, "label": "66.04.00.10"}, {
    "id": 3392,
    "label": "66.04.00.11"
}, {"id": 3393, "label": "66.04.00.12"}, {"id": 3394, "label": "66.04.00.13"}, {
    "id": 3395,
    "label": "66.04.00.14"
}, {"id": 3396, "label": "66.04.00.15"}, {"id": 3397, "label": "66.04.00.16"}, {
    "id": 3398,
    "label": "66.04.00.17"
}, {"id": 3399, "label": "66.04.00.18"}, {"id": 3400, "label": "66.04.00.19"}, {
    "id": 3401,
    "label": "66.04.00.20"
}, {"id": 3402, "label": "66.04.00.21"}, {"id": 3403, "label": "66.04.00.22"}, {
    "id": 3404,
    "label": "66.04.00.23"
}, {"id": 3405, "label": "66.04.00.24"}, {"id": 3406, "label": "66.04.00.25"}, {
    "id": 3407,
    "label": "66.04.00.26"
}, {"id": 3408, "label": "66.05.00.01"}, {"id": 3409, "label": "66.05.00.02"}, {
    "id": 3410,
    "label": "66.05.00.03"
}, {"id": 3411, "label": "67.00.00.01"}, {"id": 3412, "label": "67.00.00.02"}, {
    "id": 3413,
    "label": "67.00.00.03"
}, {"id": 3414, "label": "67.00.00.04"}, {"id": 3415, "label": "67.00.00.05"}, {
    "id": 3416,
    "label": "67.00.00.06"
}, {"id": 3417, "label": "67.00.00.07"}, {"id": 3418, "label": "67.00.00.08"}, {
    "id": 3419,
    "label": "67.00.00.09"
}, {"id": 3568, "label": "70.25.00.10"}, {"id": 3420, "label": "67.00.00.10"}, {
    "id": 3421,
    "label": "67.00.00.11"
}, {"id": 3422, "label": "67.00.00.12"}, {"id": 3423, "label": "67.00.00.13"}, {
    "id": 3424,
    "label": "70.10.00.01"
}, {"id": 3425, "label": "70.10.00.02"}, {"id": 3426, "label": "70.10.00.03"}, {
    "id": 3427,
    "label": "70.10.00.04"
}, {"id": 3428, "label": "70.10.00.05"}, {"id": 3429, "label": "70.10.00.06"}, {
    "id": 3430,
    "label": "70.10.00.07"
}, {"id": 3431, "label": "70.10.00.08"}, {"id": 3432, "label": "70.10.00.09"}, {
    "id": 3433,
    "label": "70.10.00.10"
}, {"id": 3434, "label": "70.10.00.11"}, {"id": 3435, "label": "70.10.00.12"}, {
    "id": 3436,
    "label": "70.10.00.13"
}, {"id": 3437, "label": "70.10.00.14"}, {"id": 3438, "label": "70.11.00.01"}, {
    "id": 3439,
    "label": "70.11.00.02"
}, {"id": 3440, "label": "70.11.00.03"}, {"id": 3441, "label": "70.11.00.04"}, {
    "id": 3442,
    "label": "70.11.00.05"
}, {"id": 3443, "label": "70.11.00.06"}, {"id": 3444, "label": "70.11.00.07"}, {
    "id": 3445,
    "label": "70.11.00.08"
}, {"id": 3446, "label": "70.11.00.09"}, {"id": 3447, "label": "70.11.00.10"}, {
    "id": 3448,
    "label": "70.11.00.11"
}, {"id": 3449, "label": "70.11.00.12"}, {"id": 3450, "label": "70.11.00.13"}, {
    "id": 3451,
    "label": "70.12.00.01"
}, {"id": 3452, "label": "70.12.00.02"}, {"id": 3453, "label": "70.12.00.03"}, {
    "id": 3454,
    "label": "70.12.00.04"
}, {"id": 3455, "label": "70.12.00.05"}, {"id": 3456, "label": "70.12.00.06"}, {
    "id": 3457,
    "label": "70.12.00.07"
}, {"id": 3458, "label": "70.12.00.08"}, {"id": 3459, "label": "70.12.00.09"}, {
    "id": 3460,
    "label": "70.12.00.10"
}, {"id": 3461, "label": "70.12.00.11"}, {"id": 3462, "label": "70.12.00.12"}, {
    "id": 3463,
    "label": "70.12.00.13"
}, {"id": 3464, "label": "70.12.00.14"}, {"id": 3465, "label": "70.12.00.15"}, {
    "id": 3466,
    "label": "70.12.00.16"
}, {"id": 3467, "label": "70.12.00.17"}, {"id": 3468, "label": "70.12.00.18"}, {
    "id": 3469,
    "label": "70.12.00.19"
}, {"id": 3470, "label": "70.12.00.20"}, {"id": 3471, "label": "70.12.00.21"}, {
    "id": 3472,
    "label": "70.12.00.22"
}, {"id": 3473, "label": "70.12.00.23"}, {"id": 3474, "label": "70.12.00.24"}, {
    "id": 3475,
    "label": "70.12.00.25"
}, {"id": 3476, "label": "70.12.00.26"}, {"id": 3477, "label": "70.12.00.27"}, {
    "id": 3478,
    "label": "70.12.00.28"
}, {"id": 3479, "label": "70.12.00.29"}, {"id": 3480, "label": "70.12.00.30"}, {
    "id": 3481,
    "label": "70.12.00.31"
}, {"id": 3482, "label": "70.12.00.32"}, {"id": 3483, "label": "70.12.00.33"}, {
    "id": 3484,
    "label": "70.13.00.01"
}, {"id": 3485, "label": "70.13.00.02"}, {"id": 3486, "label": "70.13.00.03"}, {
    "id": 3487,
    "label": "70.13.00.04"
}, {"id": 3488, "label": "70.13.00.05"}, {"id": 3489, "label": "70.13.00.06"}, {
    "id": 3490,
    "label": "70.13.00.07"
}, {"id": 3491, "label": "70.14.00.01"}, {"id": 3492, "label": "70.14.00.02"}, {
    "id": 3493,
    "label": "70.14.00.03"
}, {"id": 3494, "label": "70.14.00.04"}, {"id": 3495, "label": "70.14.00.05"}, {
    "id": 3496,
    "label": "70.14.00.06"
}, {"id": 3497, "label": "70.14.00.07"}, {"id": 3498, "label": "70.14.00.08"}, {
    "id": 3499,
    "label": "70.21.00.01"
}, {"id": 3500, "label": "70.21.00.02"}, {"id": 3501, "label": "70.21.00.03"}, {
    "id": 3502,
    "label": "70.22.00.01"
}, {"id": 3503, "label": "70.22.00.02"}, {"id": 3504, "label": "70.22.00.03"}, {
    "id": 3505,
    "label": "70.22.00.04"
}, {"id": 3506, "label": "70.22.00.05"}, {"id": 3507, "label": "70.22.00.06"}, {
    "id": 3508,
    "label": "70.22.00.07"
}, {"id": 3509, "label": "70.22.00.08"}, {"id": 3510, "label": "70.22.00.10"}, {
    "id": 3511,
    "label": "70.22.00.12"
}, {"id": 3512, "label": "70.22.00.13"}, {"id": 3513, "label": "70.22.00.14"}, {
    "id": 3514,
    "label": "70.22.00.16"
}, {"id": 3515, "label": "70.22.00.17"}, {"id": 3516, "label": "70.22.00.18"}, {
    "id": 3517,
    "label": "70.22.00.19"
}, {"id": 3518, "label": "70.22.00.20"}, {"id": 3519, "label": "70.22.00.21"}, {
    "id": 3520,
    "label": "70.22.00.22"
}, {"id": 3521, "label": "70.22.00.23"}, {"id": 3522, "label": "70.22.00.24"}, {
    "id": 3523,
    "label": "70.22.00.25"
}, {"id": 3524, "label": "70.22.00.26"}, {"id": 3525, "label": "70.22.00.27"}, {
    "id": 3526,
    "label": "70.22.00.28"
}, {"id": 3527, "label": "70.22.00.29"}, {"id": 3528, "label": "70.23.00.01"}, {
    "id": 3529,
    "label": "70.23.00.02"
}, {"id": 3530, "label": "70.23.00.03"}, {"id": 3531, "label": "70.23.00.04"}, {
    "id": 3532,
    "label": "70.23.00.05"
}, {"id": 3533, "label": "70.23.00.06"}, {"id": 3534, "label": "70.23.00.07"}, {
    "id": 3535,
    "label": "70.23.00.08"
}, {"id": 3536, "label": "70.23.00.09"}, {"id": 3537, "label": "70.23.00.10"}, {
    "id": 3538,
    "label": "70.23.00.11"
}, {"id": 3539, "label": "70.23.00.12"}, {"id": 3540, "label": "70.23.00.13"}, {
    "id": 3541,
    "label": "70.23.00.14"
}, {"id": 3542, "label": "70.23.00.15"}, {"id": 3543, "label": "70.23.00.16"}, {
    "id": 3544,
    "label": "70.23.00.17"
}, {"id": 3545, "label": "70.23.00.18"}, {"id": 3546, "label": "70.23.00.19"}, {
    "id": 3547,
    "label": "70.23.00.20"
}, {"id": 3548, "label": "70.23.00.21"}, {"id": 3549, "label": "70.23.00.22"}, {
    "id": 3550,
    "label": "70.23.00.23"
}, {"id": 3551, "label": "70.24.00.01"}, {"id": 3552, "label": "70.24.00.02"}, {
    "id": 3553,
    "label": "70.24.00.03"
}, {"id": 3554, "label": "70.24.00.04"}, {"id": 3555, "label": "70.24.00.05"}, {
    "id": 3556,
    "label": "70.24.00.06"
}, {"id": 3557, "label": "70.24.00.07"}, {"id": 3558, "label": "70.24.00.08"}, {
    "id": 3559,
    "label": "70.25.00.01"
}, {"id": 3560, "label": "70.25.00.02"}, {"id": 3561, "label": "70.25.00.03"}, {
    "id": 3562,
    "label": "70.25.00.04"
}, {"id": 3563, "label": "70.25.00.05"}, {"id": 3564, "label": "70.25.00.06"}, {
    "id": 3565,
    "label": "70.25.00.07"
}, {"id": 3566, "label": "70.25.00.08"}, {"id": 3567, "label": "70.25.00.09"}, {
    "id": 3569,
    "label": "70.25.00.11"
}, {"id": 3570, "label": "70.25.00.12"}, {"id": 3571, "label": "70.25.00.13"}, {
    "id": 3572,
    "label": "70.25.00.14"
}, {"id": 3573, "label": "70.25.00.15"}, {"id": 3574, "label": "70.25.00.16"}, {
    "id": 3575,
    "label": "70.25.00.17"
}, {"id": 3576, "label": "70.25.00.18"}, {"id": 3577, "label": "70.26.00.01"}, {
    "id": 3578,
    "label": "70.26.00.02"
}, {"id": 3579, "label": "70.26.00.03"}, {"id": 3580, "label": "70.26.00.04"}, {
    "id": 3581,
    "label": "70.26.00.05"
}, {"id": 3582, "label": "70.26.00.06"}, {"id": 3583, "label": "70.26.00.07"}, {
    "id": 3584,
    "label": "70.26.00.08"
}, {"id": 3585, "label": "70.26.00.09"}, {"id": 3586, "label": "70.26.00.10"}, {
    "id": 3587,
    "label": "70.26.00.11"
}, {"id": 3588, "label": "70.26.00.12"}, {"id": 3589, "label": "70.26.00.13"}, {
    "id": 3590,
    "label": "70.26.00.14"
}, {"id": 3591, "label": "70.26.00.15"}, {"id": 3592, "label": "70.27.00.01"}, {
    "id": 3593,
    "label": "70.27.00.02"
}, {"id": 3594, "label": "70.27.00.03"}, {"id": 3595, "label": "70.27.00.04"}, {
    "id": 3596,
    "label": "70.27.00.05"
}, {"id": 3597, "label": "70.27.00.06"}, {"id": 3598, "label": "70.27.00.07"}, {
    "id": 3599,
    "label": "70.27.00.08"
}, {"id": 3600, "label": "70.27.00.09"}, {"id": 3601, "label": "70.27.00.10"}, {
    "id": 3602,
    "label": "70.29.00.01"
}, {"id": 3603, "label": "70.29.00.02"}, {"id": 3604, "label": "70.29.00.03"}, {
    "id": 3605,
    "label": "70.29.00.04"
}, {"id": 3606, "label": "70.29.00.05"}, {"id": 3607, "label": "70.29.00.06"}, {
    "id": 3608,
    "label": "70.29.00.07"
}, {"id": 3609, "label": "70.29.00.08"}, {"id": 3610, "label": "70.29.00.09"}, {
    "id": 3611,
    "label": "70.31.00.01"
}, {"id": 3612, "label": "70.31.00.02"}, {"id": 3613, "label": "70.31.00.03"}, {
    "id": 3614,
    "label": "70.31.00.04"
}, {"id": 3615, "label": "70.31.00.05"}, {"id": 3616, "label": "70.31.00.06"}, {
    "id": 3617,
    "label": "70.31.00.07"
}, {"id": 3618, "label": "70.31.00.08"}, {"id": 3619, "label": "70.31.00.09"}, {
    "id": 3620,
    "label": "70.31.00.10"
}, {"id": 3621, "label": "70.31.00.11"}, {"id": 3622, "label": "70.31.00.12"}, {
    "id": 3623,
    "label": "70.31.00.13"
}, {"id": 3624, "label": "70.31.00.14"}, {"id": 3625, "label": "70.31.00.15"}, {
    "id": 3626,
    "label": "70.31.00.16"
}, {"id": 3627, "label": "70.31.00.17"}, {"id": 3628, "label": "70.31.00.18"}, {
    "id": 3629,
    "label": "70.31.00.19"
}, {"id": 3630, "label": "70.31.00.20"}, {"id": 3631, "label": "72.01.00.01"}, {
    "id": 3632,
    "label": "72.01.00.02"
}, {"id": 3633, "label": "72.01.00.03"}, {"id": 3634, "label": "72.01.00.04"}, {
    "id": 3635,
    "label": "72.01.00.05"
}, {"id": 3636, "label": "72.01.00.06"}, {"id": 3637, "label": "72.01.00.07"}, {
    "id": 3638,
    "label": "72.01.00.08"
}, {"id": 3639, "label": "72.01.00.09"}, {"id": 3640, "label": "72.01.00.10"}, {
    "id": 3641,
    "label": "72.01.00.11"
}, {"id": 3642, "label": "72.01.00.12"}, {"id": 3643, "label": "72.01.00.13"}, {
    "id": 3644,
    "label": "72.01.00.14"
}, {"id": 3645, "label": "72.01.00.15"}, {"id": 3646, "label": "72.01.00.16"}, {
    "id": 3647,
    "label": "72.01.00.17"
}, {"id": 3648, "label": "72.01.00.18"}, {"id": 3649, "label": "72.01.00.19"}, {
    "id": 3650,
    "label": "72.01.00.20"
}, {"id": 3651, "label": "72.01.00.21"}, {"id": 3652, "label": "72.01.00.22"}, {
    "id": 3653,
    "label": "72.01.00.23"
}, {"id": 3654, "label": "72.01.00.24"}, {"id": 3655, "label": "72.01.00.25"}, {
    "id": 3656,
    "label": "72.01.00.26"
}, {"id": 3657, "label": "72.01.00.27"}, {"id": 3658, "label": "72.01.00.28"}, {
    "id": 3659,
    "label": "72.01.00.29"
}, {"id": 3660, "label": "72.01.00.30"}, {"id": 3661, "label": "72.01.00.31"}, {
    "id": 3662,
    "label": "72.02.00.01"
}, {"id": 3663, "label": "72.02.00.02"}, {"id": 3664, "label": "72.02.00.03"}, {
    "id": 3665,
    "label": "72.02.00.04"
}, {"id": 3666, "label": "72.02.00.05"}, {"id": 3667, "label": "72.02.00.06"}, {
    "id": 3668,
    "label": "72.02.00.07"
}, {"id": 3669, "label": "72.02.00.08"}, {"id": 3670, "label": "72.02.00.09"}, {
    "id": 3671,
    "label": "72.02.00.10"
}, {"id": 3672, "label": "72.02.00.11"}, {"id": 3673, "label": "72.02.00.12"}, {
    "id": 3674,
    "label": "72.02.00.13"
}, {"id": 3675, "label": "72.02.00.14"}, {"id": 3676, "label": "72.02.00.15"}, {
    "id": 3677,
    "label": "72.02.00.16"
}, {"id": 3678, "label": "72.02.00.17"}, {"id": 3679, "label": "72.02.00.18"}, {
    "id": 3680,
    "label": "72.02.00.19"
}, {"id": 3681, "label": "72.02.00.20"}, {"id": 3682, "label": "72.02.00.21"}, {
    "id": 3683,
    "label": "72.02.00.22"
}, {"id": 3684, "label": "72.02.00.23"}, {"id": 3685, "label": "72.02.00.24"}, {
    "id": 3686,
    "label": "72.02.00.25"
}, {"id": 3687, "label": "72.02.00.26"}, {"id": 3688, "label": "72.02.00.27"}, {
    "id": 3689,
    "label": "72.02.00.28"
}, {"id": 3690, "label": "72.02.00.29"}, {"id": 3691, "label": "72.02.00.30"}, {
    "id": 3692,
    "label": "72.02.00.31"
}, {"id": 3693, "label": "72.02.00.32"}, {"id": 3694, "label": "72.02.00.33"}, {
    "id": 3695,
    "label": "72.02.00.34"
}, {"id": 3696, "label": "72.02.00.35"}, {"id": 3697, "label": "72.02.00.36"}, {
    "id": 3698,
    "label": "72.02.00.37"
}, {"id": 3699, "label": "72.02.00.38"}, {"id": 3700, "label": "72.02.00.39"}, {
    "id": 3701,
    "label": "72.02.00.40"
}, {"id": 3702, "label": "72.02.00.41"}, {"id": 3703, "label": "72.02.00.42"}, {
    "id": 3704,
    "label": "72.02.00.43"
}, {"id": 3705, "label": "72.02.00.44"}, {"id": 3706, "label": "72.02.00.45"}, {
    "id": 3707,
    "label": "72.02.00.46"
}, {"id": 3708, "label": "72.02.00.47"}, {"id": 3709, "label": "72.02.00.48"}, {
    "id": 3710,
    "label": "72.02.00.49"
}, {"id": 3711, "label": "72.02.00.50"}, {"id": 3712, "label": "72.02.00.51"}, {
    "id": 3713,
    "label": "72.02.00.52"
}, {"id": 3714, "label": "72.02.00.53"}, {"id": 3715, "label": "72.02.00.54"}, {
    "id": 3716,
    "label": "72.02.00.55"
}, {"id": 3717, "label": "72.02.00.56"}, {"id": 3718, "label": "72.02.00.57"}, {
    "id": 3719,
    "label": "72.02.00.58"
}, {"id": 3720, "label": "72.02.00.59"}, {"id": 3721, "label": "72.02.00.60"}, {
    "id": 3722,
    "label": "72.02.00.61"
}, {"id": 3723, "label": "72.02.00.62"}, {"id": 3724, "label": "72.02.00.63"}, {
    "id": 3725,
    "label": "72.02.00.64"
}, {"id": 3726, "label": "72.02.00.65"}, {"id": 3727, "label": "72.02.00.66"}, {
    "id": 3728,
    "label": "72.02.00.67"
}, {"id": 3729, "label": "72.02.00.68"}, {"id": 3730, "label": "72.02.00.69"}, {
    "id": 3731,
    "label": "72.03.00.01"
}, {"id": 3732, "label": "72.03.00.02"}, {"id": 3733, "label": "72.03.00.03"}, {
    "id": 3734,
    "label": "72.03.00.04"
}, {"id": 3735, "label": "72.03.00.05"}, {"id": 3736, "label": "72.03.00.06"}, {
    "id": 3737,
    "label": "72.03.00.07"
}, {"id": 3738, "label": "72.03.00.08"}, {"id": 3739, "label": "72.03.00.09"}, {
    "id": 3740,
    "label": "72.03.00.10"
}, {"id": 3741, "label": "72.03.00.11"}, {"id": 3742, "label": "72.03.00.12"}, {
    "id": 3743,
    "label": "72.03.00.13"
}, {"id": 3744, "label": "72.03.00.14"}, {"id": 3745, "label": "72.03.00.15"}, {
    "id": 3746,
    "label": "72.03.00.16"
}, {"id": 3747, "label": "72.03.00.17"}, {"id": 3748, "label": "72.03.00.18"}, {
    "id": 3749,
    "label": "72.03.00.19"
}, {"id": 3750, "label": "72.03.00.20"}, {"id": 3751, "label": "72.03.00.21"}, {
    "id": 3752,
    "label": "72.03.00.22"
}, {"id": 3753, "label": "72.03.00.23"}, {"id": 3754, "label": "72.03.00.24"}, {
    "id": 3755,
    "label": "72.03.00.25"
}, {"id": 3756, "label": "72.03.00.26"}, {"id": 3757, "label": "72.03.00.27"}, {
    "id": 3758,
    "label": "72.03.00.28"
}, {"id": 3759, "label": "72.03.00.29"}, {"id": 3760, "label": "72.03.00.30"}, {
    "id": 3761,
    "label": "72.03.00.31"
}, {"id": 3762, "label": "72.03.00.32"}, {"id": 3763, "label": "72.03.00.33"}, {
    "id": 3764,
    "label": "72.03.00.34"
}, {"id": 3765, "label": "72.03.00.35"}, {"id": 3766, "label": "72.04.00.01"}, {
    "id": 3767,
    "label": "72.04.00.02"
}, {"id": 3768, "label": "72.04.00.03"}, {"id": 3769, "label": "72.04.00.04"}, {
    "id": 3770,
    "label": "72.04.00.05"
}, {"id": 3771, "label": "72.04.00.06"}, {"id": 3772, "label": "72.04.00.07"}, {
    "id": 3773,
    "label": "72.04.00.08"
}, {"id": 3774, "label": "72.04.00.09"}, {"id": 3775, "label": "72.04.00.10"}, {
    "id": 3776,
    "label": "72.04.00.11"
}, {"id": 3777, "label": "72.04.00.12"}, {"id": 3778, "label": "72.04.00.13"}, {
    "id": 3779,
    "label": "72.04.00.14"
}, {"id": 3780, "label": "72.04.00.15"}, {"id": 3781, "label": "72.04.00.16"}, {
    "id": 3782,
    "label": "72.04.00.17"
}, {"id": 3783, "label": "72.04.00.18"}, {"id": 3784, "label": "72.04.00.19"}, {
    "id": 3785,
    "label": "72.04.00.20"
}, {"id": 3786, "label": "72.04.00.21"}, {"id": 3787, "label": "72.04.00.22"}, {
    "id": 3788,
    "label": "72.04.00.23"
}, {"id": 3789, "label": "72.04.00.24"}, {"id": 3790, "label": "72.04.00.25"}, {
    "id": 3791,
    "label": "72.04.00.26"
}, {"id": 3792, "label": "72.04.00.27"}, {"id": 3793, "label": "72.04.00.28"}, {
    "id": 3794,
    "label": "72.04.00.29"
}, {"id": 3795, "label": "72.04.00.30"}, {"id": 3796, "label": "72.04.00.31"}, {
    "id": 3797,
    "label": "72.04.00.32"
}, {"id": 3798, "label": "72.04.00.33"}, {"id": 3799, "label": "72.04.00.34"}, {
    "id": 3800,
    "label": "72.04.00.35"
}, {"id": 3801, "label": "72.04.00.36"}, {"id": 3802, "label": "72.04.00.37"}, {
    "id": 3803,
    "label": "72.04.00.38"
}, {"id": 3804, "label": "72.04.00.39"}, {"id": 3805, "label": "72.04.00.40"}, {
    "id": 3806,
    "label": "72.04.00.41"
}, {"id": 3807, "label": "72.04.00.42"}, {"id": 3808, "label": "72.04.00.43"}, {
    "id": 3809,
    "label": "72.04.00.44"
}, {"id": 3810, "label": "72.04.00.45"}, {"id": 3811, "label": "72.04.00.46"}, {
    "id": 3812,
    "label": "72.04.00.47"
}, {"id": 3813, "label": "72.04.00.48"}, {"id": 3814, "label": "72.04.00.49"}, {
    "id": 3815,
    "label": "72.04.00.50"
}, {"id": 3816, "label": "72.04.00.51"}, {"id": 3817, "label": "72.04.00.52"}, {
    "id": 3818,
    "label": "72.04.00.53"
}, {"id": 3819, "label": "72.04.00.54"}, {"id": 3820, "label": "72.04.00.55"}, {
    "id": 3821,
    "label": "72.04.00.56"
}, {"id": 3822, "label": "72.04.00.57"}, {"id": 3823, "label": "72.04.00.58"}, {
    "id": 3824,
    "label": "72.04.00.59"
}, {"id": 3825, "label": "72.04.00.60"}, {"id": 3826, "label": "72.04.00.61"}, {
    "id": 3827,
    "label": "72.04.00.62"
}, {"id": 3828, "label": "72.04.00.63"}, {"id": 3829, "label": "72.04.00.64"}, {
    "id": 3830,
    "label": "72.05.00.01"
}, {"id": 3831, "label": "72.05.00.02"}, {"id": 3832, "label": "72.05.00.03"}, {
    "id": 3833,
    "label": "72.05.00.04"
}, {"id": 3834, "label": "72.05.00.05"}, {"id": 3835, "label": "72.05.00.06"}, {
    "id": 3836,
    "label": "72.05.00.07"
}, {"id": 3837, "label": "72.05.00.08"}, {"id": 3838, "label": "72.05.00.09"}, {
    "id": 3839,
    "label": "72.05.00.10"
}, {"id": 3840, "label": "72.05.00.11"}, {"id": 3841, "label": "72.05.00.12"}, {
    "id": 3842,
    "label": "72.05.00.13"
}, {"id": 3843, "label": "72.05.00.14"}, {"id": 3844, "label": "72.05.00.15"}, {
    "id": 3845,
    "label": "72.05.00.16"
}, {"id": 3846, "label": "72.05.00.17"}, {"id": 3847, "label": "72.05.00.18"}, {
    "id": 3848,
    "label": "72.05.00.19"
}, {"id": 3849, "label": "72.05.00.20"}, {"id": 3850, "label": "72.05.00.21"}, {
    "id": 3851,
    "label": "72.05.00.22"
}, {"id": 3852, "label": "72.05.00.23"}, {"id": 3853, "label": "72.06.00.01"}, {
    "id": 3854,
    "label": "72.06.00.02"
}, {"id": 3855, "label": "72.06.00.03"}, {"id": 3856, "label": "72.06.00.04"}, {
    "id": 3857,
    "label": "72.06.00.05"
}, {"id": 3858, "label": "72.06.00.06"}, {"id": 3859, "label": "72.06.00.07"}, {
    "id": 3860,
    "label": "72.06.00.08"
}, {"id": 3861, "label": "72.06.00.09"}, {"id": 3862, "label": "72.07.00.01"}, {
    "id": 3863,
    "label": "72.07.00.02"
}, {"id": 3864, "label": "72.07.00.03"}, {"id": 3865, "label": "72.07.00.04"}, {
    "id": 3866,
    "label": "72.07.00.05"
}, {"id": 3867, "label": "72.07.00.06"}, {"id": 3868, "label": "72.07.00.07"}, {
    "id": 3869,
    "label": "72.07.00.08"
}, {"id": 3870, "label": "72.07.00.09"}, {"id": 3871, "label": "72.07.00.10"}, {
    "id": 3872,
    "label": "72.07.00.11"
}, {"id": 3873, "label": "72.08.00.01"}, {"id": 3874, "label": "72.08.00.02"}, {
    "id": 3875,
    "label": "72.08.00.03"
}, {"id": 3876, "label": "72.08.00.04"}, {"id": 3877, "label": "72.08.00.05"}, {
    "id": 3878,
    "label": "72.08.00.06"
}, {"id": 3879, "label": "72.08.00.07"}, {"id": 3880, "label": "72.08.00.08"}, {
    "id": 3881,
    "label": "72.08.00.09"
}, {"id": 3882, "label": "72.08.00.10"}, {"id": 3883, "label": "72.08.00.11"}, {
    "id": 3884,
    "label": "72.08.00.12"
}, {"id": 3885, "label": "72.08.00.13"}, {"id": 3886, "label": "72.08.00.14"}, {
    "id": 3887,
    "label": "72.08.00.15"
}, {"id": 3888, "label": "72.08.00.16"}, {"id": 3889, "label": "72.08.00.17"}, {
    "id": 3890,
    "label": "72.08.00.18"
}, {"id": 3891, "label": "72.08.00.19"}, {"id": 3892, "label": "72.08.00.20"}, {
    "id": 3893,
    "label": "72.08.00.21"
}, {"id": 3894, "label": "72.08.00.22"}, {"id": 3895, "label": "72.08.00.23"}, {
    "id": 3896,
    "label": "72.08.00.24"
}, {"id": 3897, "label": "72.08.00.25"}, {"id": 3898, "label": "72.08.00.26"}, {
    "id": 3899,
    "label": "72.08.00.27"
}, {"id": 3900, "label": "72.08.00.28"}, {"id": 3901, "label": "72.08.00.29"}, {
    "id": 3902,
    "label": "72.08.00.30"
}, {"id": 3903, "label": "72.08.00.31"}, {"id": 3904, "label": "72.08.00.32"}, {
    "id": 3905,
    "label": "72.08.00.33"
}, {"id": 3906, "label": "72.08.00.34"}, {"id": 3907, "label": "72.08.00.35"}, {
    "id": 3908,
    "label": "72.08.00.36"
}, {"id": 3909, "label": "72.08.00.37"}, {"id": 3910, "label": "72.08.00.38"}, {
    "id": 3911,
    "label": "72.08.00.39"
}, {"id": 3912, "label": "72.08.00.40"}, {"id": 3913, "label": "72.08.00.41"}, {
    "id": 3914,
    "label": "72.09.00.01"
}, {"id": 3915, "label": "72.09.00.02"}, {"id": 3916, "label": "72.09.00.03"}, {
    "id": 3917,
    "label": "72.09.00.04"
}, {"id": 3918, "label": "72.09.00.05"}, {"id": 3919, "label": "72.09.00.06"}, {
    "id": 3920,
    "label": "72.09.00.07"
}, {"id": 3921, "label": "72.09.00.08"}, {"id": 3922, "label": "72.09.00.09"}, {
    "id": 3923,
    "label": "72.09.00.10"
}, {"id": 3924, "label": "72.09.00.11"}, {"id": 3925, "label": "72.09.00.12"}, {
    "id": 3926,
    "label": "72.09.00.13"
}, {"id": 3927, "label": "72.09.00.14"}, {"id": 3928, "label": "72.09.00.15"}, {
    "id": 3929,
    "label": "72.09.00.16"
}, {"id": 3930, "label": "72.09.00.17"}, {"id": 3931, "label": "72.09.00.18"}, {
    "id": 3932,
    "label": "72.09.00.19"
}, {"id": 3933, "label": "72.09.00.20"}, {"id": 3934, "label": "72.09.00.21"}, {
    "id": 3935,
    "label": "72.09.00.22"
}, {"id": 3936, "label": "72.10.00.01"}, {"id": 3937, "label": "72.10.00.02"}, {
    "id": 3938,
    "label": "72.10.00.03"
}, {"id": 3939, "label": "72.10.00.04"}, {"id": 3940, "label": "72.10.00.05"}, {
    "id": 3941,
    "label": "72.10.00.06"
}, {"id": 3942, "label": "72.10.00.07"}, {"id": 3943, "label": "72.10.00.08"}, {
    "id": 3944,
    "label": "72.10.00.09"
}, {"id": 3945, "label": "72.10.00.10"}, {"id": 3946, "label": "72.10.00.11"}, {
    "id": 3947,
    "label": "72.10.00.12"
}, {"id": 3948, "label": "72.10.00.13"}, {"id": 3949, "label": "72.10.00.14"}, {
    "id": 3950,
    "label": "72.10.00.15"
}, {"id": 3951, "label": "72.10.00.16"}, {"id": 3952, "label": "72.10.00.17"}, {
    "id": 3953,
    "label": "72.10.00.18"
}, {"id": 3954, "label": "72.10.00.19"}, {"id": 3955, "label": "72.10.00.20"}, {
    "id": 3956,
    "label": "72.10.00.21"
}, {"id": 3957, "label": "72.10.00.22"}, {"id": 3958, "label": "72.10.00.23"}, {
    "id": 3959,
    "label": "72.10.00.24"
}, {"id": 3960, "label": "72.10.00.25"}, {"id": 3961, "label": "72.10.00.26"}, {
    "id": 3962,
    "label": "72.10.00.27"
}, {"id": 3963, "label": "72.10.00.28"}, {"id": 3964, "label": "72.10.00.29"}, {
    "id": 3965,
    "label": "72.10.00.30"
}, {"id": 3966, "label": "73.01.01.02"}, {"id": 3967, "label": "73.01.01.03"}, {
    "id": 3968,
    "label": "73.01.01.04"
}, {"id": 3969, "label": "73.01.01.05"}, {"id": 3970, "label": "73.01.01.06"}, {
    "id": 3971,
    "label": "73.01.01.07"
}, {"id": 3972, "label": "73.01.01.08"}, {"id": 3973, "label": "73.01.01.09"}, {
    "id": 3974,
    "label": "73.01.01.10"
}, {"id": 3975, "label": "73.01.01.11"}, {"id": 3976, "label": "73.01.01.12"}, {
    "id": 3977,
    "label": "73.01.01.13"
}, {"id": 3978, "label": "73.01.01.14"}, {"id": 3979, "label": "73.01.01.15"}, {
    "id": 3980,
    "label": "73.01.01.16"
}, {"id": 3981, "label": "73.01.01.17"}, {"id": 3982, "label": "73.01.01.18"}, {
    "id": 3983,
    "label": "73.01.01.19"
}, {"id": 3984, "label": "73.01.01.20"}, {"id": 3985, "label": "73.01.02.01"}, {
    "id": 3986,
    "label": "73.01.02.02"
}, {"id": 3987, "label": "73.01.02.03"}, {"id": 3988, "label": "73.01.02.04"}, {
    "id": 3989,
    "label": "73.01.02.05"
}, {"id": 3990, "label": "73.01.02.06"}, {"id": 3991, "label": "73.01.02.07"}, {
    "id": 3992,
    "label": "73.01.02.08"
}, {"id": 3993, "label": "73.01.02.09"}, {"id": 3994, "label": "73.01.02.10"}, {
    "id": 3995,
    "label": "73.01.03.01"
}, {"id": 3996, "label": "73.01.03.02"}, {"id": 3997, "label": "73.01.03.04"}, {
    "id": 3998,
    "label": "73.01.03.05"
}, {"id": 3999, "label": "73.01.03.06"}, {"id": 4000, "label": "73.01.03.07"}, {
    "id": 4001,
    "label": "73.01.03.08"
}, {"id": 4002, "label": "73.01.03.09"}, {"id": 4003, "label": "73.01.03.10"}, {
    "id": 4004,
    "label": "73.01.03.11"
}, {"id": 4005, "label": "73.01.03.12"}, {"id": 4006, "label": "73.01.03.13"}, {
    "id": 4007,
    "label": "73.01.03.14"
}, {"id": 4008, "label": "73.01.03.15"}, {"id": 4009, "label": "73.01.03.16"}, {
    "id": 4010,
    "label": "73.01.04.01"
}, {"id": 4011, "label": "73.01.04.02"}, {"id": 4012, "label": "73.01.04.03"}, {
    "id": 4013,
    "label": "73.01.04.04"
}, {"id": 4014, "label": "73.01.04.05"}, {"id": 4015, "label": "73.01.04.06"}, {
    "id": 4016,
    "label": "73.01.04.07"
}, {"id": 4017, "label": "73.01.04.08"}, {"id": 4018, "label": "73.01.04.09"}, {
    "id": 4019,
    "label": "73.01.04.10"
}, {"id": 4020, "label": "73.01.04.11"}, {"id": 4021, "label": "73.01.04.12"}, {
    "id": 4022,
    "label": "73.01.04.13"
}, {"id": 4023, "label": "73.01.04.14"}, {"id": 4024, "label": "73.01.04.15"}, {
    "id": 4025,
    "label": "73.01.04.16"
}, {"id": 4026, "label": "73.01.04.17"}, {"id": 4027, "label": "73.01.04.18"}, {
    "id": 4028,
    "label": "73.01.04.19"
}, {"id": 4029, "label": "73.01.04.20"}, {"id": 4030, "label": "73.01.04.21"}, {
    "id": 4031,
    "label": "73.01.05.01"
}, {"id": 4032, "label": "73.01.05.02"}, {"id": 4033, "label": "73.01.05.03"}, {
    "id": 4034,
    "label": "73.01.05.05"
}, {"id": 4035, "label": "73.01.05.06"}, {"id": 4036, "label": "73.01.05.07"}, {
    "id": 4037,
    "label": "73.01.05.08"
}, {"id": 4038, "label": "73.01.05.09"}, {"id": 4039, "label": "73.01.05.10"}, {
    "id": 4040,
    "label": "73.01.05.11"
}, {"id": 4041, "label": "73.01.05.12"}, {"id": 4042, "label": "73.01.06.01"}, {
    "id": 4043,
    "label": "73.01.06.02"
}, {"id": 4044, "label": "73.01.07.01"}, {"id": 4045, "label": "73.02.01.01"}, {
    "id": 4046,
    "label": "73.02.01.02"
}, {"id": 4047, "label": "73.02.01.03"}, {"id": 4048, "label": "73.02.01.04"}, {
    "id": 4049,
    "label": "73.02.01.05"
}, {"id": 4050, "label": "73.02.01.06"}, {"id": 4051, "label": "73.02.01.07"}, {
    "id": 4052,
    "label": "73.02.01.08"
}, {"id": 4053, "label": "73.02.01.09"}, {"id": 4054, "label": "73.02.01.10"}, {
    "id": 4055,
    "label": "73.02.01.11"
}, {"id": 4056, "label": "73.02.01.12"}, {"id": 4057, "label": "73.02.02.01"}, {
    "id": 4058,
    "label": "73.02.02.02"
}, {"id": 4059, "label": "73.02.03.01"}, {"id": 4060, "label": "73.02.04.01"}, {
    "id": 4061,
    "label": "74.01.00.01"
}, {"id": 4062, "label": "74.01.00.02"}, {"id": 4063, "label": "74.01.00.03"}, {
    "id": 4064,
    "label": "74.01.00.04"
}, {"id": 4065, "label": "74.01.00.05"}, {"id": 4066, "label": "74.01.00.06"}, {
    "id": 4067,
    "label": "74.01.00.07"
}, {"id": 4068, "label": "74.01.00.08"}, {"id": 4069, "label": "74.01.00.09"}, {
    "id": 4070,
    "label": "74.01.00.10"
}, {"id": 4071, "label": "74.01.00.11"}, {"id": 4072, "label": "74.01.00.12"}, {
    "id": 4073,
    "label": "74.01.00.13"
}, {"id": 4074, "label": "74.01.00.14"}, {"id": 4075, "label": "74.01.00.15"}, {
    "id": 4076,
    "label": "74.01.00.16"
}, {"id": 4077, "label": "74.01.00.18"}, {"id": 4078, "label": "74.01.00.19"}, {
    "id": 4079,
    "label": "74.01.00.20"
}, {"id": 4080, "label": "74.01.00.21"}, {"id": 4081, "label": "74.01.00.22"}, {
    "id": 4082,
    "label": "74.01.00.23"
}, {"id": 4083, "label": "74.01.00.24"}, {"id": 4084, "label": "74.01.00.25"}, {
    "id": 4085,
    "label": "74.01.00.26"
}, {"id": 4086, "label": "74.01.00.27"}, {"id": 4087, "label": "74.01.00.28"}, {
    "id": 4088,
    "label": "74.01.00.29"
}, {"id": 4089, "label": "74.01.00.30"}, {"id": 4090, "label": "74.01.00.31"}, {
    "id": 4091,
    "label": "74.01.00.32"
}, {"id": 4092, "label": "74.01.00.33"}, {"id": 4093, "label": "74.01.00.34"}, {
    "id": 4094,
    "label": "74.01.00.35"
}, {"id": 4095, "label": "74.01.00.36"}, {"id": 4096, "label": "74.01.00.37"}, {
    "id": 4097,
    "label": "74.01.00.38"
}, {"id": 4098, "label": "74.01.00.39"}, {"id": 4099, "label": "74.01.00.40"}, {
    "id": 4100,
    "label": "74.01.00.41"
}, {"id": 4101, "label": "74.01.00.42"}, {"id": 4102, "label": "74.01.00.43"}, {
    "id": 4103,
    "label": "74.01.00.44"
}, {"id": 4104, "label": "74.01.00.45"}, {"id": 4105, "label": "74.01.00.46"}, {
    "id": 4106,
    "label": "74.01.00.47"
}, {"id": 4107, "label": "74.01.00.48"}, {"id": 4108, "label": "74.01.00.49"}, {
    "id": 4109,
    "label": "74.01.00.50"
}, {"id": 4110, "label": "74.01.00.51"}, {"id": 4111, "label": "74.01.00.52"}, {
    "id": 4112,
    "label": "74.01.00.53"
}, {"id": 4113, "label": "74.01.00.54"}, {"id": 4114, "label": "74.01.00.55"}, {
    "id": 4115,
    "label": "74.02.00.01"
}, {"id": 4116, "label": "74.02.00.02"}, {"id": 4117, "label": "74.03.00.01"}, {
    "id": 4118,
    "label": "74.03.00.02"
}, {"id": 4119, "label": "74.03.00.03"}, {"id": 4120, "label": "74.03.00.04"}, {
    "id": 4121,
    "label": "74.03.00.05"
}, {"id": 4122, "label": "74.03.00.06"}, {"id": 4123, "label": "74.03.00.07"}, {
    "id": 4124,
    "label": "74.03.00.08"
}, {"id": 4125, "label": "74.03.00.09"}, {"id": 4126, "label": "74.04.00.01"}, {
    "id": 4127,
    "label": "74.04.00.02"
}, {"id": 4128, "label": "74.04.00.03"}, {"id": 4129, "label": "74.04.00.04"}, {
    "id": 4130,
    "label": "74.04.00.05"
}, {"id": 4131, "label": "74.04.00.06"}, {"id": 4132, "label": "74.04.00.07"}, {
    "id": 4133,
    "label": "74.04.00.08"
}, {"id": 4134, "label": "74.04.00.09"}, {"id": 4135, "label": "74.04.00.10"}, {
    "id": 4136,
    "label": "74.04.00.11"
}, {"id": 4137, "label": "74.04.00.12"}, {"id": 4138, "label": "74.04.00.13"}, {
    "id": 4139,
    "label": "74.04.00.14"
}, {"id": 4140, "label": "74.04.00.15"}, {"id": 4141, "label": "74.04.00.16"}, {
    "id": 4142,
    "label": "74.04.00.17"
}, {"id": 4143, "label": "74.04.00.18"}, {"id": 4144, "label": "74.04.00.19"}, {
    "id": 4145,
    "label": "74.04.00.20"
}, {"id": 4146, "label": "74.04.00.21"}, {"id": 4147, "label": "74.04.00.22"}, {
    "id": 4148,
    "label": "74.04.00.23"
}, {"id": 4149, "label": "74.04.00.24"}, {"id": 4150, "label": "75.01.00.01"}, {
    "id": 4151,
    "label": "75.01.00.02"
}, {"id": 4152, "label": "75.01.00.03"}, {"id": 4153, "label": "75.01.00.04"}, {
    "id": 4154,
    "label": "75.01.00.05"
}, {"id": 4155, "label": "75.01.00.06"}, {"id": 4156, "label": "75.01.00.07"}, {
    "id": 4157,
    "label": "75.01.00.09"
}, {"id": 4158, "label": "75.01.00.10"}, {"id": 4159, "label": "75.01.00.11"}, {
    "id": 4160,
    "label": "75.01.00.12"
}, {"id": 4161, "label": "75.01.00.13"}, {"id": 4162, "label": "75.01.00.14"}, {
    "id": 4163,
    "label": "75.01.00.15"
}, {"id": 4164, "label": "75.01.00.16"}, {"id": 4165, "label": "75.01.00.17"}, {
    "id": 4166,
    "label": "75.01.00.18"
}, {"id": 4167, "label": "75.01.00.19"}, {"id": 4168, "label": "75.01.00.20"}, {
    "id": 4169,
    "label": "75.01.00.21"
}, {"id": 4170, "label": "75.01.00.22"}, {"id": 4171, "label": "75.01.00.23"}, {
    "id": 4172,
    "label": "75.01.00.24"
}, {"id": 4173, "label": "75.01.00.25"}, {"id": 4174, "label": "75.01.00.26"}, {
    "id": 4175,
    "label": "75.01.00.27"
}, {"id": 4176, "label": "75.01.00.28"}, {"id": 4177, "label": "75.01.00.29"}, {
    "id": 4178,
    "label": "75.01.00.30"
}, {"id": 4179, "label": "75.01.00.31"}, {"id": 4180, "label": "75.01.00.32"}, {
    "id": 4181,
    "label": "75.01.00.33"
}, {"id": 4182, "label": "75.01.00.34"}, {"id": 4183, "label": "75.02.00.01"}, {
    "id": 4184,
    "label": "75.02.00.02"
}, {"id": 4185, "label": "75.02.00.03"}, {"id": 4186, "label": "75.02.00.04"}, {
    "id": 4187,
    "label": "75.02.00.05"
}, {"id": 4188, "label": "75.02.00.06"}, {"id": 4189, "label": "75.02.00.07"}, {
    "id": 4190,
    "label": "75.02.00.08"
}, {"id": 4191, "label": "75.02.00.09"}, {"id": 4192, "label": "75.02.00.10"}, {
    "id": 4193,
    "label": "75.02.00.11"
}, {"id": 4194, "label": "75.02.00.12"}, {"id": 4195, "label": "75.02.00.13"}, {
    "id": 4196,
    "label": "75.02.00.14"
}, {"id": 4197, "label": "75.02.00.15"}, {"id": 4198, "label": "75.02.00.16"}, {
    "id": 4199,
    "label": "75.02.00.17"
}, {"id": 4200, "label": "75.02.00.18"}, {"id": 4201, "label": "75.02.00.19"}, {
    "id": 4202,
    "label": "75.02.00.20"
}, {"id": 4203, "label": "75.02.00.21"}, {"id": 4204, "label": "75.02.00.22"}, {
    "id": 4205,
    "label": "75.02.00.23"
}, {"id": 4206, "label": "75.02.00.24"}, {"id": 4207, "label": "75.02.00.25"}, {
    "id": 4208,
    "label": "75.02.00.26"
}, {"id": 4209, "label": "75.02.00.27"}, {"id": 4210, "label": "75.02.00.28"}, {
    "id": 4211,
    "label": "75.02.00.29"
}, {"id": 4212, "label": "75.02.00.30"}, {"id": 4213, "label": "75.02.00.31"}, {
    "id": 4214,
    "label": "75.02.00.32"
}, {"id": 4215, "label": "75.02.00.33"}, {"id": 4216, "label": "75.02.00.34"}, {
    "id": 4217,
    "label": "75.02.00.35"
}, {"id": 4218, "label": "75.02.00.36"}, {"id": 4219, "label": "75.02.00.37"}, {
    "id": 4220,
    "label": "75.02.00.38"
}, {"id": 4221, "label": "75.02.00.39"}, {"id": 4222, "label": "75.02.00.40"}, {
    "id": 4223,
    "label": "75.02.00.41"
}, {"id": 4224, "label": "75.02.00.42"}, {"id": 4225, "label": "75.02.00.43"}, {
    "id": 4226,
    "label": "75.02.00.44"
}, {"id": 4227, "label": "75.02.00.45"}, {"id": 4228, "label": "75.02.00.46"}, {
    "id": 4229,
    "label": "75.02.00.47"
}, {"id": 4230, "label": "75.02.00.48"}, {"id": 4231, "label": "75.02.00.49"}, {
    "id": 4232,
    "label": "75.02.00.50"
}, {"id": 4233, "label": "75.02.00.51"}, {"id": 4234, "label": "75.02.00.52"}, {
    "id": 4235,
    "label": "75.02.00.53"
}, {"id": 4236, "label": "75.02.00.54"}, {"id": 4237, "label": "75.02.00.55"}, {
    "id": 4238,
    "label": "75.02.00.56"
}, {"id": 4239, "label": "75.02.00.57"}, {"id": 4240, "label": "75.02.00.58"}, {
    "id": 4241,
    "label": "75.02.00.59"
}, {"id": 4242, "label": "75.02.00.60"}, {"id": 4243, "label": "75.03.00.01"}, {
    "id": 4244,
    "label": "75.03.00.02"
}, {"id": 4245, "label": "75.03.00.03"}, {"id": 4246, "label": "75.03.00.04"}, {
    "id": 4247,
    "label": "75.03.00.05"
}, {"id": 4248, "label": "75.03.00.06"}, {"id": 4249, "label": "75.03.00.07"}, {
    "id": 4250,
    "label": "75.03.00.08"
}, {"id": 4251, "label": "75.03.00.09"}, {"id": 4252, "label": "75.03.00.10"}, {
    "id": 4253,
    "label": "75.03.00.11"
}, {"id": 4254, "label": "75.03.00.12"}, {"id": 4255, "label": "75.03.00.13"}, {
    "id": 4331,
    "label": "75.04.00.48"
}, {"id": 4256, "label": "75.03.00.14"}, {"id": 4257, "label": "75.03.00.15"}, {
    "id": 4258,
    "label": "75.03.00.16"
}, {"id": 4259, "label": "75.03.00.17"}, {"id": 4260, "label": "75.03.00.18"}, {
    "id": 4261,
    "label": "75.03.00.19"
}, {"id": 4262, "label": "75.03.00.20"}, {"id": 4263, "label": "75.03.00.21"}, {
    "id": 4264,
    "label": "75.03.00.22"
}, {"id": 4265, "label": "75.03.00.23"}, {"id": 4266, "label": "75.03.00.24"}, {
    "id": 4267,
    "label": "75.03.00.25"
}, {"id": 4268, "label": "75.03.00.26"}, {"id": 4269, "label": "75.03.00.27"}, {
    "id": 4270,
    "label": "75.03.00.28"
}, {"id": 4271, "label": "75.03.00.29"}, {"id": 4272, "label": "75.03.00.30"}, {
    "id": 4273,
    "label": "75.03.00.31"
}, {"id": 4274, "label": "75.03.00.32"}, {"id": 4275, "label": "75.03.00.33"}, {
    "id": 4276,
    "label": "75.03.00.34"
}, {"id": 4277, "label": "75.03.00.35"}, {"id": 4278, "label": "75.03.00.36"}, {
    "id": 4279,
    "label": "75.03.00.37"
}, {"id": 4280, "label": "75.03.00.38"}, {"id": 4281, "label": "75.03.00.40"}, {
    "id": 4282,
    "label": "75.03.00.41"
}, {"id": 4283, "label": "75.03.00.43"}, {"id": 4284, "label": "75.04.00.01"}, {
    "id": 4285,
    "label": "75.04.00.02"
}, {"id": 4286, "label": "75.04.00.03"}, {"id": 4287, "label": "75.04.00.04"}, {
    "id": 4288,
    "label": "75.04.00.05"
}, {"id": 4289, "label": "75.04.00.06"}, {"id": 4290, "label": "75.04.00.07"}, {
    "id": 4291,
    "label": "75.04.00.08"
}, {"id": 4292, "label": "75.04.00.09"}, {"id": 4293, "label": "75.04.00.10"}, {
    "id": 4294,
    "label": "75.04.00.11"
}, {"id": 4295, "label": "75.04.00.12"}, {"id": 4296, "label": "75.04.00.13"}, {
    "id": 4297,
    "label": "75.04.00.14"
}, {"id": 4298, "label": "75.04.00.15"}, {"id": 4299, "label": "75.04.00.16"}, {
    "id": 4300,
    "label": "75.04.00.17"
}, {"id": 4301, "label": "75.04.00.18"}, {"id": 4302, "label": "75.04.00.19"}, {
    "id": 4303,
    "label": "75.04.00.20"
}, {"id": 4304, "label": "75.04.00.21"}, {"id": 4305, "label": "75.04.00.22"}, {
    "id": 4306,
    "label": "75.04.00.23"
}, {"id": 4307, "label": "75.04.00.24"}, {"id": 4308, "label": "75.04.00.25"}, {
    "id": 4309,
    "label": "75.04.00.26"
}, {"id": 4310, "label": "75.04.00.27"}, {"id": 4311, "label": "75.04.00.28"}, {
    "id": 4312,
    "label": "75.04.00.29"
}, {"id": 4313, "label": "75.04.00.30"}, {"id": 4314, "label": "75.04.00.31"}, {
    "id": 4315,
    "label": "75.04.00.32"
}, {"id": 4316, "label": "75.04.00.33"}, {"id": 4317, "label": "75.04.00.34"}, {
    "id": 4318,
    "label": "75.04.00.35"
}, {"id": 4319, "label": "75.04.00.36"}, {"id": 4320, "label": "75.04.00.37"}, {
    "id": 4321,
    "label": "75.04.00.38"
}, {"id": 4322, "label": "75.04.00.39"}, {"id": 4323, "label": "75.04.00.40"}, {
    "id": 4324,
    "label": "75.04.00.41"
}, {"id": 4325, "label": "75.04.00.42"}, {"id": 4326, "label": "75.04.00.43"}, {
    "id": 4327,
    "label": "75.04.00.44"
}, {"id": 4328, "label": "75.04.00.45"}, {"id": 4329, "label": "75.04.00.46"}, {
    "id": 4330,
    "label": "75.04.00.47"
}, {"id": 4332, "label": "75.04.00.49"}, {"id": 4333, "label": "75.04.00.50"}, {
    "id": 4334,
    "label": "75.04.00.51"
}, {"id": 4335, "label": "75.04.00.52"}, {"id": 4336, "label": "75.04.00.53"}, {
    "id": 4337,
    "label": "75.04.00.54"
}, {"id": 4338, "label": "75.04.00.55"}, {"id": 4339, "label": "75.04.00.56"}, {
    "id": 4340,
    "label": "75.04.00.57"
}, {"id": 4341, "label": "75.04.00.58"}, {"id": 4342, "label": "75.04.00.59"}, {
    "id": 4343,
    "label": "75.04.00.60"
}, {"id": 4344, "label": "75.04.00.61"}, {"id": 4345, "label": "75.04.00.62"}, {
    "id": 4346,
    "label": "75.04.00.63"
}, {"id": 4347, "label": "75.04.00.64"}, {"id": 4348, "label": "75.04.00.65"}, {
    "id": 4349,
    "label": "75.04.00.66"
}, {"id": 4350, "label": "75.04.00.67"}, {"id": 4351, "label": "75.04.00.68"}, {
    "id": 4352,
    "label": "75.04.00.69"
}, {"id": 4353, "label": "75.04.00.70"}, {"id": 4354, "label": "75.04.00.71"}, {
    "id": 4355,
    "label": "75.04.00.72"
}, {"id": 4356, "label": "75.04.00.73"}, {"id": 4357, "label": "75.04.00.74"}, {
    "id": 4358,
    "label": "75.04.00.75"
}, {"id": 4359, "label": "75.04.00.76"}, {"id": 4360, "label": "75.04.00.77"}, {
    "id": 4361,
    "label": "75.04.00.78"
}, {"id": 4362, "label": "75.04.00.79"}, {"id": 4363, "label": "75.04.00.80"}, {
    "id": 4364,
    "label": "75.04.00.81"
}, {"id": 4365, "label": "75.04.00.82"}, {"id": 4366, "label": "75.04.00.83"}, {
    "id": 4367,
    "label": "75.04.00.84"
}, {"id": 4368, "label": "75.04.00.85"}, {"id": 4369, "label": "75.04.00.86"}, {
    "id": 4370,
    "label": "75.04.00.87"
}, {"id": 4371, "label": "75.04.00.88"}, {"id": 4372, "label": "75.04.00.89"}, {
    "id": 4373,
    "label": "75.04.00.90"
}, {"id": 4374, "label": "75.04.00.91"}, {"id": 4375, "label": "75.04.00.92"}, {
    "id": 4376,
    "label": "75.04.00.93"
}, {"id": 4377, "label": "75.04.00.94"}, {"id": 4378, "label": "75.04.00.95"}, {
    "id": 4379,
    "label": "75.04.00.96"
}, {"id": 4380, "label": "75.04.00.97"}, {"id": 4381, "label": "75.04.00.98"}, {
    "id": 4382,
    "label": "75.04.00.99"
}, {"id": 4383, "label": "75.04.01.00"}, {"id": 4384, "label": "75.04.01.01"}, {
    "id": 4385,
    "label": "75.04.01.02"
}, {"id": 4386, "label": "75.04.01.03"}, {"id": 4387, "label": "75.05.00.01"}, {
    "id": 4388,
    "label": "75.05.00.02"
}, {"id": 4389, "label": "75.05.00.03"}, {"id": 4390, "label": "75.05.00.04"}, {
    "id": 4391,
    "label": "75.05.00.05"
}, {"id": 4392, "label": "75.05.00.06"}, {"id": 4393, "label": "75.05.00.07"}, {
    "id": 4394,
    "label": "75.05.00.08"
}, {"id": 4395, "label": "75.05.00.09"}, {"id": 4396, "label": "75.05.00.10"}, {
    "id": 4397,
    "label": "75.05.00.11"
}, {"id": 4398, "label": "75.05.00.12"}, {"id": 4399, "label": "75.05.00.13"}, {
    "id": 4400,
    "label": "75.05.00.14"
}, {"id": 4401, "label": "75.05.00.15"}, {"id": 4402, "label": "75.05.00.16"}, {
    "id": 4403,
    "label": "75.05.00.17"
}, {"id": 4404, "label": "76.00.00.01"}, {"id": 4405, "label": "76.00.00.02"}, {
    "id": 4406,
    "label": "76.00.00.03"
}, {"id": 4407, "label": "76.00.00.04"}, {"id": 4408, "label": "76.00.00.05"}, {
    "id": 4409,
    "label": "76.00.00.06"
}, {"id": 4410, "label": "76.00.00.07"}, {"id": 4411, "label": "76.00.00.08"}, {
    "id": 4412,
    "label": "76.00.00.09"
}, {"id": 4413, "label": "76.00.00.10"}, {"id": 4414, "label": "76.00.00.11"}, {
    "id": 4415,
    "label": "76.00.00.12"
}, {"id": 4416, "label": "76.00.00.13"}, {"id": 4417, "label": "76.00.00.14"}, {
    "id": 4418,
    "label": "76.00.00.15"
}, {"id": 4419, "label": "76.00.00.16"}, {"id": 4420, "label": "76.00.00.17"}, {
    "id": 4421,
    "label": "76.00.00.18"
}, {"id": 4422, "label": "76.00.00.19"}, {"id": 4423, "label": "76.00.00.20"}, {
    "id": 4424,
    "label": "76.01.00.01"
}, {"id": 4425, "label": "76.01.00.02"}, {"id": 4426, "label": "76.01.00.03"}, {
    "id": 4427,
    "label": "76.01.00.04"
}, {"id": 4428, "label": "76.01.00.05"}, {"id": 4429, "label": "76.01.00.06"}, {
    "id": 4430,
    "label": "76.01.00.07"
}, {"id": 4431, "label": "76.01.00.08"}, {"id": 4432, "label": "80.00.00.01"}, {
    "id": 4433,
    "label": "80.00.00.02"
}, {"id": 4434, "label": "80.00.00.03"}, {"id": 4435, "label": "80.00.00.04"}, {
    "id": 4436,
    "label": "80.00.00.05"
}, {"id": 4437, "label": "80.00.00.06"}, {"id": 4438, "label": "80.00.00.07"}, {
    "id": 4439,
    "label": "81.00.00.01"
}, {"id": 4440, "label": "81.00.00.02"}, {"id": 4441, "label": "81.00.00.03"}, {
    "id": 4442,
    "label": "81.00.00.04"
}, {"id": 4443, "label": "81.00.00.05"}, {"id": 4444, "label": "81.00.00.06"}, {
    "id": 4445,
    "label": "81.00.00.07"
}, {"id": 4446, "label": "81.00.00.08"}, {"id": 4447, "label": "81.00.00.09"}, {
    "id": 4448,
    "label": "81.00.00.10"
}, {"id": 4449, "label": "81.00.00.11"}, {"id": 4450, "label": "81.00.00.12"}, {
    "id": 4451,
    "label": "81.00.00.13"
}, {"id": 4452, "label": "81.00.00.14"}, {"id": 4453, "label": "81.00.00.15"}, {
    "id": 4454,
    "label": "81.00.00.16"
}, {"id": 4455, "label": "81.00.00.17"}, {"id": 4456, "label": "81.00.00.18"}, {
    "id": 4457,
    "label": "90.00.00.01"
}, {"id": 4458, "label": "90.00.00.02"}, {"id": 4459, "label": "90.00.00.03"}, {
    "id": 4460,
    "label": "90.00.00.04"
}, {"id": 4461, "label": "90.00.00.05"}, {"id": 4462, "label": "90.00.00.06"}, {
    "id": 4463,
    "label": "90.00.00.07"
}, {"id": 4464, "label": "90.00.00.08"}, {"id": 4465, "label": "90.00.00.09"}, {
    "id": 4466,
    "label": "90.01.00.01"
}, {"id": 4467, "label": "90.01.00.02"}, {"id": 4468, "label": "90.01.00.03"}, {
    "id": 4469,
    "label": "90.01.00.04"
}, {"id": 4470, "label": "90.01.00.05"}, {"id": 4471, "label": "90.01.00.06"}, {
    "id": 4472,
    "label": "90.01.00.07"
}, {"id": 4473, "label": "90.01.00.08"}, {"id": 4474, "label": "90.02.00.01"}, {
    "id": 4475,
    "label": "90.02.00.02"
}, {"id": 4476, "label": "90.02.00.03"}, {"id": 4477, "label": "90.02.00.04"}, {
    "id": 4478,
    "label": "90.02.00.05"
}, {"id": 4479, "label": "90.03.00.01"}, {"id": 4480, "label": "90.03.00.02"}, {
    "id": 4481,
    "label": "90.03.00.03"
}, {"id": 4482, "label": "90.03.00.04"}, {"id": 4483, "label": "90.03.00.05"}, {
    "id": 4484,
    "label": "90.04.00.01"
}, {"id": 4485, "label": "90.04.00.02"}, {"id": 4486, "label": "90.04.00.03"}, {
    "id": 4487,
    "label": "90.04.00.04"
}, {"id": 4488, "label": "90.04.00.05"}, {"id": 4489, "label": "90.04.00.06"}, {
    "id": 4490,
    "label": "90.04.00.07"
}, {"id": 4491, "label": "90.04.00.08"}, {"id": 4492, "label": "90.05.00.01"}, {
    "id": 4493,
    "label": "90.05.00.02"
}, {"id": 4494, "label": "90.05.00.03"}, {"id": 4495, "label": "90.05.00.04"}, {
    "id": 4496,
    "label": "90.05.00.05"
}, {"id": 4497, "label": "90.05.00.06"}, {"id": 4498, "label": "90.06.00.01"}, {
    "id": 4499,
    "label": "90.06.00.02"
}, {"id": 4500, "label": "90.06.00.03"}, {"id": 4501, "label": "90.06.00.04"}, {
    "id": 4502,
    "label": "90.06.00.05"
}, {"id": 4503, "label": "90.06.00.06"}, {"id": 4504, "label": "90.06.00.07"}, {
    "id": 4505,
    "label": "90.06.00.08"
}, {"id": 4506, "label": "90.06.00.09"}, {"id": 4507, "label": "90.07.00.01"}, {
    "id": 4508,
    "label": "90.07.00.02"
}, {"id": 4509, "label": "90.07.00.03"}, {"id": 4510, "label": "90.07.00.04"}, {
    "id": 4511,
    "label": "90.08.00.01"
}, {"id": 4512, "label": "90.08.00.02"}, {"id": 4513, "label": "90.08.00.03"}, {
    "id": 4514,
    "label": "90.08.00.04"
}, {"id": 4515, "label": "90.08.00.05"}, {"id": 4516, "label": "90.08.00.06"}, {
    "id": 4517,
    "label": "90.08.00.07"
}, {"id": 4518, "label": "90.09.00.01"}, {"id": 4519, "label": "90.09.00.02"}, {
    "id": 4520,
    "label": "90.09.00.03"
}, {"id": 4521, "label": "90.09.00.04"}, {"id": 4522, "label": "90.09.00.05"}, {
    "id": 4523,
    "label": "90.09.00.06"
}, {"id": 4524, "label": "90.10.00.01"}, {"id": 4525, "label": "90.10.00.02"}, {
    "id": 4526,
    "label": "90.10.00.03"
}, {"id": 4527, "label": "90.10.00.04"}, {"id": 4528, "label": "90.10.00.05"}, {
    "id": 4529,
    "label": "90.10.00.06"
}, {"id": 4530, "label": "90.10.00.07"}, {"id": 4531, "label": "90.10.00.08"}];

const subProceduresList = [
    {
        "id": 1,
        "label": "Consultas no Consultório - Não Especialista-1a. Consulta",
        "k": "10",
        "c": "0",
        "code": "01.00.00.01"
    },
    {
        "id": 2,
        "label": "Consultas no Consultório - Não Especialista-2a. Consulta",
        "k": "8",
        "c": "0",
        "code": "01.00.00.02"
    },
    {
        "id": 3,
        "label": "Consultas no Consultório - Especialista-1a. Consulta",
        "k": "12",
        "c": "0",
        "code": "01.00.00.03"
    },
    {
        "id": 4,
        "label": "Consultas no Consultório - Especialista-2a. Consulta",
        "k": "10",
        "c": "0",
        "code": "01.00.00.04"
    },
    {
        "id": 5,
        "label": "Consultas no Consultório - Psiquiatria e Oftalmologia-1a. consulta",
        "k": "14",
        "c": "0",
        "code": "01.00.00.05"
    },
    {
        "id": 6,
        "label": "Consultas no Consultório - Psiquiatria e Oftalmologia-2a. consulta",
        "k": "12",
        "c": "0",
        "code": "01.00.00.06"
    },
    {
        "id": 7,
        "label": "Consultas no Domicílio - Não Especialista-1a. consulta",
        "k": "15",
        "c": "0",
        "code": "01.01.00.01"
    },
    {
        "id": 8,
        "label": "Consultas no Domicílio - Não Especialista-2a. consulta",
        "k": "12",
        "c": "0",
        "code": "01.01.00.02"
    },
    {
        "id": 9,
        "label": "Consultas no Domicílio - Especialista-1a. Consulta",
        "k": "18",
        "c": "0",
        "code": "01.01.00.03"
    },
    {
        "id": 10,
        "label": "Consultas no Domicílio - Especialista-2a. Consulta",
        "k": "15",
        "c": "0",
        "code": "01.01.00.04"
    },
    {
        "id": 11,
        "label": "Consultas no Domicílio - Psiquiatria-1a. Consulta",
        "k": "21",
        "c": "0",
        "code": "01.01.00.05"
    },
    {
        "id": 12,
        "label": "Consultas no Domicílio - Psiquiatria-2a. Consulta",
        "k": "18",
        "c": "0",
        "code": "01.01.00.06"
    },
    {
        "id": 13,
        "label": "Não Especialista-1a. Consulta",
        "k": "20",
        "c": "0",
        "code": "01.02.00.01"
    },
    {
        "id": 14,
        "label": "Não Especialista-2a. Consulta",
        "k": "15",
        "c": "0",
        "code": "01.02.00.02"
    },
    {
        "id": 15,
        "label": "Especialista-1a. Consulta",
        "k": "24",
        "c": "0",
        "code": "01.02.00.03"
    },
    {
        "id": 16,
        "label": "Especialista-2a. consulta",
        "k": "20",
        "c": "0",
        "code": "01.02.00.04"
    },
    {
        "id": 17,
        "label": "Psiquiatria-1a. consulta",
        "k": "28",
        "c": "0",
        "code": "01.02.00.05"
    },
    {
        "id": 18,
        "label": "Psiquiatria-2a. consulta",
        "k": "24",
        "c": "0",
        "code": "01.02.00.06"
    },
    {
        "id": 19,
        "label": "Exame pericial com relatório",
        "k": "40",
        "c": "0",
        "code": "01.03.00.02"
    },
    {
        "id": 20,
        "label": "Exame pericial em testamento",
        "k": "60",
        "c": "0",
        "code": "01.03.00.03"
    },
    {
        "id": 21,
        "label": "Relatório do processo clínico",
        "k": "6",
        "c": "0",
        "code": "01.03.00.04"
    },
    {
        "id": 22,
        "label": "Deslocação",
        "k": "0",
        "c": "0",
        "code": "01.03.00.05"
    },
    {
        "id": 23,
        "label": "Acompanhamento permanente do doente (por dia)",
        "k": "100",
        "c": "0",
        "code": "01.03.00.06"
    },
    {
        "id": 24,
        "label": "Avaliação do tratamento inicial do doente em condição crítica (até 1a. hora)",
        "k": "30",
        "c": "0",
        "code": "01.03.00.07"
    },
    {
        "id": 25,
        "label": "Assistência permanente adicional (cada 1 hora)",
        "k": "20",
        "c": "0",
        "code": "01.03.00.08"
    },
    {
        "id": 26,
        "label": "Exame sob anestesia geral (como acto médico)",
        "k": "12",
        "c": "0",
        "code": "01.03.00.09"
    },
    {
        "id": 27,
        "label": "Assistência a actos operatórios (por hora)",
        "k": "20",
        "c": "0",
        "code": "01.03.00.10"
    },
    {
        "id": 28,
        "label": "Observação de um recém-nascido",
        "k": "25",
        "c": "0",
        "code": "01.03.00.11"
    },
    {
        "id": 29,
        "label": "Assistência pediátrica ao parto, e observação de recém-nascido",
        "k": "30",
        "c": "0",
        "code": "01.03.00.12"
    },
    {
        "id": 30,
        "label": "Algaliação na Mulher",
        "k": "1",
        "c": "0",
        "code": "02.00.00.01"
    },
    {
        "id": 31,
        "label": "Algaliação no Homem",
        "k": "3",
        "c": "0",
        "code": "02.00.00.02"
    },
    {
        "id": 32,
        "label": "Paracentese",
        "k": "5",
        "c": "0",
        "code": "02.00.00.03"
    },
    {
        "id": 33,
        "label": "Pericardiocentese",
        "k": "20",
        "c": "0",
        "code": "02.00.00.04"
    },
    {
        "id": 34,
        "label": "Torancentese",
        "k": "15",
        "c": "0",
        "code": "02.00.00.05"
    },
    {
        "id": 35,
        "label": "Punção testicular",
        "k": "6",
        "c": "0",
        "code": "02.00.00.06"
    },
    {
        "id": 36,
        "label": "Punção articular",
        "k": "6",
        "c": "0",
        "code": "02.00.00.07"
    },
    {
        "id": 37,
        "label": "Punção da bolsa sub-deltoideia",
        "k": "6",
        "c": "0",
        "code": "02.00.00.08"
    },
    {
        "id": 38,
        "label": "Punção prostática",
        "k": "6",
        "c": "0",
        "code": "02.00.00.09"
    },
    {
        "id": 39,
        "label": "Punção lombar-terapêutica ou exploradora",
        "k": "8",
        "c": "0",
        "code": "02.00.00.10"
    },
    {
        "id": 40,
        "label": "Punção com drenagem de derrame pleural ou peritoneal",
        "k": "10",
        "c": "0",
        "code": "02.00.00.11"
    },
    {
        "id": 41,
        "label": "Aspiração de abcesso, hematoma, seroma ou quisto",
        "k": "6",
        "c": "0",
        "code": "02.00.00.12"
    },
    {
        "id": 42,
        "label": "Colpocentese",
        "k": "6",
        "c": "0",
        "code": "02.00.00.13"
    },
    {
        "id": 43,
        "label": "Colocação de cateter umbilical no RN",
        "k": "6",
        "c": "0",
        "code": "02.00.00.14"
    },
    {
        "id": 44,
        "label": "Desbridamento arterial ou venoso",
        "k": "20",
        "c": "0",
        "code": "02.00.00.15"
    },
    {
        "id": 45,
        "label": "Exanguíneo transfusão",
        "k": "60",
        "c": "0",
        "code": "02.00.00.16"
    },
    {
        "id": 46,
        "label": "Transfusão fetal intra-uterina",
        "k": "80",
        "c": "0",
        "code": "02.00.00.17"
    },
    {
        "id": 47,
        "label": "Punção femoral, jugular ou do seio longitudinal superior",
        "k": "3",
        "c": "0",
        "code": "02.00.00.18"
    },
    {
        "id": 48,
        "label": "Transfusão ou perfusão intravenosa (Aplicação)",
        "k": "3",
        "c": "0",
        "code": "02.00.00.19"
    },
    {
        "id": 49,
        "label": "Perfusão epicraniana",
        "k": "3",
        "c": "0",
        "code": "02.00.00.20"
    },
    {
        "id": 50,
        "label": "Colheita de sangue fetal",
        "k": "20",
        "c": "0",
        "code": "02.00.00.21"
    },
    {
        "id": 51,
        "label": "Intubação gástrica",
        "k": "3",
        "c": "0",
        "code": "02.00.00.22"
    },
    {
        "id": 52,
        "label": "Intubação duodenal",
        "k": "9",
        "c": "0",
        "code": "02.00.00.23"
    },
    {
        "id": 53,
        "label": "Lavagem gástrica",
        "k": "6",
        "c": "0",
        "code": "02.00.00.24"
    },
    {
        "id": 54,
        "label": "Punção arterial",
        "k": "3",
        "c": "0",
        "code": "02.00.00.25"
    },
    {
        "id": 55,
        "label": "Pensos",
        "k": "0",
        "c": "2",
        "code": "02.00.00.26"
    },
    {
        "id": 56,
        "label": "Infusão para quimioterapia",
        "k": "5",
        "c": "0",
        "code": "03.00.00.01"
    },
    {
        "id": 57,
        "label": "Injecção intracavitária para quimioterapia",
        "k": "8",
        "c": "0",
        "code": "03.00.00.02"
    },
    {
        "id": 58,
        "label": "Injecção intratecal para quimioterapia",
        "k": "10",
        "c": "0",
        "code": "03.00.00.03"
    },
    {
        "id": 59,
        "label": "Injecção esclerosante de varizes (por sessão)",
        "k": "10",
        "c": "0",
        "code": "03.00.00.04"
    },
    {
        "id": 60,
        "label": "Outras injecções",
        "k": "5",
        "c": "0",
        "code": "03.00.00.05"
    },
    {
        "id": 61,
        "label": "Consulta de grupo",
        "k": "3",
        "c": "0",
        "code": "04.00.00.01"
    },
    {
        "id": 62,
        "label": "Terapêutica convulsivante (electrochoque)",
        "k": "8",
        "c": "0",
        "code": "04.00.00.02"
    },
    {
        "id": 63,
        "label": "Terapêutica insulínica",
        "k": "8",
        "c": "0",
        "code": "04.00.00.03"
    },
    {
        "id": 64,
        "label": "Testes psicológicos",
        "k": "8",
        "c": "0",
        "code": "04.00.00.04"
    },
    {
        "id": 65,
        "label": "Bateria de testes psicológicos, com relatório",
        "k": "30",
        "c": "0",
        "code": "04.00.00.05"
    },
    {
        "id": 66,
        "label": "Relatório médico-legal",
        "k": "80",
        "c": "0",
        "code": "04.00.00.06"
    },
    {
        "id": 67,
        "label": "Hemodiálise aguda",
        "k": "10",
        "c": "180",
        "code": "05.00.00.01"
    },
    {
        "id": 68,
        "label": "Hemodiálise crónica com filtro novo",
        "k": "6",
        "c": "180",
        "code": "05.00.00.02"
    },
    {
        "id": 69,
        "label": "Hemodiálise crónica com filtro reutilizado",
        "k": "6",
        "c": "160",
        "code": "05.00.00.03"
    },
    {
        "id": 70,
        "label": "Hemodiálise com bicarbonato acresce",
        "k": "0",
        "c": "15",
        "code": "05.00.00.04"
    },
    {
        "id": 71,
        "label": "Hemodiálise pediátrica acresce",
        "k": "0",
        "c": "15",
        "code": "05.00.00.05"
    },
    {
        "id": 72,
        "label": "Hemodiálise em doentes HBs Ag positivos acresce",
        "k": "0",
        "c": "15",
        "code": "05.00.00.06"
    },
    {
        "id": 73,
        "label": "Hemofiltração contínua arteriovenosa",
        "k": "6",
        "c": "320",
        "code": "05.00.00.07"
    },
    {
        "id": 74,
        "label": "Hemoperfusão",
        "k": "6",
        "c": "320",
        "code": "05.00.00.08"
    },
    {
        "id": 75,
        "label": "Plasmaferese",
        "k": "6",
        "c": "320",
        "code": "05.00.00.09"
    },
    {
        "id": 76,
        "label": "Dilatação esofágica (cada sessão)",
        "k": "10",
        "c": "5",
        "code": "06.00.00.01"
    },
    {
        "id": 77,
        "label": "Dilatação esofágica (por endoscopia)",
        "k": "30",
        "c": "27",
        "code": "06.00.00.02"
    },
    {
        "id": 78,
        "label": "Tratamento de varizes por via endoscópica (esclerose)",
        "k": "30",
        "c": "25",
        "code": "06.00.00.03"
    },
    {
        "id": 79,
        "label": "Extracção de corpo estranho por via endoscópica",
        "k": "30",
        "c": "25",
        "code": "06.00.00.04"
    },
    {
        "id": 80,
        "label": "Colocação de prótese esofágica (excluindo a prótese)",
        "k": "65",
        "c": "27",
        "code": "06.00.00.05"
    },
    {
        "id": 81,
        "label": "Tamponamento de varizes esofágicas",
        "k": "25",
        "c": "0",
        "code": "06.00.00.06"
    },
    {
        "id": 82,
        "label": "Biópsia por cápsula",
        "k": "10",
        "c": "15",
        "code": "06.00.00.07"
    },
    {
        "id": 83,
        "label": "Manometria esofágica",
        "k": "20",
        "c": "10",
        "code": "06.00.00.08"
    },
    {
        "id": 84,
        "label": "Quimismo gástrico, basal",
        "k": "3",
        "c": "0",
        "code": "06.00.00.09"
    },
    {
        "id": 85,
        "label": "Quimismo gástrico, com estimulação",
        "k": "6",
        "c": "0",
        "code": "06.00.00.10"
    },
    {
        "id": 86,
        "label": "Pancreatografia e/ou colangiografia retrógada (CPRE)",
        "k": "40",
        "c": "50",
        "code": "06.00.00.11"
    },
    {
        "id": 87,
        "label": "Esfincterotomia transendoscópica",
        "k": "50",
        "c": "80",
        "code": "06.00.00.12"
    },
    {
        "id": 88,
        "label": "Esfincterotomia transendoscópica com extracção de cálculo",
        "k": "60",
        "c": "80",
        "code": "06.00.00.13"
    },
    {
        "id": 89,
        "label": "Extracção de cálculo por via transendoscópica",
        "k": "50",
        "c": "50",
        "code": "06.00.00.14"
    },
    {
        "id": 90,
        "label": "Colocação transcutânea de prótese de drenagem biliar",
        "k": "50",
        "c": "0",
        "code": "06.00.00.15"
    },
    {
        "id": 91,
        "label": "Colangiografia percutânea (CPT)",
        "k": "30",
        "c": "0",
        "code": "06.00.00.16"
    },
    {
        "id": 92,
        "label": "Implantação endoscópica da prótese de drenagem biliar",
        "k": "50",
        "c": "50",
        "code": "06.00.00.17"
    },
    {
        "id": 93,
        "label": "Tratamento esclerosante de hemorróidas (por sessão)",
        "k": "6",
        "c": "0",
        "code": "06.00.00.18"
    },
    {
        "id": 94,
        "label": "Injecção sub-fissurária",
        "k": "5",
        "c": "0",
        "code": "06.00.00.19"
    },
    {
        "id": 95,
        "label": "Tratamento de hemorróidas por laqueação elástica (por sessão)",
        "k": "6",
        "c": "0",
        "code": "06.00.00.20"
    },
    {
        "id": 96,
        "label": "Polipectomia do rectosigmoide com tubo rígido (incluindo exame endoscópico)",
        "k": "20",
        "c": "10",
        "code": "06.00.00.21"
    },
    {
        "id": 97,
        "label": "Polipectomia do tubo digestivo a adicionar ao respectivo exame endoscópico",
        "k": "10",
        "c": "30",
        "code": "06.00.00.22"
    },
    {
        "id": 98,
        "label": "Colheita de material para citologia esfoliativa",
        "k": "3",
        "c": "0",
        "code": "06.00.00.23"
    },
    {
        "id": 99,
        "label": "Determinação do pH por eléctrodo no tubo digestivo",
        "k": "10",
        "c": "20",
        "code": "06.00.00.24"
    },
    {
        "id": 100,
        "label": "Pneumoperitoneo",
        "k": "20",
        "c": "0",
        "code": "06.00.00.25"
    },
    {
        "id": 101,
        "label": "Retropneumoperitoneo",
        "k": "25",
        "c": "0",
        "code": "06.00.00.26"
    },
    {
        "id": 102,
        "label": "Gastrostomia por via endoscópica",
        "k": "50",
        "c": "30",
        "code": "06.00.00.27"
    },
    {
        "id": 103,
        "label": "Tratamento de hemorróidas por infravermelhos",
        "k": "6",
        "c": "5",
        "code": "06.00.00.28"
    },
    {
        "id": 104,
        "label": "Tratamento de hemorróidas por criocoagulação",
        "k": "10",
        "c": "10",
        "code": "06.00.00.29"
    },
    {
        "id": 105,
        "label": "Ecoendoscopia",
        "k": "50",
        "c": "200",
        "code": "06.00.00.30"
    },
    {
        "id": 106,
        "label": "Manometria ano-rectal",
        "k": "30",
        "c": "25",
        "code": "06.00.00.31"
    },
    {
        "id": 107,
        "label": "Terapêutica hemostática (não varicosa) a adicionar ao respectivo exame endoscópico",
        "k": "20",
        "c": "10",
        "code": "06.00.00.32"
    },
    {
        "id": 108,
        "label": "Terapêutica por raio laser a adicionar ao respectivo exame endoscópico (cada sessão)",
        "k": "30",
        "c": "100",
        "code": "06.00.00.33"
    },
    {
        "id": 109,
        "label": "Litotripsia biliar extracorporal",
        "k": "50",
        "c": "250",
        "code": "06.00.00.34"
    },
    {
        "id": 110,
        "label": "Teste Respiratório com Carbono 13 (diagnóstico da infecção pelo Helicobacter pylori)",
        "k": "3",
        "c": "35",
        "code": "06.00.00.35"
    },
    {
        "id": 111,
        "label": "Exame oftalmológico completo sob anestesia geral, com ou sem manipulação do globo ocular, para diagnóstico inicial, relatório médico",
        "k": "30",
        "c": "0",
        "code": "07.00.00.01"
    },
    {
        "id": 112,
        "label": "Gonioscopia",
        "k": "6",
        "c": "2",
        "code": "07.00.00.02"
    },
    {
        "id": 113,
        "label": "Estudo moto-sensorial efectuado ao sinoptóforo",
        "k": "12",
        "c": "7",
        "code": "07.00.00.03"
    },
    {
        "id": 114,
        "label": "Sessão de tratamento ortóptico ou pleóptico",
        "k": "4",
        "c": "4",
        "code": "07.00.00.04"
    },
    {
        "id": 115,
        "label": "Avaliação da visão binocular de perto e longe com testes subjectivos de fixação",
        "k": "6",
        "c": "2",
        "code": "07.00.00.05"
    },
    {
        "id": 116,
        "label": "Gráfico sinoptométrico",
        "k": "18",
        "c": "5",
        "code": "07.00.00.06"
    },
    {
        "id": 117,
        "label": "Gráfico de Hess",
        "k": "10",
        "c": "5",
        "code": "07.00.00.07"
    },
    {
        "id": 118,
        "label": "Campo visual binocular",
        "k": "16",
        "c": "5",
        "code": "07.00.00.08"
    },
    {
        "id": 119,
        "label": "Adaptação de lentes de contacto com fins terapêuticos (não inclui o preço da lente)",
        "k": "12",
        "c": "0",
        "code": "07.00.00.09"
    },
    {
        "id": 120,
        "label": "Avaliação de campos visuais, exame limitado (estimulos simples/equivalentes)",
        "k": "12",
        "c": "5",
        "code": "07.00.00.10"
    },
    {
        "id": 121,
        "label": "Avaliação dos campos visuais, exame intermédio (estimulos múltiplos, compo completo, vária esoptéras no perímetro Goldmann/equivalente)",
        "k": "18",
        "c": "5",
        "code": "07.00.00.11"
    },
    {
        "id": 122,
        "label": "Avaliação dos campos visuais, exame extenso (perimetria quantitativa, estática ou cinética)",
        "k": "30",
        "c": "8",
        "code": "07.00.00.12"
    },
    {
        "id": 123,
        "label": "Perimetria computadorizada",
        "k": "15",
        "c": "20",
        "code": "07.00.00.13"
    },
    {
        "id": 124,
        "label": "Curva tonométrica de 24 horas",
        "k": "30",
        "c": "0",
        "code": "07.00.00.14"
    },
    {
        "id": 125,
        "label": "Tonografia",
        "k": "15",
        "c": "10",
        "code": "07.00.00.15"
    },
    {
        "id": 126,
        "label": "Tonografia com testes de provocação de glaucoma",
        "k": "18",
        "c": "10",
        "code": "07.00.00.16"
    },
    {
        "id": 127,
        "label": "Testes de provocação de glaucoma sem tonografia",
        "k": "8",
        "c": "0",
        "code": "07.00.00.17"
    },
    {
        "id": 128,
        "label": "Elaboração de relatório médico com base nos elementos do processo clínico",
        "k": "12",
        "c": "0",
        "code": "07.00.00.18"
    },
    {
        "id": 129,
        "label": "Exame oftalmológico para fins médico legais com relatório",
        "k": "20",
        "c": "0",
        "code": "07.00.00.19"
    },
    {
        "id": 130,
        "label": "Conferência médica interdisciplinar ou inter-serviços",
        "k": "20",
        "c": "0",
        "code": "07.00.00.20"
    },
    {
        "id": 131,
        "label": "Oftalmoscopia indirecta completa (inclui interposição lente, desenho/esquema e/ou biomicroscopia do fundo)",
        "k": "20",
        "c": "2",
        "code": "07.00.00.21"
    },
    {
        "id": 132,
        "label": "Angioscopia fluoresceínica, fotografias seriadas, relatório médico",
        "k": "40",
        "c": "30",
        "code": "07.00.00.22"
    },
    {
        "id": 133,
        "label": "Oftalmodinamometria",
        "k": "10",
        "c": "1",
        "code": "07.00.00.23"
    },
    {
        "id": 134,
        "label": "Retinorrafia",
        "k": "10",
        "c": "20",
        "code": "07.00.00.24"
    },
    {
        "id": 135,
        "label": "Angiografia scan laser oftalmológico",
        "k": "25",
        "c": "80",
        "code": "07.00.00.25"
    },
    {
        "id": 136,
        "label": "Cinevideoangiografia",
        "k": "35",
        "c": "40",
        "code": "07.00.00.26"
    },
    {
        "id": 137,
        "label": "Angiografia com verde indocianina",
        "k": "45",
        "c": "40",
        "code": "07.00.00.27"
    },
    {
        "id": 138,
        "label": "Eco Doppler “Duplex Scan” Carótideo/Oftalmológico",
        "k": "30",
        "c": "120",
        "code": "07.00.00.28"
    },
    {
        "id": 139,
        "label": "Electro-oculomiografia, 1 ou mais músculos extraoculares, relatório",
        "k": "40",
        "c": "40",
        "code": "07.00.00.29"
    },
    {
        "id": 140,
        "label": "Electro-oculografia com registo e relatório",
        "k": "40",
        "c": "40",
        "code": "07.00.00.30"
    },
    {
        "id": 141,
        "label": "Electro-retinografia com registo e relatório",
        "k": "40",
        "c": "40",
        "code": "07.00.00.31"
    },
    {
        "id": 142,
        "label": "Estudo dos potenciais occipitais evocados e relatório",
        "k": "40",
        "c": "40",
        "code": "07.00.00.32"
    },
    {
        "id": 143,
        "label": "Estudo elaborado da visão cromática",
        "k": "25",
        "c": "10",
        "code": "07.00.00.33"
    },
    {
        "id": 144,
        "label": "Adaptometria",
        "k": "20",
        "c": "10",
        "code": "07.00.00.34"
    },
    {
        "id": 145,
        "label": "Fotografia de aspetos oculares externos",
        "k": "10",
        "c": "10",
        "code": "07.00.00.35"
    },
    {
        "id": 146,
        "label": "Fotografia especial do segmento anterior, com ou sem microscopia especular",
        "k": "25",
        "c": "10",
        "code": "07.00.00.36"
    },
    {
        "id": 434,
        "label": "Electrocauterização",
        "k": "10",
        "c": "0",
        "code": "10.04.00.03"
    },
    {
        "id": 147,
        "label": "Fotografia do segmento anterior com angiografia fluoresceínica",
        "k": "40",
        "c": "40",
        "code": "07.00.00.37"
    },
    {
        "id": 148,
        "label": "Fluofotometria do segmento anterior",
        "k": "30",
        "c": "20",
        "code": "07.00.00.38"
    },
    {
        "id": 149,
        "label": "Fluofotometria do segmento posterior",
        "k": "30",
        "c": "20",
        "code": "07.00.00.39"
    },
    {
        "id": 150,
        "label": "Avaliação da acuidade visual por técnicas diferenciadas (interferometria, visão de sensibilidade ao contraste, visão mesópica e escotópica/outras)",
        "k": "15",
        "c": "20",
        "code": "07.00.00.40"
    },
    {
        "id": 151,
        "label": "Queratoscopia fotográfia",
        "k": "15",
        "c": "15",
        "code": "07.00.00.41"
    },
    {
        "id": 152,
        "label": "Queratoscopia computorizada",
        "k": "25",
        "c": "15",
        "code": "07.00.00.42"
    },
    {
        "id": 153,
        "label": "Electronistagmografia e/ou electro-oculograma dinâmico com teste de nistagmo optocinético",
        "k": "35",
        "c": "20",
        "code": "07.00.00.43"
    },
    {
        "id": 154,
        "label": "Biomicroscopia especular",
        "k": "15",
        "c": "20",
        "code": "07.00.00.44"
    },
    {
        "id": 155,
        "label": "Prescrição e adaptação de próteses oculares (olho artificial)",
        "k": "10",
        "c": "0",
        "code": "07.00.00.45"
    },
    {
        "id": 156,
        "label": "Prescrição de auxiliares ópticos em situação de subvisâo",
        "k": "25",
        "c": "20",
        "code": "07.00.00.46"
    },
    {
        "id": 157,
        "label": "Ecografia oftalmica A+B",
        "k": "20",
        "c": "30",
        "code": "07.00.00.47"
    },
    {
        "id": 158,
        "label": "Ecografia oftalmica linear, análise espectral com quantificação da amplitude",
        "k": "15",
        "c": "20",
        "code": "07.00.00.48"
    },
    {
        "id": 159,
        "label": "Ecografia oftalmica bidimensional de contacto",
        "k": "15",
        "c": "20",
        "code": "07.00.00.49"
    },
    {
        "id": 160,
        "label": "Biometria oftalmica por ecografia linear",
        "k": "10",
        "c": "20",
        "code": "07.00.00.50"
    },
    {
        "id": 161,
        "label": "Biometria oftalmica por ecografia linear com cálculo de potência da lente intraocular",
        "k": "15",
        "c": "20",
        "code": "07.00.00.51"
    },
    {
        "id": 162,
        "label": "Biometria oftalmica por ecografia linear com cálculo da espessura da córnea, paquimetria",
        "k": "15",
        "c": "20",
        "code": "07.00.00.52"
    },
    {
        "id": 163,
        "label": "Ecografia oftalmica para localização de corpos estranhos",
        "k": "15",
        "c": "20",
        "code": "07.00.00.53"
    },
    {
        "id": 164,
        "label": "Localização radiológica de corpo estranho da região orbitária (anel Comberg/equivalente)",
        "k": "15",
        "c": "50",
        "code": "07.00.00.54"
    },
    {
        "id": 165,
        "label": "Biomicroscopia do fundo ocular ou visão camerular com lente de Goldmann",
        "k": "10",
        "c": "2",
        "code": "07.00.00.55"
    },
    {
        "id": 166,
        "label": "Audiograma tonal simples",
        "k": "8",
        "c": "10",
        "code": "08.00.00.01"
    },
    {
        "id": 167,
        "label": "Audiograma vocal",
        "k": "10",
        "c": "20",
        "code": "08.00.00.02"
    },
    {
        "id": 168,
        "label": "Audiometria automática (Beckesy)",
        "k": "5",
        "c": "8",
        "code": "08.00.00.03"
    },
    {
        "id": 169,
        "label": "Estudo auditivo completo (audiometria tonal e vocal, impedância, prova de fadiga e recobro)",
        "k": "30",
        "c": "50",
        "code": "08.00.00.04"
    },
    {
        "id": 170,
        "label": "Testes suplementares de audiometria (Tone Decay, Sisi, recobro, etc.) cada",
        "k": "8",
        "c": "10",
        "code": "08.00.00.05"
    },
    {
        "id": 171,
        "label": "Acufenometria",
        "k": "5",
        "c": "10",
        "code": "08.00.00.06"
    },
    {
        "id": 172,
        "label": "\"Optimização do ganho auditivo de performance electro-acústica das próteses auditivas \"\"in situ\"\"\"",
        "k": "10",
        "c": "40",
        "code": "08.00.00.07"
    },
    {
        "id": 173,
        "label": "Rastreio da surdez do recém nascido",
        "k": "5",
        "c": "10",
        "code": "08.01.00.01"
    },
    {
        "id": 174,
        "label": "Audiometria tonal até 5 anos de idade",
        "k": "25",
        "c": "12",
        "code": "08.01.00.02"
    },
    {
        "id": 175,
        "label": "Audiometria tonal até 8 anos de idade",
        "k": "20",
        "c": "12",
        "code": "08.01.00.03"
    },
    {
        "id": 176,
        "label": "Audiometria vocal até 10 anos de idade",
        "k": "20",
        "c": "20",
        "code": "08.01.00.04"
    },
    {
        "id": 177,
        "label": "ERA (incluindo BER e ECOG ou outra prova global)",
        "k": "60",
        "c": "140",
        "code": "08.02.00.01"
    },
    {
        "id": 178,
        "label": "Electrococleografia - traçado e protocolo",
        "k": "60",
        "c": "100",
        "code": "08.02.00.02"
    },
    {
        "id": 179,
        "label": "Respostas de tronco cerebral - traçado e protocolo",
        "k": "50",
        "c": "90",
        "code": "08.02.00.03"
    },
    {
        "id": 180,
        "label": "Respostas semi precoces - traçado e protocolo",
        "k": "50",
        "c": "90",
        "code": "08.02.00.04"
    },
    {
        "id": 181,
        "label": "Respostas auditivas corticais",
        "k": "50",
        "c": "90",
        "code": "08.02.00.05"
    },
    {
        "id": 182,
        "label": "Otoemissões",
        "k": "10",
        "c": "40",
        "code": "08.02.00.06"
    },
    {
        "id": 183,
        "label": "Teste do promontório",
        "k": "60",
        "c": "100",
        "code": "08.02.00.07"
    },
    {
        "id": 184,
        "label": "Timpanograma, incluindo a medição de compliance e volume do conduto externo",
        "k": "8",
        "c": "10",
        "code": "08.03.00.01"
    },
    {
        "id": 185,
        "label": "Pesquisa de reflexos acústicos ipsi-laterais ou contra-laterais",
        "k": "5",
        "c": "10",
        "code": "08.03.00.02"
    },
    {
        "id": 186,
        "label": "Pesquisa do “Decay” do reflexo bilateral",
        "k": "5",
        "c": "10",
        "code": "08.03.00.03"
    },
    {
        "id": 187,
        "label": "Pesquisa de reflexos não acústicos",
        "k": "5",
        "c": "10",
        "code": "08.03.00.04"
    },
    {
        "id": 188,
        "label": "Reflexograma de Metz",
        "k": "5",
        "c": "10",
        "code": "08.03.00.05"
    },
    {
        "id": 189,
        "label": "Estudo timpanométrico do funcionamento da trompa de Eustáquio (medição feita com ponte de admitância)",
        "k": "5",
        "c": "10",
        "code": "08.03.00.06"
    },
    {
        "id": 190,
        "label": "Provas suplementares de timpanometria",
        "k": "5",
        "c": "10",
        "code": "08.03.00.07"
    },
    {
        "id": 191,
        "label": "Impedância ou admitância (incluindo timpanograma, medição de compliance, volume do conduto externo, reflexos acústicos ipsi e contra-laterais)",
        "k": "15",
        "c": "25",
        "code": "08.03.00.08"
    },
    {
        "id": 192,
        "label": "Exame vestibular sumário (provas térmicas)",
        "k": "10",
        "c": "3",
        "code": "08.04.00.01"
    },
    {
        "id": 193,
        "label": "Exame vestibular por electronistagmografia (E.N.G.)",
        "k": "50",
        "c": "90",
        "code": "08.04.00.02"
    },
    {
        "id": 194,
        "label": "E.N.G. computorizada",
        "k": "60",
        "c": "140",
        "code": "08.04.00.03"
    },
    {
        "id": 195,
        "label": "Craniocorpografia",
        "k": "10",
        "c": "10",
        "code": "08.04.00.04"
    },
    {
        "id": 196,
        "label": "Posturografia estática",
        "k": "50",
        "c": "90",
        "code": "08.04.00.05"
    },
    {
        "id": 197,
        "label": "Posturografia dinâmica",
        "k": "60",
        "c": "200",
        "code": "08.04.00.06"
    },
    {
        "id": 198,
        "label": "Electroneuronomiografia de superfície com auxílio de equipamento computorizado e.no.m.g (três avaliações sucessivas)",
        "k": "40",
        "c": "90",
        "code": "08.05.00.01"
    },
    {
        "id": 199,
        "label": "Electroneuronografia",
        "k": "20",
        "c": "60",
        "code": "08.05.00.02"
    },
    {
        "id": 200,
        "label": "Estroboscopia",
        "k": "20",
        "c": "60",
        "code": "08.06.00.01"
    },
    {
        "id": 201,
        "label": "Sonografia",
        "k": "15",
        "c": "10",
        "code": "08.06.00.02"
    },
    {
        "id": 202,
        "label": "Glotografia",
        "k": "10",
        "c": "10",
        "code": "08.06.00.03"
    },
    {
        "id": 203,
        "label": "Fonetograma",
        "k": "10",
        "c": "10",
        "code": "08.06.00.04"
    },
    {
        "id": 204,
        "label": "Electrogustometria",
        "k": "10",
        "c": "3",
        "code": "08.07.00.01"
    },
    {
        "id": 205,
        "label": "Tratamento método de PROETZ",
        "k": "3",
        "c": "3",
        "code": "08.08.00.01"
    },
    {
        "id": 206,
        "label": "Rinodebitomanometria",
        "k": "15",
        "c": "20",
        "code": "08.08.00.02"
    },
    {
        "id": 207,
        "label": "Exames realizados sob indução medicamentosa",
        "k": "10",
        "c": "0",
        "code": "08.09.00.01"
    },
    {
        "id": 208,
        "label": "Exames realizados sob anestesia geral",
        "k": "30",
        "c": "0",
        "code": "08.09.00.02"
    },
    {
        "id": 209,
        "label": "Observação e tratamento sob microscopia",
        "k": "5",
        "c": "0",
        "code": "08.09.00.03"
    },
    {
        "id": 210,
        "label": "Fonocardiograma com registo simultâneo duma derivação electrocardiográfica e dum mecanograma de referência",
        "k": "9",
        "c": "9",
        "code": "09.00.00.01"
    },
    {
        "id": 211,
        "label": "Apexocardiograma",
        "k": "7",
        "c": "7",
        "code": "09.00.00.02"
    },
    {
        "id": 212,
        "label": "Electrocardiograma simples de 12 derivações com interpretação e relatório",
        "k": "6",
        "c": "4",
        "code": "09.00.00.03"
    },
    {
        "id": 213,
        "label": "Electrocardiograma simples de 12 derivações com interpretação e relatório, no domicílio",
        "k": "9",
        "c": "9",
        "code": "09.00.00.04"
    },
    {
        "id": 256,
        "label": "Cateterismo cardíaco direito com angiografia (ventrículo direito ou artéria pulmonar)",
        "k": "100",
        "c": "0",
        "code": "09.02.00.06"
    },
    {
        "id": 214,
        "label": "Prova de esforço máxima ou submáxima em tapete rolante ou cicloergómetro com monitorização electrocardiográfica contínua, sob supervisão médica, com interpretação e relatório",
        "k": "40",
        "c": "60",
        "code": "09.00.00.05"
    },
    {
        "id": 215,
        "label": "Vectocardiograma, com ou sem ECG, com interpretação e relatório",
        "k": "10",
        "c": "13",
        "code": "09.00.00.06"
    },
    {
        "id": 216,
        "label": "\"Monitorização electrocardiográfica contínua prolongada por método de Holter com gravação contínua, \"\"scanning\"\" por sobreposição ou impressão total miniaturizada e análise automática, efectuada sob supervisão médica, com interpretação e relatório\"",
        "k": "20",
        "c": "80",
        "code": "09.00.00.07"
    },
    {
        "id": 217,
        "label": "Monitorização electrocardiográfica contínua prolongada por método de Holter, com análise de dados em tempo real, gravação não contínua e registo intermitente, efectuada sob supervisão médica, com interpretação e relatório",
        "k": "12",
        "c": "40",
        "code": "09.00.00.08"
    },
    {
        "id": 218,
        "label": "Monitorização electrocardiográfica prolongada com registo de eventos activado pelo doente com memorização pré e pós-sintomática, efectuada sob supervisão médica, com intrepretação",
        "k": "10",
        "c": "20",
        "code": "09.00.00.09"
    },
    {
        "id": 219,
        "label": "Registo electrocardiográfico de alta resolução, com ou sem ECG de 12 derivações",
        "k": "9",
        "c": "10",
        "code": "09.00.00.10"
    },
    {
        "id": 220,
        "label": "Análise da variabilidade do intervalo RR",
        "k": "9",
        "c": "9",
        "code": "09.00.00.11"
    },
    {
        "id": 221,
        "label": "Fluoroscopia cardíaca",
        "k": "7",
        "c": "20",
        "code": "09.00.01.01"
    },
    {
        "id": 222,
        "label": "\"Registo ambulatório prolongado (24h ou mais) da pressão arterial incluindo gravação, análise por \"\"scanning\"\", interpretação e relatório\"",
        "k": "20",
        "c": "80",
        "code": "09.00.02.01"
    },
    {
        "id": 223,
        "label": "Teste baroreflexo da função cardiovascular com mesa basculante (“tilt table”), com ou sem intervenção farmacológica",
        "k": "20",
        "c": "50",
        "code": "09.00.02.02"
    },
    {
        "id": 224,
        "label": "Ecocardiografia em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M",
        "k": "20",
        "c": "80",
        "code": "09.00.03.01"
    },
    {
        "id": 225,
        "label": "Idem, associada a ecografia Doppler, pulsada ou contínua, com análise espectral",
        "k": "40",
        "c": "190",
        "code": "09.00.03.02"
    },
    {
        "id": 226,
        "label": "Ecocardiografia transesofágica em tempo real (bidimensional), com ou sem registo em modo-m, com inclusão de posicionamento da sonda, aquisição de imagem, interpretação e relatório",
        "k": "80",
        "c": "220",
        "code": "09.00.03.03"
    },
    {
        "id": 227,
        "label": "Ecocardiog. de sobrecarga em tempo real (bidim.), c/ou sem registo em modo-M, durante repouso e prova cardiov., c/ teste máx. ou submáx. em tap. rolante, cicloergométrico e/ou sobrec. farmac., incluindo monitorização electrocardiog., c/ interpret. e relat.",
        "k": "80",
        "c": "240",
        "code": "09.00.03.04"
    },
    {
        "id": 228,
        "label": "Ecocardiografia intra-operatória em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M, com estudo Doppler, pulsado ou contínuo, com análise espectral, estudo completo, com interpretação e relatório",
        "k": "80",
        "c": "200",
        "code": "09.00.03.05"
    },
    {
        "id": 229,
        "label": "Fonocardiograma com registo simultâneo duma derivação electrocardiográfica e dum mecanograma de referência",
        "k": "14",
        "c": "14",
        "code": "09.01.00.01"
    },
    {
        "id": 230,
        "label": "Apexocardiograma",
        "k": "10",
        "c": "7",
        "code": "09.01.00.02"
    },
    {
        "id": 231,
        "label": "Electrocardiograma simples de 12 derivações com interpretação e relatório",
        "k": "8",
        "c": "6",
        "code": "09.01.00.03"
    },
    {
        "id": 232,
        "label": "Electrocardiograma simples de 12 derivações com interpretação e relatório, no domicílio",
        "k": "14",
        "c": "14",
        "code": "09.01.00.04"
    },
    {
        "id": 233,
        "label": "Prova de esforço máxima ou submáxima em tapete rolante ou cicloergómetro com monitorização electrocardiográfica contínua, sob supervisão médica, com interpretação e relatório",
        "k": "30",
        "c": "75",
        "code": "09.01.00.05"
    },
    {
        "id": 234,
        "label": "Vectocardiograma, com ou sem ECG, com interpretação e relatório",
        "k": "15",
        "c": "20",
        "code": "09.01.00.06"
    },
    {
        "id": 235,
        "label": "\"Monitorização electrocardiográfica contínua prolongada por método de Holter com gravação contínua, \"\"scanning\"\" por sobreposição ou impressão total miniaturizada e análise automática, efectuada sob supervisão médica, com interpretação e relatório\"",
        "k": "30",
        "c": "100",
        "code": "09.01.00.07"
    },
    {
        "id": 236,
        "label": "Monitorização electrocardiográfica contínua prolongada por método de Holter, com análise de dados em tempo real, gravação não contínua e registo intermitente, efectuada sob supervisão médica, com interpretação e relatório",
        "k": "16",
        "c": "35",
        "code": "09.01.00.08"
    },
    {
        "id": 237,
        "label": "Monitorização electrocardiográfica prolongada com registo de eventos activado pelo doente com memorização pré e pós sintomática, efectuada sob supervisão médica, com intrepretação",
        "k": "15",
        "c": "20",
        "code": "09.01.00.09"
    },
    {
        "id": 238,
        "label": "Registo electrocardiográfico de alta resolução, com ou sem ECG de 12 derivações",
        "k": "12",
        "c": "10",
        "code": "09.01.00.10"
    },
    {
        "id": 239,
        "label": "Análise da variabilidade do intervalo RR",
        "k": "12",
        "c": "10",
        "code": "09.01.00.11"
    },
    {
        "id": 240,
        "label": "Fluoroscopia cardíaca",
        "k": "10",
        "c": "20",
        "code": "09.01.01.01"
    },
    {
        "id": 241,
        "label": "\"Registo ambulatório prolongado (24h ou mais) da pressão arterial incluindo gravação, análise por \"\"scanning\"\", interpretação e relatório\"",
        "k": "20",
        "c": "40",
        "code": "09.01.02.01"
    },
    {
        "id": 242,
        "label": "Teste baroreflexo da função cardiovascular com mesa basculante (“tilt table”), com ou sem intervenção farmacológica",
        "k": "20",
        "c": "50",
        "code": "09.01.02.02"
    },
    {
        "id": 243,
        "label": "Ecocardiografia em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M",
        "k": "30",
        "c": "120",
        "code": "09.01.03.01"
    },
    {
        "id": 244,
        "label": "Idem, associada a ecografia Doppler, pulsada ou contínua, com análise espectral",
        "k": "50",
        "c": "16",
        "code": "09.01.03.02"
    },
    {
        "id": 245,
        "label": "Ecocardiografia transesofágica em tempo real (bidimensional), com ou sem registo em modo-m, com inclusão de posicionamento da sonda, aquisição de imagem, interpretação e relatório",
        "k": "120",
        "c": "190",
        "code": "09.01.03.03"
    },
    {
        "id": 246,
        "label": "Ecocardiog. de sobrecarga em tempo real (bidim.), c/ou sem registo em modo-M, durante repouso e prova cardiov., c/ teste máx. ou submáx. em tap. rolante, cicloergométrico e/ou sobrec. farmac., incluindo monitorização electrocardiog., c/ interpret. e relat.",
        "k": "50",
        "c": "100",
        "code": "09.01.03.04"
    },
    {
        "id": 247,
        "label": "Ecocardiografia em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M, com estudo Doppler, pulsado ou contínuo, com análise espectral, intra-operatória, estudo completo, com interpretação e relatório",
        "k": "45",
        "c": "100",
        "code": "09.01.03.05"
    },
    {
        "id": 248,
        "label": "Ecocardiografia de contraste",
        "k": "60",
        "c": "150",
        "code": "09.01.03.06"
    },
    {
        "id": 249,
        "label": "Ecocardiografia fetal",
        "k": "50",
        "c": "190",
        "code": "09.01.03.07"
    },
    {
        "id": 250,
        "label": "Estudo Doppler cardíaco fetal",
        "k": "50",
        "c": "190",
        "code": "09.01.03.08"
    },
    {
        "id": 251,
        "label": "Cateterismo cardíaco direito",
        "k": "60",
        "c": "0",
        "code": "09.02.00.01"
    },
    {
        "id": 252,
        "label": "Implantação e posicionamento de catéter de balão por cateterismo direito para monitorização (Swan-Ganz)",
        "k": "50",
        "c": "0",
        "code": "09.02.00.02"
    },
    {
        "id": 253,
        "label": "Cateterismo cardíaco esquerdo",
        "k": "60",
        "c": "0",
        "code": "09.02.00.03"
    },
    {
        "id": 254,
        "label": "Cateterismo cardíaco esquerdo por via trans-septal",
        "k": "105",
        "c": "0",
        "code": "09.02.00.04"
    },
    {
        "id": 255,
        "label": "Cateterismo cardíaco direito e esquerdo",
        "k": "105",
        "c": "0",
        "code": "09.02.00.05"
    },
    {
        "id": 309,
        "label": "Biópsia endomiocárdica",
        "k": "200",
        "c": "0",
        "code": "09.03.02.03"
    },
    {
        "id": 257,
        "label": "Cateterismo cardíaco esquerdo com ventrículografia esquerda",
        "k": "100",
        "c": "0",
        "code": "09.02.00.07"
    },
    {
        "id": 258,
        "label": "Cateterismo cardíaco esquerdo com coronariografia selectiva",
        "k": "110",
        "c": "0",
        "code": "09.02.00.08"
    },
    {
        "id": 259,
        "label": "Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva",
        "k": "115",
        "c": "0",
        "code": "09.02.00.09"
    },
    {
        "id": 260,
        "label": "Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva e aortografia",
        "k": "120",
        "c": "0",
        "code": "09.02.00.10"
    },
    {
        "id": 261,
        "label": "Cateterismo cardíaco esquerdo com ventriculografia esquerda, coronariografia selectiva, aortografia e cateterismo direito",
        "k": "145",
        "c": "0",
        "code": "09.02.00.11"
    },
    {
        "id": 262,
        "label": "\"Cateterismo cardíaco esquerdo com ventriculografia esquerda, coronariografia selectiva, aortografia e cateterismo direito e visualização de \"\"bypasses\"\" aorto-coronários\"",
        "k": "155",
        "c": "0",
        "code": "09.02.00.12"
    },
    {
        "id": 263,
        "label": "\"Cateterismo cardíaco esquerdo com visualização de \"\"bypasses\"\" aorto-coronários\"",
        "k": "110",
        "c": "0",
        "code": "09.02.00.13"
    },
    {
        "id": 264,
        "label": "Prova de provocação de espasmo coronário (ergonovina)",
        "k": "75",
        "c": "0",
        "code": "09.02.00.14"
    },
    {
        "id": 265,
        "label": "Estudos de medição de débito cardíaco com corantes indicadores ou por termodiluição, incluindo cateterismo arterial ou venoso",
        "k": "75",
        "c": "0",
        "code": "09.02.00.15"
    },
    {
        "id": 266,
        "label": "Idem, medições subsequentes",
        "k": "15",
        "c": "0",
        "code": "09.02.00.16"
    },
    {
        "id": 267,
        "label": "Registo electrocardiográfico transesofágico",
        "k": "13",
        "c": "0",
        "code": "09.02.01.01"
    },
    {
        "id": 268,
        "label": "\"Registo electrocardiográfico transesofágico com estimulação eléctrica (\"\"pacing\"\")\"",
        "k": "18",
        "c": "0",
        "code": "09.02.01.02"
    },
    {
        "id": 269,
        "label": "Registo do electrograma intra-auricular, do feixe de His, do ventrículo direito ou do ventrículo esquerdo",
        "k": "25",
        "c": "0",
        "code": "09.02.01.03"
    },
    {
        "id": 270,
        "label": "Mapeamento intraventricular e/ou intra-auricular de focos de taquicardia com registo multifocal, para identificação da origem da taquicardia",
        "k": "35",
        "c": "0",
        "code": "09.02.01.04"
    },
    {
        "id": 271,
        "label": "\"Indução de arritmia por \"\"pacing\"\"\"",
        "k": "45",
        "c": "0",
        "code": "09.02.01.05"
    },
    {
        "id": 272,
        "label": "\"\"\"Pacing\"\" intra-auricular ou intraventricular\"",
        "k": "25",
        "c": "0",
        "code": "09.02.01.06"
    },
    {
        "id": 273,
        "label": "\"Estudo electrofisiológico completo com \"\"pacing\"\" e/ou registo de auricula direita, ventrículo direito e feixe de His, com indução de arritmias, incluindo implantação e reposicionamento de múltiplos electro-catéteres\"",
        "k": "130",
        "c": "0",
        "code": "09.02.01.07"
    },
    {
        "id": 274,
        "label": "Idem, com indução de arritmias",
        "k": "175",
        "c": "0",
        "code": "09.02.01.08"
    },
    {
        "id": 275,
        "label": "\"Idem, com regiso de aurícula esquerda, seio coronário ou ventrículo esquerdo com ou sem \"\"pacing\"\"\"",
        "k": "200",
        "c": "0",
        "code": "09.02.01.09"
    },
    {
        "id": 276,
        "label": "\"Estimulação programada e \"\"pacing\"\" após infusão intravenosa de fármacos\"",
        "k": "70",
        "c": "0",
        "code": "09.02.01.10"
    },
    {
        "id": 277,
        "label": "\"Estudo electrofisiológico de \"\"follow-up\"\" com \"\"pacing\"\" e registo para teste de eficácia de terapêutica, incluindo indução ou tentativa de indução de arritmia\"",
        "k": "70",
        "c": "0",
        "code": "09.02.01.11"
    },
    {
        "id": 278,
        "label": "Cateterismo cardíaco esquerdo com coronariografia selectiva e angioscopia coronária",
        "k": "130",
        "c": "0",
        "code": "09.02.02.01"
    },
    {
        "id": 279,
        "label": "Cateterismo cardíaco esquerdo com coronariografia selectiva e ultrassonografia intracoronária",
        "k": "130",
        "c": "0",
        "code": "09.02.02.02"
    },
    {
        "id": 280,
        "label": "Biópsia endomiocárdica",
        "k": "55",
        "c": "0",
        "code": "09.02.02.03"
    },
    {
        "id": 281,
        "label": "Cateterismo cardíaco direito (venoso)",
        "k": "100",
        "c": "0",
        "code": "09.03.00.01"
    },
    {
        "id": 282,
        "label": "Implantação e posicionamento de catéter de balão por cateterismo direito para monitorização (Swan-Ganz)",
        "k": "75",
        "c": "0",
        "code": "09.03.00.02"
    },
    {
        "id": 283,
        "label": "Cateterismo cardíaco esquerdo (por punção arterial)",
        "k": "125",
        "c": "0",
        "code": "09.03.00.03"
    },
    {
        "id": 284,
        "label": "Cateterismo cardíaco esquerdo (por desbridamento)",
        "k": "150",
        "c": "0",
        "code": "09.03.00.04"
    },
    {
        "id": 285,
        "label": "Cateterismo cardíaco esquerdo por via transeptal",
        "k": "220",
        "c": "0",
        "code": "09.03.00.05"
    },
    {
        "id": 286,
        "label": "Cateterismo cardíaco direito e esquerdo",
        "k": "220",
        "c": "0",
        "code": "09.03.00.06"
    },
    {
        "id": 287,
        "label": "Cateterismo cardíaco direito com angiografia (ventrículo direito ou artéria pulmonar)",
        "k": "120",
        "c": "0",
        "code": "09.03.00.07"
    },
    {
        "id": 288,
        "label": "Cateterismo cardíaco esquerdo com ventrículografia esquerda",
        "k": "150",
        "c": "0",
        "code": "09.03.00.08"
    },
    {
        "id": 289,
        "label": "Cateterismo cardíaco esquerdo com ventrículografia e aortografia",
        "k": "175",
        "c": "0",
        "code": "09.03.00.09"
    },
    {
        "id": 290,
        "label": "Cateterismo cardíaco esquerdo com coronariografia selectiva",
        "k": "200",
        "c": "0",
        "code": "09.03.00.10"
    },
    {
        "id": 291,
        "label": "Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva",
        "k": "220",
        "c": "0",
        "code": "09.03.00.11"
    },
    {
        "id": 292,
        "label": "Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva e aortografia",
        "k": "130",
        "c": "0",
        "code": "09.03.00.12"
    },
    {
        "id": 293,
        "label": "Cateterismo cardíaco esquerdo com ventriculografia esquerda, coronariografia selectiva, aortografia e cateterismo direito",
        "k": "300",
        "c": "0",
        "code": "09.03.00.13"
    },
    {
        "id": 294,
        "label": "\"Cateterismo cardíaco esquerdo com ventriculografia esquerda, coronariografia selectiva, aortografia e cateterismo direito e visualização de \"\"bypasses\"\" aorto-coronários\"",
        "k": "300",
        "c": "0",
        "code": "09.03.00.14"
    },
    {
        "id": 295,
        "label": "\"Cateterismo cardíaco esquerdo com visualização de \"\"bypasses\"\" aorto-coronários\"",
        "k": "225",
        "c": "0",
        "code": "09.03.00.15"
    },
    {
        "id": 296,
        "label": "Estudos de medição de débito cardíaco com corantes indicadores ou por termodiluição, incluindo cateterismo arterial ou venoso",
        "k": "125",
        "c": "0",
        "code": "09.03.00.16"
    },
    {
        "id": 297,
        "label": "Idem, medições subsequentes",
        "k": "15",
        "c": "0",
        "code": "09.03.00.17"
    },
    {
        "id": 298,
        "label": "Registo electrocardiográfico transesofágico",
        "k": "30",
        "c": "0",
        "code": "09.03.01.01"
    },
    {
        "id": 299,
        "label": "\"Registo electrocardiográfico transesofágico com estimulação eléctrica (\"\"pacing\"\")\"",
        "k": "40",
        "c": "0",
        "code": "09.03.01.02"
    },
    {
        "id": 300,
        "label": "Registo do electrograma intra-auricular, do feixe de His, do ventrículo direito ou do ventrículo esquerdo",
        "k": "50",
        "c": "0",
        "code": "09.03.01.03"
    },
    {
        "id": 301,
        "label": "Mapeamento intraventricular e/ou intra-auricular de focos de taquicardia com registo multifocal, para identificação da origem da taquicardia",
        "k": "75",
        "c": "0",
        "code": "09.03.01.04"
    },
    {
        "id": 302,
        "label": "\"Indução de arritmia por \"\"pacing\"\"\"",
        "k": "75",
        "c": "0",
        "code": "09.03.01.05"
    },
    {
        "id": 303,
        "label": "\"\"\"Pacing\"\" intra-auricular ou intraventricular\"",
        "k": "50",
        "c": "0",
        "code": "09.03.01.06"
    },
    {
        "id": 304,
        "label": "\"Estudo electrofisiológico completo com \"\"pacing\"\" e/ou registo de auricula direita, ventrículo direito e feixe de His, com indução de arritmias, incluindo implantação e reposicionamento de múltiplos electro-catéteres\"",
        "k": "150",
        "c": "0",
        "code": "09.03.01.07"
    },
    {
        "id": 305,
        "label": "Idem, com indução de arritmias",
        "k": "175",
        "c": "0",
        "code": "09.03.01.08"
    },
    {
        "id": 306,
        "label": "\"Idem, com registo de aurícula esquerda, seio coronário ou ventrículo esquerdo com ou sem \"\"pacing\"\"\"",
        "k": "180",
        "c": "0",
        "code": "09.03.01.09"
    },
    {
        "id": 307,
        "label": "Cateterismo cardíaco esquerdo com coronariografia selectiva e angioscopia coronária",
        "k": "250",
        "c": "0",
        "code": "09.03.02.01"
    },
    {
        "id": 308,
        "label": "Cateterismo cardíaco esquerdo com coronariografia selectiva e ultrassonografia intracoronária",
        "k": "250",
        "c": "0",
        "code": "09.03.02.02"
    },
    {
        "id": 310,
        "label": "Cardioversão eléctrica externa, electiva",
        "k": "45",
        "c": "0",
        "code": "09.04.00.01"
    },
    {
        "id": 311,
        "label": "Ressuscitação cardio-respiratória",
        "k": "35",
        "c": "0",
        "code": "09.04.00.02"
    },
    {
        "id": 312,
        "label": "Colocação percutânea de dispositivo de assistência cardio-circulatória, v.g. balão intra-aórtico para contrapulsão",
        "k": "105",
        "c": "0",
        "code": "09.04.00.03"
    },
    {
        "id": 313,
        "label": "Idem, remoção",
        "k": "55",
        "c": "0",
        "code": "09.04.00.04"
    },
    {
        "id": 314,
        "label": "Idem, controle",
        "k": "30",
        "c": "0",
        "code": "09.04.00.05"
    },
    {
        "id": 315,
        "label": "Trombólise coronária por infusão intracoronária, incluindo coronariografia selectiva",
        "k": "80",
        "c": "0",
        "code": "09.04.01.01"
    },
    {
        "id": 316,
        "label": "Trombólise coronária por infusão intravenosa",
        "k": "70",
        "c": "0",
        "code": "09.04.01.02"
    },
    {
        "id": 317,
        "label": "Angioplastia coronária percutânea transluminal de um vaso",
        "k": "250",
        "c": "0",
        "code": "09.04.01.03"
    },
    {
        "id": 318,
        "label": "Idem, por cada vaso adicional",
        "k": "125",
        "c": "0",
        "code": "09.04.01.04"
    },
    {
        "id": 319,
        "label": "\"Implantação de prótese intracoronária (\"\"stent\"\")\"",
        "k": "210",
        "c": "0",
        "code": "09.04.01.05"
    },
    {
        "id": 320,
        "label": "Aterectomia percutânea trasluminal direccional coronária de Simpson de um vaso",
        "k": "210",
        "c": "0",
        "code": "09.04.01.06"
    },
    {
        "id": 321,
        "label": "Idem, por cada vaso adicional",
        "k": "80",
        "c": "0",
        "code": "09.04.01.07"
    },
    {
        "id": 322,
        "label": "Valvuloplastia pulmunar percutânea de balão",
        "k": "230",
        "c": "0",
        "code": "09.04.02.01"
    },
    {
        "id": 323,
        "label": "Valvuloplastia tricúspide percutânea de balão",
        "k": "195",
        "c": "0",
        "code": "09.04.02.02"
    },
    {
        "id": 324,
        "label": "Valvuloplastia aórtica percutânea de balão",
        "k": "260",
        "c": "0",
        "code": "09.04.02.03"
    },
    {
        "id": 325,
        "label": "Valvuloplastia mitral percutânea de balão",
        "k": "355",
        "c": "0",
        "code": "09.04.02.04"
    },
    {
        "id": 326,
        "label": "Dilatação percutânea de coarctação da aorta",
        "k": "195",
        "c": "0",
        "code": "09.04.02.05"
    },
    {
        "id": 327,
        "label": "Atrioseptostomia transvenosa por balão, do tipo Rashkind",
        "k": "230",
        "c": "0",
        "code": "09.04.02.06"
    },
    {
        "id": 328,
        "label": "Idem por lâmina, do tipo Park",
        "k": "230",
        "c": "0",
        "code": "09.04.02.07"
    },
    {
        "id": 329,
        "label": "Encerramento percutâneo de canal arterial persistente",
        "k": "310",
        "c": "0",
        "code": "09.04.02.08"
    },
    {
        "id": 330,
        "label": "Encerramento percutâneo de comunicação interauricular",
        "k": "310",
        "c": "0",
        "code": "09.04.02.09"
    },
    {
        "id": 331,
        "label": "Encerramento de comunicação interventricular",
        "k": "310",
        "c": "0",
        "code": "09.04.02.10"
    },
    {
        "id": 332,
        "label": "Dilatação de ramos da artéria pulmonar",
        "k": "230",
        "c": "0",
        "code": "09.04.02.11"
    },
    {
        "id": 333,
        "label": "Dilatação de estenoses de veias pulmonares",
        "k": "230",
        "c": "0",
        "code": "09.04.02.12"
    },
    {
        "id": 334,
        "label": "Embolização vascular",
        "k": "230",
        "c": "0",
        "code": "09.04.02.13"
    },
    {
        "id": 335,
        "label": "Electrofisiologia de intervenção terapêutica, com ablacção de vias anómalas, por energia de radiofrequência",
        "k": "235",
        "c": "0",
        "code": "09.04.03.01"
    },
    {
        "id": 336,
        "label": "Electrofisiologia de intervenção terapêutica, com ablacção ou modulação da junção auriculo-ventricular, por energia de radiofrequência",
        "k": "200",
        "c": "0",
        "code": "09.04.03.02"
    },
    {
        "id": 337,
        "label": "Electrofisiologia de intervenção terapêutica, com ablacção de focos de taquidisritmia ventricular, por energia de radiofrequência",
        "k": "250",
        "c": "0",
        "code": "09.04.03.03"
    },
    {
        "id": 338,
        "label": "\"\"\"Pacing\"\" temporário percutâneo\"",
        "k": "45",
        "c": "0",
        "code": "09.04.04.01"
    },
    {
        "id": 339,
        "label": "Implantação de pacemaker permanente com eléctrodo transvenoso, auricular",
        "k": "180",
        "c": "0",
        "code": "09.04.04.02"
    },
    {
        "id": 340,
        "label": "Implantação de pacemaker permanente com eléctrodo transvenoso, ventricular",
        "k": "180",
        "c": "0",
        "code": "09.04.04.03"
    },
    {
        "id": 341,
        "label": "Implantação de pacemaker permanente com eléctrodo transvenoso, de dupla câmara",
        "k": "195",
        "c": "0",
        "code": "09.04.04.04"
    },
    {
        "id": 342,
        "label": "\"Substituição de gerador \"\"pacemaker\"\", de uma ou duas câmaras\"",
        "k": "85",
        "c": "0",
        "code": "09.04.04.05"
    },
    {
        "id": 343,
        "label": "\"Passagem de sistema \"\"pacemaker\"\" de câmara única a dupla câmara, (incluindo explantação do gerador anterior, teste do eléctrodo existente e implantação de novo eléctrodo e de novo gerador)\"",
        "k": "185",
        "c": "0",
        "code": "09.04.04.06"
    },
    {
        "id": 344,
        "label": "\"Revisão cirúrgica de sistema \"\"pacemaker\"\", sem substituição de gerador (incluindo substituição, reposicionamento ou reparação de eléctrodos transvenosos permanentes), cinco ou mais dias após implantação inicial\"",
        "k": "70",
        "c": "0",
        "code": "09.04.04.07"
    },
    {
        "id": 345,
        "label": "\"Remoção de sistema \"\"pacemaker\"\"\"",
        "k": "70",
        "c": "0",
        "code": "09.04.04.08"
    },
    {
        "id": 346,
        "label": "\"Controlo electrónico do sistema \"\"pacemaker\"\" permanente de uma câmara, sem programação\"",
        "k": "4.5",
        "c": "0",
        "code": "09.04.04.09"
    },
    {
        "id": 347,
        "label": "Idem, com programação",
        "k": "6",
        "c": "0",
        "code": "09.04.04.10"
    },
    {
        "id": 348,
        "label": "\"Controlo electrónico de sistema \"\"pacemaker\"\" permanente de dupla câmara, sem programação\"",
        "k": "6",
        "c": "0",
        "code": "09.04.04.11"
    },
    {
        "id": 349,
        "label": "Idem, com programação",
        "k": "8",
        "c": "0",
        "code": "09.04.04.12"
    },
    {
        "id": 350,
        "label": "Implantação de cardioversor-desfibrilhador automático com eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos",
        "k": "360",
        "c": "0",
        "code": "09.04.05.01"
    },
    {
        "id": 351,
        "label": "Substituição de gerador cardioversor-desfibrilhador",
        "k": "120",
        "c": "0",
        "code": "09.04.05.02"
    },
    {
        "id": 352,
        "label": "Revisão de loca de gerador cardioversor-desfibrilhador",
        "k": "115",
        "c": "0",
        "code": "09.04.05.03"
    },
    {
        "id": 353,
        "label": "Revisão, reposicionamento ou explantação de eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos de sistema cardioversor-desfibrilhador",
        "k": "315",
        "c": "0",
        "code": "09.04.05.04"
    },
    {
        "id": 354,
        "label": "Controlo electrónico de cardioversor-desfibrilhador automático, sem programação",
        "k": "5",
        "c": "0",
        "code": "09.04.05.05"
    },
    {
        "id": 355,
        "label": "Idem, com programação",
        "k": "8",
        "c": "0",
        "code": "09.04.05.06"
    },
    {
        "id": 356,
        "label": "Avaliação electrofisiológica de cardioversor desfibrilhador automático",
        "k": "75",
        "c": "0",
        "code": "09.04.05.07"
    },
    {
        "id": 357,
        "label": "Pericardiocentese",
        "k": "20",
        "c": "0",
        "code": "09.04.06.01"
    },
    {
        "id": 358,
        "label": "Explantação de corpos estranhos por cateterismo percutâneo",
        "k": "75",
        "c": "0",
        "code": "09.04.06.02"
    },
    {
        "id": 359,
        "label": "Cardioversão eléctrica externa, electiva",
        "k": "75",
        "c": "0",
        "code": "09.05.00.01"
    },
    {
        "id": 360,
        "label": "Ressuscitação cardio-respiratória",
        "k": "50",
        "c": "0",
        "code": "09.05.00.02"
    },
    {
        "id": 361,
        "label": "Colocação percutânea de dispositivo de assistência cardio-circulatória, v.g. balão intra-aórtico para contrapulsão",
        "k": "120",
        "c": "0",
        "code": "09.05.00.03"
    },
    {
        "id": 362,
        "label": "Idem, remoção",
        "k": "55",
        "c": "0",
        "code": "09.05.00.04"
    },
    {
        "id": 363,
        "label": "Idem, controle",
        "k": "30",
        "c": "0",
        "code": "09.05.00.05"
    },
    {
        "id": 364,
        "label": "Valvuloplastia pulmonar percutânea de balão",
        "k": "200",
        "c": "0",
        "code": "09.05.01.01"
    },
    {
        "id": 365,
        "label": "Valvuloplastia aórtica percutânea de balão",
        "k": "250",
        "c": "0",
        "code": "09.05.01.02"
    },
    {
        "id": 366,
        "label": "Valvuloplastia mitral percutânea de balão",
        "k": "300",
        "c": "0",
        "code": "09.05.01.03"
    },
    {
        "id": 367,
        "label": "Dilatação percutânea de coarctação ou recoartação da aorta",
        "k": "250",
        "c": "0",
        "code": "09.05.01.04"
    },
    {
        "id": 368,
        "label": "Atrioseptostomia transvenosa por balão, do tipo Rashkind",
        "k": "250",
        "c": "0",
        "code": "09.05.01.05"
    },
    {
        "id": 369,
        "label": "Idem por lâmina, do tipo Park",
        "k": "300",
        "c": "0",
        "code": "09.05.01.06"
    },
    {
        "id": 370,
        "label": "Encerramento percutâneo de canal arterial persistente",
        "k": "300",
        "c": "0",
        "code": "09.05.01.07"
    },
    {
        "id": 371,
        "label": "Encerramento percutâneo de comunicação interauricular",
        "k": "350",
        "c": "0",
        "code": "09.05.01.08"
    },
    {
        "id": 372,
        "label": "Encerramento de comunicação interventricular",
        "k": "350",
        "c": "0",
        "code": "09.05.01.09"
    },
    {
        "id": 373,
        "label": "Dilatação (angioplastia) de ramos da artéria pulmonar",
        "k": "300",
        "c": "0",
        "code": "09.05.01.10"
    },
    {
        "id": 374,
        "label": "Dilatação (angioplastia) de estenoses de veias pulmonares",
        "k": "300",
        "c": "0",
        "code": "09.05.01.11"
    },
    {
        "id": 375,
        "label": "Embolização vascular, arterial, venosa ou arteriovenosa",
        "k": "300",
        "c": "0",
        "code": "09.05.01.12"
    },
    {
        "id": 376,
        "label": "Electrofisiologia de intervenção terapêutica, com ablacção de vias anómalas, por energia de radiofrequência",
        "k": "320",
        "c": "0",
        "code": "09.05.02.01"
    },
    {
        "id": 377,
        "label": "Electrofisiologia de intervenção terapêutica, com ablacção ou modulação da junção auriculo-ventricular, por energia de radiofrequência",
        "k": "320",
        "c": "0",
        "code": "09.05.02.02"
    },
    {
        "id": 378,
        "label": "Electrofisiologia de intervenção terapêutica, com ablacção de focos de taquidisritmia ventricular, por energia de radiofrequência",
        "k": "320",
        "c": "0",
        "code": "09.05.02.03"
    },
    {
        "id": 379,
        "label": "\"\"\"Pacing\"\" temporário percutâneo\"",
        "k": "120",
        "c": "0",
        "code": "09.05.03.01"
    },
    {
        "id": 380,
        "label": "\"Implantação de \"\"pacemaker\"\" permanente com eléctrodo transvenoso, auricular\"",
        "k": "150",
        "c": "0",
        "code": "09.05.03.02"
    },
    {
        "id": 381,
        "label": "\"Implantação de \"\"pacemaker\"\" permanente com eléctrodo transvenoso, ventricular\"",
        "k": "120",
        "c": "0",
        "code": "09.05.03.03"
    },
    {
        "id": 382,
        "label": "\"Implantação de \"\"pacemaker\"\" permanente com eléctrodos transvenosos, de dupla câmara\"",
        "k": "270",
        "c": "0",
        "code": "09.05.03.04"
    },
    {
        "id": 383,
        "label": "\"Substituição de gerador \"\"pacemaker\"\", de uma ou duas câmaras\"",
        "k": "100",
        "c": "0",
        "code": "09.05.03.05"
    },
    {
        "id": 384,
        "label": "\"Passagem de sistema \"\"pacemaker\"\" de câmara única a dupla câmara, (incluindo explantação do gerador anterior, teste do eléctrodo existente e implantação de novo eléctrodo e de novo gerador)\"",
        "k": "185",
        "c": "0",
        "code": "09.05.03.06"
    },
    {
        "id": 385,
        "label": "\"Revisão cirúrgica de sistema \"\"pacemaker\"\", sem substituição de gerador (incluindo substituição, reposicionamento ou reparação de eléctrodos transvenosos permanentes), cinco ou mais dias após implantação inicial\"",
        "k": "150",
        "c": "0",
        "code": "09.05.03.07"
    },
    {
        "id": 386,
        "label": "\"Remoção de sistema \"\"pacemaker\"\"\"",
        "k": "150",
        "c": "0",
        "code": "09.05.03.08"
    },
    {
        "id": 387,
        "label": "\"Controlo electrónico do sistema \"\"pacemaker\"\" permanente de uma câmara, sem programação\"",
        "k": "4.5",
        "c": "0",
        "code": "09.05.03.09"
    },
    {
        "id": 388,
        "label": "Idem, com programação",
        "k": "6",
        "c": "0",
        "code": "09.05.03.10"
    },
    {
        "id": 389,
        "label": "\"Controlo electrónico de sistema \"\"pacemaker\"\" permanente de dupla câmara, sem programação\"",
        "k": "6",
        "c": "0",
        "code": "09.05.03.11"
    },
    {
        "id": 390,
        "label": "Idem, com programação",
        "k": "8",
        "c": "0",
        "code": "09.05.03.12"
    },
    {
        "id": 391,
        "label": "Implantação de cardioversor-desfibrilhador automático com eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos",
        "k": "360",
        "c": "0",
        "code": "09.05.04.01"
    },
    {
        "id": 392,
        "label": "Substituição de gerador cardioversor-desfibrilhador",
        "k": "120",
        "c": "0",
        "code": "09.05.04.02"
    },
    {
        "id": 393,
        "label": "Revisão de loca de gerador cardioversor-desfibrilhador",
        "k": "115",
        "c": "0",
        "code": "09.05.04.03"
    },
    {
        "id": 394,
        "label": "Revisão, reposicionamento ou explantação de eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos de sistema cardioversor-desfibrilhador",
        "k": "315",
        "c": "0",
        "code": "09.05.04.04"
    },
    {
        "id": 395,
        "label": "Controlo electrónico de cardioversor-desfibrilhador automático, sem programação",
        "k": "5",
        "c": "0",
        "code": "09.05.04.05"
    },
    {
        "id": 396,
        "label": "Idem, com programação",
        "k": "8",
        "c": "0",
        "code": "09.05.04.06"
    },
    {
        "id": 397,
        "label": "Avaliação electrofisiológica de cardioversor desfibrilhador automático",
        "k": "75",
        "c": "0",
        "code": "09.05.04.07"
    },
    {
        "id": 398,
        "label": "Pericardiocentese",
        "k": "50",
        "c": "0",
        "code": "09.05.05.01"
    },
    {
        "id": 399,
        "label": "Explantação de corpos estranhos por cateterismo percutâneo",
        "k": "75",
        "c": "0",
        "code": "09.05.05.02"
    },
    {
        "id": 400,
        "label": "Drenagem pleural contínua",
        "k": "15",
        "c": "0",
        "code": "10.00.00.01"
    },
    {
        "id": 401,
        "label": "Exsuflação de pneumotórax expontâneo",
        "k": "20",
        "c": "0",
        "code": "10.00.00.02"
    },
    {
        "id": 402,
        "label": "Pleurodese",
        "k": "5",
        "c": "0",
        "code": "10.00.00.03"
    },
    {
        "id": 403,
        "label": "Punção transtraqueal",
        "k": "15",
        "c": "0",
        "code": "10.00.00.04"
    },
    {
        "id": 404,
        "label": "Punção transtorácica",
        "k": "25",
        "c": "0",
        "code": "10.00.00.05"
    },
    {
        "id": 405,
        "label": "Espirometria simples (estudo dos volumes e débitos)",
        "k": "10",
        "c": "0",
        "code": "10.01.00.01"
    },
    {
        "id": 406,
        "label": "Espirometria simples com prova de broncodilatação",
        "k": "13",
        "c": "14",
        "code": "10.01.00.02"
    },
    {
        "id": 407,
        "label": "Espirometria simples com prova de provocação inalatória inespecífica",
        "k": "20",
        "c": "19",
        "code": "10.01.00.03"
    },
    {
        "id": 408,
        "label": "Espirometria simples com prova de provocação inalatória específica",
        "k": "20",
        "c": "24",
        "code": "10.01.00.04"
    },
    {
        "id": 409,
        "label": "Mecânica ventilatória simples (estudo de volumes, incluindo o volume residual+débitos+resistência das vias aéreas)",
        "k": "22",
        "c": "36",
        "code": "10.01.00.05"
    },
    {
        "id": 410,
        "label": "Mecânica ventilatória com prova de broncodilatação",
        "k": "25",
        "c": "40",
        "code": "10.01.00.06"
    },
    {
        "id": 411,
        "label": "Mecânica ventilatória com prova de provocação inalatória inespecífica",
        "k": "25",
        "c": "45",
        "code": "10.01.00.07"
    },
    {
        "id": 412,
        "label": "Mecânica ventilatória com prova de provocação inalatória específica",
        "k": "25",
        "c": "50",
        "code": "10.01.00.08"
    },
    {
        "id": 413,
        "label": "\"\"\"Compliance\"\" pulmonar\"",
        "k": "10",
        "c": "30",
        "code": "10.01.00.09"
    },
    {
        "id": 414,
        "label": "Difusão",
        "k": "10",
        "c": "30",
        "code": "10.01.00.10"
    },
    {
        "id": 415,
        "label": "Oximetria transcutânea",
        "k": "5",
        "c": "10",
        "code": "10.01.00.11"
    },
    {
        "id": 416,
        "label": "Registo poligráfico do sono com avaliação terapêutica (CPAP)",
        "k": "150",
        "c": "340",
        "code": "10.01.00.12"
    },
    {
        "id": 417,
        "label": "Aspirado brônquico, para bacteriologia, micologia, parasitologia e citologia",
        "k": "5",
        "c": "0",
        "code": "10.02.00.01"
    },
    {
        "id": 418,
        "label": "Citologia por escovado",
        "k": "5",
        "c": "0",
        "code": "10.02.00.02"
    },
    {
        "id": 419,
        "label": "Citologia por punção aspirativa (transbrônquica)",
        "k": "15",
        "c": "0",
        "code": "10.02.00.03"
    },
    {
        "id": 420,
        "label": "Escovado brônquico duplamente protegido para pesquisa de germens (aeróbios e anaeróbios) e fungos",
        "k": "5",
        "c": "20",
        "code": "10.02.00.04"
    },
    {
        "id": 421,
        "label": "Lavagem bronco-alveolar",
        "k": "10",
        "c": "0",
        "code": "10.02.00.05"
    },
    {
        "id": 422,
        "label": "Lavagens brônquicas dirigidas",
        "k": "5",
        "c": "0",
        "code": "10.02.00.06"
    },
    {
        "id": 423,
        "label": "Broncografia (introdução do produto de contraste)",
        "k": "9",
        "c": "0",
        "code": "10.02.00.07"
    },
    {
        "id": 424,
        "label": "Broncoaspiração de secreções",
        "k": "5",
        "c": "0",
        "code": "10.03.00.01"
    },
    {
        "id": 425,
        "label": "Cirurgia por Laser ( fotocoagulação)",
        "k": "30",
        "c": "75",
        "code": "10.03.00.02"
    },
    {
        "id": 426,
        "label": "Extracção de corpo estranho",
        "k": "20",
        "c": "0",
        "code": "10.03.00.03"
    },
    {
        "id": 427,
        "label": "Instilação de soro gelado e/ou adrenalina em hemoptises",
        "k": "5",
        "c": "0",
        "code": "10.03.00.04"
    },
    {
        "id": 428,
        "label": "Intubações endotraqueais (conduzidas por broncofibroscópio)",
        "k": "20",
        "c": "0",
        "code": "10.03.00.05"
    },
    {
        "id": 429,
        "label": "Tamponamento de hemoptises",
        "k": "15",
        "c": "0",
        "code": "10.03.00.06"
    },
    {
        "id": 430,
        "label": "Crioterapia endobrônquica",
        "k": "20",
        "c": "25",
        "code": "10.03.00.07"
    },
    {
        "id": 431,
        "label": "Colocação de prótese enduminal",
        "k": "20",
        "c": "200",
        "code": "10.03.00.08"
    },
    {
        "id": 432,
        "label": "Aplicação de colas biológicas",
        "k": "5",
        "c": "0",
        "code": "10.04.00.01"
    },
    {
        "id": 433,
        "label": "Coagulação por Laser",
        "k": "10",
        "c": "75",
        "code": "10.04.00.02"
    },
    {
        "id": 435,
        "label": "Pleurodese",
        "k": "5",
        "c": "0",
        "code": "10.04.00.04"
    },
    {
        "id": 436,
        "label": "Aerossóis (por sessão)",
        "k": "1",
        "c": "1",
        "code": "10.05.00.01"
    },
    {
        "id": 437,
        "label": "Aerossóis ultra-sónicos",
        "k": "1",
        "c": "2",
        "code": "10.05.00.02"
    },
    {
        "id": 438,
        "label": "IPPB (Ventilação por pressão positiva intermitente)",
        "k": "1",
        "c": "3",
        "code": "10.05.00.03"
    },
    {
        "id": 439,
        "label": "Oxigenoterapia (a utilizar durante as sessões de readaptação)",
        "k": "1",
        "c": "1",
        "code": "10.05.00.04"
    },
    {
        "id": 440,
        "label": "Cinesiterapia Respiratória (Ver Fisiatria Cod. 90)",
        "k": "0",
        "c": "0",
        "code": "10.05.00.05"
    },
    {
        "id": 441,
        "label": "Imunoalergologia (Ver Cod. 11)",
        "k": "0",
        "c": "0",
        "code": "10.05.00.06"
    },
    {
        "id": 442,
        "label": "Por picada (no mínimo série standard)",
        "k": "12",
        "c": "18",
        "code": "11.00.00.01"
    },
    {
        "id": 443,
        "label": "Intradérmica (no mínimo série standard)",
        "k": "12",
        "c": "18",
        "code": "11.00.00.02"
    },
    {
        "id": 444,
        "label": "Por contacto (no mínimo série standard)",
        "k": "12",
        "c": "40",
        "code": "11.00.00.03"
    },
    {
        "id": 445,
        "label": "Estudo da imunidade celular por testes múltiplos",
        "k": "12",
        "c": "30",
        "code": "11.00.00.04"
    },
    {
        "id": 446,
        "label": "Inespecíficas",
        "k": "5",
        "c": "5",
        "code": "11.01.00.01"
    },
    {
        "id": 447,
        "label": "Específicas",
        "k": "5",
        "c": "5",
        "code": "11.01.00.02"
    },
    {
        "id": 448,
        "label": "Inespecíficas",
        "k": "15",
        "c": "25",
        "code": "11.02.00.01"
    },
    {
        "id": 449,
        "label": "Específicas",
        "k": "15",
        "c": "25",
        "code": "11.02.00.02"
    },
    {
        "id": 450,
        "label": "Cada alergeno",
        "k": "15",
        "c": "15",
        "code": "11.03.00.01"
    },
    {
        "id": 451,
        "label": "Cada alergeno",
        "k": "15",
        "c": "15",
        "code": "11.04.00.01"
    },
    {
        "id": 452,
        "label": "Espirometria simples (estudo dos volumes e débitos)",
        "k": "10",
        "c": "0",
        "code": "11.05.00.01"
    },
    {
        "id": 453,
        "label": "Broncodilatadoras por espirometria simples",
        "k": "13",
        "c": "14",
        "code": "11.05.00.02"
    },
    {
        "id": 454,
        "label": "Broncoconstritoras inespecíficas por espirometria simples",
        "k": "20",
        "c": "19",
        "code": "11.05.00.03"
    },
    {
        "id": 455,
        "label": "Broncoconstritoras específicas (cada) por espirometria simples",
        "k": "20",
        "c": "24",
        "code": "11.05.00.04"
    },
    {
        "id": 456,
        "label": "Mecânica ventilatória simples (estudo de volumes, incluindo volume residual+débitos+resistência das vias aéreas)",
        "k": "22",
        "c": "36",
        "code": "11.05.00.05"
    },
    {
        "id": 457,
        "label": "Broncodilatadoras por mecânica ventilatória",
        "k": "25",
        "c": "40",
        "code": "11.05.00.06"
    },
    {
        "id": 458,
        "label": "Broncoconstritoras inespecíficas por mecânica ventilatória",
        "k": "25",
        "c": "45",
        "code": "11.05.00.07"
    },
    {
        "id": 459,
        "label": "Broncoconstritoras",
        "k": "25",
        "c": "50",
        "code": "11.05.00.08"
    },
    {
        "id": 460,
        "label": "Injecção (sob vigilância médica)",
        "k": "5",
        "c": "0",
        "code": "11.06.00.01"
    },
    {
        "id": 461,
        "label": "Aerossóis (cada)",
        "k": "3",
        "c": "3",
        "code": "11.07.00.01"
    },
    {
        "id": 462,
        "label": "Introdução de pessário",
        "k": "10",
        "c": "0",
        "code": "12.00.00.01"
    },
    {
        "id": 463,
        "label": "Introdução do DIU",
        "k": "10",
        "c": "0",
        "code": "12.00.00.02"
    },
    {
        "id": 464,
        "label": "Extracção do DIU por via abdominal (laparotomia ou celioscopia)",
        "k": "70",
        "c": "0",
        "code": "12.00.00.03"
    },
    {
        "id": 465,
        "label": "Manobras para exame radiográfico do útero e anexos",
        "k": "20",
        "c": "0",
        "code": "12.00.00.04"
    },
    {
        "id": 466,
        "label": "Secção de sinéquias por histeroscopia",
        "k": "50",
        "c": "0",
        "code": "12.00.00.05"
    },
    {
        "id": 467,
        "label": "Teste de Huhner",
        "k": "5",
        "c": "0",
        "code": "12.00.00.06"
    },
    {
        "id": 468,
        "label": "Inseminação artificial",
        "k": "20",
        "c": "100",
        "code": "12.00.00.07"
    },
    {
        "id": 469,
        "label": "Ciclo G.I.F.T.",
        "k": "175",
        "c": "700",
        "code": "12.00.00.08"
    },
    {
        "id": 470,
        "label": "Ciclo F.I.V.",
        "k": "150",
        "c": "1000",
        "code": "12.00.00.09"
    },
    {
        "id": 471,
        "label": "Ciclo Z.I.F.T.",
        "k": "175",
        "c": "1000",
        "code": "12.00.00.10"
    },
    {
        "id": 472,
        "label": "Ciclo I.C.S.I.",
        "k": "150",
        "c": "2000",
        "code": "12.00.00.11"
    },
    {
        "id": 473,
        "label": "Monitorização da ovulação",
        "k": "15",
        "c": "0",
        "code": "12.00.00.12"
    },
    {
        "id": 474,
        "label": "Tratamento de condilomas vulvares (cauterização química, eléctrica ou criocoagulação)",
        "k": "15",
        "c": "0",
        "code": "12.00.00.13"
    },
    {
        "id": 475,
        "label": "Amniocentese (2o. Trimestre)",
        "k": "25",
        "c": "0",
        "code": "13.00.00.01"
    },
    {
        "id": 476,
        "label": "Amniocentese (3o. Trimestre)",
        "k": "20",
        "c": "0",
        "code": "13.00.00.02"
    },
    {
        "id": 477,
        "label": "Teste de stress à ocitocina",
        "k": "20",
        "c": "0",
        "code": "13.00.00.03"
    },
    {
        "id": 478,
        "label": "Iniciação e/ou supervisão de monitorização fetal interna durante o trabalho de parto",
        "k": "40",
        "c": "0",
        "code": "13.00.00.04"
    },
    {
        "id": 479,
        "label": "Injecção intra-amniótica (amniocentese) de solução hipertónica e/ou prostaglandinas para indução do trabalho de parto",
        "k": "20",
        "c": "0",
        "code": "13.00.00.05"
    },
    {
        "id": 480,
        "label": "Injecção intra-uterina extra amniótica de solução hipertónica e/ou prostaglandinas para indução do trabalho de parto",
        "k": "10",
        "c": "0",
        "code": "13.00.00.06"
    },
    {
        "id": 481,
        "label": "Monitorização fetal externa, com protocolos e extractos dos cardiotocogramas (fora ou durante o trabalho de parto) . Teste de reatividade fetal",
        "k": "8",
        "c": "0",
        "code": "13.00.00.07"
    },
    {
        "id": 482,
        "label": "Biópsia do corion",
        "k": "20",
        "c": "0",
        "code": "13.00.00.08"
    },
    {
        "id": 483,
        "label": "Cordocentese",
        "k": "30",
        "c": "0",
        "code": "13.00.00.09"
    },
    {
        "id": 484,
        "label": "Traçado diurno com provas de activação (HPP e ELI)",
        "k": "6",
        "c": "44",
        "code": "14.00.00.01"
    },
    {
        "id": 485,
        "label": "Traçado de sono diurno",
        "k": "6",
        "c": "48",
        "code": "14.00.00.02"
    },
    {
        "id": 486,
        "label": "Traçado fora do laboratório",
        "k": "12",
        "c": "110",
        "code": "14.00.00.03"
    },
    {
        "id": 487,
        "label": "Traçado poligráfico",
        "k": "38",
        "c": "156",
        "code": "14.00.00.04"
    },
    {
        "id": 488,
        "label": "Electrocorticografia",
        "k": "36",
        "c": "156",
        "code": "14.00.00.05"
    },
    {
        "id": 489,
        "label": "Teste de latência múltipla do sono",
        "k": "60",
        "c": "200",
        "code": "14.00.00.06"
    },
    {
        "id": 490,
        "label": "Registo prolongado de EEG e Video (monitorização no laboratório)",
        "k": "80",
        "c": "200",
        "code": "14.00.00.07"
    },
    {
        "id": 491,
        "label": "Registo prolongado de EEG e Video (monitorização em ambulatório)",
        "k": "12",
        "c": "110",
        "code": "14.00.00.08"
    },
    {
        "id": 492,
        "label": "Traçado de sono em ambulatório",
        "k": "12",
        "c": "110",
        "code": "14.00.00.09"
    },
    {
        "id": 493,
        "label": "Registo poligráfico de sono nocturno",
        "k": "100",
        "c": "250",
        "code": "14.00.00.10"
    },
    {
        "id": 494,
        "label": "Cartografia do EEG",
        "k": "60",
        "c": "120",
        "code": "14.00.00.11"
    },
    {
        "id": 495,
        "label": "Cartografia de potenciais evocados visuais",
        "k": "60",
        "c": "120",
        "code": "14.00.00.12"
    },
    {
        "id": 496,
        "label": "Cartografia de potenciais evocados auditivos",
        "k": "60",
        "c": "120",
        "code": "14.00.00.13"
    },
    {
        "id": 497,
        "label": "Cartografia de potenciais evocados somatosensitivos",
        "k": "60",
        "c": "120",
        "code": "14.00.00.14"
    },
    {
        "id": 498,
        "label": "Cartografia do P300",
        "k": "60",
        "c": "120",
        "code": "14.00.00.15"
    },
    {
        "id": 499,
        "label": "Potenciais evocados visuais",
        "k": "50",
        "c": "90",
        "code": "14.01.00.01"
    },
    {
        "id": 500,
        "label": "Potenciais evocados auditivos",
        "k": "50",
        "c": "90",
        "code": "14.01.00.02"
    },
    {
        "id": 501,
        "label": "Potenciais evocados somatosensitivos",
        "k": "50",
        "c": "90",
        "code": "14.01.00.03"
    },
    {
        "id": 502,
        "label": "Potenciais evocados do nervo pudendo",
        "k": "50",
        "c": "90",
        "code": "14.01.00.04"
    },
    {
        "id": 503,
        "label": "Potenciais evocados por estimulação de pares cranianos",
        "k": "60",
        "c": "100",
        "code": "14.01.00.05"
    },
    {
        "id": 504,
        "label": "Potenciais evocados por estimulação paraespinhal",
        "k": "60",
        "c": "100",
        "code": "14.01.00.06"
    },
    {
        "id": 505,
        "label": "Potenciais evocados por estimulação de dermatomas",
        "k": "60",
        "c": "100",
        "code": "14.01.00.07"
    },
    {
        "id": 506,
        "label": "Reflexo bulbocavernoso",
        "k": "50",
        "c": "90",
        "code": "14.01.00.08"
    },
    {
        "id": 507,
        "label": "Electromiografia (incluindo velocidades de condução)",
        "k": "25",
        "c": "35",
        "code": "14.02.00.01"
    },
    {
        "id": 508,
        "label": "Electromiografia de fibra única",
        "k": "45",
        "c": "55",
        "code": "14.02.00.02"
    },
    {
        "id": 509,
        "label": "Reflexo de encerramento ocular (Blink reflex)",
        "k": "45",
        "c": "35",
        "code": "14.02.00.03"
    },
    {
        "id": 510,
        "label": "Estudo da condução do nervo frénico",
        "k": "45",
        "c": "55",
        "code": "14.02.00.04"
    },
    {
        "id": 511,
        "label": "Resposta simpática cutânea",
        "k": "50",
        "c": "90",
        "code": "14.03.00.01"
    },
    {
        "id": 512,
        "label": "Estudo da variação R-R",
        "k": "50",
        "c": "90",
        "code": "14.03.00.02"
    },
    {
        "id": 513,
        "label": "Estimulação magnética motora com captação a níveis diversos",
        "k": "60",
        "c": "100",
        "code": "14.04.00.01"
    },
    {
        "id": 514,
        "label": "Crioterapia com neve carbónica (por sessão)",
        "k": "8",
        "c": "4",
        "code": "15.00.00.01"
    },
    {
        "id": 515,
        "label": "Crioterapia, com azoto liquido, de lesões benignas (por sessão)",
        "k": "8",
        "c": "4",
        "code": "15.00.00.02"
    },
    {
        "id": 516,
        "label": "Crioterapia, com azoto liquido, de lesões malignas, excepto face e região frontal",
        "k": "30",
        "c": "4",
        "code": "15.00.00.03"
    },
    {
        "id": 517,
        "label": "Crioterapia, com azoto liquido, de lesões malignas da face e região frontal",
        "k": "40",
        "c": "4",
        "code": "15.00.00.04"
    },
    {
        "id": 518,
        "label": "Electrocoagulação ou electrólise de pêlos (por sessão)",
        "k": "8",
        "c": "4",
        "code": "15.00.00.05"
    },
    {
        "id": 519,
        "label": "Electrocoagulação de lesões cutâneas",
        "k": "15",
        "c": "4",
        "code": "15.00.00.06"
    },
    {
        "id": 520,
        "label": "Cirurgia pelo método de Mohs (microscopicamente controlada)",
        "k": "50",
        "c": "30",
        "code": "15.00.00.07"
    },
    {
        "id": 521,
        "label": "Enxerto de cabelo (técnica",
        "k": "3",
        "c": "1",
        "code": "15.00.00.08"
    },
    {
        "id": 522,
        "label": "Terapêutica intralesional com corticóides ou citostáticos",
        "k": "6",
        "c": "0",
        "code": "15.00.00.09"
    },
    {
        "id": 523,
        "label": "P.U.V.A. (por sessão) banho prévio com psolareno",
        "k": "12",
        "c": "5",
        "code": "15.00.00.10"
    },
    {
        "id": 524,
        "label": "P.U.V.A. (por sessão) terapêutica oral ou tópica com psolareno",
        "k": "8",
        "c": "5",
        "code": "15.00.00.11"
    },
    {
        "id": 525,
        "label": "Quimio cirurgia com pasta de zinco",
        "k": "20",
        "c": "10",
        "code": "15.00.00.12"
    },
    {
        "id": 526,
        "label": "Laserterapia cirúrgica por laser de CO2 de lesões cutâneas",
        "k": "50",
        "c": "20",
        "code": "15.00.00.13"
    },
    {
        "id": 527,
        "label": "Diagnóstico pela luz de Wood",
        "k": "2",
        "c": "2",
        "code": "15.00.00.14"
    },
    {
        "id": 528,
        "label": "Laser pulsado de contraste (até 10 cm2)",
        "k": "40",
        "c": "230",
        "code": "15.00.00.15"
    },
    {
        "id": 529,
        "label": "Idem, > 10 cm2 < 20 cm2",
        "k": "60",
        "c": "250",
        "code": "15.00.00.16"
    },
    {
        "id": 530,
        "label": "Idem, maior que 20 cm2",
        "k": "80",
        "c": "320",
        "code": "15.00.00.17"
    },
    {
        "id": 531,
        "label": "Testes imunológicos, (Ver Imunoalergologia, Cód. 11)",
        "k": "0",
        "c": "0",
        "code": "15.00.00.18"
    },
    {
        "id": 532,
        "label": "Exames bacteriológicos, micológicos e parasitológicos (Ver Patologia Clínica, Cód. 70)",
        "k": "0",
        "c": "0",
        "code": "15.00.00.19"
    },
    {
        "id": 533,
        "label": "Exames citológicos, (Ver Anatomia Patológica, Cód. 80)",
        "k": "0",
        "c": "0",
        "code": "15.00.00.20"
    },
    {
        "id": 534,
        "label": "Redução manual de parafimose",
        "k": "15",
        "c": "0",
        "code": "16.00.00.01"
    },
    {
        "id": 535,
        "label": "Fulguração e cauterização nos genitais externos",
        "k": "15",
        "c": "0",
        "code": "16.00.00.02"
    },
    {
        "id": 536,
        "label": "Calibração e dilatação da uretra",
        "k": "15",
        "c": "0",
        "code": "16.00.00.03"
    },
    {
        "id": 537,
        "label": "Instilação intravesical",
        "k": "10",
        "c": "0",
        "code": "16.00.00.04"
    },
    {
        "id": 538,
        "label": "Substituição não cirúrgica de sondas cateteres ou tubos de drenagem",
        "k": "10",
        "c": "0",
        "code": "16.00.00.05"
    },
    {
        "id": 539,
        "label": "Fluxometria",
        "k": "5",
        "c": "15",
        "code": "16.01.00.01"
    },
    {
        "id": 540,
        "label": "Cistografia (água ou gás)",
        "k": "15",
        "c": "25",
        "code": "16.01.00.02"
    },
    {
        "id": 541,
        "label": "Electromiografia esfincteriana",
        "k": "25",
        "c": "25",
        "code": "16.01.00.03"
    },
    {
        "id": 542,
        "label": "Perfil uretral",
        "k": "5",
        "c": "15",
        "code": "16.01.00.04"
    },
    {
        "id": 543,
        "label": "Exame urodinâmico completo do aparelho urinário baixo",
        "k": "50",
        "c": "80",
        "code": "16.01.00.05"
    },
    {
        "id": 544,
        "label": "Exame urodinâmico do aparelho urinário alto-estudo de perfusão renal (exclui nefrostomia)",
        "k": "25",
        "c": "25",
        "code": "16.01.00.06"
    },
    {
        "id": 545,
        "label": "Rigiscan",
        "k": "25",
        "c": "40",
        "code": "16.02.00.01"
    },
    {
        "id": 546,
        "label": "Doppler peniano",
        "k": "15",
        "c": "15",
        "code": "16.02.00.02"
    },
    {
        "id": 547,
        "label": "Cavernosometria",
        "k": "10",
        "c": "40",
        "code": "16.02.00.03"
    },
    {
        "id": 548,
        "label": "Cavernosografia dinâmica",
        "k": "15",
        "c": "40",
        "code": "16.02.00.04"
    },
    {
        "id": 549,
        "label": "Test. PGE com papaverina ou prostaglandina",
        "k": "5",
        "c": "5",
        "code": "16.02.00.05"
    },
    {
        "id": 550,
        "label": "Electromiografia da fibra muscular do corpo cavernoso",
        "k": "25",
        "c": "25",
        "code": "16.02.00.06"
    },
    {
        "id": 551,
        "label": "Potenciais evocados somato-sensitivos do nervo pudendo",
        "k": "50",
        "c": "90",
        "code": "16.02.00.07"
    },
    {
        "id": 552,
        "label": "Esofagoscopia",
        "k": "20",
        "c": "25",
        "code": "17.00.00.01"
    },
    {
        "id": 553,
        "label": "Endoscopia Alta (Esofagogastroduodenoscopia)",
        "k": "30",
        "c": "25",
        "code": "17.00.00.02"
    },
    {
        "id": 554,
        "label": "Enteroscopia",
        "k": "30",
        "c": "25",
        "code": "17.00.00.03"
    },
    {
        "id": 555,
        "label": "Coledoscopia peroral",
        "k": "50",
        "c": "35",
        "code": "17.00.00.04"
    },
    {
        "id": 556,
        "label": "Colonoscopia Total",
        "k": "50",
        "c": "40",
        "code": "17.00.00.05"
    },
    {
        "id": 557,
        "label": "Colonoscopia esquerda",
        "k": "35",
        "c": "35",
        "code": "17.00.00.06"
    },
    {
        "id": 558,
        "label": "Fibrosigmoidoscopia",
        "k": "15",
        "c": "30",
        "code": "17.00.00.07"
    },
    {
        "id": 559,
        "label": "Rectosigmoidoscopia (tubo rígido)",
        "k": "10",
        "c": "5",
        "code": "17.00.00.08"
    },
    {
        "id": 560,
        "label": "Anuscopia",
        "k": "5",
        "c": "0",
        "code": "17.00.00.09"
    },
    {
        "id": 561,
        "label": "Rinoscopia posterior endoscópica",
        "k": "15",
        "c": "30",
        "code": "17.01.00.01"
    },
    {
        "id": 562,
        "label": "Sinuscopia",
        "k": "15",
        "c": "30",
        "code": "17.01.00.02"
    },
    {
        "id": 563,
        "label": "Laringoscopia",
        "k": "15",
        "c": "30",
        "code": "17.01.00.03"
    },
    {
        "id": 564,
        "label": "Microlaringoscopia em suspensão",
        "k": "25",
        "c": "30",
        "code": "17.01.00.04"
    },
    {
        "id": 565,
        "label": "Broncoscopia",
        "k": "30",
        "c": "25",
        "code": "17.01.00.05"
    },
    {
        "id": 566,
        "label": "Pleuroscopia",
        "k": "35",
        "c": "15",
        "code": "17.01.00.06"
    },
    {
        "id": 567,
        "label": "Broncoscopia com broncovideoscopia",
        "k": "30",
        "c": "40",
        "code": "17.01.00.07"
    },
    {
        "id": 568,
        "label": "Mediastinoscopia cervical",
        "k": "75",
        "c": "15",
        "code": "17.01.00.08"
    },
    {
        "id": 569,
        "label": "Hiloscopia",
        "k": "40",
        "c": "15",
        "code": "17.01.00.09"
    },
    {
        "id": 570,
        "label": "Uretroscopia",
        "k": "30",
        "c": "50",
        "code": "17.02.00.01"
    },
    {
        "id": 571,
        "label": "Cistoscopia simples",
        "k": "30",
        "c": "50",
        "code": "17.02.00.02"
    },
    {
        "id": 572,
        "label": "Ureterorrenoscopia de diagnóstico",
        "k": "110",
        "c": "200",
        "code": "17.02.00.03"
    },
    {
        "id": 573,
        "label": "Nefroscopia percutânea",
        "k": "140",
        "c": "200",
        "code": "17.02.00.04"
    },
    {
        "id": 574,
        "label": "Endoscopia flexivel (a acrescentar ao valor do custo real da endoscopia do orgão)",
        "k": "50",
        "c": "100",
        "code": "17.02.00.05"
    },
    {
        "id": 575,
        "label": "Peniscopia",
        "k": "15",
        "c": "30",
        "code": "17.02.00.06"
    },
    {
        "id": 576,
        "label": "Laparoscopia Diagnóstica",
        "k": "35",
        "c": "20",
        "code": "17.03.00.01"
    },
    {
        "id": 577,
        "label": "Colposcopia",
        "k": "15",
        "c": "15",
        "code": "17.03.00.02"
    },
    {
        "id": 578,
        "label": "Culdoscopia",
        "k": "40",
        "c": "15",
        "code": "17.03.00.03"
    },
    {
        "id": 579,
        "label": "Histeroscopia",
        "k": "25",
        "c": "20",
        "code": "17.03.00.04"
    },
    {
        "id": 580,
        "label": "Amnioscopia",
        "k": "5",
        "c": "0",
        "code": "17.03.00.05"
    },
    {
        "id": 581,
        "label": "Amnioscopia intra ovular ( fetoscopia)",
        "k": "50",
        "c": "20",
        "code": "17.03.00.06"
    },
    {
        "id": 582,
        "label": "Artroscopia",
        "k": "50",
        "c": "15",
        "code": "17.04.00.01"
    },
    {
        "id": 583,
        "label": "Gânglio",
        "k": "5",
        "c": "3",
        "code": "18.00.00.01"
    },
    {
        "id": 584,
        "label": "Gengival",
        "k": "5",
        "c": "3",
        "code": "18.00.00.02"
    },
    {
        "id": 585,
        "label": "Fígado",
        "k": "20",
        "c": "3",
        "code": "18.00.00.03"
    },
    {
        "id": 586,
        "label": "Mama",
        "k": "5",
        "c": "3",
        "code": "18.00.00.04"
    },
    {
        "id": 587,
        "label": "Tecidos Moles",
        "k": "5",
        "c": "3",
        "code": "18.00.00.05"
    },
    {
        "id": 588,
        "label": "Osso",
        "k": "15",
        "c": "3",
        "code": "18.00.00.06"
    },
    {
        "id": 589,
        "label": "Pénis",
        "k": "5",
        "c": "3",
        "code": "18.00.00.07"
    },
    {
        "id": 590,
        "label": "Próstata",
        "k": "25",
        "c": "3",
        "code": "18.00.00.08"
    },
    {
        "id": 591,
        "label": "Rim",
        "k": "30",
        "c": "3",
        "code": "18.00.00.09"
    },
    {
        "id": 592,
        "label": "Testículo",
        "k": "10",
        "c": "3",
        "code": "18.00.00.10"
    },
    {
        "id": 593,
        "label": "Tiróide",
        "k": "10",
        "c": "3",
        "code": "18.00.00.11"
    },
    {
        "id": 594,
        "label": "Pulmão",
        "k": "25",
        "c": "3",
        "code": "18.00.00.12"
    },
    {
        "id": 595,
        "label": "Pleura",
        "k": "10",
        "c": "3",
        "code": "18.00.00.13"
    },
    {
        "id": 596,
        "label": "Mediastino",
        "k": "30",
        "c": "3",
        "code": "18.00.00.14"
    },
    {
        "id": 597,
        "label": "Vulva",
        "k": "5",
        "c": "3",
        "code": "18.00.00.15"
    },
    {
        "id": 598,
        "label": "Vagina",
        "k": "5",
        "c": "3",
        "code": "18.00.00.16"
    },
    {
        "id": 599,
        "label": "Colo do útero",
        "k": "5",
        "c": "3",
        "code": "18.00.00.17"
    },
    {
        "id": 600,
        "label": "Recto",
        "k": "5",
        "c": "3",
        "code": "18.00.00.18"
    },
    {
        "id": 601,
        "label": "Orofaringe",
        "k": "8",
        "c": "3",
        "code": "18.00.00.19"
    },
    {
        "id": 602,
        "label": "Nasofaringe",
        "k": "10",
        "c": "3",
        "code": "18.00.00.20"
    },
    {
        "id": 603,
        "label": "Laringe",
        "k": "10",
        "c": "3",
        "code": "18.00.00.21"
    },
    {
        "id": 604,
        "label": "Nariz",
        "k": "5",
        "c": "3",
        "code": "18.00.00.22"
    },
    {
        "id": 605,
        "label": "Baço",
        "k": "20",
        "c": "3",
        "code": "18.00.00.23"
    },
    {
        "id": 606,
        "label": "Baço, com manometria",
        "k": "25",
        "c": "3",
        "code": "18.00.00.24"
    },
    {
        "id": 607,
        "label": "Pele",
        "k": "5",
        "c": "3",
        "code": "18.00.00.25"
    },
    {
        "id": 608,
        "label": "Mucosa",
        "k": "5",
        "c": "3",
        "code": "18.00.00.26"
    },
    {
        "id": 609,
        "label": "Endométrio",
        "k": "10",
        "c": "3",
        "code": "18.00.00.27"
    },
    {
        "id": 610,
        "label": "Biópsia endoscópica (acresce ao valor da endoscopia)",
        "k": "5",
        "c": "3",
        "code": "18.00.00.28"
    },
    {
        "id": 611,
        "label": "Antebraço",
        "k": "20",
        "c": "0",
        "code": "19.00.00.01"
    },
    {
        "id": 612,
        "label": "Braço e antebraço",
        "k": "25",
        "c": "0",
        "code": "19.00.00.02"
    },
    {
        "id": 613,
        "label": "Cervicotorácico (Minerva)",
        "k": "40",
        "c": "0",
        "code": "19.00.00.03"
    },
    {
        "id": 614,
        "label": "Dedos da mão ou pé",
        "k": "15",
        "c": "0",
        "code": "19.00.00.04"
    },
    {
        "id": 615,
        "label": "Mão e antebraço distal (luva gessada)",
        "k": "20",
        "c": "0",
        "code": "19.00.00.05"
    },
    {
        "id": 616,
        "label": "Tóraco-braquial",
        "k": "40",
        "c": "0",
        "code": "19.00.00.06"
    },
    {
        "id": 617,
        "label": "Torácico (colete gessado)",
        "k": "40",
        "c": "0",
        "code": "19.00.00.07"
    },
    {
        "id": 618,
        "label": "Colar",
        "k": "15",
        "c": "0",
        "code": "19.00.00.08"
    },
    {
        "id": 619,
        "label": "Velpeau",
        "k": "30",
        "c": "0",
        "code": "19.00.00.09"
    },
    {
        "id": 620,
        "label": "Pelvi-podálico unilateral",
        "k": "30",
        "c": "0",
        "code": "19.00.00.10"
    },
    {
        "id": 621,
        "label": "Pelvi-podálico bilateral",
        "k": "40",
        "c": "0",
        "code": "19.00.00.11"
    },
    {
        "id": 622,
        "label": "Halopelvico",
        "k": "50",
        "c": "0",
        "code": "19.00.00.12"
    },
    {
        "id": 623,
        "label": "Coxa, perna e pé",
        "k": "25",
        "c": "0",
        "code": "19.00.00.13"
    },
    {
        "id": 624,
        "label": "Perna e pé",
        "k": "20",
        "c": "0",
        "code": "19.00.00.14"
    },
    {
        "id": 625,
        "label": "Coxa e perna (joelheira gessada)",
        "k": "25",
        "c": "0",
        "code": "19.00.00.15"
    },
    {
        "id": 626,
        "label": "Leito gessado",
        "k": "40",
        "c": "0",
        "code": "19.00.00.16"
    },
    {
        "id": 627,
        "label": "Toda a coluna vertebral com correcção de escoliose",
        "k": "50",
        "c": "0",
        "code": "19.00.00.17"
    },
    {
        "id": 628,
        "label": "Colocação de tala tipo Denis Browne em pé ou mão bôta",
        "k": "5",
        "c": "0",
        "code": "19.00.00.18"
    },
    {
        "id": 629,
        "label": "Cutânea à cabeça",
        "k": "10",
        "c": "0",
        "code": "19.01.00.01"
    },
    {
        "id": 630,
        "label": "Cutânea à bacia",
        "k": "10",
        "c": "0",
        "code": "19.01.00.02"
    },
    {
        "id": 631,
        "label": "Cutânea aos membros",
        "k": "10",
        "c": "0",
        "code": "19.01.00.03"
    },
    {
        "id": 632,
        "label": "Esquelética ao crânio",
        "k": "25",
        "c": "0",
        "code": "19.01.00.04"
    },
    {
        "id": 633,
        "label": "Esquelética aos membros",
        "k": "35",
        "c": "0",
        "code": "19.01.00.05"
    },
    {
        "id": 634,
        "label": "Esquelética aos dedos",
        "k": "25",
        "c": "0",
        "code": "19.01.00.06"
    },
    {
        "id": 635,
        "label": "Halopélvica",
        "k": "50",
        "c": "0",
        "code": "19.01.00.07"
    },
    {
        "id": 636,
        "label": "Escleroterapia ambulatória de varizes do membro inferior (por sessão e por membro)",
        "k": "15",
        "c": "5",
        "code": "20.00.00.01"
    },
    {
        "id": 637,
        "label": "Escleroterapia de varizes do membroinferior sob anestesia geral",
        "k": "80",
        "c": "5",
        "code": "20.00.00.02"
    },
    {
        "id": 638,
        "label": "Limpeza ou curetagem de úlcera de perna",
        "k": "20",
        "c": "10",
        "code": "20.00.00.03"
    },
    {
        "id": 639,
        "label": "Enxerto cutâneo de úlcera de perna",
        "k": "70",
        "c": "0",
        "code": "20.00.00.04"
    },
    {
        "id": 640,
        "label": "Aplicação de aparelho de compressão permanente (bota una, cola de zinco, kompress, etc.)",
        "k": "10",
        "c": "20",
        "code": "20.00.00.05"
    },
    {
        "id": 641,
        "label": "Compressão pneumática sequencial",
        "k": "5",
        "c": "20",
        "code": "20.00.00.06"
    },
    {
        "id": 642,
        "label": "Drenagem linfática de membro por correntes farádicas em sincronismo cardíaco, com massagem associada",
        "k": "5",
        "c": "30",
        "code": "20.00.00.07"
    },
    {
        "id": 643,
        "label": "Laserterapia de varizes",
        "k": "40",
        "c": "30",
        "code": "20.00.00.08"
    },
    {
        "id": 644,
        "label": "Simpatólise lombar",
        "k": "50",
        "c": "0",
        "code": "20.00.00.09"
    },
    {
        "id": 645,
        "label": "Aspiração de bolsas sinoviais",
        "k": "6",
        "c": "0",
        "code": "21.00.00.01"
    },
    {
        "id": 646,
        "label": "Aspiração de bolsas sinoviais sob controlo ecográfico",
        "k": "16",
        "c": "0",
        "code": "21.00.00.02"
    },
    {
        "id": 647,
        "label": "Artrocentese diagnóstica",
        "k": "8",
        "c": "0",
        "code": "21.00.00.03"
    },
    {
        "id": 648,
        "label": "Artrocentese diagnóstica sob controlo ecográfico",
        "k": "18",
        "c": "0",
        "code": "21.00.00.04"
    },
    {
        "id": 649,
        "label": "Biópsia sinovial fechada do joelho",
        "k": "20",
        "c": "0",
        "code": "21.00.00.05"
    },
    {
        "id": 650,
        "label": "Biópsia sinovial fechada da coxo-femoral",
        "k": "40",
        "c": "0",
        "code": "21.00.00.06"
    },
    {
        "id": 651,
        "label": "Biópsia sinovial fechada de outras articulações sem intensificador de imagem",
        "k": "20",
        "c": "0",
        "code": "21.00.00.07"
    },
    {
        "id": 652,
        "label": "Biópsia sinovial fechada de outras articulações com intensificador de imagem",
        "k": "35",
        "c": "0",
        "code": "21.00.00.08"
    },
    {
        "id": 653,
        "label": "Biópsia sinovial sob artroscopia (acresce ao valor da artroscopia)",
        "k": "5",
        "c": "0",
        "code": "21.00.00.09"
    },
    {
        "id": 654,
        "label": "Biópsia óssea da crista ilíaca - Ver Cód. 18.00.00.06",
        "k": "0",
        "c": "0",
        "code": "21.00.00.10"
    },
    {
        "id": 655,
        "label": "Biópsia das glândulas salivares",
        "k": "20",
        "c": "0",
        "code": "21.00.00.11"
    },
    {
        "id": 656,
        "label": "Biópsia de nódulo sub-cutâneo - Ver Cód 18.",
        "k": "0",
        "c": "0",
        "code": "21.00.00.12"
    },
    {
        "id": 657,
        "label": "Biópsia de músculo - Ver Cód. 18.",
        "k": "0",
        "c": "0",
        "code": "21.00.00.13"
    },
    {
        "id": 658,
        "label": "Biópsia de fascia muscular - Ver Cód. 18.",
        "k": "0",
        "c": "0",
        "code": "21.00.00.14"
    },
    {
        "id": 659,
        "label": "Condroscopia",
        "k": "40",
        "c": "0",
        "code": "21.00.00.15"
    },
    {
        "id": 660,
        "label": "Artrografia",
        "k": "15",
        "c": "0",
        "code": "21.00.00.16"
    },
    {
        "id": 661,
        "label": "Discografia",
        "k": "50",
        "c": "0",
        "code": "21.00.00.17"
    },
    {
        "id": 662,
        "label": "Infiltração de partes moles",
        "k": "6",
        "c": "0",
        "code": "21.00.00.18"
    },
    {
        "id": 663,
        "label": "Infiltração de partes moles sob controlo ecográfico",
        "k": "16",
        "c": "0",
        "code": "21.00.00.19"
    },
    {
        "id": 664,
        "label": "Infiltração articular",
        "k": "8",
        "c": "0",
        "code": "21.00.00.20"
    },
    {
        "id": 665,
        "label": "Infiltração articular sob controlo ecográfico",
        "k": "18",
        "c": "0",
        "code": "21.00.00.21"
    },
    {
        "id": 666,
        "label": "Infiltração articular sob intensificador de imagem",
        "k": "23",
        "c": "0",
        "code": "21.00.00.22"
    },
    {
        "id": 667,
        "label": "Artroclise",
        "k": "35",
        "c": "0",
        "code": "21.00.00.23"
    },
    {
        "id": 668,
        "label": "Bloqueio de nervo periférico",
        "k": "10",
        "c": "0",
        "code": "21.00.00.24"
    },
    {
        "id": 669,
        "label": "Infiltração epidural",
        "k": "10",
        "c": "0",
        "code": "21.00.00.25"
    },
    {
        "id": 670,
        "label": "Injecção intratecal",
        "k": "25",
        "c": "0",
        "code": "21.00.00.26"
    },
    {
        "id": 671,
        "label": "Sinoviortese com hexacetonido",
        "k": "15",
        "c": "0",
        "code": "21.00.00.27"
    },
    {
        "id": 672,
        "label": "Sinoviortese com hexacetonido sob controlo ecográfico",
        "k": "15",
        "c": "20",
        "code": "21.00.00.28"
    },
    {
        "id": 673,
        "label": "Sinoviortese com hexacetonido sob intensificador de imagem",
        "k": "15",
        "c": "20",
        "code": "21.00.00.29"
    },
    {
        "id": 674,
        "label": "Sinoviortese com ácido ósmico",
        "k": "25",
        "c": "0",
        "code": "21.00.00.30"
    },
    {
        "id": 675,
        "label": "Sinoviortese com ácido ósmico sob controlo ecográfico",
        "k": "15",
        "c": "20",
        "code": "21.00.00.31"
    },
    {
        "id": 676,
        "label": "Sinoviortese com ácido ósmico sob intensificador de imagem",
        "k": "30",
        "c": "20",
        "code": "21.00.00.32"
    },
    {
        "id": 677,
        "label": "Sinoviortese com radioisótopos Itrium 90",
        "k": "30",
        "c": "0",
        "code": "21.00.00.33"
    },
    {
        "id": 678,
        "label": "Sinoviortese com radioisótopos Renium 186 (com controlo ecográfico)",
        "k": "30",
        "c": "20",
        "code": "21.00.00.34"
    },
    {
        "id": 679,
        "label": "Sinoviortese com radioisótopos Renium 186 (com intensificador de imagem)",
        "k": "30",
        "c": "20",
        "code": "21.00.00.35"
    },
    {
        "id": 680,
        "label": "Quimionucleólise",
        "k": "150",
        "c": "0",
        "code": "21.00.00.36"
    },
    {
        "id": 681,
        "label": "Nucleólise percutânea",
        "k": "150",
        "c": "0",
        "code": "21.00.00.37"
    },
    {
        "id": 682,
        "label": "Artroscopia terapêutica simples (extração de corpos livres, desbridamentos, secções, etc)",
        "k": "90",
        "c": "0",
        "code": "21.00.00.38"
    },
    {
        "id": 683,
        "label": "Artroscopia terapêutica de lesões articulares circunscritas",
        "k": "130",
        "c": "0",
        "code": "21.00.00.39"
    },
    {
        "id": 684,
        "label": "Capilaroscopia da prega cutânea periungueal",
        "k": "6",
        "c": "0",
        "code": "21.00.00.40"
    },
    {
        "id": 685,
        "label": "Incisão e drenagem de abcesso subcutâneo",
        "k": "15",
        "c": "4",
        "code": "30.00.00.01"
    },
    {
        "id": 686,
        "label": "Incisão e drenagem de abcesso profundo",
        "k": "25",
        "c": "4",
        "code": "30.00.00.02"
    },
    {
        "id": 687,
        "label": "Incisão e drenagem de quisto sebáceo, quisto pilonidal ou fúrunculo",
        "k": "15",
        "c": "4",
        "code": "30.00.00.03"
    },
    {
        "id": 688,
        "label": "Incisão e drenagem de oníquia ou perioníquia",
        "k": "15",
        "c": "4",
        "code": "30.00.00.04"
    },
    {
        "id": 689,
        "label": "Incisão e drenagem de hematoma",
        "k": "15",
        "c": "4",
        "code": "30.00.00.05"
    },
    {
        "id": 690,
        "label": "Excisão de pequenos tumores benignos ou quistos subcutâneos excepto região frontal e face",
        "k": "30",
        "c": "0",
        "code": "30.00.00.06"
    },
    {
        "id": 691,
        "label": "Excisão de lesões benignas da região frontal da face e mão, passíveis de encerramento directo",
        "k": "40",
        "c": "0",
        "code": "30.00.00.07"
    },
    {
        "id": 692,
        "label": "Excisão de tumor profundo",
        "k": "100",
        "c": "0",
        "code": "30.00.00.08"
    },
    {
        "id": 693,
        "label": "Excisão de lesões benignas ou malignas só passíveis de encerramento com plastia complexa, na região frontal, face e mão",
        "k": "200",
        "c": "0",
        "code": "30.00.00.09"
    },
    {
        "id": 694,
        "label": "Excisão de lesões benignas ou malignas só passíveis de encerramento com plastia complexa, excepto região frontal, face e mão",
        "k": "150",
        "c": "0",
        "code": "30.00.00.10"
    },
    {
        "id": 695,
        "label": "Excisão de cicatrizes da face, pescoço ou mão e plastia por retalhos locais (Z, W, LLL, etc)",
        "k": "100",
        "c": "0",
        "code": "30.00.00.11"
    },
    {
        "id": 696,
        "label": "Curetagem de verrugas ou condilomas",
        "k": "15",
        "c": "3",
        "code": "30.00.00.12"
    },
    {
        "id": 697,
        "label": "Excisão de quisto ou fístula pilonidal",
        "k": "75",
        "c": "8",
        "code": "30.00.00.13"
    },
    {
        "id": 698,
        "label": "Excisão de quisto ou fístula branquial",
        "k": "110",
        "c": "8",
        "code": "30.00.00.14"
    },
    {
        "id": 699,
        "label": "Sutura de ferida da face e região frontal até 5 cm (adultos) e 2,5 cm (crianças)",
        "k": "30",
        "c": "8",
        "code": "30.00.00.15"
    },
    {
        "id": 700,
        "label": "Sutura de ferida da face e região frontal maior do que 5 cm (adultos) e 2,5 cm(crianças)",
        "k": "60",
        "c": "8",
        "code": "30.00.00.16"
    },
    {
        "id": 701,
        "label": "Sutura de ferida cutânea até 5 cm (adultos) ou 2,5 cm (crianças) excepto face e região frontal",
        "k": "15",
        "c": "8",
        "code": "30.00.00.17"
    },
    {
        "id": 702,
        "label": "Sutura de ferida cutânea maior do que 5 cm (adultos) ou 2,5 cm (crianças), excepto face e região frontal",
        "k": "20",
        "c": "8",
        "code": "30.00.00.18"
    },
    {
        "id": 703,
        "label": "Tratamento cirúrgico da unha encravada",
        "k": "15",
        "c": "8",
        "code": "30.00.00.19"
    },
    {
        "id": 704,
        "label": "Excisão de cicatrizes da face, pescoço ou mão e sutura directa",
        "k": "50",
        "c": "0",
        "code": "30.00.00.20"
    },
    {
        "id": 705,
        "label": "Excisão de cicatrizes de pregas de flexão e plastia por retalhos locais",
        "k": "75",
        "c": "0",
        "code": "30.00.00.21"
    },
    {
        "id": 706,
        "label": "Excisão de cicatrizes, excepto face, pescoço ou mão e sutura directa",
        "k": "50",
        "c": "0",
        "code": "30.00.00.22"
    },
    {
        "id": 707,
        "label": "Excisão de cicatrizes, excepto face, pescoço ou mão e plastia por retalhos locais",
        "k": "60",
        "c": "0",
        "code": "30.00.00.23"
    },
    {
        "id": 708,
        "label": "Excisão de cicatriz e plastia por enxerto de pele total",
        "k": "120",
        "c": "0",
        "code": "30.00.00.24"
    },
    {
        "id": 709,
        "label": "Extracção de corpo estranho supra-aponevrótico excepto face ou mão",
        "k": "20",
        "c": "8",
        "code": "30.00.00.25"
    },
    {
        "id": 710,
        "label": "Extracção de corpo estranho subaponevrótico excepto face ou mão",
        "k": "40",
        "c": "8",
        "code": "30.00.00.26"
    },
    {
        "id": 711,
        "label": "Extracção de corpo estranho da face ou mão",
        "k": "40",
        "c": "8",
        "code": "30.00.00.27"
    },
    {
        "id": 712,
        "label": "Desbridamento cirúrgico de ulceração até 3% da superfície corporal",
        "k": "15",
        "c": "0",
        "code": "30.00.00.28"
    },
    {
        "id": 713,
        "label": "Desbridamento cirúrgico de ulceração entre 3% e 10%",
        "k": "40",
        "c": "0",
        "code": "30.00.00.29"
    },
    {
        "id": 714,
        "label": "Desbridamento cirúrgico de ulceração entre 10% e 30%",
        "k": "60",
        "c": "0",
        "code": "30.00.00.30"
    },
    {
        "id": 715,
        "label": "Desbridamento cirúrgico de ulceração acima de 30%",
        "k": "80",
        "c": "0",
        "code": "30.00.00.31"
    },
    {
        "id": 716,
        "label": "Desbridamento cirúrgico de queimaduras da face, pescoço ou mão",
        "k": "40",
        "c": "0",
        "code": "30.01.00.01"
    },
    {
        "id": 717,
        "label": "Desbridamento cirúrgico de queimadura até 3% excepto face, pescoço e mão",
        "k": "20",
        "c": "0",
        "code": "30.01.00.02"
    },
    {
        "id": 718,
        "label": "Desbridamento cirúrgico de queimaduras entre 3% e 10%",
        "k": "40",
        "c": "0",
        "code": "30.01.00.03"
    },
    {
        "id": 719,
        "label": "Desbridamento cirúrgico de queimaduras entre 10% e 30%",
        "k": "60",
        "c": "0",
        "code": "30.01.00.04"
    },
    {
        "id": 720,
        "label": "Desbridamento cirúrgico de queimaduras acima de 30%",
        "k": "80",
        "c": "0",
        "code": "30.01.00.05"
    },
    {
        "id": 721,
        "label": "Penso cirúrgico de queimadura até 3%",
        "k": "10",
        "c": "0",
        "code": "30.01.00.06"
    },
    {
        "id": 722,
        "label": "Penso cirúrgico de queimadura entre 3% e 10%",
        "k": "15",
        "c": "0",
        "code": "30.01.00.07"
    },
    {
        "id": 723,
        "label": "Penso cirúrgico de queimadura entre 10% e 30%",
        "k": "25",
        "c": "0",
        "code": "30.01.00.08"
    },
    {
        "id": 724,
        "label": "Penso cirúrgico de queimadura com mais de 30%",
        "k": "35",
        "c": "0",
        "code": "30.01.00.09"
    },
    {
        "id": 725,
        "label": "Penso inicial de queimadura até 3%",
        "k": "10",
        "c": "0",
        "code": "30.01.00.10"
    },
    {
        "id": 726,
        "label": "Penso inicial de queimadura entre 3% e 10%",
        "k": "20",
        "c": "0",
        "code": "30.01.00.11"
    },
    {
        "id": 727,
        "label": "Penso inicial de queimadura entre 10% e 30%",
        "k": "30",
        "c": "0",
        "code": "30.01.00.12"
    },
    {
        "id": 728,
        "label": "Penso inicial de queimadura mais de 30%",
        "k": "35",
        "c": "0",
        "code": "30.01.00.13"
    },
    {
        "id": 729,
        "label": "Pensos ulteriores entre 3% e 10%",
        "k": "15",
        "c": "0",
        "code": "30.01.00.14"
    },
    {
        "id": 730,
        "label": "Pensos ulteriores entre 10% e 30%",
        "k": "25",
        "c": "0",
        "code": "30.01.00.15"
    },
    {
        "id": 731,
        "label": "Pensos ulteriores mais de 30%",
        "k": "30",
        "c": "0",
        "code": "30.01.00.16"
    },
    {
        "id": 732,
        "label": "Cirurgia da calvície com expansor tecidular - cada tempo",
        "k": "150",
        "c": "0",
        "code": "30.02.00.01"
    },
    {
        "id": 733,
        "label": "Cirurgia da calvície, enxertos pilosos, com Laser (cada sessão)",
        "k": "200",
        "c": "0",
        "code": "30.02.00.02"
    },
    {
        "id": 734,
        "label": "Cirurgia da calvície, enxertos pilosos, com microcirurgia (cada sessão)",
        "k": "200",
        "c": "0",
        "code": "30.02.00.03"
    },
    {
        "id": 735,
        "label": "Cirurgia da calvície, enxertos pilosos, cada sessão",
        "k": "100",
        "c": "0",
        "code": "30.02.00.04"
    },
    {
        "id": 736,
        "label": "Dermabrasão cirúrgica total da face",
        "k": "100",
        "c": "0",
        "code": "30.02.00.05"
    },
    {
        "id": 737,
        "label": "Dermabrasão cirúrgica parcial da face por unidade estética",
        "k": "45",
        "c": "0",
        "code": "30.02.00.06"
    },
    {
        "id": 738,
        "label": "Dermabrasão cirúrgica em qualquer outra área",
        "k": "30",
        "c": "0",
        "code": "30.02.00.07"
    },
    {
        "id": 739,
        "label": "Dermabrasão química total da face",
        "k": "90",
        "c": "0",
        "code": "30.02.00.08"
    },
    {
        "id": 740,
        "label": "Dermabrasão química parcial da face por unidade estética",
        "k": "40",
        "c": "0",
        "code": "30.02.00.09"
    },
    {
        "id": 741,
        "label": "Ritidectomia cervicofacial",
        "k": "300",
        "c": "0",
        "code": "30.02.00.10"
    },
    {
        "id": 742,
        "label": "Ritidectomia frontal",
        "k": "150",
        "c": "0",
        "code": "30.02.00.11"
    },
    {
        "id": 743,
        "label": "Ritidectomia cervicofacial e frontal",
        "k": "350",
        "c": "0",
        "code": "30.02.00.12"
    },
    {
        "id": 744,
        "label": "Ritidectomia das pálpebras (por pálpebra)",
        "k": "40",
        "c": "0",
        "code": "30.02.00.13"
    },
    {
        "id": 745,
        "label": "Ritidectomia das pálpebras (por pálpebra) com ressecção das bolsas adiposas",
        "k": "60",
        "c": "0",
        "code": "30.02.00.14"
    },
    {
        "id": 746,
        "label": "Rinoplastia completa",
        "k": "125",
        "c": "0",
        "code": "30.02.00.15"
    },
    {
        "id": 747,
        "label": "Rinoplastia da ponta",
        "k": "100",
        "c": "0",
        "code": "30.02.00.16"
    },
    {
        "id": 748,
        "label": "Rinoplastia das asas",
        "k": "100",
        "c": "0",
        "code": "30.02.00.17"
    },
    {
        "id": 749,
        "label": "Reconstrução nasal parcial, tempo principal",
        "k": "120",
        "c": "0",
        "code": "30.02.00.18"
    },
    {
        "id": 750,
        "label": "Reconstrução nasal parcial, tempo complementar",
        "k": "60",
        "c": "0",
        "code": "30.02.00.19"
    },
    {
        "id": 751,
        "label": "Reconstrução nasal total, tempo principal",
        "k": "180",
        "c": "0",
        "code": "30.02.00.20"
    },
    {
        "id": 752,
        "label": "Reconstrução nasal total, tempo complementar",
        "k": "80",
        "c": "0",
        "code": "30.02.00.21"
    },
    {
        "id": 753,
        "label": "Reconstrução nasal por retalho pré-fabricado (1o. tempo)",
        "k": "300",
        "c": "0",
        "code": "30.02.00.22"
    },
    {
        "id": 754,
        "label": "Correcção do nariz em sela com enxerto ósseo ou cartilagens",
        "k": "200",
        "c": "0",
        "code": "30.02.00.23"
    },
    {
        "id": 755,
        "label": "Reconstrução auricular (ver Cod. 47)",
        "k": "0",
        "c": "0",
        "code": "30.02.00.24"
    },
    {
        "id": 756,
        "label": "Tratamento de orelhas descoladas (otoplastia) unilateral",
        "k": "60",
        "c": "0",
        "code": "30.02.00.25"
    },
    {
        "id": 757,
        "label": "Reconstrução total da orelha, tempo principal",
        "k": "200",
        "c": "0",
        "code": "30.02.00.26"
    },
    {
        "id": 758,
        "label": "Reconstrução total da orelha, tempo complementar",
        "k": "80",
        "c": "0",
        "code": "30.02.00.27"
    },
    {
        "id": 759,
        "label": "Reconstrução parcial da orelha, tempo principal",
        "k": "100",
        "c": "0",
        "code": "30.02.00.28"
    },
    {
        "id": 760,
        "label": "Reconstrução parcial da orelha, tempo complementar",
        "k": "50",
        "c": "0",
        "code": "30.02.00.29"
    },
    {
        "id": 761,
        "label": "Queilopastia estética",
        "k": "100",
        "c": "0",
        "code": "30.02.00.30"
    },
    {
        "id": 762,
        "label": "Mentoplastia estética com endopróteses",
        "k": "100",
        "c": "0",
        "code": "30.02.00.31"
    },
    {
        "id": 763,
        "label": "Mentoplastia estética com osteotomias",
        "k": "120",
        "c": "0",
        "code": "30.02.00.32"
    },
    {
        "id": 764,
        "label": "Correcção do duplo queixo",
        "k": "80",
        "c": "0",
        "code": "30.02.00.33"
    },
    {
        "id": 765,
        "label": "Modelação estética malar-zigomática com endoprótese",
        "k": "100",
        "c": "0",
        "code": "30.02.00.34"
    },
    {
        "id": 766,
        "label": "Modelação estética malar-zigomática com osteotomias",
        "k": "130",
        "c": "0",
        "code": "30.02.00.35"
    },
    {
        "id": 767,
        "label": "Abdominoplastia (simples ressecção)",
        "k": "100",
        "c": "0",
        "code": "30.02.00.36"
    },
    {
        "id": 768,
        "label": "Abdominoplastia, com transposição do umbigo",
        "k": "120",
        "c": "0",
        "code": "30.02.00.37"
    },
    {
        "id": 769,
        "label": "Abdominoplastia, com transposição do umbigo e reparação músculo-aponevrótica",
        "k": "150",
        "c": "0",
        "code": "30.02.00.38"
    },
    {
        "id": 770,
        "label": "Dermolipectomiabraquial (unilateral)",
        "k": "70",
        "c": "0",
        "code": "30.02.00.39"
    },
    {
        "id": 771,
        "label": "Ritidectomia da mão (unilateral)",
        "k": "70",
        "c": "0",
        "code": "30.02.00.40"
    },
    {
        "id": 772,
        "label": "Cirurgia estética da região glutea(unilateral)",
        "k": "70",
        "c": "0",
        "code": "30.02.00.41"
    },
    {
        "id": 773,
        "label": "Dermolipectomia da coxa (unilateral)",
        "k": "70",
        "c": "0",
        "code": "30.02.00.42"
    },
    {
        "id": 774,
        "label": "Lipoaspiração do pescoço",
        "k": "50",
        "c": "0",
        "code": "30.02.00.43"
    },
    {
        "id": 775,
        "label": "Lipoaspiração do tórax (zonas limitadas)",
        "k": "30",
        "c": "0",
        "code": "30.02.00.44"
    },
    {
        "id": 776,
        "label": "Lipoaspiração do abdómen",
        "k": "75",
        "c": "0",
        "code": "30.02.00.45"
    },
    {
        "id": 777,
        "label": "Lipoaspiração do membro superior(unilateral)",
        "k": "50",
        "c": "0",
        "code": "30.02.00.46"
    },
    {
        "id": 778,
        "label": "Lipoaspiração da região glútea(unilateral)",
        "k": "60",
        "c": "0",
        "code": "30.02.00.47"
    },
    {
        "id": 779,
        "label": "Lipoaspiração trocantérica (unilateral)",
        "k": "60",
        "c": "0",
        "code": "30.02.00.48"
    },
    {
        "id": 780,
        "label": "Lipoaspiração da coxa (unilateral)",
        "k": "75",
        "c": "0",
        "code": "30.02.00.49"
    },
    {
        "id": 781,
        "label": "Lipoaspiração da perna",
        "k": "50",
        "c": "0",
        "code": "30.02.00.50"
    },
    {
        "id": 782,
        "label": "Remodelação corporal por auto-enxertos",
        "k": "100",
        "c": "0",
        "code": "30.02.00.51"
    },
    {
        "id": 783,
        "label": "Remodelação corporal por inclusão de material biológico conservado, por unidade estética",
        "k": "50",
        "c": "0",
        "code": "30.02.00.52"
    },
    {
        "id": 784,
        "label": "Tatuagem estética por sessão ou unidade anatómica",
        "k": "50",
        "c": "0",
        "code": "30.02.00.53"
    },
    {
        "id": 785,
        "label": "Remoção cirúrgica de tatuagem, cada tempo",
        "k": "50",
        "c": "0",
        "code": "30.02.00.54"
    },
    {
        "id": 786,
        "label": "Cirurgia da calvície, com retalhos, cada tempo operatório",
        "k": "100",
        "c": "0",
        "code": "30.02.00.55"
    },
    {
        "id": 787,
        "label": "Mentoplastia estética com retalhos locais",
        "k": "120",
        "c": "0",
        "code": "30.02.00.56"
    },
    {
        "id": 788,
        "label": "Enxerto dermoepidérmico até 10 cm2 ou de 0,5% da superfície corporal das crianças, excepto face, boca, pescoço, genitais ou mão",
        "k": "40",
        "c": "0",
        "code": "30.03.00.01"
    },
    {
        "id": 789,
        "label": "Enxerto dermoepidérmico até 100 cm2 ou de 1% da superfície corporal das crianças excepto face, boca, pescoço, genitais ou mão",
        "k": "60",
        "c": "0",
        "code": "30.03.00.02"
    },
    {
        "id": 790,
        "label": "Enxerto dermoepidérmico maior que 100 cm2 ou de 1% da superfície corporal das crianças",
        "k": "100",
        "c": "0",
        "code": "30.03.00.03"
    },
    {
        "id": 791,
        "label": "Enxerto dermoepidérmico maior que 100 cm2 ou de 1% da superfície corporal das crianças por cada área de 100 cm2 a mais",
        "k": "50",
        "c": "0",
        "code": "30.03.00.04"
    },
    {
        "id": 792,
        "label": "Enxertos em rede",
        "k": "80",
        "c": "0",
        "code": "30.03.00.05"
    },
    {
        "id": 793,
        "label": "Enxerto dermoepidérmico até 100 cm2 ou de 1% da superfície corporal das crianças, face, boca, pescoço, genitais ou mão",
        "k": "100",
        "c": "0",
        "code": "30.03.00.06"
    },
    {
        "id": 794,
        "label": "Enxerto dermoepidérmico maior que 100 cm2 ou de 1% da superfície corporal das crianças na face, boca, genitais ou mão",
        "k": "150",
        "c": "0",
        "code": "30.03.00.07"
    },
    {
        "id": 795,
        "label": "Enxerto de clivagem, ou de pele total na região frontal, face, boca, pescoço, axila, genitais, mãos e pés até 20 cm2",
        "k": "100",
        "c": "0",
        "code": "30.03.00.08"
    },
    {
        "id": 796,
        "label": "Enxerto de clivagem, ou de pele total na região frontal, face, boca, pescoço, axila, genitais, mãos e pés maior que 20cm2",
        "k": "140",
        "c": "0",
        "code": "30.03.00.09"
    },
    {
        "id": 797,
        "label": "Enxerto de clivagem de pele total até 20 cm2 noutras regiões",
        "k": "80",
        "c": "0",
        "code": "30.03.00.10"
    },
    {
        "id": 798,
        "label": "Enxerto de clivagem em pele total maior que 20 cm2 noutras regiões",
        "k": "100",
        "c": "0",
        "code": "30.03.00.11"
    },
    {
        "id": 799,
        "label": "Enxertos adiposos ou dermo-adiposos fascia, cartilagem, ósseo, periósteo",
        "k": "100",
        "c": "0",
        "code": "30.03.00.12"
    },
    {
        "id": 800,
        "label": "Retalhos locais, em Z,U,W,V, Y, etc.",
        "k": "50",
        "c": "0",
        "code": "30.03.00.13"
    },
    {
        "id": 801,
        "label": "Retalhos locais, plastias em Z, múltiplas, etc.",
        "k": "90",
        "c": "0",
        "code": "30.03.00.14"
    },
    {
        "id": 802,
        "label": "Retalhos de tecidos adjacentes na região frontal face, boca, pescoço, axila, genitais mãos, pés até 10 cm2",
        "k": "140",
        "c": "0",
        "code": "30.03.00.15"
    },
    {
        "id": 870,
        "label": "Meniscectomia têmporo-mandíbular",
        "k": "100",
        "c": "0",
        "code": "33.00.00.09"
    },
    {
        "id": 803,
        "label": "Retalhos de tecidos adjacentes na região frontal, face, boca, pescoço, axila, genitais, mãos, pés, maior que 10 cm2",
        "k": "150",
        "c": "0",
        "code": "30.03.00.16"
    },
    {
        "id": 804,
        "label": "Retalhos de tecidos adjacentes noutras regiões menores que 10 cm2",
        "k": "50",
        "c": "0",
        "code": "30.03.00.17"
    },
    {
        "id": 805,
        "label": "Retalhos de tecidos adjacentes noutras regiões de 10 cm2 a 30 cm2",
        "k": "80",
        "c": "0",
        "code": "30.03.00.18"
    },
    {
        "id": 806,
        "label": "Formação de retalhos pediculados, à distância, 1o. tempo",
        "k": "110",
        "c": "0",
        "code": "30.03.00.19"
    },
    {
        "id": 807,
        "label": "Cada tempo complementar",
        "k": "80",
        "c": "0",
        "code": "30.03.00.20"
    },
    {
        "id": 808,
        "label": "Retalhos de tecidos adjacentes noutras regiões maior que 30 cm2",
        "k": "100",
        "c": "0",
        "code": "30.03.00.21"
    },
    {
        "id": 809,
        "label": "Retalhos miocutâneos sem pedículo vascular identificado",
        "k": "150",
        "c": "0",
        "code": "30.03.00.22"
    },
    {
        "id": 810,
        "label": "Retalhos cutâneos, miocutâneos ou musculares com pedículo vascular ou vasculo nervoso identificado",
        "k": "200",
        "c": "0",
        "code": "30.03.00.23"
    },
    {
        "id": 811,
        "label": "Retalhos fasciocutâneos",
        "k": "120",
        "c": "0",
        "code": "30.03.00.24"
    },
    {
        "id": 812,
        "label": "Retalhos musculares ou miocutâneos",
        "k": "150",
        "c": "0",
        "code": "30.03.00.25"
    },
    {
        "id": 813,
        "label": "Retalhos osteomiocutâneos ou osteo-musculares",
        "k": "170",
        "c": "0",
        "code": "30.03.00.26"
    },
    {
        "id": 814,
        "label": "Retalho livre com microanastomoses vasculares",
        "k": "250",
        "c": "0",
        "code": "30.03.00.27"
    },
    {
        "id": 815,
        "label": "Retalhos de tecidos adjacentes no couro cabeludo, tronco e membros (excepto mãos e pés) menores que 10cm2",
        "k": "100",
        "c": "0",
        "code": "30.03.00.28"
    },
    {
        "id": 816,
        "label": "Retalhos de tecidos adjacentes no couro cabeludo, tronco e membros (excepto mãos e pés) de 10cm2 a 30cm2",
        "k": "120",
        "c": "0",
        "code": "30.03.00.29"
    },
    {
        "id": 817,
        "label": "Retalhos de tecidos adjacentes no couro cabeludo, tronco e membros (excepto mãos e pés) maior que 30cm2",
        "k": "150",
        "c": "0",
        "code": "30.03.00.30"
    },
    {
        "id": 818,
        "label": "Retalhos miocutâneos, musculares, ou fasciocutâneos sem pedículo vascular indentificado",
        "k": "150",
        "c": "0",
        "code": "30.03.00.31"
    },
    {
        "id": 819,
        "label": "Retalhos cutâneos, miocutâneos ou musculares com pedículo vascular ou vasculo nervoso identificado",
        "k": "200",
        "c": "0",
        "code": "30.03.00.32"
    },
    {
        "id": 820,
        "label": "Retalho livre com microanastomoses",
        "k": "400",
        "c": "0",
        "code": "30.03.00.33"
    },
    {
        "id": 821,
        "label": "Reconstrução osteoplástica de dedos, cada tempo",
        "k": "150",
        "c": "0",
        "code": "30.03.00.34"
    },
    {
        "id": 822,
        "label": "Expansão tissular para correcção de anomalias várias, por cada expansor e cada tempo operatório",
        "k": "100",
        "c": "0",
        "code": "30.04.00.01"
    },
    {
        "id": 823,
        "label": "Desbridamento de escara de decúbito",
        "k": "50",
        "c": "0",
        "code": "30.04.00.02"
    },
    {
        "id": 824,
        "label": "Desbridamento de escara de decúbito com plastia local",
        "k": "130",
        "c": "0",
        "code": "30.04.00.03"
    },
    {
        "id": 825,
        "label": "Transferência de dedo à distância por microcirurgia",
        "k": "450",
        "c": "0",
        "code": "30.04.00.04"
    },
    {
        "id": 826,
        "label": "Incisão e drenagem de abcesso profundo",
        "k": "20",
        "c": "0",
        "code": "31.00.00.01"
    },
    {
        "id": 827,
        "label": "Excisão de fibroadenomas e quisto",
        "k": "40",
        "c": "0",
        "code": "31.00.00.02"
    },
    {
        "id": 828,
        "label": "Mastectomia parcial (quadrantectomia)",
        "k": "60",
        "c": "0",
        "code": "31.00.00.03"
    },
    {
        "id": 829,
        "label": "Mastectomia simples",
        "k": "110",
        "c": "0",
        "code": "31.00.00.04"
    },
    {
        "id": 830,
        "label": "Mastectomia subcutânea",
        "k": "110",
        "c": "0",
        "code": "31.00.00.05"
    },
    {
        "id": 831,
        "label": "Mastectomia por ginecomastia, unilateral",
        "k": "100",
        "c": "0",
        "code": "31.00.00.06"
    },
    {
        "id": 832,
        "label": "Mastectomia radical",
        "k": "160",
        "c": "0",
        "code": "31.00.00.07"
    },
    {
        "id": 833,
        "label": "Mastectomia radical com linfadenectomia da mamária interna",
        "k": "200",
        "c": "0",
        "code": "31.00.00.08"
    },
    {
        "id": 834,
        "label": "Mastectomia superradical (Urban)",
        "k": "280",
        "c": "0",
        "code": "31.00.00.09"
    },
    {
        "id": 835,
        "label": "Mastectomia radical modificada",
        "k": "160",
        "c": "0",
        "code": "31.00.00.10"
    },
    {
        "id": 836,
        "label": "Mastectomia parcial com esvasiamento axilar",
        "k": "140",
        "c": "0",
        "code": "31.00.00.11"
    },
    {
        "id": 837,
        "label": "Plastia mamária de redução unilateral",
        "k": "175",
        "c": "0",
        "code": "31.00.00.12"
    },
    {
        "id": 838,
        "label": "Plastia mamária de aumento unilateral",
        "k": "100",
        "c": "0",
        "code": "31.00.00.13"
    },
    {
        "id": 839,
        "label": "Remoção ou substituição de material de prótese",
        "k": "50",
        "c": "0",
        "code": "31.00.00.14"
    },
    {
        "id": 840,
        "label": "Tratamento cirúrgico de encapsulação de material de prótese",
        "k": "70",
        "c": "0",
        "code": "31.00.00.15"
    },
    {
        "id": 841,
        "label": "Reconstrução mamária pós mastectomia ou agenesia com utilização de expansor",
        "k": "150",
        "c": "0",
        "code": "31.00.00.16"
    },
    {
        "id": 842,
        "label": "Reconstrução mamária com retalhos adjacentes",
        "k": "150",
        "c": "0",
        "code": "31.00.00.17"
    },
    {
        "id": 843,
        "label": "Reconstrução mamária com retalhos miocutâneos à distância",
        "k": "250",
        "c": "0",
        "code": "31.00.00.18"
    },
    {
        "id": 844,
        "label": "Reconstrução do complexo areolo-mamilar",
        "k": "100",
        "c": "0",
        "code": "31.00.00.19"
    },
    {
        "id": 845,
        "label": "Reconstrução mamária com retalho miocutâneo do grande dorsal",
        "k": "250",
        "c": "0",
        "code": "31.00.00.20"
    },
    {
        "id": 846,
        "label": "Reconstrução mamária com Tram-Flap",
        "k": "350",
        "c": "0",
        "code": "31.00.00.21"
    },
    {
        "id": 847,
        "label": "Correcção de mamilos invertidos (unilateral)",
        "k": "100",
        "c": "0",
        "code": "31.00.00.22"
    },
    {
        "id": 848,
        "label": "Exérese de mamilos supranumerários",
        "k": "50",
        "c": "0",
        "code": "31.00.00.23"
    },
    {
        "id": 849,
        "label": "Exérese de mama supranumerária",
        "k": "70",
        "c": "0",
        "code": "31.00.00.24"
    },
    {
        "id": 850,
        "label": "Reconstrução mamária com retalho livre",
        "k": "400",
        "c": "0",
        "code": "31.00.00.25"
    },
    {
        "id": 851,
        "label": "Excisão de lesão infraclínica da mama com marcação prévia",
        "k": "100",
        "c": "0",
        "code": "31.00.00.26"
    },
    {
        "id": 852,
        "label": "Excisão de lesão da mama (com ou sem marcação) e com esvaziamento axilar",
        "k": "140",
        "c": "0",
        "code": "31.00.00.27"
    },
    {
        "id": 853,
        "label": "Reexcisão da área da biópsia prévia e esvasiamento axilar",
        "k": "140",
        "c": "0",
        "code": "31.00.00.28"
    },
    {
        "id": 854,
        "label": "Ressecção de canais galactóforos",
        "k": "60",
        "c": "0",
        "code": "31.00.00.29"
    },
    {
        "id": 855,
        "label": "Esvasiamento axilar como 2o. tempo de cirurgia conservadora do carcinoma da mama (cirurgia diferida)",
        "k": "140",
        "c": "0",
        "code": "31.00.00.30"
    },
    {
        "id": 856,
        "label": "Reimplantes do braço ou antebraço, completos",
        "k": "500",
        "c": "0",
        "code": "32.00.00.01"
    },
    {
        "id": 857,
        "label": "Reimplantes do braço e antebraço incompletos (com pedículo de tecidos moles)",
        "k": "450",
        "c": "0",
        "code": "32.00.00.02"
    },
    {
        "id": 858,
        "label": "Reimplantes da mão, completa",
        "k": "450",
        "c": "0",
        "code": "32.00.00.03"
    },
    {
        "id": 859,
        "label": "Reimplantes da mão, incompleta (com pedículo de tecidos moles)",
        "k": "400",
        "c": "0",
        "code": "32.00.00.04"
    },
    {
        "id": 860,
        "label": "Reimplantes de dedos, completa",
        "k": "200",
        "c": "0",
        "code": "32.00.00.05"
    },
    {
        "id": 861,
        "label": "Reimplantes de dedos, incompleta (com pedículo de tecidos moles)",
        "k": "150",
        "c": "0",
        "code": "32.00.00.06"
    },
    {
        "id": 862,
        "label": "Tratamento de craniosinostose por via extracraniana",
        "k": "200",
        "c": "0",
        "code": "33.00.00.01"
    },
    {
        "id": 863,
        "label": "Tratamento de craniosinostose por via intracraniana",
        "k": "300",
        "c": "0",
        "code": "33.00.00.02"
    },
    {
        "id": 864,
        "label": "Correcção de teleorbitismo por via extracraniana",
        "k": "200",
        "c": "0",
        "code": "33.00.00.03"
    },
    {
        "id": 865,
        "label": "Correcção de teleorbitismo por via intracraniana",
        "k": "250",
        "c": "0",
        "code": "33.00.00.04"
    },
    {
        "id": 866,
        "label": "Cranioplastias (ver Cod. 45)",
        "k": "0",
        "c": "0",
        "code": "33.00.00.05"
    },
    {
        "id": 867,
        "label": "Artrotomia têmporo-mandíbular",
        "k": "70",
        "c": "0",
        "code": "33.00.00.06"
    },
    {
        "id": 868,
        "label": "Coronoidectomia (operação isolada)",
        "k": "140",
        "c": "0",
        "code": "33.00.00.07"
    },
    {
        "id": 869,
        "label": "Ressecção do condilo mandíbular",
        "k": "110",
        "c": "0",
        "code": "33.00.00.08"
    },
    {
        "id": 871,
        "label": "Excisão de quisto ou tumor benigno da mandíbula",
        "k": "60",
        "c": "0",
        "code": "33.00.00.10"
    },
    {
        "id": 872,
        "label": "Ressecção parcial da mandíbula, sem perda de continuidade",
        "k": "75",
        "c": "0",
        "code": "33.00.00.11"
    },
    {
        "id": 873,
        "label": "Ressecção parcial da mandíbula com perda de continuidade",
        "k": "150",
        "c": "0",
        "code": "33.00.00.12"
    },
    {
        "id": 874,
        "label": "Ressecção total da mandíbula",
        "k": "200",
        "c": "0",
        "code": "33.00.00.13"
    },
    {
        "id": 875,
        "label": "Ressecção total da mandíbula com reconstrução imediata",
        "k": "300",
        "c": "0",
        "code": "33.00.00.14"
    },
    {
        "id": 876,
        "label": "Ressecção parcial do maxilar superior",
        "k": "110",
        "c": "0",
        "code": "33.00.00.15"
    },
    {
        "id": 877,
        "label": "Ressecção parcial do maxilar superior com reconstrução imediata",
        "k": "200",
        "c": "0",
        "code": "33.00.00.16"
    },
    {
        "id": 878,
        "label": "Ressecção total do maxilar superior",
        "k": "200",
        "c": "0",
        "code": "33.00.00.17"
    },
    {
        "id": 879,
        "label": "Ressecção de outros ossos da face por quisto ou tumor",
        "k": "110",
        "c": "0",
        "code": "33.00.00.18"
    },
    {
        "id": 880,
        "label": "Reconstrução parcial da mandíbula com material aloplástico",
        "k": "100",
        "c": "0",
        "code": "33.00.00.19"
    },
    {
        "id": 881,
        "label": "Reconstrução parcial da mandíbula com enxerto osteo-cartilagineo",
        "k": "150",
        "c": "0",
        "code": "33.00.00.20"
    },
    {
        "id": 882,
        "label": "Reconstrução total da mandíbula com material aloplástico",
        "k": "120",
        "c": "0",
        "code": "33.00.00.21"
    },
    {
        "id": 883,
        "label": "Reconstrução total da mandíbula com enxerto ósseo",
        "k": "200",
        "c": "0",
        "code": "33.00.00.22"
    },
    {
        "id": 884,
        "label": "Osteoplastia mandíbular por prognatismo ou retroprognatismo",
        "k": "300",
        "c": "0",
        "code": "33.00.00.23"
    },
    {
        "id": 885,
        "label": "Osteoplastia da mandíbula segmentar",
        "k": "200",
        "c": "0",
        "code": "33.00.00.24"
    },
    {
        "id": 886,
        "label": "Osteoplastia da mandíbula, total",
        "k": "300",
        "c": "0",
        "code": "33.00.00.25"
    },
    {
        "id": 887,
        "label": "Osteoplastia do maxilar superior, segmentar tipo Le Fort I",
        "k": "200",
        "c": "0",
        "code": "33.00.00.26"
    },
    {
        "id": 888,
        "label": "Osteoplastia maxilo-facial, com osteotomia tipo Le Fort II",
        "k": "300",
        "c": "0",
        "code": "33.00.00.27"
    },
    {
        "id": 889,
        "label": "Condiloplastia mandíbular programada unilateral",
        "k": "140",
        "c": "0",
        "code": "33.00.00.28"
    },
    {
        "id": 890,
        "label": "Artroplastia têmporo-mandíbular (cada lado)",
        "k": "140",
        "c": "0",
        "code": "33.00.00.29"
    },
    {
        "id": 891,
        "label": "Cranioplastia complexa com enxerto ósseo",
        "k": "450",
        "c": "0",
        "code": "33.00.00.30"
    },
    {
        "id": 892,
        "label": "Osteotomia segmentar do maxilar superior",
        "k": "150",
        "c": "0",
        "code": "33.00.00.31"
    },
    {
        "id": 893,
        "label": "Cranioplastia simples com enxerto ósseo",
        "k": "250",
        "c": "0",
        "code": "33.00.00.32"
    },
    {
        "id": 894,
        "label": "Disfunção intermaxilar",
        "k": "150",
        "c": "0",
        "code": "33.00.00.33"
    },
    {
        "id": 895,
        "label": "Cranioplastia simples com material aloplastico",
        "k": "170",
        "c": "0",
        "code": "33.00.00.34"
    },
    {
        "id": 896,
        "label": "Ablação de tumor por dupla abordagem (intra e extracraniana)",
        "k": "450",
        "c": "0",
        "code": "33.00.00.35"
    },
    {
        "id": 897,
        "label": "Tratamento da fractura de nariz por redução simples fechada",
        "k": "30",
        "c": "0",
        "code": "33.00.01.01"
    },
    {
        "id": 898,
        "label": "Tratamento de fractura instável de nariz",
        "k": "50",
        "c": "0",
        "code": "33.00.01.02"
    },
    {
        "id": 899,
        "label": "Tratamento de fractura do complexo nasoetmoide, incluindo reparação dos ligamentos centrais epicantais",
        "k": "150",
        "c": "0",
        "code": "33.00.01.03"
    },
    {
        "id": 900,
        "label": "Tratamento de fractura nasomaxilar (tipo Le Fort III)",
        "k": "150",
        "c": "0",
        "code": "33.00.01.04"
    },
    {
        "id": 901,
        "label": "Tratamento da fractura-disjunção cranio-facial (tipo Le Fort III)",
        "k": "160",
        "c": "0",
        "code": "33.00.01.05"
    },
    {
        "id": 902,
        "label": "Tratamento de fractura do maxilar superior, por método simples",
        "k": "75",
        "c": "0",
        "code": "33.00.01.06"
    },
    {
        "id": 903,
        "label": "Tratamento de fractura do maxilar superior, com fixação interna ou externa",
        "k": "140",
        "c": "0",
        "code": "33.00.01.07"
    },
    {
        "id": 904,
        "label": "Tratamento da fractura do complexo zigomático malar sem fixação",
        "k": "75",
        "c": "0",
        "code": "33.00.01.08"
    },
    {
        "id": 905,
        "label": "Tratamento da fractura do complexo zigomático malar com fixação",
        "k": "150",
        "c": "0",
        "code": "33.00.01.09"
    },
    {
        "id": 906,
        "label": "\"Tratamento de fractura do pavimento da órbita, tipo \"\"blow-out\"\"\"",
        "k": "120",
        "c": "0",
        "code": "33.00.01.10"
    },
    {
        "id": 907,
        "label": "\"Tratamento de fractura do pavimento da òrbita, tipo \"\"blow-out\"\" com endoprotese de \"\"Silastic\"\"\"",
        "k": "150",
        "c": "0",
        "code": "33.00.01.11"
    },
    {
        "id": 908,
        "label": "\"Tratamento de fractura do pavimento da órbita, tipo \"\"blow-out\"\", com enxerto ósseo\"",
        "k": "150",
        "c": "0",
        "code": "33.00.01.12"
    },
    {
        "id": 909,
        "label": "Bloqueio intermaxilar (operação isolada)",
        "k": "70",
        "c": "0",
        "code": "33.00.01.13"
    },
    {
        "id": 910,
        "label": "Tratamento da fractura da mandíbula por método simples",
        "k": "75",
        "c": "0",
        "code": "33.00.01.14"
    },
    {
        "id": 911,
        "label": "Tratamento ortopédico da fractura mandíbular por fixação intermaxilar",
        "k": "110",
        "c": "0",
        "code": "33.00.01.15"
    },
    {
        "id": 912,
        "label": "Tratamento cirúrgico e osteossíntese da fractura mandíbular (1 osteossíntese)",
        "k": "150",
        "c": "0",
        "code": "33.00.01.16"
    },
    {
        "id": 913,
        "label": "Tratamento de luxação têmporo-maxilar por manipulação externa",
        "k": "15",
        "c": "0",
        "code": "33.00.01.17"
    },
    {
        "id": 914,
        "label": "Tratamento de luxação têmporo-maxilar por método cirúrgico",
        "k": "110",
        "c": "0",
        "code": "33.00.01.18"
    },
    {
        "id": 915,
        "label": "Tratamento de fractura tipo Le Fort I ou Le Fort II",
        "k": "100",
        "c": "0",
        "code": "33.00.01.19"
    },
    {
        "id": 916,
        "label": "Tratamento cirúrgico com osteossínteses múltiplas de fracturas mandíbulares",
        "k": "200",
        "c": "0",
        "code": "33.00.01.20"
    },
    {
        "id": 917,
        "label": "Tratamento de fractura do maxilar superior, por bloqueio intermaxilar",
        "k": "75",
        "c": "0",
        "code": "33.00.01.21"
    },
    {
        "id": 918,
        "label": "Tratamento de fractura do maxilar superior com osteossíntese",
        "k": "100",
        "c": "0",
        "code": "33.00.01.22"
    },
    {
        "id": 919,
        "label": "Idem com suspensão",
        "k": "75",
        "c": "0",
        "code": "33.00.01.23"
    },
    {
        "id": 920,
        "label": "Tratamento de fractura mandíbular por bloqueio intermaxilar",
        "k": "110",
        "c": "0",
        "code": "33.00.01.24"
    },
    {
        "id": 921,
        "label": "Tratamento cirúrgico de fractura mandíbular por osteossíntese e bloqueio intermaxilar",
        "k": "150",
        "c": "0",
        "code": "33.00.01.25"
    },
    {
        "id": 922,
        "label": "Tratamento de luxação têmporo-mandíbular por manipulação externa",
        "k": "30",
        "c": "0",
        "code": "33.00.01.26"
    },
    {
        "id": 923,
        "label": "Tenotomia dos escalenos",
        "k": "90",
        "c": "0",
        "code": "33.01.00.01"
    },
    {
        "id": 924,
        "label": "Cirurgia muscular dinâmica por transferência muscular",
        "k": "150",
        "c": "0",
        "code": "33.01.00.02"
    },
    {
        "id": 925,
        "label": "Enxertos musculares livres",
        "k": "250",
        "c": "0",
        "code": "33.01.00.03"
    },
    {
        "id": 926,
        "label": "Cirurgia estética para estabilização funcional das comissuras (suspensões) mioneurotomias selectivas",
        "k": "150",
        "c": "0",
        "code": "33.01.00.04"
    },
    {
        "id": 927,
        "label": "Torcicolo congénito, mioplastia de alongamento ou miectomia",
        "k": "110",
        "c": "0",
        "code": "33.01.00.05"
    },
    {
        "id": 928,
        "label": "Celulectomia cervical unilateral",
        "k": "200",
        "c": "0",
        "code": "33.01.00.06"
    },
    {
        "id": 929,
        "label": "Celulectomia cervical bilateral",
        "k": "300",
        "c": "0",
        "code": "33.01.00.07"
    },
    {
        "id": 930,
        "label": "Neurorrafia do nervo facial",
        "k": "200",
        "c": "0",
        "code": "33.01.00.08"
    },
    {
        "id": 931,
        "label": "Enxerto nervoso do nervo facial",
        "k": "250",
        "c": "0",
        "code": "33.01.00.09"
    },
    {
        "id": 932,
        "label": "Enxerto nervoso cruzado do nervo facial",
        "k": "300",
        "c": "0",
        "code": "33.01.00.10"
    },
    {
        "id": 933,
        "label": "Neurotização a partir de outro nervo craniano",
        "k": "300",
        "c": "0",
        "code": "33.01.00.11"
    },
    {
        "id": 934,
        "label": "Fractura do esterno (osteossíntese)",
        "k": "110",
        "c": "0",
        "code": "33.02.00.01"
    },
    {
        "id": 935,
        "label": "Fracturas de costelas (fixação)",
        "k": "75",
        "c": "0",
        "code": "33.02.00.02"
    },
    {
        "id": 936,
        "label": "Ressecção de costelas",
        "k": "75",
        "c": "0",
        "code": "33.02.00.03"
    },
    {
        "id": 937,
        "label": "Reparação da parede torácica com prótese",
        "k": "120",
        "c": "0",
        "code": "33.02.00.04"
    },
    {
        "id": 938,
        "label": "\"Tratamento cirúrgico de \"\"pectus excavatum\"\" ou \"\"carinatum\"\"\"",
        "k": "260",
        "c": "0",
        "code": "33.02.00.05"
    },
    {
        "id": 939,
        "label": "Fractura ou luxação vertebral",
        "k": "100",
        "c": "0",
        "code": "33.03.00.01"
    },
    {
        "id": 940,
        "label": "Apófises espinhosas cervicais",
        "k": "50",
        "c": "0",
        "code": "33.03.00.02"
    },
    {
        "id": 941,
        "label": "Apófises transversas lombares",
        "k": "40",
        "c": "0",
        "code": "33.03.00.03"
    },
    {
        "id": 942,
        "label": "Sacro e cóccix",
        "k": "40",
        "c": "0",
        "code": "33.03.00.04"
    },
    {
        "id": 943,
        "label": "Coluna cervical, via transoral ou lateral",
        "k": "180",
        "c": "0",
        "code": "33.03.01.01"
    },
    {
        "id": 944,
        "label": "Coluna cervical, via anterior ou anterolateral",
        "k": "180",
        "c": "0",
        "code": "33.03.01.02"
    },
    {
        "id": 945,
        "label": "Coluna cervical, via posterior",
        "k": "160",
        "c": "0",
        "code": "33.03.01.03"
    },
    {
        "id": 946,
        "label": "Coluna dorsal, via anterior",
        "k": "220",
        "c": "0",
        "code": "33.03.01.04"
    },
    {
        "id": 947,
        "label": "Coluna dorsal, via anterolateral",
        "k": "200",
        "c": "0",
        "code": "33.03.01.05"
    },
    {
        "id": 948,
        "label": "Coluna dorsal, via posterior",
        "k": "160",
        "c": "0",
        "code": "33.03.01.06"
    },
    {
        "id": 949,
        "label": "Coluna lombar, via anterior",
        "k": "160",
        "c": "0",
        "code": "33.03.01.07"
    },
    {
        "id": 950,
        "label": "Coluna lombar, via anterolateral",
        "k": "160",
        "c": "0",
        "code": "33.03.01.08"
    },
    {
        "id": 951,
        "label": "Coluna lombar, via posterior",
        "k": "160",
        "c": "0",
        "code": "33.03.01.09"
    },
    {
        "id": 952,
        "label": "Artrodese da occípito vertebral",
        "k": "200",
        "c": "0",
        "code": "33.03.01.10"
    },
    {
        "id": 953,
        "label": "Artrodese da coluna cervical, via anterior",
        "k": "220",
        "c": "0",
        "code": "33.03.01.11"
    },
    {
        "id": 954,
        "label": "Artrodese da coluna cervical, via posterior",
        "k": "180",
        "c": "0",
        "code": "33.03.01.12"
    },
    {
        "id": 955,
        "label": "Artrodese da coluna dorsal, via anterior",
        "k": "270",
        "c": "0",
        "code": "33.03.01.13"
    },
    {
        "id": 956,
        "label": "Artrodese da coluna dorsal, via posterior",
        "k": "180",
        "c": "0",
        "code": "33.03.01.14"
    },
    {
        "id": 957,
        "label": "Artrodese da coluna lombar, via anterior",
        "k": "240",
        "c": "0",
        "code": "33.03.01.15"
    },
    {
        "id": 958,
        "label": "Artrodese da coluna lombar, via posterior",
        "k": "180",
        "c": "0",
        "code": "33.03.01.16"
    },
    {
        "id": 959,
        "label": "Artrodese da coluna lombossagrada, via anterior",
        "k": "250",
        "c": "0",
        "code": "33.03.01.17"
    },
    {
        "id": 960,
        "label": "Artrodese da coluna lombossagrada, via posterior",
        "k": "180",
        "c": "0",
        "code": "33.03.01.18"
    },
    {
        "id": 961,
        "label": "Artrodese da coluna lombossagrada, via combinada",
        "k": "300",
        "c": "0",
        "code": "33.03.01.19"
    },
    {
        "id": 962,
        "label": "Fracturas ou fractura luxação da coluna cervical, via transoral, sem artrodese ou osteossíntese",
        "k": "180",
        "c": "0",
        "code": "33.03.01.20"
    },
    {
        "id": 963,
        "label": "Fracturas ou fractura luxação da coluna cervical, via transoral, com artrodese ou osteossíntese",
        "k": "220",
        "c": "0",
        "code": "33.03.01.21"
    },
    {
        "id": 964,
        "label": "Fracturas ou fractura luxação da coluna cervical, via anterior ou anterolateral sem artrodese",
        "k": "180",
        "c": "0",
        "code": "33.03.01.22"
    },
    {
        "id": 965,
        "label": "Fracturas ou fractura luxação da coluna cervical, via anterior ou anterolateral com artrodese",
        "k": "220",
        "c": "0",
        "code": "33.03.01.23"
    },
    {
        "id": 966,
        "label": "Fracturas ou fractura luxação da coluna cervical, via posterior sem artrodese",
        "k": "160",
        "c": "0",
        "code": "33.03.01.24"
    },
    {
        "id": 967,
        "label": "Fracturas ou fractura luxação da coluna cervical, via posterior com artrodese",
        "k": "180",
        "c": "0",
        "code": "33.03.01.25"
    },
    {
        "id": 968,
        "label": "Fracturas ou fractura luxação da coluna dorsal, via anterior",
        "k": "220",
        "c": "0",
        "code": "33.03.01.26"
    },
    {
        "id": 969,
        "label": "Fracturas ou fractura luxação da coluna dorsal, via anterior com artrodese",
        "k": "270",
        "c": "0",
        "code": "33.03.01.27"
    },
    {
        "id": 970,
        "label": "Fracturas ou fractura luxação da coluna dorsal, via posterior sem artrodese",
        "k": "160",
        "c": "0",
        "code": "33.03.01.28"
    },
    {
        "id": 971,
        "label": "Fracturas ou fractura luxação da coluna dorsal, via posterior com artrodese",
        "k": "180",
        "c": "0",
        "code": "33.03.01.29"
    },
    {
        "id": 972,
        "label": "Fracturas ou fractura luxação da coluna lombar, via anterior sem artrodese",
        "k": "160",
        "c": "0",
        "code": "33.03.01.30"
    },
    {
        "id": 973,
        "label": "Fracturas ou fractura luxação da coluna lombar, via anterior com artrodese",
        "k": "240",
        "c": "0",
        "code": "33.03.01.31"
    },
    {
        "id": 974,
        "label": "Fracturas ou fractura luxação da coluna lombar, via posterior sem artrodese",
        "k": "160",
        "c": "0",
        "code": "33.03.01.32"
    },
    {
        "id": 975,
        "label": "Fracturas ou fractura luxação da coluna lombar, via posterior com artrodese",
        "k": "180",
        "c": "0",
        "code": "33.03.01.33"
    },
    {
        "id": 976,
        "label": "Espondilolistese via anterior",
        "k": "240",
        "c": "0",
        "code": "33.03.01.34"
    },
    {
        "id": 977,
        "label": "Espondilolistese via posterior",
        "k": "180",
        "c": "0",
        "code": "33.03.01.35"
    },
    {
        "id": 978,
        "label": "Espondilolistese via combinada",
        "k": "300",
        "c": "0",
        "code": "33.03.01.36"
    },
    {
        "id": 979,
        "label": "Escoliose, cifose ou em associação - Artrodese posterior",
        "k": "270",
        "c": "0",
        "code": "33.03.01.37"
    },
    {
        "id": 980,
        "label": "Escoliose, cifose ou em associação - Artrodese anterior",
        "k": "350",
        "c": "0",
        "code": "33.03.01.38"
    },
    {
        "id": 981,
        "label": "Escoliose, cifose ou em associação - Via combinada",
        "k": "400",
        "c": "0",
        "code": "33.03.01.39"
    },
    {
        "id": 982,
        "label": "Osteótomia da coluna vertebral",
        "k": "350",
        "c": "0",
        "code": "33.03.01.40"
    },
    {
        "id": 983,
        "label": "Ressecção do cóccix",
        "k": "50",
        "c": "0",
        "code": "33.03.01.41"
    },
    {
        "id": 984,
        "label": "Ressecção de apofises transversas lombares",
        "k": "60",
        "c": "0",
        "code": "33.03.01.42"
    },
    {
        "id": 985,
        "label": "Lamínectomia descompressiva (até duas vértebras)",
        "k": "140",
        "c": "0",
        "code": "33.03.01.43"
    },
    {
        "id": 986,
        "label": "Laminectomia descompressiva (mais de duas vértebras)",
        "k": "180",
        "c": "0",
        "code": "33.03.01.44"
    },
    {
        "id": 987,
        "label": "Realinhamento de canal estreito",
        "k": "250",
        "c": "0",
        "code": "33.03.01.45"
    },
    {
        "id": 988,
        "label": "Corporectomia cervical por via anterior",
        "k": "300",
        "c": "0",
        "code": "33.03.01.46"
    },
    {
        "id": 989,
        "label": "Foraminectomia",
        "k": "250",
        "c": "0",
        "code": "33.03.01.47"
    },
    {
        "id": 990,
        "label": "Extirpação de hérnia discal cervical",
        "k": "250",
        "c": "0",
        "code": "33.03.01.48"
    },
    {
        "id": 991,
        "label": "Extirpação de hérnia discal dorsal",
        "k": "300",
        "c": "0",
        "code": "33.03.01.49"
    },
    {
        "id": 992,
        "label": "Extirpação de hérnia discal lombar",
        "k": "180",
        "c": "0",
        "code": "33.03.01.50"
    },
    {
        "id": 993,
        "label": "Nucleolise percutânea",
        "k": "150",
        "c": "0",
        "code": "33.03.01.51"
    },
    {
        "id": 994,
        "label": "Fractura da clavícula",
        "k": "40",
        "c": "0",
        "code": "33.04.00.01"
    },
    {
        "id": 995,
        "label": "Fractura da omoplata",
        "k": "45",
        "c": "0",
        "code": "33.04.00.02"
    },
    {
        "id": 996,
        "label": "Fractura do troquíter",
        "k": "40",
        "c": "0",
        "code": "33.04.00.03"
    },
    {
        "id": 997,
        "label": "Fractura da epífise umeral ou do colo do úmero",
        "k": "60",
        "c": "0",
        "code": "33.04.00.04"
    },
    {
        "id": 998,
        "label": "Fractura da diáfise do úmero",
        "k": "60",
        "c": "0",
        "code": "33.04.00.05"
    },
    {
        "id": 999,
        "label": "Luxação esternoclavicular",
        "k": "25",
        "c": "0",
        "code": "33.04.00.06"
    },
    {
        "id": 1000,
        "label": "Luxação acromioclavicular",
        "k": "25",
        "c": "0",
        "code": "33.04.00.07"
    },
    {
        "id": 1001,
        "label": "Luxação gleno-umeral",
        "k": "40",
        "c": "0",
        "code": "33.04.00.08"
    },
    {
        "id": 1002,
        "label": "Fractura-luxação do ombro",
        "k": "65",
        "c": "0",
        "code": "33.04.00.09"
    },
    {
        "id": 1003,
        "label": "Osteossíntese da fractura da clavícula",
        "k": "75",
        "c": "0",
        "code": "33.04.01.01"
    },
    {
        "id": 1004,
        "label": "Tratamento da pseudoartrose da clavícula",
        "k": "100",
        "c": "0",
        "code": "33.04.01.02"
    },
    {
        "id": 1005,
        "label": "Osteossíntese da omoplata",
        "k": "100",
        "c": "0",
        "code": "33.04.01.03"
    },
    {
        "id": 1006,
        "label": "Osteossíntese da fractura-avulsão do troquíter",
        "k": "120",
        "c": "0",
        "code": "33.04.01.04"
    },
    {
        "id": 1007,
        "label": "Osteossíntese do colo do úmero com ou sem fractura do troquíter",
        "k": "140",
        "c": "0",
        "code": "33.04.01.05"
    },
    {
        "id": 1008,
        "label": "Tratamento de fractura cominutiva ou fractura-luxação da extremidade proximal do úmero",
        "k": "160",
        "c": "0",
        "code": "33.04.01.06"
    },
    {
        "id": 1009,
        "label": "Osteossíntese da diáfise umeral (com ou sem exploração do nervo radial)",
        "k": "140",
        "c": "0",
        "code": "33.04.01.07"
    },
    {
        "id": 1010,
        "label": "Tratamento da pseudoartrose do úmero (colo ou diáfise)",
        "k": "160",
        "c": "0",
        "code": "33.04.01.08"
    },
    {
        "id": 1011,
        "label": "Luxação esternoclavicular (aguda)",
        "k": "75",
        "c": "0",
        "code": "33.04.01.09"
    },
    {
        "id": 1012,
        "label": "Luxação esternoclavicular (recidivante ou inveterada)",
        "k": "90",
        "c": "0",
        "code": "33.04.01.10"
    },
    {
        "id": 1013,
        "label": "Luxação acrómioclavicular",
        "k": "75",
        "c": "0",
        "code": "33.04.01.11"
    },
    {
        "id": 1014,
        "label": "Redução da luxação do ombro (inveterada)",
        "k": "110",
        "c": "0",
        "code": "33.04.01.12"
    },
    {
        "id": 1015,
        "label": "Tratamento da luxação recidivante do ombro",
        "k": "150",
        "c": "0",
        "code": "33.04.01.13"
    },
    {
        "id": 1016,
        "label": "Tratamento de osteomielite (clavícula omoplata, úmero)",
        "k": "120",
        "c": "0",
        "code": "33.04.01.14"
    },
    {
        "id": 1017,
        "label": "Ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)",
        "k": "90",
        "c": "0",
        "code": "33.04.01.15"
    },
    {
        "id": 1018,
        "label": "Ressecção de tumores osteoperiósticos extensos",
        "k": "180",
        "c": "0",
        "code": "33.04.01.16"
    },
    {
        "id": 1019,
        "label": "Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo",
        "k": "280",
        "c": "0",
        "code": "33.04.01.17"
    },
    {
        "id": 1020,
        "label": "Amputação interescápulotorácica",
        "k": "280",
        "c": "0",
        "code": "33.04.01.18"
    },
    {
        "id": 1021,
        "label": "Desarticulação do ombro",
        "k": "160",
        "c": "0",
        "code": "33.04.01.19"
    },
    {
        "id": 1022,
        "label": "Amputação pelo braço",
        "k": "120",
        "c": "0",
        "code": "33.04.01.20"
    },
    {
        "id": 1023,
        "label": "Ressecção parcial da omoplata",
        "k": "140",
        "c": "0",
        "code": "33.04.01.21"
    },
    {
        "id": 1024,
        "label": "Ressecção total da omoplata",
        "k": "160",
        "c": "0",
        "code": "33.04.01.22"
    },
    {
        "id": 1025,
        "label": "Cleidectomia parcial",
        "k": "100",
        "c": "0",
        "code": "33.04.01.23"
    },
    {
        "id": 1026,
        "label": "Cleidectomia total",
        "k": "130",
        "c": "0",
        "code": "33.04.01.24"
    },
    {
        "id": 1027,
        "label": "Ressecção da extremidade proximal do úmero",
        "k": "120",
        "c": "0",
        "code": "33.04.01.25"
    },
    {
        "id": 1028,
        "label": "Osteotomia com osteossíntese do úmero (colo ou diáfise)",
        "k": "140",
        "c": "0",
        "code": "33.04.01.26"
    },
    {
        "id": 1029,
        "label": "Ressecção do acromion",
        "k": "90",
        "c": "0",
        "code": "33.04.01.27"
    },
    {
        "id": 1030,
        "label": "Artroplastia parcial com prótese",
        "k": "140",
        "c": "0",
        "code": "33.04.01.28"
    },
    {
        "id": 1031,
        "label": "Artroplastia total",
        "k": "200",
        "c": "0",
        "code": "33.04.01.29"
    },
    {
        "id": 1032,
        "label": "Artrodese do ombro",
        "k": "140",
        "c": "0",
        "code": "33.04.01.30"
    },
    {
        "id": 1033,
        "label": "Artrotomia simples",
        "k": "50",
        "c": "0",
        "code": "33.04.01.31"
    },
    {
        "id": 1034,
        "label": "Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas",
        "k": "120",
        "c": "0",
        "code": "33.04.01.32"
    },
    {
        "id": 1035,
        "label": "Sinovectomia",
        "k": "120",
        "c": "0",
        "code": "33.04.01.33"
    },
    {
        "id": 1036,
        "label": "Tratamento da elevação congénita da omoplata",
        "k": "210",
        "c": "0",
        "code": "33.04.02.01"
    },
    {
        "id": 1037,
        "label": "Tratamento de tendinopatia calcificante",
        "k": "120",
        "c": "0",
        "code": "33.04.02.02"
    },
    {
        "id": 1038,
        "label": "Tratamento do síndroma de conflito infra-acromiocoracoideu",
        "k": "140",
        "c": "0",
        "code": "33.04.02.03"
    },
    {
        "id": 1039,
        "label": "Tenotomia dos músculos do ombro",
        "k": "90",
        "c": "0",
        "code": "33.04.02.04"
    },
    {
        "id": 1040,
        "label": "Tratamento da rotura da coifa",
        "k": "140",
        "c": "0",
        "code": "33.04.02.05"
    },
    {
        "id": 1041,
        "label": "Tratamento da rotura do supraespinhoso",
        "k": "120",
        "c": "0",
        "code": "33.04.02.06"
    },
    {
        "id": 1042,
        "label": "Sutura do tendão ou tendões do bicípite ou de um longo músculo do ombro",
        "k": "75",
        "c": "0",
        "code": "33.04.02.07"
    },
    {
        "id": 1043,
        "label": "Transposição tendinosa por paralisia dos flexores do cotovelo",
        "k": "160",
        "c": "0",
        "code": "33.04.02.08"
    },
    {
        "id": 1044,
        "label": "Correcção de sequelas de paralisia obstétrica no ombro",
        "k": "120",
        "c": "0",
        "code": "33.04.02.09"
    },
    {
        "id": 1045,
        "label": "Correcção das sequelas da paralisia braquial no ombro do adulto",
        "k": "160",
        "c": "0",
        "code": "33.04.02.10"
    },
    {
        "id": 1046,
        "label": "Correcção das sequelas da paralisia braquial no cotovelo (dinamização)",
        "k": "150",
        "c": "0",
        "code": "33.04.02.11"
    },
    {
        "id": 1047,
        "label": "Cirurgia do plexo braquial, exploração cirúrgica",
        "k": "160",
        "c": "0",
        "code": "33.04.02.12"
    },
    {
        "id": 1048,
        "label": "Cirurgia do plexo braquial, neurólise",
        "k": "200",
        "c": "0",
        "code": "33.04.02.13"
    },
    {
        "id": 1049,
        "label": "Cirurgia do plexo braquial, reconstrução com enxertos nervosos",
        "k": "320",
        "c": "0",
        "code": "33.04.02.14"
    },
    {
        "id": 1050,
        "label": "Fractura supracondiliana do úmero",
        "k": "70",
        "c": "0",
        "code": "33.05.00.01"
    },
    {
        "id": 1051,
        "label": "Fractura dos côndilos umerais",
        "k": "70",
        "c": "0",
        "code": "33.05.00.02"
    },
    {
        "id": 1052,
        "label": "Fractura da epitróclea ou epicôndilo",
        "k": "30",
        "c": "0",
        "code": "33.05.00.03"
    },
    {
        "id": 1053,
        "label": "Fractura do olecrâneo",
        "k": "40",
        "c": "0",
        "code": "33.05.00.04"
    },
    {
        "id": 1054,
        "label": "Fractura da tacícula radial",
        "k": "30",
        "c": "0",
        "code": "33.05.00.05"
    },
    {
        "id": 1055,
        "label": "Fractura da diáfise do rádio ou do cúbito",
        "k": "50",
        "c": "0",
        "code": "33.05.00.06"
    },
    {
        "id": 1056,
        "label": "Fractura das diáfises do rádio e cúbito",
        "k": "60",
        "c": "0",
        "code": "33.05.00.07"
    },
    {
        "id": 1057,
        "label": "Osteoclasia por fractura em consolidação viciosa",
        "k": "90",
        "c": "0",
        "code": "33.05.00.08"
    },
    {
        "id": 1058,
        "label": "Luxação do cotovelo",
        "k": "40",
        "c": "0",
        "code": "33.05.00.09"
    },
    {
        "id": 1059,
        "label": "Fractura-luxação do cotovelo",
        "k": "80",
        "c": "0",
        "code": "33.05.00.10"
    },
    {
        "id": 1060,
        "label": "Pronação dolorosa",
        "k": "10",
        "c": "0",
        "code": "33.05.00.11"
    },
    {
        "id": 1061,
        "label": "Osteossíntese percutânea ou cruenta da fractura supracondiliana do úmero na criança",
        "k": "130",
        "c": "0",
        "code": "33.05.01.01"
    },
    {
        "id": 1062,
        "label": "Osteossíntese da fractura supracondiliana no adulto",
        "k": "120",
        "c": "0",
        "code": "33.05.01.02"
    },
    {
        "id": 1063,
        "label": "Osteossíntese supra e intercondiliana no adulto",
        "k": "140",
        "c": "0",
        "code": "33.05.01.03"
    },
    {
        "id": 1064,
        "label": "Osteossíntese de um côndilo umeral",
        "k": "90",
        "c": "0",
        "code": "33.05.01.04"
    },
    {
        "id": 1065,
        "label": "Osteossíntese da epitróclea",
        "k": "90",
        "c": "0",
        "code": "33.05.01.05"
    },
    {
        "id": 1066,
        "label": "Osteossíntese da fractura-luxação complexa do cotovelo",
        "k": "140",
        "c": "0",
        "code": "33.05.01.06"
    },
    {
        "id": 1067,
        "label": "Ressecção do côndilo umeral",
        "k": "90",
        "c": "0",
        "code": "33.05.01.07"
    },
    {
        "id": 1068,
        "label": "Osteossíntese do olecrâneo",
        "k": "80",
        "c": "0",
        "code": "33.05.01.08"
    },
    {
        "id": 1069,
        "label": "Ressecção do olecrâneo",
        "k": "90",
        "c": "0",
        "code": "33.05.01.09"
    },
    {
        "id": 1070,
        "label": "Osteossíntese ou Exérese da tacícula radial",
        "k": "100",
        "c": "0",
        "code": "33.05.01.10"
    },
    {
        "id": 1071,
        "label": "Reconstrução do ligamento anular do colo do rádio",
        "k": "120",
        "c": "0",
        "code": "33.05.01.11"
    },
    {
        "id": 1072,
        "label": "Osteossíntese da diáfise do rádio ou do cúbito",
        "k": "110",
        "c": "0",
        "code": "33.05.01.12"
    },
    {
        "id": 1073,
        "label": "Osteossíntese diafisária dos dois ossos do antebraço",
        "k": "180",
        "c": "0",
        "code": "33.05.01.13"
    },
    {
        "id": 1074,
        "label": "\"Osteossíntese a \"\"céu fechado\"\" da diáfise do rádio ou do cúbito\"",
        "k": "110",
        "c": "0",
        "code": "33.05.01.14"
    },
    {
        "id": 1075,
        "label": "\"Osteossíntese a \"\"céu fechado\"\" diafisária dos dois ossos do antebraço\"",
        "k": "180",
        "c": "0",
        "code": "33.05.01.15"
    },
    {
        "id": 1076,
        "label": "Osteossíntese da fractura-luxação de Monteggia ou Galeazzi",
        "k": "120",
        "c": "0",
        "code": "33.05.01.16"
    },
    {
        "id": 1077,
        "label": "Luxação do cotovelo (inveterada)",
        "k": "110",
        "c": "0",
        "code": "33.05.01.17"
    },
    {
        "id": 1078,
        "label": "Pseudartrose supracondiliana do úmero",
        "k": "160",
        "c": "0",
        "code": "33.05.01.18"
    },
    {
        "id": 1079,
        "label": "Pseudartrose de um osso do antebraço",
        "k": "130",
        "c": "0",
        "code": "33.05.01.19"
    },
    {
        "id": 1080,
        "label": "Pseudartrose dos dois ossos do antebraço",
        "k": "200",
        "c": "0",
        "code": "33.05.01.20"
    },
    {
        "id": 1081,
        "label": "Tratamento de osteíte ou osteomielite no cotovelo ou antebraço",
        "k": "120",
        "c": "0",
        "code": "33.05.01.21"
    },
    {
        "id": 1082,
        "label": "Ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)",
        "k": "90",
        "c": "0",
        "code": "33.05.01.22"
    },
    {
        "id": 1083,
        "label": "Ressecção de tumores sinoviais ou osteoperiósticos extensos no cotovelo",
        "k": "180",
        "c": "0",
        "code": "33.05.01.23"
    },
    {
        "id": 1084,
        "label": "Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo no cotovelo",
        "k": "220",
        "c": "0",
        "code": "33.05.01.24"
    },
    {
        "id": 1085,
        "label": "Ressecção óssea segmentar no antebraço com reconstituição",
        "k": "150",
        "c": "0",
        "code": "33.05.01.25"
    },
    {
        "id": 1086,
        "label": "Amputação do cotovelo",
        "k": "120",
        "c": "0",
        "code": "33.05.01.26"
    },
    {
        "id": 1087,
        "label": "Amputação pelo antebraço",
        "k": "120",
        "c": "0",
        "code": "33.05.01.27"
    },
    {
        "id": 1088,
        "label": "Operação de Krukenberg",
        "k": "200",
        "c": "0",
        "code": "33.05.01.28"
    },
    {
        "id": 1089,
        "label": "Artrolise do cotovelo",
        "k": "160",
        "c": "0",
        "code": "33.05.01.29"
    },
    {
        "id": 1090,
        "label": "Artroplastia total do cotovelo",
        "k": "200",
        "c": "0",
        "code": "33.05.01.30"
    },
    {
        "id": 1091,
        "label": "Artroplastia protésica da tacícula",
        "k": "100",
        "c": "0",
        "code": "33.05.01.31"
    },
    {
        "id": 1092,
        "label": "Artrodese do cotovelo",
        "k": "140",
        "c": "0",
        "code": "33.05.01.32"
    },
    {
        "id": 1093,
        "label": "Osteotomia do rádio ou do cúbito",
        "k": "110",
        "c": "0",
        "code": "33.05.01.33"
    },
    {
        "id": 1094,
        "label": "Osteotomia dos dois ossos do antebraço",
        "k": "130",
        "c": "0",
        "code": "33.05.01.34"
    },
    {
        "id": 1095,
        "label": "Ressecção de sinostose rádiocubital",
        "k": "150",
        "c": "0",
        "code": "33.05.01.35"
    },
    {
        "id": 1096,
        "label": "Artrotomia simples",
        "k": "40",
        "c": "0",
        "code": "33.05.01.36"
    },
    {
        "id": 1097,
        "label": "Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas",
        "k": "110",
        "c": "0",
        "code": "33.05.01.37"
    },
    {
        "id": 1098,
        "label": "Sinovectomia",
        "k": "110",
        "c": "0",
        "code": "33.05.01.38"
    },
    {
        "id": 1099,
        "label": "Transposição do nervo cubital",
        "k": "110",
        "c": "0",
        "code": "33.05.02.01"
    },
    {
        "id": 1100,
        "label": "Tratamento da epicondilite ou epitrocleíte",
        "k": "80",
        "c": "0",
        "code": "33.05.02.02"
    },
    {
        "id": 1101,
        "label": "Ressecção de higroma ou bursite",
        "k": "40",
        "c": "0",
        "code": "33.05.02.03"
    },
    {
        "id": 1102,
        "label": "Cirurgia reparadora da retracção de Wolkman",
        "k": "200",
        "c": "0",
        "code": "33.05.02.04"
    },
    {
        "id": 1103,
        "label": "Tenotomia dos músculos flexores ou extensores do punho e dedos",
        "k": "75",
        "c": "0",
        "code": "33.05.02.05"
    },
    {
        "id": 1104,
        "label": "Tenodese dos músculos do antebraço em um ou vários tempos",
        "k": "120",
        "c": "0",
        "code": "33.05.02.06"
    },
    {
        "id": 1105,
        "label": "Transposição dos tendões por paralisia dos extensores (paralisia do nervo radial)",
        "k": "120",
        "c": "0",
        "code": "33.05.02.07"
    },
    {
        "id": 1106,
        "label": "Transposição dos tendões por paralisia dos flexores dos dedos",
        "k": "120",
        "c": "0",
        "code": "33.05.02.08"
    },
    {
        "id": 1107,
        "label": "Fractura da extremidade distal do rádio ou cúbito",
        "k": "60",
        "c": "0",
        "code": "33.06.00.01"
    },
    {
        "id": 1108,
        "label": "Fractura do escafóide",
        "k": "70",
        "c": "0",
        "code": "33.06.00.02"
    },
    {
        "id": 1109,
        "label": "Fractura de outros ossos do carpo",
        "k": "40",
        "c": "0",
        "code": "33.06.00.03"
    },
    {
        "id": 1110,
        "label": "Fractura do 1o. Metacarpiano",
        "k": "30",
        "c": "0",
        "code": "33.06.00.04"
    },
    {
        "id": 1111,
        "label": "Fractura de outros metacarpianos",
        "k": "25",
        "c": "0",
        "code": "33.06.00.05"
    },
    {
        "id": 1112,
        "label": "Fractura de uma falange",
        "k": "20",
        "c": "0",
        "code": "33.06.00.06"
    },
    {
        "id": 1113,
        "label": "Fractura de duas ou mais falanges",
        "k": "30",
        "c": "0",
        "code": "33.06.00.07"
    },
    {
        "id": 1114,
        "label": "Luxação rádio-cárpica",
        "k": "60",
        "c": "0",
        "code": "33.06.00.08"
    },
    {
        "id": 1115,
        "label": "Luxação semilunar",
        "k": "70",
        "c": "0",
        "code": "33.06.00.09"
    },
    {
        "id": 1116,
        "label": "Luxação de dedos da mão (cada)",
        "k": "20",
        "c": "0",
        "code": "33.06.00.10"
    },
    {
        "id": 1117,
        "label": "Fractura da extremidade distal do rádio",
        "k": "110",
        "c": "0",
        "code": "33.06.01.01"
    },
    {
        "id": 1118,
        "label": "Reparação rádiocubital distal",
        "k": "75",
        "c": "0",
        "code": "33.06.01.02"
    },
    {
        "id": 1119,
        "label": "Fractura do escafóide",
        "k": "100",
        "c": "0",
        "code": "33.06.01.03"
    },
    {
        "id": 1120,
        "label": "Pseudartrose do escafóide",
        "k": "130",
        "c": "0",
        "code": "33.06.01.04"
    },
    {
        "id": 1121,
        "label": "Luxação do semilunar",
        "k": "100",
        "c": "0",
        "code": "33.06.01.05"
    },
    {
        "id": 1122,
        "label": "Luxação do punho",
        "k": "110",
        "c": "0",
        "code": "33.06.01.06"
    },
    {
        "id": 1123,
        "label": "Fractura-luxação do carpo ou instabilidade traumática",
        "k": "120",
        "c": "0",
        "code": "33.06.01.07"
    },
    {
        "id": 1124,
        "label": "Fractura-luxação de Bennet",
        "k": "110",
        "c": "0",
        "code": "33.06.01.08"
    },
    {
        "id": 1125,
        "label": "Fractura de um ou dois metacarpianos",
        "k": "80",
        "c": "0",
        "code": "33.06.01.09"
    },
    {
        "id": 1126,
        "label": "Luxação metacarpofalângica",
        "k": "60",
        "c": "0",
        "code": "33.06.01.10"
    },
    {
        "id": 1127,
        "label": "Fractura de uma falange",
        "k": "60",
        "c": "0",
        "code": "33.06.01.11"
    },
    {
        "id": 1128,
        "label": "Fractura de várias falanges",
        "k": "80",
        "c": "0",
        "code": "33.06.01.12"
    },
    {
        "id": 1129,
        "label": "Luxação interfalângica",
        "k": "50",
        "c": "0",
        "code": "33.06.01.13"
    },
    {
        "id": 1130,
        "label": "Várias luxações interfalângicas",
        "k": "75",
        "c": "0",
        "code": "33.06.01.14"
    },
    {
        "id": 1131,
        "label": "Curetagem (osteíte, encondromas) ou biópsia",
        "k": "40",
        "c": "0",
        "code": "33.06.01.15"
    },
    {
        "id": 1132,
        "label": "Ressecção de pequenas lesões ou tumores ósseos circunscritos com preenchimento ósseo",
        "k": "80",
        "c": "0",
        "code": "33.06.01.16"
    },
    {
        "id": 1133,
        "label": "Ressecção da extremidade distal do rádio com reconstrução",
        "k": "130",
        "c": "0",
        "code": "33.06.01.17"
    },
    {
        "id": 1134,
        "label": "Ressecção da apófise estiloideia do rádio",
        "k": "70",
        "c": "0",
        "code": "33.06.01.18"
    },
    {
        "id": 1135,
        "label": "Ressecção da extremidade distal do cúbito",
        "k": "70",
        "c": "0",
        "code": "33.06.01.19"
    },
    {
        "id": 1136,
        "label": "Ressecção parcial do escafóide cárpico ou semilunar com artroplastia de interposição",
        "k": "140",
        "c": "0",
        "code": "33.06.01.20"
    },
    {
        "id": 1137,
        "label": "Ressecção da 1a. fileira do carpo",
        "k": "100",
        "c": "0",
        "code": "33.06.01.21"
    },
    {
        "id": 1138,
        "label": "Ressecção de um metacarpiano",
        "k": "70",
        "c": "0",
        "code": "33.06.01.22"
    },
    {
        "id": 1139,
        "label": "Ressecção de dois ou mais",
        "k": "100",
        "c": "0",
        "code": "33.06.01.23"
    },
    {
        "id": 1140,
        "label": "Ressecção artroplástica metacarpofalângica (cada)",
        "k": "70",
        "c": "0",
        "code": "33.06.01.24"
    },
    {
        "id": 1141,
        "label": "Amputação e desarticulação pelo punho",
        "k": "120",
        "c": "0",
        "code": "33.06.01.25"
    },
    {
        "id": 1142,
        "label": "Amputação e desarticulação de metacarpiano",
        "k": "70",
        "c": "0",
        "code": "33.06.01.26"
    },
    {
        "id": 1143,
        "label": "Amputação e desarticulação de dedo",
        "k": "50",
        "c": "0",
        "code": "33.06.01.27"
    },
    {
        "id": 1144,
        "label": "Amputação de dois ou mais",
        "k": "80",
        "c": "0",
        "code": "33.06.01.28"
    },
    {
        "id": 1145,
        "label": "Osteotomia distal do rádio",
        "k": "120",
        "c": "0",
        "code": "33.06.01.29"
    },
    {
        "id": 1146,
        "label": "Osteotomia do 1o. metacarpiano",
        "k": "90",
        "c": "0",
        "code": "33.06.01.30"
    },
    {
        "id": 1147,
        "label": "Osteotomia de um metacarpiano excepto 1o.",
        "k": "70",
        "c": "0",
        "code": "33.06.01.31"
    },
    {
        "id": 1148,
        "label": "Osteotomia de uma falange",
        "k": "40",
        "c": "0",
        "code": "33.06.01.32"
    },
    {
        "id": 1149,
        "label": "Artroplastia total do punho",
        "k": "200",
        "c": "0",
        "code": "33.06.01.33"
    },
    {
        "id": 1150,
        "label": "Artroplastia de substituição do escafóide ou semilunar",
        "k": "140",
        "c": "0",
        "code": "33.06.01.34"
    },
    {
        "id": 1151,
        "label": "Artroplastia do grande osso para tratamento de doença Kienboeck",
        "k": "150",
        "c": "0",
        "code": "33.06.01.35"
    },
    {
        "id": 1152,
        "label": "Artroplastia total carpometacarpiana do polegar",
        "k": "140",
        "c": "0",
        "code": "33.06.01.36"
    },
    {
        "id": 1153,
        "label": "Artroplastia metacarpofalângica ou interfalângica (uma)",
        "k": "110",
        "c": "0",
        "code": "33.06.01.37"
    },
    {
        "id": 1154,
        "label": "Artroplastia metacarpofalângica ou interfalângica (mais de uma)",
        "k": "150",
        "c": "0",
        "code": "33.06.01.38"
    },
    {
        "id": 1155,
        "label": "Artrodese do punho",
        "k": "130",
        "c": "0",
        "code": "33.06.01.39"
    },
    {
        "id": 1156,
        "label": "Artrodese intercárpica",
        "k": "100",
        "c": "0",
        "code": "33.06.01.40"
    },
    {
        "id": 1157,
        "label": "Artrodese carpometacarpiana",
        "k": "90",
        "c": "0",
        "code": "33.06.01.41"
    },
    {
        "id": 1158,
        "label": "Artrodese metacarpofalângica ou interfalângica (cada)",
        "k": "50",
        "c": "0",
        "code": "33.06.01.42"
    },
    {
        "id": 1159,
        "label": "Alongamento de um metacarpiano ou falange",
        "k": "180",
        "c": "0",
        "code": "33.06.01.43"
    },
    {
        "id": 1160,
        "label": "Falangização do 1o. metacarpiano",
        "k": "110",
        "c": "0",
        "code": "33.06.01.44"
    },
    {
        "id": 1161,
        "label": "Polegarização",
        "k": "250",
        "c": "0",
        "code": "33.06.01.45"
    },
    {
        "id": 1162,
        "label": "Polegarização por transplante",
        "k": "300",
        "c": "0",
        "code": "33.06.01.46"
    },
    {
        "id": 1163,
        "label": "Reconstrução do polegar num só tempo (Gillies)",
        "k": "110",
        "c": "0",
        "code": "33.06.01.47"
    },
    {
        "id": 1164,
        "label": "Reconstrução do polegar em vários tempos com plastia abdominal ou torácica e enxerto ósseo",
        "k": "230",
        "c": "0",
        "code": "33.06.01.48"
    },
    {
        "id": 1165,
        "label": "Reconstrução do polegar em vários tempos com plastia abdominal ou torácica, enxerto ósseo e pedículo neurovascular de Littler",
        "k": "300",
        "c": "0",
        "code": "33.06.01.49"
    },
    {
        "id": 1166,
        "label": "Artrotomia",
        "k": "40",
        "c": "0",
        "code": "33.06.01.50"
    },
    {
        "id": 1167,
        "label": "Idem, com sinovectomia",
        "k": "50",
        "c": "0",
        "code": "33.06.01.51"
    },
    {
        "id": 1168,
        "label": "Artrotomia ou artroscopia para tratamento de lesões articulares",
        "k": "50",
        "c": "0",
        "code": "33.06.01.52"
    },
    {
        "id": 1169,
        "label": "Sutura dos tendões extensores dos dedos (um tendão)",
        "k": "50",
        "c": "0",
        "code": "33.06.02.01"
    },
    {
        "id": 1170,
        "label": "Sutura dos tendões extensores dos dedos (mais de um tendão)",
        "k": "80",
        "c": "0",
        "code": "33.06.02.02"
    },
    {
        "id": 1171,
        "label": "Sutura dos tendões flexores dos dedos (um tendão)",
        "k": "90",
        "c": "0",
        "code": "33.06.02.03"
    },
    {
        "id": 1172,
        "label": "Sutura dos tendões flexores dos dedos (mais de um tendão)",
        "k": "130",
        "c": "0",
        "code": "33.06.02.04"
    },
    {
        "id": 1173,
        "label": "Plastia tendinosa para oponência ou para a extensão do polegar",
        "k": "120",
        "c": "0",
        "code": "33.06.02.05"
    },
    {
        "id": 1174,
        "label": "Tenosinovectomia do punho e mão",
        "k": "150",
        "c": "0",
        "code": "33.06.02.06"
    },
    {
        "id": 1175,
        "label": "Tratamento da tenosinovite de DuQuervain",
        "k": "60",
        "c": "0",
        "code": "33.06.02.07"
    },
    {
        "id": 1176,
        "label": "Operação da bainha tendinosa dos dedos (dedo em gatilho)",
        "k": "40",
        "c": "0",
        "code": "33.06.02.08"
    },
    {
        "id": 1177,
        "label": "Outras tenolises",
        "k": "30",
        "c": "0",
        "code": "33.06.02.09"
    },
    {
        "id": 1178,
        "label": "Fasciotomia limitada por retracção da aponevrose palmar",
        "k": "90",
        "c": "0",
        "code": "33.06.02.10"
    },
    {
        "id": 1179,
        "label": "Fasciotomia total por retracção da aponevrose palmar",
        "k": "120",
        "c": "0",
        "code": "33.06.02.11"
    },
    {
        "id": 1180,
        "label": "Fasciotomia total com enxerto cutâneo por retracção da aponevrose palmar",
        "k": "160",
        "c": "0",
        "code": "33.06.02.12"
    },
    {
        "id": 1181,
        "label": "Correcção da deformidade em botoeira ou em colo de cisne",
        "k": "80",
        "c": "0",
        "code": "33.06.02.13"
    },
    {
        "id": 1182,
        "label": "Libertação da aderência dos tendões flexores dos dedos (Howard)",
        "k": "100",
        "c": "0",
        "code": "33.06.02.14"
    },
    {
        "id": 1183,
        "label": "Libertação da aderência dos tendões extensores dos dedos (Howard)",
        "k": "80",
        "c": "0",
        "code": "33.06.02.15"
    },
    {
        "id": 1184,
        "label": "Sutura de ligamento metacarpofalângico ou interfalângico",
        "k": "40",
        "c": "0",
        "code": "33.06.02.16"
    },
    {
        "id": 1185,
        "label": "Ligamentoplastia metacarpofalângica ou interfalângica",
        "k": "80",
        "c": "0",
        "code": "33.06.02.17"
    },
    {
        "id": 1186,
        "label": "Correcção da paralisia dos músculos intrinsecos por lesão do nervo cubital",
        "k": "120",
        "c": "0",
        "code": "33.06.02.18"
    },
    {
        "id": 1187,
        "label": "Correcção da paralisia dos músculos intrinsecos por lesão do nervo mediano",
        "k": "160",
        "c": "0",
        "code": "33.06.02.19"
    },
    {
        "id": 1188,
        "label": "Correcção cirúrgica do síndrome do canal cárpico ou do de Guyon (Ver Cód.45.09.00.05)",
        "k": "0",
        "c": "0",
        "code": "33.06.02.20"
    },
    {
        "id": 1189,
        "label": "Correcção cirúrgica de sindactilia (uma) sem enxerto",
        "k": "75",
        "c": "0",
        "code": "33.06.02.21"
    },
    {
        "id": 1190,
        "label": "Idem, cada comissura a mais, sem enxerto",
        "k": "30",
        "c": "0",
        "code": "33.06.02.22"
    },
    {
        "id": 1191,
        "label": "Idem, com enxerto",
        "k": "100",
        "c": "0",
        "code": "33.06.02.23"
    },
    {
        "id": 1192,
        "label": "Idem, com enxerto por cada uma a mais",
        "k": "50",
        "c": "0",
        "code": "33.06.02.24"
    },
    {
        "id": 1193,
        "label": "Correcção da sindactilia com sinfalangismo",
        "k": "120",
        "c": "0",
        "code": "33.06.02.25"
    },
    {
        "id": 1194,
        "label": "Mão bota radial (partes moles)",
        "k": "75",
        "c": "0",
        "code": "33.06.02.26"
    },
    {
        "id": 1195,
        "label": "Mão bota radial (com centralização do cúbito)",
        "k": "150",
        "c": "0",
        "code": "33.06.02.27"
    },
    {
        "id": 1196,
        "label": "Correcção de polidactilia",
        "k": "75",
        "c": "0",
        "code": "33.06.02.28"
    },
    {
        "id": 1197,
        "label": "Correcção de clinodactilia",
        "k": "90",
        "c": "0",
        "code": "33.06.02.29"
    },
    {
        "id": 1198,
        "label": "Correcção de malformações congénitas do polegar",
        "k": "120",
        "c": "0",
        "code": "33.06.02.30"
    },
    {
        "id": 1199,
        "label": "Tenoplastia por enxerto ou prótese de tendão da mão (um)",
        "k": "140",
        "c": "0",
        "code": "33.06.02.31"
    },
    {
        "id": 1200,
        "label": "Idem, dois",
        "k": "170",
        "c": "0",
        "code": "33.06.02.32"
    },
    {
        "id": 1201,
        "label": "Idem, três ou mais",
        "k": "200",
        "c": "0",
        "code": "33.06.02.33"
    },
    {
        "id": 1202,
        "label": "Reconstrução osteoplástica dos dedos (Cada tempo)",
        "k": "75",
        "c": "0",
        "code": "33.06.02.34"
    },
    {
        "id": 1203,
        "label": "Reconstrução dos dedos por transferência",
        "k": "250",
        "c": "0",
        "code": "33.06.02.35"
    },
    {
        "id": 1204,
        "label": "Sutura ou tenólise dos tendões, extensores dos dedos da mão 1 tendão",
        "k": "40",
        "c": "0",
        "code": "33.06.02.36"
    },
    {
        "id": 1205,
        "label": "Sutura ou tenólise dos tendões extensores dos dedos da mão: mais de um tendão",
        "k": "80",
        "c": "0",
        "code": "33.06.02.37"
    },
    {
        "id": 1206,
        "label": "Sutura tenólise dos tendões flexores dos dedos da mão 1 tendão",
        "k": "70",
        "c": "0",
        "code": "33.06.02.38"
    },
    {
        "id": 1207,
        "label": "Tenoplastia por enxerto de tendão da mão 1",
        "k": "120",
        "c": "0",
        "code": "33.06.02.39"
    },
    {
        "id": 1208,
        "label": "Tenoplastia por enxerto de tendão da mão 2",
        "k": "140",
        "c": "0",
        "code": "33.06.02.40"
    },
    {
        "id": 1209,
        "label": "Tenoplastia por enxerto de tendão da mão 3 ou mais",
        "k": "160",
        "c": "0",
        "code": "33.06.02.41"
    },
    {
        "id": 1210,
        "label": "Fasciotomia por retracção da aponevrose palmar",
        "k": "40",
        "c": "0",
        "code": "33.06.02.42"
    },
    {
        "id": 1211,
        "label": "Fasciectomia regional por retracção da aponevrose palmar",
        "k": "80",
        "c": "0",
        "code": "33.06.02.43"
    },
    {
        "id": 1212,
        "label": "Fasciectomia total por retracção da aponevrose palmar",
        "k": "120",
        "c": "0",
        "code": "33.06.02.44"
    },
    {
        "id": 1213,
        "label": "Fasciectomia parcial com enxerto cutâneo por retracção da aponevrose palmar",
        "k": "100",
        "c": "0",
        "code": "33.06.02.45"
    },
    {
        "id": 1214,
        "label": "Fasciectomia total com enxerto cutâneo por retracção da aponevrose palmar",
        "k": "160",
        "c": "0",
        "code": "33.06.02.46"
    },
    {
        "id": 1215,
        "label": "Correcção de sequelas reumatismais da mão (artroplastia) por cada articulação",
        "k": "90",
        "c": "0",
        "code": "33.06.02.47"
    },
    {
        "id": 1216,
        "label": "Artroplastia por cada articulação",
        "k": "70",
        "c": "0",
        "code": "33.06.02.48"
    },
    {
        "id": 1217,
        "label": "Correcção da sindroma do canal cárpico e outras sindromes compressivos do membro superior",
        "k": "80",
        "c": "0",
        "code": "33.06.02.49"
    },
    {
        "id": 1218,
        "label": "Correcção de sindactília sem sinfalangismo",
        "k": "100",
        "c": "0",
        "code": "33.06.02.50"
    },
    {
        "id": 1219,
        "label": "Exploração nervosa cirúrgica",
        "k": "70",
        "c": "0",
        "code": "33.06.02.51"
    },
    {
        "id": 1220,
        "label": "Neurorrafia sem microcirurgia",
        "k": "100",
        "c": "0",
        "code": "33.06.02.52"
    },
    {
        "id": 1221,
        "label": "Enxerto nervoso",
        "k": "200",
        "c": "0",
        "code": "33.06.02.53"
    },
    {
        "id": 1222,
        "label": "Transposição nervosa",
        "k": "160",
        "c": "0",
        "code": "33.06.02.54"
    },
    {
        "id": 1223,
        "label": "Fractura do ílion, púbis ou ísquion",
        "k": "60",
        "c": "0",
        "code": "33.07.00.01"
    },
    {
        "id": 1224,
        "label": "Idem, com desvios ou luxações",
        "k": "80",
        "c": "0",
        "code": "33.07.00.02"
    },
    {
        "id": 1225,
        "label": "Luxação congénita da anca (LCA)",
        "k": "90",
        "c": "0",
        "code": "33.07.00.03"
    },
    {
        "id": 1226,
        "label": "Fractura-luxação coxofemoral",
        "k": "100",
        "c": "0",
        "code": "33.07.00.04"
    },
    {
        "id": 1227,
        "label": "Fractura da cavidade cotiloideia",
        "k": "80",
        "c": "0",
        "code": "33.07.00.05"
    },
    {
        "id": 1228,
        "label": "Luxação traumática da anca",
        "k": "90",
        "c": "0",
        "code": "33.07.00.06"
    },
    {
        "id": 1229,
        "label": "Fractura do colo do fémur e fractura trocantérica",
        "k": "90",
        "c": "0",
        "code": "33.07.00.07"
    },
    {
        "id": 1230,
        "label": "Redução cirúrgica da luxação traumática da anca",
        "k": "120",
        "c": "0",
        "code": "33.07.01.01"
    },
    {
        "id": 1231,
        "label": "Osteossíntese do rebordo posterior do acetábulo",
        "k": "170",
        "c": "0",
        "code": "33.07.01.02"
    },
    {
        "id": 1232,
        "label": "Osteossíntese das colunas acetabulares",
        "k": "200",
        "c": "0",
        "code": "33.07.01.03"
    },
    {
        "id": 1233,
        "label": "Osteossíntese da sínfise púbica",
        "k": "120",
        "c": "0",
        "code": "33.07.01.04"
    },
    {
        "id": 1234,
        "label": "Osteossíntese sacro-íliaca",
        "k": "150",
        "c": "0",
        "code": "33.07.01.05"
    },
    {
        "id": 1235,
        "label": "Fractura-luxação Malgaigne",
        "k": "200",
        "c": "0",
        "code": "33.07.01.06"
    },
    {
        "id": 1236,
        "label": "Osteossíntese da fractura do colo ou trocantérica",
        "k": "140",
        "c": "0",
        "code": "33.07.01.07"
    },
    {
        "id": 1237,
        "label": "Tratamento de osteomielite",
        "k": "120",
        "c": "0",
        "code": "33.07.01.08"
    },
    {
        "id": 1238,
        "label": "\"Biópsia a \"\"céu aberto\"\" ou ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)\"",
        "k": "90",
        "c": "0",
        "code": "33.07.01.09"
    },
    {
        "id": 1239,
        "label": "Ressecção de tumores osteoperiósticos extensos",
        "k": "200",
        "c": "0",
        "code": "33.07.01.10"
    },
    {
        "id": 1240,
        "label": "Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo",
        "k": "300",
        "c": "0",
        "code": "33.07.01.11"
    },
    {
        "id": 1241,
        "label": "Amputação interílio-abdominal",
        "k": "300",
        "c": "0",
        "code": "33.07.01.12"
    },
    {
        "id": 1242,
        "label": "Desarticulação coxofemoral",
        "k": "180",
        "c": "0",
        "code": "33.07.01.13"
    },
    {
        "id": 1243,
        "label": "Ressecção da extremidade superior do fémur (Girdlestone)",
        "k": "150",
        "c": "0",
        "code": "33.07.01.14"
    },
    {
        "id": 1244,
        "label": "Osteotomia com osteossíntese, do colo do fémur",
        "k": "160",
        "c": "0",
        "code": "33.07.01.15"
    },
    {
        "id": 1245,
        "label": "Idem, trocantérica ou subtrocantérica, na criança",
        "k": "160",
        "c": "0",
        "code": "33.07.01.16"
    },
    {
        "id": 1246,
        "label": "Idem, trocantérica ou subtroncatérica, no adulto",
        "k": "160",
        "c": "0",
        "code": "33.07.01.17"
    },
    {
        "id": 1247,
        "label": "Osteotomias tipo Salter, Chiari ou Pemberton",
        "k": "200",
        "c": "0",
        "code": "33.07.01.18"
    },
    {
        "id": 1248,
        "label": "Tectoplastia cotiloideia",
        "k": "180",
        "c": "0",
        "code": "33.07.01.19"
    },
    {
        "id": 1249,
        "label": "Redução cirúrgica de LCA com duas ou mais osteotomias",
        "k": "220",
        "c": "0",
        "code": "33.07.01.20"
    },
    {
        "id": 1250,
        "label": "Transposição do grande trocânter",
        "k": "110",
        "c": "0",
        "code": "33.07.01.21"
    },
    {
        "id": 1251,
        "label": "Queilectomia",
        "k": "120",
        "c": "0",
        "code": "33.07.01.22"
    },
    {
        "id": 1252,
        "label": "Artroplastia parcial (Moore, Tompson)",
        "k": "180",
        "c": "0",
        "code": "33.07.01.23"
    },
    {
        "id": 1253,
        "label": "Artroplastia total em coxartrose ou revisão de hemiartroplastia",
        "k": "220",
        "c": "0",
        "code": "33.07.01.24"
    },
    {
        "id": 1254,
        "label": "Artroplastia total em revisão de prótese total, de artrodese, de LCA ou após Girdlestone",
        "k": "260",
        "c": "0",
        "code": "33.07.01.25"
    },
    {
        "id": 1255,
        "label": "Artrodese sacro-ilíaca (Unilateral)",
        "k": "120",
        "c": "0",
        "code": "33.07.01.26"
    },
    {
        "id": 1256,
        "label": "Artrodese da anca sem osteossíntese",
        "k": "180",
        "c": "0",
        "code": "33.07.01.27"
    },
    {
        "id": 1257,
        "label": "Idem, com osteossíntese",
        "k": "200",
        "c": "0",
        "code": "33.07.01.28"
    },
    {
        "id": 1258,
        "label": "Fixação in situ de epifisiolise",
        "k": "140",
        "c": "0",
        "code": "33.07.01.29"
    },
    {
        "id": 1259,
        "label": "Tratamento de epifísiolise com osteotomia e osteossíntese",
        "k": "180",
        "c": "0",
        "code": "33.07.01.30"
    },
    {
        "id": 1260,
        "label": "Artrotomia simples",
        "k": "70",
        "c": "0",
        "code": "33.07.01.31"
    },
    {
        "id": 1261,
        "label": "Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas",
        "k": "140",
        "c": "0",
        "code": "33.07.01.32"
    },
    {
        "id": 1262,
        "label": "Sinovectomia",
        "k": "140",
        "c": "0",
        "code": "33.07.01.33"
    },
    {
        "id": 1263,
        "label": "Tenotomia dos adutores com ou sem neurectomia",
        "k": "75",
        "c": "0",
        "code": "33.07.02.01"
    },
    {
        "id": 1264,
        "label": "Transposição dos adutores",
        "k": "120",
        "c": "0",
        "code": "33.07.02.02"
    },
    {
        "id": 1265,
        "label": "Tenotomia dos adutores com neurectomia intrapélvica",
        "k": "100",
        "c": "0",
        "code": "33.07.02.03"
    },
    {
        "id": 1266,
        "label": "Tenotomia ou alongamento dos flexores",
        "k": "90",
        "c": "0",
        "code": "33.07.02.04"
    },
    {
        "id": 1267,
        "label": "Tenotomia dos rotatores",
        "k": "90",
        "c": "0",
        "code": "33.07.02.05"
    },
    {
        "id": 1268,
        "label": "Plastia músculo-aponevrótica por paralisia dos glúteos em 1 ou vários tempos",
        "k": "150",
        "c": "0",
        "code": "33.07.02.06"
    },
    {
        "id": 1269,
        "label": "Transposição dos glúteos em 1 ou vários tempos",
        "k": "150",
        "c": "0",
        "code": "33.07.02.07"
    },
    {
        "id": 1270,
        "label": "Transposição do psoas-iliaco",
        "k": "160",
        "c": "0",
        "code": "33.07.02.08"
    },
    {
        "id": 1271,
        "label": "Ressecção da bolsa subglútea incluindo trocânter",
        "k": "75",
        "c": "0",
        "code": "33.07.02.09"
    },
    {
        "id": 1272,
        "label": "Tratamento da anca de ressalto",
        "k": "100",
        "c": "0",
        "code": "33.07.02.10"
    },
    {
        "id": 1273,
        "label": "Tratamento da pubalgia",
        "k": "100",
        "c": "0",
        "code": "33.07.02.11"
    },
    {
        "id": 1274,
        "label": "Fractura da diáfise do fémur",
        "k": "90",
        "c": "0",
        "code": "33.08.00.01"
    },
    {
        "id": 1275,
        "label": "Fractura supracondiliana ou intercondiliana",
        "k": "100",
        "c": "0",
        "code": "33.08.00.02"
    },
    {
        "id": 1276,
        "label": "Fractura ou luxação da rótula",
        "k": "40",
        "c": "0",
        "code": "33.08.00.03"
    },
    {
        "id": 1277,
        "label": "Fractura-luxação do joelho",
        "k": "100",
        "c": "0",
        "code": "33.08.00.04"
    },
    {
        "id": 1278,
        "label": "Fractura da extremidade proximal da tíbia ou dos planaltos tibiais",
        "k": "70",
        "c": "0",
        "code": "33.08.00.05"
    },
    {
        "id": 1279,
        "label": "Lesão ligamentar",
        "k": "50",
        "c": "0",
        "code": "33.08.00.06"
    },
    {
        "id": 1280,
        "label": "Luxação femorotibial",
        "k": "50",
        "c": "0",
        "code": "33.08.00.07"
    },
    {
        "id": 1281,
        "label": "\"Osteossíntese diafisária a \"\"céu aberto\"\"\"",
        "k": "140",
        "c": "0",
        "code": "33.08.01.01"
    },
    {
        "id": 1282,
        "label": "\"Osteossíntese diafisária a \"\"céu fechado\"\"\"",
        "k": "140",
        "c": "0",
        "code": "33.08.01.02"
    },
    {
        "id": 1283,
        "label": "Osteotaxia da fractura do fémur",
        "k": "140",
        "c": "0",
        "code": "33.08.01.03"
    },
    {
        "id": 1284,
        "label": "Osteossíntese da fractura supracondiliana",
        "k": "140",
        "c": "0",
        "code": "33.08.01.04"
    },
    {
        "id": 1285,
        "label": "Osteossíntese da fractura supra e intercondiliana",
        "k": "150",
        "c": "0",
        "code": "33.08.01.05"
    },
    {
        "id": 1286,
        "label": "Osteossíntese da fractura unicondiliana",
        "k": "110",
        "c": "0",
        "code": "33.08.01.06"
    },
    {
        "id": 1287,
        "label": "Fractura da rótula (osteossíntese ou patelectomia)",
        "k": "75",
        "c": "0",
        "code": "33.08.01.07"
    },
    {
        "id": 1288,
        "label": "Fractura da espinha da tíbia",
        "k": "110",
        "c": "0",
        "code": "33.08.01.08"
    },
    {
        "id": 1289,
        "label": "Fractura de um planalto tibial",
        "k": "110",
        "c": "0",
        "code": "33.08.01.09"
    },
    {
        "id": 1290,
        "label": "Osteossíntese da fractura bituberositária ou da fractura cominutiva da extremidade proximal",
        "k": "130",
        "c": "0",
        "code": "33.08.01.10"
    },
    {
        "id": 1291,
        "label": "Osteossíntese das fracturas osteocondrais",
        "k": "110",
        "c": "0",
        "code": "33.08.01.11"
    },
    {
        "id": 1292,
        "label": "Luxação do joelho : Ver Cód. 33.08.02 e 33.08.03",
        "k": "0",
        "c": "0",
        "code": "33.08.01.12"
    },
    {
        "id": 1293,
        "label": "Osteomielite",
        "k": "120",
        "c": "0",
        "code": "33.08.01.13"
    },
    {
        "id": 1294,
        "label": "Pseudartrose do fémur",
        "k": "160",
        "c": "0",
        "code": "33.08.01.14"
    },
    {
        "id": 1295,
        "label": "Artrite séptica",
        "k": "70",
        "c": "0",
        "code": "33.08.01.15"
    },
    {
        "id": 1368,
        "label": "Amputação pela perna",
        "k": "130",
        "c": "0",
        "code": "33.09.01.19"
    },
    {
        "id": 1296,
        "label": "Ressecção de pequenos tumores benignos (exostoses, 1 ou 2)",
        "k": "90",
        "c": "0",
        "code": "33.08.01.16"
    },
    {
        "id": 1297,
        "label": "Ressecção de tumores osteoperiósticos extensos",
        "k": "140",
        "c": "0",
        "code": "33.08.01.17"
    },
    {
        "id": 1298,
        "label": "Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo",
        "k": "300",
        "c": "0",
        "code": "33.08.01.18"
    },
    {
        "id": 1299,
        "label": "Idem, com reconstituição da continuidade óssea por artrodese",
        "k": "220",
        "c": "0",
        "code": "33.08.01.19"
    },
    {
        "id": 1300,
        "label": "Amputação pela coxa",
        "k": "130",
        "c": "0",
        "code": "33.08.01.20"
    },
    {
        "id": 1301,
        "label": "Amputação pelo joelho",
        "k": "130",
        "c": "0",
        "code": "33.08.01.21"
    },
    {
        "id": 1302,
        "label": "Osteotomia diafisária ou distal do fémur",
        "k": "140",
        "c": "0",
        "code": "33.08.01.22"
    },
    {
        "id": 1303,
        "label": "Osteotomia proximal da tíbia",
        "k": "100",
        "c": "0",
        "code": "33.08.01.23"
    },
    {
        "id": 1304,
        "label": "Osteotomia da tíbia e peróneo",
        "k": "110",
        "c": "0",
        "code": "33.08.01.24"
    },
    {
        "id": 1305,
        "label": "Epifisiodese (cada osso)",
        "k": "60",
        "c": "0",
        "code": "33.08.01.25"
    },
    {
        "id": 1306,
        "label": "Reconstrução focal da superfície articular com enxerto osteocartilagíneo",
        "k": "120",
        "c": "0",
        "code": "33.08.01.26"
    },
    {
        "id": 1307,
        "label": "Artroplastia total por artrose ou revisão de prótese unicompartimental",
        "k": "220",
        "c": "0",
        "code": "33.08.01.27"
    },
    {
        "id": 1308,
        "label": "Artroplastia total por revisão de prótese total",
        "k": "300",
        "c": "0",
        "code": "33.08.01.28"
    },
    {
        "id": 1309,
        "label": "Artroplastia unicompartimental femorotibial",
        "k": "160",
        "c": "0",
        "code": "33.08.01.29"
    },
    {
        "id": 1310,
        "label": "Artroplastia femoropatelar",
        "k": "100",
        "c": "0",
        "code": "33.08.01.30"
    },
    {
        "id": 1311,
        "label": "Artrodese do joelho",
        "k": "160",
        "c": "0",
        "code": "33.08.01.31"
    },
    {
        "id": 1312,
        "label": "Meniscectomia convencional ou artroscópica",
        "k": "90",
        "c": "0",
        "code": "33.08.01.32"
    },
    {
        "id": 1313,
        "label": "Reinserção meniscal convencional ou artroscópica",
        "k": "120",
        "c": "0",
        "code": "33.08.01.33"
    },
    {
        "id": 1314,
        "label": "Um dos ligamentos cruzados",
        "k": "120",
        "c": "0",
        "code": "33.08.02.01"
    },
    {
        "id": 1315,
        "label": "Um dos ligamentos periféricos",
        "k": "100",
        "c": "0",
        "code": "33.08.02.02"
    },
    {
        "id": 1316,
        "label": "\"Reparação das lesões da \"\"tríada\"\"\"",
        "k": "200",
        "c": "0",
        "code": "33.08.02.03"
    },
    {
        "id": 1317,
        "label": "\"Reparação das lesões da \"\"pêntada\"\"\"",
        "k": "240",
        "c": "0",
        "code": "33.08.02.04"
    },
    {
        "id": 1318,
        "label": "Ligamento cruzado (cada)",
        "k": "150",
        "c": "0",
        "code": "33.08.03.01"
    },
    {
        "id": 1319,
        "label": "Ligamento periférico (cada)",
        "k": "120",
        "c": "0",
        "code": "33.08.03.02"
    },
    {
        "id": 1320,
        "label": "Extrarticulares ou de compensação (acto cirúrgico isolado)",
        "k": "100",
        "c": "0",
        "code": "33.08.03.03"
    },
    {
        "id": 1321,
        "label": "Extrarticulares ou de compensação (acto cirúrgico associado)",
        "k": "75",
        "c": "0",
        "code": "33.08.03.04"
    },
    {
        "id": 1322,
        "label": "Quadriciplastia",
        "k": "150",
        "c": "0",
        "code": "33.08.04.01"
    },
    {
        "id": 1323,
        "label": "Cirurgia pararotuliana convencional ou artroscópica (suturas, plicaduras, secções)",
        "k": "90",
        "c": "0",
        "code": "33.08.04.02"
    },
    {
        "id": 1324,
        "label": "Luxação recidivante da rótula",
        "k": "150",
        "c": "0",
        "code": "33.08.04.03"
    },
    {
        "id": 1325,
        "label": "Luxação congénita da rótula",
        "k": "150",
        "c": "0",
        "code": "33.08.04.04"
    },
    {
        "id": 1326,
        "label": "Tendinite rotuliana",
        "k": "90",
        "c": "0",
        "code": "33.08.04.05"
    },
    {
        "id": 1327,
        "label": "Rotura do tendão quadricipital, rotuliano, ou fractura-avulsão tuberositária",
        "k": "90",
        "c": "0",
        "code": "33.08.04.06"
    },
    {
        "id": 1328,
        "label": "Alongamento ou encurtamento do aparelho extensor a qualquer nível",
        "k": "130",
        "c": "0",
        "code": "33.08.04.07"
    },
    {
        "id": 1329,
        "label": "Artrolise simples convencional ou artroscópica",
        "k": "110",
        "c": "0",
        "code": "33.08.04.08"
    },
    {
        "id": 1330,
        "label": "Artrotomia simples e artroscopia diagnóstica",
        "k": "60",
        "c": "0",
        "code": "33.08.04.09"
    },
    {
        "id": 1331,
        "label": "Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas",
        "k": "130",
        "c": "0",
        "code": "33.08.04.10"
    },
    {
        "id": 1332,
        "label": "Sinovectomia",
        "k": "130",
        "c": "0",
        "code": "33.08.04.11"
    },
    {
        "id": 1333,
        "label": "Operações sobre os tendões (Eggers)",
        "k": "110",
        "c": "0",
        "code": "33.08.05.01"
    },
    {
        "id": 1334,
        "label": "Transferência dos isquiotibiais para a rótula",
        "k": "130",
        "c": "0",
        "code": "33.08.05.02"
    },
    {
        "id": 1335,
        "label": "Outras transferências",
        "k": "120",
        "c": "0",
        "code": "33.08.05.03"
    },
    {
        "id": 1336,
        "label": "Intervenções múltiplas para correcção do flexo",
        "k": "130",
        "c": "0",
        "code": "33.08.05.04"
    },
    {
        "id": 1337,
        "label": "Fasciotomia (Yount)",
        "k": "80",
        "c": "0",
        "code": "33.08.05.05"
    },
    {
        "id": 1338,
        "label": "Bursite ou higroma rotuliano",
        "k": "50",
        "c": "0",
        "code": "33.08.05.06"
    },
    {
        "id": 1339,
        "label": "Quisto poplíteu, outros quistos e bursites",
        "k": "70",
        "c": "0",
        "code": "33.08.05.07"
    },
    {
        "id": 1340,
        "label": "Fractura da diáfise da tíbia e peróneo",
        "k": "75",
        "c": "0",
        "code": "33.09.00.01"
    },
    {
        "id": 1341,
        "label": "Fractura da diáfise da tíbia",
        "k": "60",
        "c": "0",
        "code": "33.09.00.02"
    },
    {
        "id": 1342,
        "label": "Fractura da diáfise do peróneo",
        "k": "30",
        "c": "0",
        "code": "33.09.00.03"
    },
    {
        "id": 1343,
        "label": "Fractura da extremidade distal da tíbia",
        "k": "60",
        "c": "0",
        "code": "33.09.00.04"
    },
    {
        "id": 1344,
        "label": "Fractura-luxação do tornozelo",
        "k": "90",
        "c": "0",
        "code": "33.09.00.05"
    },
    {
        "id": 1345,
        "label": "Fractura monomaleolar",
        "k": "40",
        "c": "0",
        "code": "33.09.00.06"
    },
    {
        "id": 1346,
        "label": "Fractura bimaleolar",
        "k": "60",
        "c": "0",
        "code": "33.09.00.07"
    },
    {
        "id": 1347,
        "label": "Fractura trimaleolar",
        "k": "80",
        "c": "0",
        "code": "33.09.00.08"
    },
    {
        "id": 1348,
        "label": "Luxação do tornozelo",
        "k": "40",
        "c": "0",
        "code": "33.09.00.09"
    },
    {
        "id": 1349,
        "label": "Entorse ou rotura ligamentar externa do tornozelo",
        "k": "30",
        "c": "0",
        "code": "33.09.00.10"
    },
    {
        "id": 1350,
        "label": "\"Osteossíntese da fractura diafisária da tíbia a \"\"céu aberto\"\"\"",
        "k": "110",
        "c": "0",
        "code": "33.09.01.01"
    },
    {
        "id": 1351,
        "label": "\"Osteossíntese da fractura diafisária da tíbia a \"\"céu fechado\"\"\"",
        "k": "120",
        "c": "0",
        "code": "33.09.01.02"
    },
    {
        "id": 1352,
        "label": "Osteossíntese da tíbia e peróneo",
        "k": "120",
        "c": "0",
        "code": "33.09.01.03"
    },
    {
        "id": 1353,
        "label": "Osteotaxia da fractura da tíbia",
        "k": "110",
        "c": "0",
        "code": "33.09.01.04"
    },
    {
        "id": 1354,
        "label": "Tratamento da pseudoartrose da diáfise da tíbia após fractura (com ou sem enxerto ósseo)",
        "k": "160",
        "c": "0",
        "code": "33.09.01.05"
    },
    {
        "id": 1355,
        "label": "Tratamento da pseudoartrose congénita da tíbia",
        "k": "220",
        "c": "0",
        "code": "33.09.01.06"
    },
    {
        "id": 1356,
        "label": "Osteossíntese da diáfise do peróneo",
        "k": "80",
        "c": "0",
        "code": "33.09.01.07"
    },
    {
        "id": 1357,
        "label": "Luxação tibiotársica",
        "k": "110",
        "c": "0",
        "code": "33.09.01.08"
    },
    {
        "id": 1358,
        "label": "Osteossíntese de um ou dois maléolos ou equivalentes ligamentares",
        "k": "110",
        "c": "0",
        "code": "33.09.01.09"
    },
    {
        "id": 1359,
        "label": "Osteossíntese trimaleolar ou equivalentes ligamentares",
        "k": "120",
        "c": "0",
        "code": "33.09.01.10"
    },
    {
        "id": 1360,
        "label": "Osteossíntese da fractura cominutiva do pilão tibial",
        "k": "140",
        "c": "0",
        "code": "33.09.01.11"
    },
    {
        "id": 1361,
        "label": "Correcção da consolidação viciosa da fractura de um maleolo",
        "k": "120",
        "c": "0",
        "code": "33.09.01.12"
    },
    {
        "id": 1362,
        "label": "Correcção da consolidação viciosa das fracturas bi ou trimaleolares",
        "k": "150",
        "c": "0",
        "code": "33.09.01.13"
    },
    {
        "id": 1363,
        "label": "Osteomielite (tratamento em um tempo)",
        "k": "110",
        "c": "0",
        "code": "33.09.01.14"
    },
    {
        "id": 1364,
        "label": "Osteomielite (tratamento em dois ou mais tempos)",
        "k": "200",
        "c": "0",
        "code": "33.09.01.15"
    },
    {
        "id": 1365,
        "label": "Ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)",
        "k": "110",
        "c": "0",
        "code": "33.09.01.16"
    },
    {
        "id": 1366,
        "label": "Ressecção de tumores osteoperiósticos extensos",
        "k": "120",
        "c": "0",
        "code": "33.09.01.17"
    },
    {
        "id": 1367,
        "label": "Ressecção óssea segmentar de tumores invasivos com reconstrução por prótese ou enxerto",
        "k": "280",
        "c": "0",
        "code": "33.09.01.18"
    },
    {
        "id": 1369,
        "label": "Osteotomia diafisária da tíbia sem osteossíntese",
        "k": "110",
        "c": "0",
        "code": "33.09.01.20"
    },
    {
        "id": 1370,
        "label": "Osteotomia diafisária da tíbia com osteossíntese",
        "k": "130",
        "c": "0",
        "code": "33.09.01.21"
    },
    {
        "id": 1371,
        "label": "Osteotomia diafisária do peróneo (isolada, não adjuvante de osteotomia da tíbia)",
        "k": "90",
        "c": "0",
        "code": "33.09.01.22"
    },
    {
        "id": 1372,
        "label": "Ressecção da cabeça do peróneo",
        "k": "75",
        "c": "0",
        "code": "33.09.01.23"
    },
    {
        "id": 1373,
        "label": "Osteotomia da extremidade distal da tíbia e peróneo",
        "k": "130",
        "c": "0",
        "code": "33.09.01.24"
    },
    {
        "id": 1374,
        "label": "Artroplastia total do tornozelo",
        "k": "160",
        "c": "0",
        "code": "33.09.01.25"
    },
    {
        "id": 1375,
        "label": "Artrodese do tornozelo",
        "k": "140",
        "c": "0",
        "code": "33.09.01.26"
    },
    {
        "id": 1376,
        "label": "Artrotomia simples e artroscopia diagnóstica",
        "k": "50",
        "c": "0",
        "code": "33.09.01.27"
    },
    {
        "id": 1377,
        "label": "Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas",
        "k": "110",
        "c": "0",
        "code": "33.09.01.28"
    },
    {
        "id": 1378,
        "label": "Artrotomia por osteotomia maleolar com tratamento de lesões articulares",
        "k": "110",
        "c": "0",
        "code": "33.09.01.29"
    },
    {
        "id": 1379,
        "label": "Sinovectomia total",
        "k": "110",
        "c": "0",
        "code": "33.09.01.30"
    },
    {
        "id": 1380,
        "label": "Tenotomia subcutânea do tendão de Aquiles",
        "k": "30",
        "c": "0",
        "code": "33.09.02.01"
    },
    {
        "id": 1381,
        "label": "Alongamento a “céu aberto” do tendão de Aquiles ou tratamento da tendinite",
        "k": "90",
        "c": "0",
        "code": "33.09.02.02"
    },
    {
        "id": 1382,
        "label": "Reparação da rotura do tendão de Aquiles",
        "k": "90",
        "c": "0",
        "code": "33.09.02.03"
    },
    {
        "id": 1383,
        "label": "Reparação da rotura de outros tendões na região",
        "k": "60",
        "c": "0",
        "code": "33.09.02.04"
    },
    {
        "id": 1384,
        "label": "Tratamento do síndrome do canal társico e das neuropatias estenosantes dos ramos do nervo tibial posterior",
        "k": "110",
        "c": "0",
        "code": "33.09.02.05"
    },
    {
        "id": 1385,
        "label": "Tratamento da luxação dos peroniais",
        "k": "110",
        "c": "0",
        "code": "33.09.02.06"
    },
    {
        "id": 1386,
        "label": "Reparação de instabilidade ligamentar crónica do tornozelo",
        "k": "120",
        "c": "0",
        "code": "33.09.02.07"
    },
    {
        "id": 1387,
        "label": "Transposição tendinosa para a insuficiência tricipital",
        "k": "130",
        "c": "0",
        "code": "33.09.02.08"
    },
    {
        "id": 1388,
        "label": "Fractura do astrágalo",
        "k": "70",
        "c": "0",
        "code": "33.10.00.01"
    },
    {
        "id": 1389,
        "label": "Fractura-luxação do astrágalo",
        "k": "90",
        "c": "0",
        "code": "33.10.00.02"
    },
    {
        "id": 1390,
        "label": "Fractura do calcâneo",
        "k": "60",
        "c": "0",
        "code": "33.10.00.03"
    },
    {
        "id": 1391,
        "label": "Fractura de outros ossos do tarso",
        "k": "40",
        "c": "0",
        "code": "33.10.00.04"
    },
    {
        "id": 1392,
        "label": "Fractura de um metatarso",
        "k": "30",
        "c": "0",
        "code": "33.10.00.05"
    },
    {
        "id": 1393,
        "label": "Fractura de mais que um metatarso",
        "k": "40",
        "c": "0",
        "code": "33.10.00.06"
    },
    {
        "id": 1394,
        "label": "Fractura de um ou mais dedos",
        "k": "20",
        "c": "0",
        "code": "33.10.00.07"
    },
    {
        "id": 1395,
        "label": "Luxação mediotársica ou tarsometatársica",
        "k": "40",
        "c": "0",
        "code": "33.10.00.08"
    },
    {
        "id": 1396,
        "label": "Luxação de dedos (cada)",
        "k": "10",
        "c": "0",
        "code": "33.10.00.09"
    },
    {
        "id": 1397,
        "label": "Osteossíntese da fractura ou fractura luxação do astrágalo",
        "k": "110",
        "c": "0",
        "code": "33.10.01.01"
    },
    {
        "id": 1398,
        "label": "Osteossíntese da fractura do calcâneo",
        "k": "110",
        "c": "0",
        "code": "33.10.01.02"
    },
    {
        "id": 1399,
        "label": "Fractura do tarso",
        "k": "80",
        "c": "0",
        "code": "33.10.01.03"
    },
    {
        "id": 1400,
        "label": "Osteossíntese de um ou dois metatarsianos",
        "k": "50",
        "c": "0",
        "code": "33.10.01.04"
    },
    {
        "id": 1401,
        "label": "Osteossíntese de mais de dois metatarsianos",
        "k": "70",
        "c": "0",
        "code": "33.10.01.05"
    },
    {
        "id": 1402,
        "label": "Osteossíntese de uma ou duas falanges de dedos",
        "k": "40",
        "c": "0",
        "code": "33.10.01.06"
    },
    {
        "id": 1403,
        "label": "Osteossíntese de mais de duas falanges",
        "k": "60",
        "c": "0",
        "code": "33.10.01.07"
    },
    {
        "id": 1404,
        "label": "Fractura-luxação tarsometatársica",
        "k": "110",
        "c": "0",
        "code": "33.10.01.08"
    },
    {
        "id": 1405,
        "label": "Luxação tarsometatársica",
        "k": "90",
        "c": "0",
        "code": "33.10.01.09"
    },
    {
        "id": 1406,
        "label": "Luxação de dedo (cada)",
        "k": "40",
        "c": "0",
        "code": "33.10.01.10"
    },
    {
        "id": 1407,
        "label": "Tratamento de osteomielite no retropé",
        "k": "100",
        "c": "0",
        "code": "33.10.01.11"
    },
    {
        "id": 1408,
        "label": "Tratamento de osteomielite no mediopé ou antepé",
        "k": "80",
        "c": "0",
        "code": "33.10.01.12"
    },
    {
        "id": 1409,
        "label": "Ressecção de pequenas lesões ou tumores ósseos circunscritos com preenchimento ósseo",
        "k": "80",
        "c": "0",
        "code": "33.10.01.13"
    },
    {
        "id": 1410,
        "label": "Amputação de Syme",
        "k": "120",
        "c": "0",
        "code": "33.10.01.14"
    },
    {
        "id": 1411,
        "label": "Amputação transmetatarsiana",
        "k": "90",
        "c": "0",
        "code": "33.10.01.15"
    },
    {
        "id": 1412,
        "label": "Amputação do 1o. Raio (metatarsiano+hallux)",
        "k": "90",
        "c": "0",
        "code": "33.10.01.16"
    },
    {
        "id": 1413,
        "label": "Amputação de raio do 2o. Ao 5o. (metatarsiano+dedo)",
        "k": "70",
        "c": "0",
        "code": "33.10.01.17"
    },
    {
        "id": 1414,
        "label": "Amputação de dedo",
        "k": "50",
        "c": "0",
        "code": "33.10.01.18"
    },
    {
        "id": 1415,
        "label": "Ressecção do astrágalo",
        "k": "120",
        "c": "0",
        "code": "33.10.01.19"
    },
    {
        "id": 1416,
        "label": "Ressecção de um ou mais ossos do tarso",
        "k": "110",
        "c": "0",
        "code": "33.10.01.20"
    },
    {
        "id": 1417,
        "label": "Ressecção de um metatarsiano",
        "k": "70",
        "c": "0",
        "code": "33.10.01.21"
    },
    {
        "id": 1418,
        "label": "Dois ou mais metatarsianos",
        "k": "100",
        "c": "0",
        "code": "33.10.01.22"
    },
    {
        "id": 1419,
        "label": "Ressecção de exostose ou ossículo supranumerário no retro ou mediopé",
        "k": "60",
        "c": "0",
        "code": "33.10.01.23"
    },
    {
        "id": 1420,
        "label": "Ressecção artroplástica de uma metatarsofalângica, excepto a 1a. Ou de uma ou duas interfalângicas",
        "k": "60",
        "c": "0",
        "code": "33.10.01.24"
    },
    {
        "id": 1421,
        "label": "Ressecção artroplástica de duas metatarsifalângicas, excepto a 1a. Ou de várias interfalângicas",
        "k": "60",
        "c": "0",
        "code": "33.10.01.25"
    },
    {
        "id": 1422,
        "label": "Ressecção artroplástica múltipla para realinhamento metatarsofalângico",
        "k": "110",
        "c": "0",
        "code": "33.10.01.26"
    },
    {
        "id": 1423,
        "label": "Osteotomia do calcâneo",
        "k": "100",
        "c": "0",
        "code": "33.10.01.27"
    },
    {
        "id": 1424,
        "label": "Osteotomia mediotársica",
        "k": "120",
        "c": "0",
        "code": "33.10.01.28"
    },
    {
        "id": 1425,
        "label": "Artrodese subastragaliana (intra ou extrarticular)",
        "k": "120",
        "c": "0",
        "code": "33.10.01.29"
    },
    {
        "id": 1426,
        "label": "Triciple artrodese",
        "k": "130",
        "c": "0",
        "code": "33.10.01.30"
    },
    {
        "id": 1427,
        "label": "Artrodese mediotársica",
        "k": "120",
        "c": "0",
        "code": "33.10.01.31"
    },
    {
        "id": 1428,
        "label": "Artrodese tarsometatarsiana",
        "k": "120",
        "c": "0",
        "code": "33.10.01.32"
    },
    {
        "id": 1429,
        "label": "Artrorrisis subastragaliana no pé plano infantil (via interna e externa)",
        "k": "120",
        "c": "0",
        "code": "33.10.01.33"
    },
    {
        "id": 1430,
        "label": "\"Artrorrisis subastragaliana no pé plano infantil por \"\"calcâneo stop\"\" bilateral\"",
        "k": "120",
        "c": "0",
        "code": "33.10.01.34"
    },
    {
        "id": 1431,
        "label": "Alongamento de um metatarsiano",
        "k": "120",
        "c": "0",
        "code": "33.10.01.35"
    },
    {
        "id": 1432,
        "label": "Alongamento de dois ou mais metatarsianos",
        "k": "140",
        "c": "0",
        "code": "33.10.01.36"
    },
    {
        "id": 1433,
        "label": "Artrotomia",
        "k": "30",
        "c": "0",
        "code": "33.10.01.37"
    },
    {
        "id": 1434,
        "label": "Idem, com sinovectomia",
        "k": "40",
        "c": "0",
        "code": "33.10.01.38"
    },
    {
        "id": 1435,
        "label": "Ressecção simples de exostose no 1o.metatarsiano",
        "k": "60",
        "c": "0",
        "code": "33.10.02.01"
    },
    {
        "id": 1436,
        "label": "Ressecção simples de exostose no 5o.metatarsiano",
        "k": "50",
        "c": "0",
        "code": "33.10.02.02"
    },
    {
        "id": 1437,
        "label": "Artroplastia de ressecção metatarsofalângica (tipo Op. de Keller)",
        "k": "100",
        "c": "0",
        "code": "33.10.02.03"
    },
    {
        "id": 1438,
        "label": "Realinhamento da 1o. metatarso falângica (tipo Op. de Silver)",
        "k": "100",
        "c": "0",
        "code": "33.10.02.04"
    },
    {
        "id": 1439,
        "label": "Osteotomia da base do 1o. metatarsiano ou artrodese cuneometatarsiana",
        "k": "80",
        "c": "0",
        "code": "33.10.02.05"
    },
    {
        "id": 1507,
        "label": "Ressecção submucosa do septo",
        "k": "80",
        "c": "0",
        "code": "34.00.00.22"
    },
    {
        "id": 1440,
        "label": "Osteotomia diafisária do 1o. metatarsiano (tipo Qp. Wilson ou de Helal)",
        "k": "80",
        "c": "0",
        "code": "33.10.02.06"
    },
    {
        "id": 1441,
        "label": "\"Osteotomia distal do 1o. Matatarsiano (tipo Op. de Mitchell ou de \"\"chevron\"\")\"",
        "k": "110",
        "c": "0",
        "code": "33.10.02.07"
    },
    {
        "id": 1442,
        "label": "Transposição do tendão conjunto (tipo Op. de McBride)",
        "k": "100",
        "c": "0",
        "code": "33.10.02.08"
    },
    {
        "id": 1443,
        "label": "Artroplastia de interposição da 1a. metatarsofalângica",
        "k": "120",
        "c": "0",
        "code": "33.10.02.09"
    },
    {
        "id": 1444,
        "label": "Artrodese metatarsofalângica do 1o.raio",
        "k": "60",
        "c": "0",
        "code": "33.10.02.10"
    },
    {
        "id": 1445,
        "label": "Osteotomia de um ou de dois metatarsianos, excepto o 1o.",
        "k": "60",
        "c": "0",
        "code": "33.10.02.11"
    },
    {
        "id": 1446,
        "label": "Osteotomia de três ou de mais metatarsianos, excepto o 1o.",
        "k": "80",
        "c": "0",
        "code": "33.10.02.12"
    },
    {
        "id": 1447,
        "label": "Uma ou duas artroplastias de interposição protésica metarsofalângica, excepto no 1o. raio, ou interfalângicas",
        "k": "100",
        "c": "0",
        "code": "33.10.02.13"
    },
    {
        "id": 1448,
        "label": "Três ou mais artroplastias de interposição protésica metarsofalângica, excepto no 1o. raio, ou interfalângicas",
        "k": "120",
        "c": "0",
        "code": "33.10.02.14"
    },
    {
        "id": 1449,
        "label": "Uma ou duas artroplastias de ressecção ou artrodeses interfalângicas, excepto no 1o. raio",
        "k": "50",
        "c": "0",
        "code": "33.10.02.15"
    },
    {
        "id": 1450,
        "label": "Três ou mais artroplastias de ressecção ou artrodeses interfalângicas, excepto no 1o. raio",
        "k": "70",
        "c": "0",
        "code": "33.10.02.16"
    },
    {
        "id": 1451,
        "label": "Osteotomia cuneiforme ou de encurtamento da 1a. falange no hallux",
        "k": "40",
        "c": "0",
        "code": "33.10.02.17"
    },
    {
        "id": 1452,
        "label": "Artrodese ou tenodese interfalângica no hallux",
        "k": "40",
        "c": "0",
        "code": "33.10.02.18"
    },
    {
        "id": 1453,
        "label": "Tratamento do 5o. dedo aduto",
        "k": "70",
        "c": "0",
        "code": "33.10.02.19"
    },
    {
        "id": 1454,
        "label": "Transferência do tendão do tibial posterior",
        "k": "130",
        "c": "0",
        "code": "33.10.03.01"
    },
    {
        "id": 1455,
        "label": "Transferência de tendão do tibial anterior, peroniais ou do longo extensor comum",
        "k": "110",
        "c": "0",
        "code": "33.10.03.02"
    },
    {
        "id": 1456,
        "label": "Transferência do longo extensor ao colo do 1o. metatarsiano (Op. de Jones)",
        "k": "100",
        "c": "0",
        "code": "33.10.03.03"
    },
    {
        "id": 1457,
        "label": "Transferência do extensor comum ao colo dos metatarsianos",
        "k": "140",
        "c": "0",
        "code": "33.10.03.04"
    },
    {
        "id": 1458,
        "label": "Tenodeses e outras transferências de tendão da perna ou pé",
        "k": "100",
        "c": "0",
        "code": "33.10.03.05"
    },
    {
        "id": 1459,
        "label": "Tratamento de doença de Morton",
        "k": "110",
        "c": "0",
        "code": "33.10.03.06"
    },
    {
        "id": 1460,
        "label": "Secção superficial da fáscia plantar",
        "k": "40",
        "c": "0",
        "code": "33.10.03.07"
    },
    {
        "id": 1461,
        "label": "Secção profunda das estruturas plantares (Op. de Steindler)",
        "k": "90",
        "c": "0",
        "code": "33.10.03.08"
    },
    {
        "id": 1462,
        "label": "Tenotomia dum tendão do pé ou dedo",
        "k": "30",
        "c": "0",
        "code": "33.10.03.09"
    },
    {
        "id": 1463,
        "label": "Idem, de vários dedos",
        "k": "40",
        "c": "0",
        "code": "33.10.03.10"
    },
    {
        "id": 1464,
        "label": "Tenoplastias com enxerto-1 tendão",
        "k": "110",
        "c": "0",
        "code": "33.10.03.11"
    },
    {
        "id": 1465,
        "label": "Idem, 2 tendões",
        "k": "130",
        "c": "0",
        "code": "33.10.03.12"
    },
    {
        "id": 1466,
        "label": "Idem, 3 ou mais tendões",
        "k": "150",
        "c": "0",
        "code": "33.10.03.13"
    },
    {
        "id": 1467,
        "label": "Tratamento do pé boto",
        "k": "180",
        "c": "0",
        "code": "33.10.04.01"
    },
    {
        "id": 1468,
        "label": "Tratamento do astrágalo vertical congénito",
        "k": "180",
        "c": "0",
        "code": "33.10.04.02"
    },
    {
        "id": 1469,
        "label": "Tratamento do antepé aduto (metarsus varus)",
        "k": "130",
        "c": "0",
        "code": "33.10.04.03"
    },
    {
        "id": 1470,
        "label": "Tratamento de defeitos congénitos no antepé e dedos",
        "k": "90",
        "c": "0",
        "code": "33.10.04.04"
    },
    {
        "id": 1471,
        "label": "Tratamento do pé plano valgo",
        "k": "180",
        "c": "0",
        "code": "33.10.04.05"
    },
    {
        "id": 1472,
        "label": "Colheita de enxerto cortico-esponjoso, como adjuvante de uma cirurgia",
        "k": "30",
        "c": "0",
        "code": "33.11.00.01"
    },
    {
        "id": 1473,
        "label": "Tratamento de quisto, ou outros defeitos ósseos circunscritos, por esvaziamento e preenchimento enxerto ósseo, no ombro e anca",
        "k": "140",
        "c": "0",
        "code": "33.11.00.02"
    },
    {
        "id": 1474,
        "label": "Tratamento de quisto, ou outros defeitos ósseos circunscritos, por esvaziamento e preenchimento enxerto ósseo, na zona média dos membros",
        "k": "120",
        "c": "0",
        "code": "33.11.00.03"
    },
    {
        "id": 1475,
        "label": "Tratamento de quisto, ou outros defeitos ósseos circunscritos, por esvaziamento e preenchimento enxerto ósseo, na mão e no pé",
        "k": "90",
        "c": "0",
        "code": "33.11.00.04"
    },
    {
        "id": 1476,
        "label": "Transposição óssea",
        "k": "180",
        "c": "0",
        "code": "33.11.00.06"
    },
    {
        "id": 1477,
        "label": "Trepanação óssea",
        "k": "70",
        "c": "0",
        "code": "33.11.00.07"
    },
    {
        "id": 1478,
        "label": "",
        "k": "0",
        "c": "0",
        "code": "33.11.01.  "
    },
    {
        "id": 1479,
        "label": "Por via percutânea (extracção de material de osteossíntese ou de tracção esquelética)",
        "k": "30",
        "c": "0",
        "code": "33.11.01.01"
    },
    {
        "id": 1480,
        "label": "Por abordagem do plano ósseo: 40% do valor que lhe corresponde na osteossíntese simples (sem colocação de enxerto)",
        "k": "0",
        "c": "0",
        "code": "33.11.01.02"
    },
    {
        "id": 1481,
        "label": "Redução e fixação percutânea de fracturas, luxações ou fracturas luxações em casos não considerados especificamente: acresce em 50% o valor estipulado no tratamento incruento.",
        "k": "0",
        "c": "0",
        "code": "33.11.01.05"
    },
    {
        "id": 1482,
        "label": "Alongamento ósseo com fixador externo (Illizarov, Wagner, etc.) (tratamento total)",
        "k": "250",
        "c": "0",
        "code": "33.11.02.01"
    },
    {
        "id": 1483,
        "label": "Fasciotomias por síndrome de compartimento",
        "k": "90",
        "c": "0",
        "code": "33.11.03.01"
    },
    {
        "id": 1484,
        "label": "Excisão de tumores benignos",
        "k": "75",
        "c": "0",
        "code": "33.11.03.02"
    },
    {
        "id": 1485,
        "label": "Excisão de tumores malignos de tecidos moles",
        "k": "180",
        "c": "0",
        "code": "33.11.03.03"
    },
    {
        "id": 1486,
        "label": "Tamponamento nasal anterior",
        "k": "12",
        "c": "0",
        "code": "34.00.00.01"
    },
    {
        "id": 1487,
        "label": "Idem, posterior",
        "k": "27",
        "c": "0",
        "code": "34.00.00.02"
    },
    {
        "id": 1488,
        "label": "Cauterização da mancha vascular",
        "k": "8",
        "c": "0",
        "code": "34.00.00.03"
    },
    {
        "id": 1489,
        "label": "Extracção de corpos estranhos das fossas nasais com anestesia local",
        "k": "12",
        "c": "0",
        "code": "34.00.00.04"
    },
    {
        "id": 1490,
        "label": "Idem, com anestesia geral",
        "k": "32",
        "c": "0",
        "code": "34.00.00.05"
    },
    {
        "id": 1491,
        "label": "Electrocoagulação dos cornetos unilateral",
        "k": "18",
        "c": "0",
        "code": "34.00.00.06"
    },
    {
        "id": 1492,
        "label": "Turbinectomia unilateral",
        "k": "30",
        "c": "0",
        "code": "34.00.00.07"
    },
    {
        "id": 1493,
        "label": "Exérese de papiloma do vestíbulo nasal",
        "k": "15",
        "c": "0",
        "code": "34.00.00.08"
    },
    {
        "id": 1494,
        "label": "Idem, de pólipo sangrante do septo",
        "k": "37",
        "c": "0",
        "code": "34.00.00.09"
    },
    {
        "id": 1495,
        "label": "Polipectomia nasal unilateral",
        "k": "37",
        "c": "0",
        "code": "34.00.00.10"
    },
    {
        "id": 1496,
        "label": "Idem, bilateral",
        "k": "57",
        "c": "0",
        "code": "34.00.00.11"
    },
    {
        "id": 1497,
        "label": "Polipectomia nasal com etmoidectomia unilateral",
        "k": "90",
        "c": "0",
        "code": "34.00.00.12"
    },
    {
        "id": 1498,
        "label": "Idem, bilateral",
        "k": "120",
        "c": "0",
        "code": "34.00.00.13"
    },
    {
        "id": 1499,
        "label": "Polipectomia com Caldwell-Luc unilateral",
        "k": "100",
        "c": "0",
        "code": "34.00.00.14"
    },
    {
        "id": 1500,
        "label": "Idem, bilateral",
        "k": "130",
        "c": "0",
        "code": "34.00.00.15"
    },
    {
        "id": 1501,
        "label": "Caldwell-Luc unilateral",
        "k": "80",
        "c": "0",
        "code": "34.00.00.16"
    },
    {
        "id": 1502,
        "label": "Idem, bilateral",
        "k": "120",
        "c": "0",
        "code": "34.00.00.17"
    },
    {
        "id": 1503,
        "label": "Caldwell-Luc com etmoidectomìa unilateral",
        "k": "110",
        "c": "0",
        "code": "34.00.00.18"
    },
    {
        "id": 1504,
        "label": "Idem, bilateral",
        "k": "160",
        "c": "0",
        "code": "34.00.00.19"
    },
    {
        "id": 1505,
        "label": "Operação de Ermiro de Lima",
        "k": "145",
        "c": "0",
        "code": "34.00.00.20"
    },
    {
        "id": 1506,
        "label": "Cirurgia do nervo vidiano",
        "k": "145",
        "c": "0",
        "code": "34.00.00.21"
    },
    {
        "id": 1508,
        "label": "Septoplastia (operação isolada)",
        "k": "120",
        "c": "0",
        "code": "34.00.00.23"
    },
    {
        "id": 1509,
        "label": "Microcirurgia endonasal e /ou endoscópica unilateral",
        "k": "130",
        "c": "0",
        "code": "34.00.00.24"
    },
    {
        "id": 1510,
        "label": "Idem, bilateral",
        "k": "200",
        "c": "0",
        "code": "34.00.00.25"
    },
    {
        "id": 1511,
        "label": "Abordagem da hipófise, via transeptal",
        "k": "300",
        "c": "0",
        "code": "34.00.00.26"
    },
    {
        "id": 1512,
        "label": "Rino-septoplastia",
        "k": "200",
        "c": "0",
        "code": "34.00.00.27"
    },
    {
        "id": 1513,
        "label": "Tratamento cirúrgico da ozena",
        "k": "80",
        "c": "0",
        "code": "34.00.00.28"
    },
    {
        "id": 1514,
        "label": "Etmoidectomia externa por via paralateronasal",
        "k": "125",
        "c": "0",
        "code": "34.00.00.29"
    },
    {
        "id": 1515,
        "label": "Etmoidectomia total, via combinada",
        "k": "260",
        "c": "0",
        "code": "34.00.00.30"
    },
    {
        "id": 1516,
        "label": "Exérese de quisto naso-vestibular",
        "k": "40",
        "c": "0",
        "code": "34.00.00.31"
    },
    {
        "id": 1517,
        "label": "Correcção da sinéquia nasal",
        "k": "12",
        "c": "0",
        "code": "34.00.00.32"
    },
    {
        "id": 1518,
        "label": "Operação osteoplástica da sinusite frontal",
        "k": "180",
        "c": "0",
        "code": "34.00.00.33"
    },
    {
        "id": 1519,
        "label": "Maxilectomia sem exenteração da órbita",
        "k": "180",
        "c": "0",
        "code": "34.00.00.34"
    },
    {
        "id": 1520,
        "label": "Idem, com exenteração",
        "k": "250",
        "c": "0",
        "code": "34.00.00.35"
    },
    {
        "id": 1521,
        "label": "Ressecção de angiofibroma naso-faringeo",
        "k": "220",
        "c": "0",
        "code": "34.00.00.36"
    },
    {
        "id": 1522,
        "label": "Rinectomia parcial",
        "k": "75",
        "c": "0",
        "code": "34.00.00.37"
    },
    {
        "id": 1523,
        "label": "Idem, total",
        "k": "120",
        "c": "0",
        "code": "34.00.00.38"
    },
    {
        "id": 1524,
        "label": "Operação de rinofima",
        "k": "80",
        "c": "0",
        "code": "34.00.00.39"
    },
    {
        "id": 1525,
        "label": "Abordagem cirúrgica do seio esfenoidal",
        "k": "120",
        "c": "0",
        "code": "34.00.00.40"
    },
    {
        "id": 1526,
        "label": "Tratamento cirúrgico de imperfuração choanal via endonasal",
        "k": "65",
        "c": "0",
        "code": "34.00.00.41"
    },
    {
        "id": 1527,
        "label": "Idem, outras vias",
        "k": "160",
        "c": "0",
        "code": "34.00.00.42"
    },
    {
        "id": 1528,
        "label": "Drenagem de hematoma do septo nasal",
        "k": "15",
        "c": "0",
        "code": "34.00.00.43"
    },
    {
        "id": 1529,
        "label": "Punção do seio maxilar",
        "k": "12",
        "c": "0",
        "code": "34.00.00.44"
    },
    {
        "id": 1530,
        "label": "Idem, bilateral",
        "k": "18",
        "c": "0",
        "code": "34.00.00.45"
    },
    {
        "id": 1531,
        "label": "Punção do seio maxilar com implantação de tubo de drenagem",
        "k": "18",
        "c": "0",
        "code": "34.00.00.46"
    },
    {
        "id": 1532,
        "label": "Idem, bilateral",
        "k": "25",
        "c": "0",
        "code": "34.00.00.47"
    },
    {
        "id": 1533,
        "label": "Drenagem do seio frontal",
        "k": "65",
        "c": "0",
        "code": "34.00.00.48"
    },
    {
        "id": 1534,
        "label": "Laringectomia total simples",
        "k": "270",
        "c": "0",
        "code": "34.01.00.01"
    },
    {
        "id": 1535,
        "label": "Laringectomia supra glótica com esvaziamento",
        "k": "300",
        "c": "0",
        "code": "34.01.00.02"
    },
    {
        "id": 1536,
        "label": "Hemilaringectomia",
        "k": "280",
        "c": "0",
        "code": "34.01.00.03"
    },
    {
        "id": 1537,
        "label": "Laringofissura com cordectomia",
        "k": "155",
        "c": "0",
        "code": "34.01.00.04"
    },
    {
        "id": 1538,
        "label": "Aritenoidopexia",
        "k": "155",
        "c": "0",
        "code": "34.01.00.05"
    },
    {
        "id": 1539,
        "label": "Aritenoidectomia+ Cordopexia",
        "k": "155",
        "c": "0",
        "code": "34.01.00.06"
    },
    {
        "id": 1540,
        "label": "Tratamento de estenose laringo-traqueal (1o. Tempo)",
        "k": "240",
        "c": "0",
        "code": "34.01.00.07"
    },
    {
        "id": 1541,
        "label": "Tempos seguintes",
        "k": "135",
        "c": "0",
        "code": "34.01.00.08"
    },
    {
        "id": 1542,
        "label": "Laringectomia (total ou parcíal) com esvaziamento unilateral",
        "k": "320",
        "c": "0",
        "code": "34.01.00.09"
    },
    {
        "id": 1543,
        "label": "Idem, com esvaziamento bilateral",
        "k": "365",
        "c": "0",
        "code": "34.01.00.10"
    },
    {
        "id": 1544,
        "label": "Faringo-laringectomia com esvaziamento sem reconstrução",
        "k": "365",
        "c": "0",
        "code": "34.01.00.11"
    },
    {
        "id": 1545,
        "label": "Idem, com reconstrução",
        "k": "465",
        "c": "0",
        "code": "34.01.00.12"
    },
    {
        "id": 1546,
        "label": "Microcirurgia laríngea",
        "k": "135",
        "c": "0",
        "code": "34.01.00.13"
    },
    {
        "id": 1547,
        "label": "Microcirurgia laríngea com laser",
        "k": "160",
        "c": "100",
        "code": "34.01.00.14"
    },
    {
        "id": 1548,
        "label": "Tratamento cirúrgico das malformações congénitas da laringe (bridas, quistos, palmuras)",
        "k": "100",
        "c": "0",
        "code": "34.01.00.15"
    },
    {
        "id": 1549,
        "label": "Traqueotomia (operação isolada)",
        "k": "85",
        "c": "0",
        "code": "34.02.00.01"
    },
    {
        "id": 1550,
        "label": "Cricotiroidotomia (operação isolada)",
        "k": "70",
        "c": "0",
        "code": "34.02.00.02"
    },
    {
        "id": 1551,
        "label": "Encerramento simples de traqueotomia ou fístula traqueal",
        "k": "100",
        "c": "0",
        "code": "34.02.00.03"
    },
    {
        "id": 1552,
        "label": "Fístula fonatória",
        "k": "110",
        "c": "0",
        "code": "34.02.00.04"
    },
    {
        "id": 1553,
        "label": "Traqueoplastia por estenose traqueal",
        "k": "250",
        "c": "0",
        "code": "34.02.00.05"
    },
    {
        "id": 1554,
        "label": "Broncoplastia",
        "k": "250",
        "c": "0",
        "code": "34.02.00.06"
    },
    {
        "id": 1555,
        "label": "Broncotomia",
        "k": "200",
        "c": "0",
        "code": "34.02.00.07"
    },
    {
        "id": 1556,
        "label": "Anastomose traqueo-brônquica ou bronco-brônquica",
        "k": "400",
        "c": "0",
        "code": "34.02.00.08"
    },
    {
        "id": 1557,
        "label": "Sutura de ferida brônquica",
        "k": "200",
        "c": "0",
        "code": "34.02.00.09"
    },
    {
        "id": 1558,
        "label": "Fístula traqueo-ou bronco-esofágica, tratamento cirúrgico",
        "k": "270",
        "c": "0",
        "code": "34.02.00.10"
    },
    {
        "id": 1559,
        "label": "Remoção de corpos estranhos por via endoscópica",
        "k": "60",
        "c": "0",
        "code": "34.02.00.11"
    },
    {
        "id": 1560,
        "label": "Drenagem pleural",
        "k": "20",
        "c": "0",
        "code": "34.03.00.01"
    },
    {
        "id": 1561,
        "label": "Drenagem pleural por empiema com ressecção costal",
        "k": "60",
        "c": "0",
        "code": "34.03.00.02"
    },
    {
        "id": 1562,
        "label": "Toracotomia exploradora",
        "k": "120",
        "c": "0",
        "code": "34.03.00.03"
    },
    {
        "id": 1563,
        "label": "Toracotomia por ferida aberta do tórax",
        "k": "135",
        "c": "0",
        "code": "34.03.00.04"
    },
    {
        "id": 1564,
        "label": "Toracotomia por pneumotórax espontâneo",
        "k": "135",
        "c": "0",
        "code": "34.03.00.05"
    },
    {
        "id": 1565,
        "label": "Toracotomia por hemorragia traumática ou perda de tecido pulmonar",
        "k": "135",
        "c": "0",
        "code": "34.03.00.06"
    },
    {
        "id": 1566,
        "label": "Pneumectomia",
        "k": "300",
        "c": "0",
        "code": "34.03.00.07"
    },
    {
        "id": 1567,
        "label": "Pneumectomia com esvaziamento ganglionar mediastinico",
        "k": "370",
        "c": "0",
        "code": "34.03.00.08"
    },
    {
        "id": 1568,
        "label": "Lobectomia",
        "k": "300",
        "c": "0",
        "code": "34.03.00.09"
    },
    {
        "id": 1569,
        "label": "Bilobectomia",
        "k": "300",
        "c": "0",
        "code": "34.03.00.10"
    },
    {
        "id": 1570,
        "label": "Segmentectomia ou ressecção em cunha, única ou múltipla",
        "k": "180",
        "c": "0",
        "code": "34.03.00.11"
    },
    {
        "id": 1571,
        "label": "Ressecção pulmonar com ressecção de parede torácica",
        "k": "350",
        "c": "0",
        "code": "34.03.00.12"
    },
    {
        "id": 1572,
        "label": "Toracoplastia (primeiro tempo)",
        "k": "150",
        "c": "0",
        "code": "34.03.00.13"
    },
    {
        "id": 1573,
        "label": "Toracoplastia (tempo complementar)",
        "k": "150",
        "c": "0",
        "code": "34.03.00.14"
    },
    {
        "id": 1574,
        "label": "Exérese de tumor da pleura",
        "k": "150",
        "c": "0",
        "code": "34.03.00.15"
    },
    {
        "id": 1575,
        "label": "Descorticação pulmonar",
        "k": "250",
        "c": "0",
        "code": "34.03.00.16"
    },
    {
        "id": 1576,
        "label": "Pleurectomia parietal",
        "k": "175",
        "c": "0",
        "code": "34.03.00.17"
    },
    {
        "id": 1577,
        "label": "Toracoplastia de indicação pleural (num só tempo)",
        "k": "200",
        "c": "0",
        "code": "34.03.00.18"
    },
    {
        "id": 1578,
        "label": "Encerramento do canal arterial",
        "k": "175",
        "c": "0",
        "code": "35.00.00.01"
    },
    {
        "id": 1579,
        "label": "“Banding” da artéria pulmonar",
        "k": "200",
        "c": "0",
        "code": "35.00.00.02"
    },
    {
        "id": 1580,
        "label": "Operação de Blalock e outros shunts sistémico-pulmonares",
        "k": "200",
        "c": "0",
        "code": "35.00.00.03"
    },
    {
        "id": 1581,
        "label": "Focalização de MAPCAS",
        "k": "250",
        "c": "0",
        "code": "35.00.00.04"
    },
    {
        "id": 1582,
        "label": "Correcção de anel vascular",
        "k": "200",
        "c": "0",
        "code": "35.00.00.05"
    },
    {
        "id": 1583,
        "label": "Shunt cavo-pulmonar",
        "k": "250",
        "c": "0",
        "code": "35.00.00.06"
    },
    {
        "id": 1584,
        "label": "Operação de Blalock-Hanlon",
        "k": "300",
        "c": "0",
        "code": "35.00.00.07"
    },
    {
        "id": 1585,
        "label": "Correcção de coartação da aorta torácica",
        "k": "250",
        "c": "0",
        "code": "35.00.00.08"
    },
    {
        "id": 1586,
        "label": "Correcção de interrupção do arco aórtico",
        "k": "300",
        "c": "0",
        "code": "35.00.00.09"
    },
    {
        "id": 1587,
        "label": "Reparação de aneurisma/rotura traumática da aorta torácica",
        "k": "400",
        "c": "0",
        "code": "35.00.00.10"
    },
    {
        "id": 1588,
        "label": "Valvulotomia aórtica",
        "k": "300",
        "c": "0",
        "code": "35.00.00.11"
    },
    {
        "id": 1589,
        "label": "Pericardiotomia - via subxifoideia",
        "k": "50",
        "c": "0",
        "code": "35.00.00.12"
    },
    {
        "id": 1590,
        "label": "Construção de janela pleuropericárdica",
        "k": "150",
        "c": "0",
        "code": "35.00.00.13"
    },
    {
        "id": 1591,
        "label": "Pericardiectomia",
        "k": "370",
        "c": "0",
        "code": "35.00.00.14"
    },
    {
        "id": 1592,
        "label": "Valvulotomia mitral",
        "k": "355",
        "c": "0",
        "code": "35.00.00.15"
    },
    {
        "id": 1593,
        "label": "Sutura de feridas cardíacas",
        "k": "325",
        "c": "0",
        "code": "35.00.00.16"
    },
    {
        "id": 1594,
        "label": "Cirurgia de implantação epicárdica de sistemas de pacemaker/disfibrilhação automática",
        "k": "200",
        "c": "0",
        "code": "35.00.00.17"
    },
    {
        "id": 1595,
        "label": "Bypass coronário com veia safena e/ou 1 anastomose arterial",
        "k": "500",
        "c": "0",
        "code": "35.00.00.18"
    },
    {
        "id": 1596,
        "label": "Bypass coronário com 2 ou mais anastomoses arteriais",
        "k": "525",
        "c": "0",
        "code": "35.00.00.19"
    },
    {
        "id": 1597,
        "label": "Bypass coronário com 3 ou mais anastomoses arteriais",
        "k": "550",
        "c": "0",
        "code": "35.00.00.20"
    },
    {
        "id": 1598,
        "label": "Ressecção de aneurisma do VE com ou sem bypass coronário",
        "k": "600",
        "c": "0",
        "code": "35.00.00.21"
    },
    {
        "id": 1599,
        "label": "rotura do septo IV ou parede livre após enfarte",
        "k": "650",
        "c": "0",
        "code": "35.00.00.22"
    },
    {
        "id": 1600,
        "label": "Substituição de uma válvula",
        "k": "450",
        "c": "0",
        "code": "35.00.00.23"
    },
    {
        "id": 1601,
        "label": "Substituição de duas válvulas",
        "k": "500",
        "c": "0",
        "code": "35.00.00.24"
    },
    {
        "id": 1602,
        "label": "Substituição de três válvulas",
        "k": "550",
        "c": "0",
        "code": "35.00.00.25"
    },
    {
        "id": 1603,
        "label": "Plastia de 1 válvula",
        "k": "500",
        "c": "0",
        "code": "35.00.00.26"
    },
    {
        "id": 1604,
        "label": "Plastia de 2 ou mais válvulas",
        "k": "550",
        "c": "0",
        "code": "35.00.00.27"
    },
    {
        "id": 1605,
        "label": "Operação de Ross",
        "k": "700",
        "c": "0",
        "code": "35.00.00.28"
    },
    {
        "id": 1606,
        "label": "Excisão de tumores de coração",
        "k": "500",
        "c": "0",
        "code": "35.00.00.29"
    },
    {
        "id": 1607,
        "label": "Encerramento de comunicação inter auricular",
        "k": "250",
        "c": "0",
        "code": "35.00.00.30"
    },
    {
        "id": 1608,
        "label": "Encerramento de comunicação interventricular",
        "k": "450",
        "c": "0",
        "code": "35.00.00.31"
    },
    {
        "id": 1609,
        "label": "Correcção de estenose da artéria pulmonar",
        "k": "350",
        "c": "0",
        "code": "35.00.00.32"
    },
    {
        "id": 1610,
        "label": "Correcção de canal AV parcial/Ostium Primum",
        "k": "500",
        "c": "0",
        "code": "35.00.00.33"
    },
    {
        "id": 1611,
        "label": "Correcção de canal AV completo",
        "k": "550",
        "c": "0",
        "code": "35.00.00.34"
    },
    {
        "id": 1612,
        "label": "Correcção de Tetralogia de Fallot simples",
        "k": "525",
        "c": "0",
        "code": "35.00.00.35"
    },
    {
        "id": 1613,
        "label": "Correcção de obstrução da câmara de saída VE",
        "k": "500",
        "c": "0",
        "code": "35.00.00.36"
    },
    {
        "id": 1614,
        "label": "Dissecção da aorta",
        "k": "625",
        "c": "0",
        "code": "35.00.00.37"
    },
    {
        "id": 1615,
        "label": "Substituição da aorta ascendente e válvula aórtica c/tubo valvulado ou homoenxerto (op. de Bentall)",
        "k": "700",
        "c": "0",
        "code": "35.00.00.38"
    },
    {
        "id": 1616,
        "label": "Cirurgia do arco aórtico",
        "k": "700",
        "c": "0",
        "code": "35.00.00.39"
    },
    {
        "id": 1617,
        "label": "Outras cirurgias para correcção total de cardiopatias congénitas complexas",
        "k": "700",
        "c": "0",
        "code": "35.00.00.40"
    },
    {
        "id": 1618,
        "label": "Troncos supra-aorticos (carótida e TABC)",
        "k": "150",
        "c": "0",
        "code": "35.01.00.01"
    },
    {
        "id": 1619,
        "label": "Artérias dos membros-incisão única",
        "k": "110",
        "c": "0",
        "code": "35.01.00.02"
    },
    {
        "id": 1620,
        "label": "Artérias dos membros-incisão múltipla",
        "k": "150",
        "c": "0",
        "code": "35.01.00.03"
    },
    {
        "id": 1621,
        "label": "Bifurcação aórtica",
        "k": "150",
        "c": "0",
        "code": "35.01.00.04"
    },
    {
        "id": 1622,
        "label": "Artérias viscerais",
        "k": "200",
        "c": "0",
        "code": "35.01.00.05"
    },
    {
        "id": 1623,
        "label": "Artéria carótida, via cervical",
        "k": "200",
        "c": "0",
        "code": "35.01.01.01"
    },
    {
        "id": 1624,
        "label": "Artéria carótida, via torácica",
        "k": "250",
        "c": "0",
        "code": "35.01.01.02"
    },
    {
        "id": 1625,
        "label": "Tronco arterial braquiocefálico",
        "k": "250",
        "c": "0",
        "code": "35.01.01.03"
    },
    {
        "id": 1626,
        "label": "Artérias subclavias, via cervical",
        "k": "150",
        "c": "0",
        "code": "35.01.01.04"
    },
    {
        "id": 1627,
        "label": "Artérias subclavias, via torácica ou combinada",
        "k": "230",
        "c": "0",
        "code": "35.01.01.05"
    },
    {
        "id": 1628,
        "label": "Artéria vertebral",
        "k": "160",
        "c": "0",
        "code": "35.01.01.06"
    },
    {
        "id": 1629,
        "label": "Artéria do membro superior",
        "k": "120",
        "c": "0",
        "code": "35.01.01.07"
    },
    {
        "id": 1630,
        "label": "Aorta abdominal",
        "k": "230",
        "c": "0",
        "code": "35.01.01.08"
    },
    {
        "id": 1631,
        "label": "Ramos viscerais da aorta",
        "k": "280",
        "c": "0",
        "code": "35.01.01.09"
    },
    {
        "id": 1632,
        "label": "Artérias ilíacas: unilateral sem desobstrução aórtica, via abdominal ou extraperitoneal",
        "k": "150",
        "c": "0",
        "code": "35.01.01.10"
    },
    {
        "id": 1633,
        "label": "Artérias ilíacas: unilateral sem desobstrução aórtica, via inguinal (anéis)",
        "k": "120",
        "c": "0",
        "code": "35.01.01.11"
    },
    {
        "id": 1634,
        "label": "Bilateral, em combinação com a aorta",
        "k": "280",
        "c": "0",
        "code": "35.01.01.12"
    },
    {
        "id": 1635,
        "label": "Bilateral, sem desobstrução aórtica, via abdominal",
        "k": "200",
        "c": "0",
        "code": "35.01.01.13"
    },
    {
        "id": 1636,
        "label": "Bilateral, sem desobstrução aórtica, via inguinal (aneis)",
        "k": "150",
        "c": "0",
        "code": "35.01.01.14"
    },
    {
        "id": 1637,
        "label": "Artéria femoral comum ou profunda",
        "k": "120",
        "c": "0",
        "code": "35.01.01.15"
    },
    {
        "id": 1638,
        "label": "Artérias femoral superficial ou poplitea ou tronco tibioperoneal segmentar",
        "k": "120",
        "c": "0",
        "code": "35.01.01.16"
    },
    {
        "id": 1639,
        "label": "Artérias femoral superficial ou poplitea ou tronco tibioperoneal, extensa(Edwards)",
        "k": "180",
        "c": "0",
        "code": "35.01.01.17"
    },
    {
        "id": 1640,
        "label": "Revascularização de artéria cerebral extra-craniana (via cervical)",
        "k": "230",
        "c": "0",
        "code": "35.01.02.01"
    },
    {
        "id": 1641,
        "label": "Idem, via torácica",
        "k": "250",
        "c": "0",
        "code": "35.01.02.02"
    },
    {
        "id": 1642,
        "label": "Subclavio-subclavia ou axilar",
        "k": "150",
        "c": "0",
        "code": "35.01.02.03"
    },
    {
        "id": 1643,
        "label": "Aorto-subclavia",
        "k": "300",
        "c": "0",
        "code": "35.01.02.04"
    },
    {
        "id": 1644,
        "label": "Revascularização múltipla de troncos supra-aorticos a partir da aorta",
        "k": "350",
        "c": "0",
        "code": "35.01.02.05"
    },
    {
        "id": 1645,
        "label": "Axilo-femoral unilateral",
        "k": "200",
        "c": "0",
        "code": "35.01.02.06"
    },
    {
        "id": 1646,
        "label": "Axilo-bifemoral",
        "k": "250",
        "c": "0",
        "code": "35.01.02.07"
    },
    {
        "id": 1647,
        "label": "Revascularização de um ramo visceral da aorta",
        "k": "350",
        "c": "0",
        "code": "35.01.02.08"
    },
    {
        "id": 1648,
        "label": "Revascularização múltipla de ramos viscerais da aorta",
        "k": "460",
        "c": "0",
        "code": "35.01.02.09"
    },
    {
        "id": 1649,
        "label": "Aorto-iliaco unilateral",
        "k": "200",
        "c": "0",
        "code": "35.01.02.10"
    },
    {
        "id": 1650,
        "label": "Aorto-iliaco bilateral",
        "k": "250",
        "c": "0",
        "code": "35.01.02.11"
    },
    {
        "id": 1651,
        "label": "Aorto-femoral ou aorto-popliteo unilateral",
        "k": "200",
        "c": "0",
        "code": "35.01.02.12"
    },
    {
        "id": 1652,
        "label": "Aorto-femoral ou aorto-popliteo bilateral",
        "k": "250",
        "c": "0",
        "code": "35.01.02.13"
    },
    {
        "id": 1653,
        "label": "Aorto-iliofemoral unilateral",
        "k": "220",
        "c": "0",
        "code": "35.01.02.14"
    },
    {
        "id": 1654,
        "label": "Aorto-iliofemoral bilateral",
        "k": "300",
        "c": "0",
        "code": "35.01.02.15"
    },
    {
        "id": 1655,
        "label": "Aorto-femoropopliteo unilateral",
        "k": "220",
        "c": "0",
        "code": "35.01.02.16"
    },
    {
        "id": 1656,
        "label": "Aorto-femoropopliteo bilateral",
        "k": "300",
        "c": "0",
        "code": "35.01.02.17"
    },
    {
        "id": 1657,
        "label": "Ilio- femoral via anatómica",
        "k": "200",
        "c": "0",
        "code": "35.01.02.18"
    },
    {
        "id": 1658,
        "label": "Ilio-femoral via extra anatómica",
        "k": "230",
        "c": "0",
        "code": "35.01.02.19"
    },
    {
        "id": 1659,
        "label": "Femoro-popliteo ou femoro- femoral unilateral",
        "k": "200",
        "c": "0",
        "code": "35.01.02.20"
    },
    {
        "id": 1660,
        "label": "Femoro- femoral cruzado",
        "k": "200",
        "c": "0",
        "code": "35.01.02.21"
    },
    {
        "id": 1661,
        "label": "Ilio-iliaco",
        "k": "200",
        "c": "0",
        "code": "35.01.02.22"
    },
    {
        "id": 1662,
        "label": "Femoro-distal",
        "k": "220",
        "c": "0",
        "code": "35.01.02.23"
    },
    {
        "id": 1663,
        "label": "Popliteo-distal",
        "k": "220",
        "c": "0",
        "code": "35.01.02.24"
    },
    {
        "id": 1664,
        "label": "Artérias dos membros superiores",
        "k": "160",
        "c": "0",
        "code": "35.01.02.25"
    },
    {
        "id": 1665,
        "label": "Artérias genitais",
        "k": "160",
        "c": "0",
        "code": "35.01.02.26"
    },
    {
        "id": 1666,
        "label": "Arco aortico, com protecção por C.E.C. ou pontes (incluindo toda a equipa médica)",
        "k": "800",
        "c": "0",
        "code": "35.01.03.01"
    },
    {
        "id": 1667,
        "label": "Aorta descendente torácica e/ou abdominal; incluindo ramos viscerais, sem C.E.C. (aorta toracoabdominal)",
        "k": "500",
        "c": "0",
        "code": "35.01.03.02"
    },
    {
        "id": 1668,
        "label": "Aorta descendente torácica e/ou abdominal; incluindo ramos viscerais, com C.E.C. (incluindo a equipa médica)",
        "k": "600",
        "c": "0",
        "code": "35.01.03.03"
    },
    {
        "id": 1669,
        "label": "Carótidas via cervical",
        "k": "250",
        "c": "0",
        "code": "35.01.03.04"
    },
    {
        "id": 1670,
        "label": "Carótidas via toracocervical",
        "k": "350",
        "c": "0",
        "code": "35.01.03.05"
    },
    {
        "id": 1671,
        "label": "Idem com C.E.C. ou ponte (incluindo toda a equipa médica)",
        "k": "800",
        "c": "0",
        "code": "35.01.03.06"
    },
    {
        "id": 1672,
        "label": "Tronco braquiocefálico",
        "k": "430",
        "c": "0",
        "code": "35.01.03.07"
    },
    {
        "id": 1673,
        "label": "Artérias subclavias, via cervical ou axilar",
        "k": "200",
        "c": "0",
        "code": "35.01.03.08"
    },
    {
        "id": 1674,
        "label": "Artérias subclavias, via toracocervical",
        "k": "300",
        "c": "0",
        "code": "35.01.03.09"
    },
    {
        "id": 1675,
        "label": "Artérias axilar e restantes do membro superior",
        "k": "180",
        "c": "0",
        "code": "35.01.03.10"
    },
    {
        "id": 1676,
        "label": "Aorta abdominal infra-renal",
        "k": "350",
        "c": "0",
        "code": "35.01.03.11"
    },
    {
        "id": 1677,
        "label": "Ramos viscerais da aorta",
        "k": "350",
        "c": "0",
        "code": "35.01.03.12"
    },
    {
        "id": 1678,
        "label": "Artérias ilíacas",
        "k": "250",
        "c": "0",
        "code": "35.01.03.13"
    },
    {
        "id": 1679,
        "label": "Artérias femorais ou popliteas",
        "k": "200",
        "c": "0",
        "code": "35.01.03.14"
    },
    {
        "id": 1680,
        "label": "Outras artérias dos membros",
        "k": "180",
        "c": "0",
        "code": "35.01.03.15"
    },
    {
        "id": 1681,
        "label": "Reparação das lesões da dissecção da aorta, tipo distal na porta de entrada",
        "k": "500",
        "c": "0",
        "code": "35.01.03.16"
    },
    {
        "id": 1682,
        "label": "Idem, nos ramos viscerais da aorta",
        "k": "400",
        "c": "0",
        "code": "35.01.03.17"
    },
    {
        "id": 1683,
        "label": "Idem, na circulação dos membros inferiores",
        "k": "300",
        "c": "0",
        "code": "35.01.03.18"
    },
    {
        "id": 1684,
        "label": "No pescoço",
        "k": "150",
        "c": "0",
        "code": "35.01.04.01"
    },
    {
        "id": 1685,
        "label": "No tórax com C.E.C. ou ponte",
        "k": "400",
        "c": "0",
        "code": "35.01.04.02"
    },
    {
        "id": 1686,
        "label": "No tórax sem C.E.C. ou ponte",
        "k": "250",
        "c": "0",
        "code": "35.01.04.03"
    },
    {
        "id": 1687,
        "label": "No abdómen, aorta acima de renais",
        "k": "250",
        "c": "0",
        "code": "35.01.04.04"
    },
    {
        "id": 1688,
        "label": "No abdómen, aorta abaixo de renais ou ilíacas",
        "k": "180",
        "c": "0",
        "code": "35.01.04.05"
    },
    {
        "id": 1689,
        "label": "Ramos viscerais da aorta",
        "k": "180",
        "c": "0",
        "code": "35.01.04.06"
    },
    {
        "id": 1690,
        "label": "Nos membros, simples",
        "k": "120",
        "c": "0",
        "code": "35.01.04.07"
    },
    {
        "id": 1691,
        "label": "Nos membros, quando combinada com sutura venosa",
        "k": "160",
        "c": "0",
        "code": "35.01.04.08"
    },
    {
        "id": 1692,
        "label": "Artérias carótidas, exploração simples",
        "k": "80",
        "c": "0",
        "code": "35.01.05.01"
    },
    {
        "id": 1693,
        "label": "Artérias carótidas, libertação e fixação para tratamento de angulações",
        "k": "130",
        "c": "0",
        "code": "35.01.05.02"
    },
    {
        "id": 1694,
        "label": "Artérias do tórax",
        "k": "150",
        "c": "0",
        "code": "35.01.05.03"
    },
    {
        "id": 1695,
        "label": "Artérias do abdómen e pelve",
        "k": "150",
        "c": "0",
        "code": "35.01.05.04"
    },
    {
        "id": 1696,
        "label": "Artérias dos membros",
        "k": "80",
        "c": "0",
        "code": "35.01.05.05"
    },
    {
        "id": 1697,
        "label": "Artérias do pescoço",
        "k": "190",
        "c": "0",
        "code": "35.01.06.01"
    },
    {
        "id": 1698,
        "label": "Artérias intratorácicas",
        "k": "160",
        "c": "0",
        "code": "35.01.06.02"
    },
    {
        "id": 1699,
        "label": "Artérias abdominais",
        "k": "120",
        "c": "0",
        "code": "35.01.06.03"
    },
    {
        "id": 1700,
        "label": "Artérias dos membros",
        "k": "100",
        "c": "0",
        "code": "35.01.06.04"
    },
    {
        "id": 1701,
        "label": "Artéria maxilar interna na fossa pterigopalatina",
        "k": "110",
        "c": "0",
        "code": "35.01.07.01"
    },
    {
        "id": 1702,
        "label": "Artéria etmoidal anterior, via intraorbitária",
        "k": "100",
        "c": "0",
        "code": "35.01.07.02"
    },
    {
        "id": 1703,
        "label": "Artérias do pescoço",
        "k": "80",
        "c": "0",
        "code": "35.01.07.03"
    },
    {
        "id": 1704,
        "label": "Artérias do tórax",
        "k": "150",
        "c": "0",
        "code": "35.01.07.04"
    },
    {
        "id": 1705,
        "label": "Artérias abdominais",
        "k": "150",
        "c": "0",
        "code": "35.01.07.05"
    },
    {
        "id": 1706,
        "label": "Excisão de prótese entre a aorta e artérias do membro inferior",
        "k": "200",
        "c": "0",
        "code": "35.01.07.06"
    },
    {
        "id": 1707,
        "label": "Idem, entre a aorta e troncos supraaorticos",
        "k": "200",
        "c": "0",
        "code": "35.01.07.07"
    },
    {
        "id": 1708,
        "label": "Artérias dos membros",
        "k": "100",
        "c": "0",
        "code": "35.01.07.08"
    },
    {
        "id": 1709,
        "label": "Tratamento da fístula aorto-digestiva ou aortocava",
        "k": "400",
        "c": "0",
        "code": "35.01.07.09"
    },
    {
        "id": 1710,
        "label": "Simpaticectomia lombar",
        "k": "100",
        "c": "0",
        "code": "35.02.00.01"
    },
    {
        "id": 1711,
        "label": "Simpaticectomia cervicodorsal",
        "k": "120",
        "c": "0",
        "code": "35.02.00.02"
    },
    {
        "id": 1712,
        "label": "Simpaticectomia torácica superior (via axilar ou transpleural)",
        "k": "150",
        "c": "0",
        "code": "35.02.00.03"
    },
    {
        "id": 1713,
        "label": "Ressecção de costela cervical, unilateral",
        "k": "120",
        "c": "0",
        "code": "35.02.00.05"
    },
    {
        "id": 1714,
        "label": "Ressecção da 1a. Costela, unilateral",
        "k": "120",
        "c": "0",
        "code": "35.02.00.06"
    },
    {
        "id": 1715,
        "label": "Veias cava inferior, ilíacas, femorais e popliteas, via abdominal",
        "k": "150",
        "c": "0",
        "code": "35.03.00.01"
    },
    {
        "id": 1716,
        "label": "Grandes veias do tórax",
        "k": "250",
        "c": "0",
        "code": "35.03.00.02"
    },
    {
        "id": 1717,
        "label": "Veias dos membros (via periférica)",
        "k": "100",
        "c": "0",
        "code": "35.03.00.03"
    },
    {
        "id": 1718,
        "label": "Veias viscerais abdominais",
        "k": "200",
        "c": "0",
        "code": "35.03.00.04"
    },
    {
        "id": 1719,
        "label": "Veias do pescoço",
        "k": "130",
        "c": "0",
        "code": "35.03.01.01"
    },
    {
        "id": 1720,
        "label": "Grandes veias do tórax",
        "k": "200",
        "c": "0",
        "code": "35.03.01.02"
    },
    {
        "id": 1721,
        "label": "Veia cava inferior acima das veias renais",
        "k": "250",
        "c": "0",
        "code": "35.03.01.03"
    },
    {
        "id": 1722,
        "label": "Restantes veias do abdómen",
        "k": "200",
        "c": "0",
        "code": "35.03.01.04"
    },
    {
        "id": 1723,
        "label": "Veias dos membros",
        "k": "150",
        "c": "0",
        "code": "35.03.01.05"
    },
    {
        "id": 1724,
        "label": "Enxerto do segmento venoso valvulado",
        "k": "150",
        "c": "0",
        "code": "35.03.01.06"
    },
    {
        "id": 1725,
        "label": "Valvuloplastias",
        "k": "200",
        "c": "0",
        "code": "35.03.01.07"
    },
    {
        "id": 1726,
        "label": "Operação de Palma e similares",
        "k": "150",
        "c": "0",
        "code": "35.03.01.08"
    },
    {
        "id": 1727,
        "label": "Veias do pescoço",
        "k": "120",
        "c": "0",
        "code": "35.03.02.01"
    },
    {
        "id": 1728,
        "label": "Veias dos membros",
        "k": "100",
        "c": "0",
        "code": "35.03.02.02"
    },
    {
        "id": 1729,
        "label": "Veias do tórax",
        "k": "200",
        "c": "0",
        "code": "35.03.02.03"
    },
    {
        "id": 1730,
        "label": "Grandes veias abdominais e pélvicas",
        "k": "150",
        "c": "0",
        "code": "35.03.02.04"
    },
    {
        "id": 1731,
        "label": "Laqueação de veias do pescoço",
        "k": "60",
        "c": "0",
        "code": "35.03.03.01"
    },
    {
        "id": 1732,
        "label": "Interrupção da veia cava inferior por laqueação, plicatura, ou agrafe",
        "k": "150",
        "c": "0",
        "code": "35.03.03.02"
    },
    {
        "id": 1733,
        "label": "Interrupção de veia ilíaca",
        "k": "90",
        "c": "0",
        "code": "35.03.03.03"
    },
    {
        "id": 1734,
        "label": "Interrupção de veia femoral",
        "k": "70",
        "c": "0",
        "code": "35.03.03.04"
    },
    {
        "id": 1735,
        "label": "Laqueação isolada da crossa da veia safena interna ou externa",
        "k": "80",
        "c": "0",
        "code": "35.03.03.05"
    },
    {
        "id": 1736,
        "label": "Idem + excisão da veia safena interna ou externa com ou sem laqueação de comunicantes com ou sem excisão de segmentos venosos",
        "k": "160",
        "c": "0",
        "code": "35.03.03.06"
    },
    {
        "id": 1737,
        "label": "Idem em ambas as veias de um membro (veia safena interna e externa)",
        "k": "190",
        "c": "0",
        "code": "35.03.03.07"
    },
    {
        "id": 2259,
        "label": "Transureteroureterostomia",
        "k": "160",
        "c": "0",
        "code": "40.01.00.18"
    },
    {
        "id": 1738,
        "label": "Excisão da veia safena interna ou externa com ou sem laqueação de comunicantes, com ou sem excisão de segmentos venosos intermédios, sem laqueação de crossas de safena interna ou externa",
        "k": "130",
        "c": "0",
        "code": "35.03.03.08"
    },
    {
        "id": 1739,
        "label": "Laqueação de comunicantes com ou sem excisão de segmentos venosos",
        "k": "75",
        "c": "0",
        "code": "35.03.03.09"
    },
    {
        "id": 1740,
        "label": "Laqueação da crossa da veia safena interna ou externa + laqueação de comunicantes com ou sem excisão de segmentos",
        "k": "150",
        "c": "0",
        "code": "35.03.03.10"
    },
    {
        "id": 1741,
        "label": "Laqueação das crossas das veias safena interna e externa + laqueação de comunicantes com ou sem excisão venosas",
        "k": "190",
        "c": "0",
        "code": "35.03.03.11"
    },
    {
        "id": 1742,
        "label": "Revisão de laqueação de crossa de veia safena interna ou externa em recidiva de varizes",
        "k": "90",
        "c": "0",
        "code": "35.03.03.12"
    },
    {
        "id": 1743,
        "label": "Idem em ambas as veias de um membro",
        "k": "140",
        "c": "0",
        "code": "35.03.03.13"
    },
    {
        "id": 1744,
        "label": "Operação de Linton ou Cockett isolada",
        "k": "110",
        "c": "0",
        "code": "35.03.03.14"
    },
    {
        "id": 1745,
        "label": "Idem a adicionar a valor de outra cirurgia de varizes",
        "k": "60",
        "c": "0",
        "code": "35.03.03.15"
    },
    {
        "id": 1746,
        "label": "Via torácica, intraesofágica",
        "k": "200",
        "c": "0",
        "code": "35.03.04.01"
    },
    {
        "id": 1747,
        "label": "Via abdominal, extragastrica",
        "k": "150",
        "c": "0",
        "code": "35.03.04.02"
    },
    {
        "id": 1748,
        "label": "Via abdominal, intra e extragastrica",
        "k": "180",
        "c": "0",
        "code": "35.03.04.03"
    },
    {
        "id": 1749,
        "label": "Operação de Sugiura",
        "k": "200",
        "c": "0",
        "code": "35.03.04.04"
    },
    {
        "id": 1750,
        "label": "Via abdominal, transsecção esofágica ou plicatura com anastomose(instrumento mecânico)",
        "k": "200",
        "c": "0",
        "code": "35.03.04.05"
    },
    {
        "id": 1751,
        "label": "Via abdominal, ressecção gástrica",
        "k": "200",
        "c": "0",
        "code": "35.03.04.06"
    },
    {
        "id": 1752,
        "label": "Porto-cava termino-lateral",
        "k": "250",
        "c": "0",
        "code": "35.03.04.07"
    },
    {
        "id": 1753,
        "label": "Porto-cava latero-lateral",
        "k": "250",
        "c": "0",
        "code": "35.03.04.08"
    },
    {
        "id": 1754,
        "label": "Porto-cava em H",
        "k": "250",
        "c": "0",
        "code": "35.03.04.09"
    },
    {
        "id": 1755,
        "label": "Esplenorenal proximal (anastomose directa)",
        "k": "280",
        "c": "0",
        "code": "35.03.04.10"
    },
    {
        "id": 1756,
        "label": "Esplenorenal distal (op. Warren) ou espleno cava distal",
        "k": "300",
        "c": "0",
        "code": "35.03.04.11"
    },
    {
        "id": 1757,
        "label": "Esplenorenal em H",
        "k": "250",
        "c": "0",
        "code": "35.03.04.12"
    },
    {
        "id": 1758,
        "label": "Mesenterico-cava – iliaca-ovarica ou renal",
        "k": "280",
        "c": "0",
        "code": "35.03.04.13"
    },
    {
        "id": 1759,
        "label": "Mesenterico-cava em H",
        "k": "250",
        "c": "0",
        "code": "35.03.04.14"
    },
    {
        "id": 1760,
        "label": "Coronário-cava (op. Inokuchi)",
        "k": "280",
        "c": "0",
        "code": "35.03.04.15"
    },
    {
        "id": 1761,
        "label": "Outras anastomoses atípicas",
        "k": "250",
        "c": "0",
        "code": "35.03.04.16"
    },
    {
        "id": 1762,
        "label": "Arterialização do fígado",
        "k": "200",
        "c": "0",
        "code": "35.03.04.17"
    },
    {
        "id": 1763,
        "label": "Excisão-enxerto",
        "k": "150",
        "c": "0",
        "code": "35.04.00.01"
    },
    {
        "id": 1764,
        "label": "Enxerto pediculado",
        "k": "110",
        "c": "0",
        "code": "35.04.00.02"
    },
    {
        "id": 1765,
        "label": "Operação de Thompson",
        "k": "150",
        "c": "0",
        "code": "35.04.00.03"
    },
    {
        "id": 1766,
        "label": "Epiploplastia",
        "k": "150",
        "c": "0",
        "code": "35.04.00.04"
    },
    {
        "id": 1767,
        "label": "Implantação de fios ou outro material para incrementar a drenagem linfática",
        "k": "80",
        "c": "0",
        "code": "35.04.00.05"
    },
    {
        "id": 1768,
        "label": "Anastomose linfovenosa",
        "k": "150",
        "c": "0",
        "code": "35.04.00.06"
    },
    {
        "id": 1769,
        "label": "Canal torácico, via cervical",
        "k": "70",
        "c": "0",
        "code": "35.04.01.01"
    },
    {
        "id": 1770,
        "label": "Canal torácico, via torácica",
        "k": "150",
        "c": "0",
        "code": "35.04.01.02"
    },
    {
        "id": 1771,
        "label": "Membros",
        "k": "50",
        "c": "0",
        "code": "35.04.01.03"
    },
    {
        "id": 1772,
        "label": "Sutura ou anastomose do canal torácico, via cervical",
        "k": "100",
        "c": "0",
        "code": "35.04.02.01"
    },
    {
        "id": 1773,
        "label": "Sutura ou anastomose do canal torácico, via torácica",
        "k": "150",
        "c": "0",
        "code": "35.04.02.02"
    },
    {
        "id": 1774,
        "label": "Ponte (Shunt) exterior",
        "k": "50",
        "c": "0",
        "code": "35.05.00.01"
    },
    {
        "id": 1775,
        "label": "Fistula arteriovenosa no punho",
        "k": "100",
        "c": "0",
        "code": "35.05.00.02"
    },
    {
        "id": 1776,
        "label": "Fistula arteriovenosa no cotovelo",
        "k": "130",
        "c": "0",
        "code": "35.05.00.03"
    },
    {
        "id": 1777,
        "label": "Ponte arterio-arterial ou arterio-venosa (não inclui o custo de op. acessória ou de prótese)",
        "k": "160",
        "c": "0",
        "code": "35.05.00.04"
    },
    {
        "id": 1778,
        "label": "Cirurgia das complicações dos acessos vasculares com continuidade do acesso",
        "k": "120",
        "c": "0",
        "code": "35.05.00.05"
    },
    {
        "id": 1779,
        "label": "Idem, com sacrifício do acesso vascular",
        "k": "50",
        "c": "0",
        "code": "35.05.00.06"
    },
    {
        "id": 1780,
        "label": "Introdução de cateter i.v. com tunelização ou em posição subcutânea",
        "k": "50",
        "c": "0",
        "code": "35.05.00.07"
    },
    {
        "id": 1781,
        "label": "Revascularização da artéria hipogastrica",
        "k": "180",
        "c": "0",
        "code": "35.06.00.01"
    },
    {
        "id": 1782,
        "label": "Revascularização do pénis",
        "k": "150",
        "c": "0",
        "code": "35.06.00.02"
    },
    {
        "id": 1783,
        "label": "Idem, com microcirurgia",
        "k": "200",
        "c": "30",
        "code": "35.06.00.03"
    },
    {
        "id": 1784,
        "label": "Correcção de drenagem venosa do pénis",
        "k": "120",
        "c": "0",
        "code": "35.06.00.04"
    },
    {
        "id": 1785,
        "label": "Veia cava superior",
        "k": "20",
        "c": "0",
        "code": "35.07.00.01"
    },
    {
        "id": 1786,
        "label": "Coração direito ou artéria pulmonar",
        "k": "30",
        "c": "0",
        "code": "35.07.00.02"
    },
    {
        "id": 1787,
        "label": "Veias cervicais",
        "k": "20",
        "c": "0",
        "code": "35.07.00.03"
    },
    {
        "id": 1788,
        "label": "Veias renais",
        "k": "20",
        "c": "0",
        "code": "35.07.00.04"
    },
    {
        "id": 1789,
        "label": "Veias supra-hepáticas",
        "k": "30",
        "c": "0",
        "code": "35.07.00.05"
    },
    {
        "id": 1790,
        "label": "Veias intra-hepática",
        "k": "30",
        "c": "0",
        "code": "35.07.00.06"
    },
    {
        "id": 1791,
        "label": "Veia aferente do sistema porta",
        "k": "40",
        "c": "0",
        "code": "35.07.00.07"
    },
    {
        "id": 1792,
        "label": "Veias dos membros",
        "k": "5",
        "c": "0",
        "code": "35.07.00.08"
    },
    {
        "id": 1793,
        "label": "Carótida",
        "k": "20",
        "c": "0",
        "code": "35.07.01.01"
    },
    {
        "id": 1794,
        "label": "Artéria vertebral",
        "k": "20",
        "c": "0",
        "code": "35.07.01.02"
    },
    {
        "id": 1795,
        "label": "Artéria do membro superior ou inferior",
        "k": "10",
        "c": "0",
        "code": "35.07.01.03"
    },
    {
        "id": 1796,
        "label": "Aorta",
        "k": "20",
        "c": "0",
        "code": "35.07.01.04"
    },
    {
        "id": 1797,
        "label": "Carótida",
        "k": "80",
        "c": "0",
        "code": "35.07.02.01"
    },
    {
        "id": 1798,
        "label": "Artéria dos membros",
        "k": "80",
        "c": "0",
        "code": "35.07.02.02"
    },
    {
        "id": 1799,
        "label": "Canal torácico",
        "k": "100",
        "c": "0",
        "code": "35.07.03.01"
    },
    {
        "id": 1800,
        "label": "Vasos linfáticos de membros (superiores e inferiores)",
        "k": "50",
        "c": "0",
        "code": "35.07.03.02"
    },
    {
        "id": 1801,
        "label": "Esplenectomia (total ou parcial) ou esplenorrafia",
        "k": "160",
        "c": "0",
        "code": "36.00.00.01"
    },
    {
        "id": 1802,
        "label": "Drenagem de abcesso ganglionar",
        "k": "17",
        "c": "0",
        "code": "36.01.00.01"
    },
    {
        "id": 1803,
        "label": "Excisão de gânglio linfático superficial",
        "k": "32",
        "c": "0",
        "code": "36.01.00.02"
    },
    {
        "id": 1804,
        "label": "Excisão de gânglio linfático profundo",
        "k": "42",
        "c": "0",
        "code": "36.01.00.03"
    },
    {
        "id": 1805,
        "label": "Excisão de linfangioma quistico (Exceptuando parótida)",
        "k": "155",
        "c": "0",
        "code": "36.01.00.04"
    },
    {
        "id": 1806,
        "label": "Excisão de linfangioma quístico cervico-parótideo",
        "k": "270",
        "c": "0",
        "code": "36.01.00.05"
    },
    {
        "id": 1807,
        "label": "Esvasiamento suprahioideu, unilateral",
        "k": "115",
        "c": "0",
        "code": "36.01.00.06"
    },
    {
        "id": 1808,
        "label": "Esvasiamento suprahioideu, bilateral",
        "k": "140",
        "c": "0",
        "code": "36.01.00.07"
    },
    {
        "id": 1809,
        "label": "Esvasiamento cervical radical",
        "k": "165",
        "c": "0",
        "code": "36.01.00.08"
    },
    {
        "id": 1810,
        "label": "Esvasiamento cervical radical, bilateral",
        "k": "280",
        "c": "0",
        "code": "36.01.00.09"
    },
    {
        "id": 1811,
        "label": "Esvasiamento cervical conservador, unilateral",
        "k": "130",
        "c": "0",
        "code": "36.01.00.10"
    },
    {
        "id": 2404,
        "label": "Uretrectomia parcial",
        "k": "80",
        "c": "0",
        "code": "40.04.00.25"
    },
    {
        "id": 1812,
        "label": "Esvasiamento cervical conservador, bilateral",
        "k": "210",
        "c": "0",
        "code": "36.01.00.11"
    },
    {
        "id": 1813,
        "label": "Esvasiamento axilar",
        "k": "130",
        "c": "0",
        "code": "36.01.00.12"
    },
    {
        "id": 1814,
        "label": "Esvasiamento inguinal, unilateral",
        "k": "130",
        "c": "0",
        "code": "36.01.00.13"
    },
    {
        "id": 1815,
        "label": "Esvasiamento inguinal e pélvico em continuidade, unilateral",
        "k": "160",
        "c": "0",
        "code": "36.01.00.14"
    },
    {
        "id": 1816,
        "label": "Esvasiamento pélvico unilateral",
        "k": "140",
        "c": "0",
        "code": "36.01.00.15"
    },
    {
        "id": 1817,
        "label": "Esvasiamento pélvico bilateral",
        "k": "210",
        "c": "0",
        "code": "36.01.00.16"
    },
    {
        "id": 1818,
        "label": "Esvasiamento retroperitoneal (aorto-renal e pélvico)",
        "k": "250",
        "c": "0",
        "code": "36.01.00.17"
    },
    {
        "id": 1819,
        "label": "Mediastinotomia transesternal exploradora",
        "k": "120",
        "c": "0",
        "code": "37.00.00.01"
    },
    {
        "id": 1820,
        "label": "Mediastinotomia transtorácica exploradora",
        "k": "120",
        "c": "0",
        "code": "37.00.00.02"
    },
    {
        "id": 1821,
        "label": "Exérese de tumor do mediastino",
        "k": "300",
        "c": "0",
        "code": "37.00.00.03"
    },
    {
        "id": 1822,
        "label": "Tratamento de hérnia do hiato por via abdominal",
        "k": "250",
        "c": "0",
        "code": "37.00.00.04"
    },
    {
        "id": 1823,
        "label": "Tratamento de hérnia do hiato por via torácica",
        "k": "250",
        "c": "0",
        "code": "37.00.00.05"
    },
    {
        "id": 1824,
        "label": "Tratamento de rotura traumática do diafragma",
        "k": "250",
        "c": "0",
        "code": "37.00.00.06"
    },
    {
        "id": 1825,
        "label": "Tratamento de hérnia de Bochdalek",
        "k": "250",
        "c": "0",
        "code": "37.00.00.07"
    },
    {
        "id": 1826,
        "label": "Imbricação do diafragma por eventração",
        "k": "250",
        "c": "0",
        "code": "37.00.00.08"
    },
    {
        "id": 1827,
        "label": "Tratamento de hérnia de Morgagni",
        "k": "250",
        "c": "0",
        "code": "37.00.00.09"
    },
    {
        "id": 1828,
        "label": "Ressecção de diafragma (por tumor ou perfuração inflamatória)",
        "k": "250",
        "c": "0",
        "code": "37.00.00.10"
    },
    {
        "id": 1829,
        "label": "Reparação do diafragma com prótese",
        "k": "250",
        "c": "0",
        "code": "37.00.00.11"
    },
    {
        "id": 1830,
        "label": "Em cavidade com compromisso de 1 só face dentária",
        "k": "15",
        "c": "10",
        "code": "38.00.00.01"
    },
    {
        "id": 1831,
        "label": "Em cavidade com compromisso 2 faces dentárias",
        "k": "20",
        "c": "15",
        "code": "38.00.00.02"
    },
    {
        "id": 1832,
        "label": "Em cavidade com compromisso de 3 ou mais faces dentárias",
        "k": "25",
        "c": "25",
        "code": "38.00.00.03"
    },
    {
        "id": 1833,
        "label": "Com espigões dentários ou intra-radiculares (cada espigão)",
        "k": "8",
        "c": "8",
        "code": "38.00.00.04"
    },
    {
        "id": 1834,
        "label": "Polimento de restauração metálica",
        "k": "10",
        "c": "8",
        "code": "38.00.00.05"
    },
    {
        "id": 1835,
        "label": "Dente de 1 só canal",
        "k": "15",
        "c": "20",
        "code": "38.00.01.01"
    },
    {
        "id": 1836,
        "label": "Dente de 2 canais",
        "k": "20",
        "c": "25",
        "code": "38.00.01.02"
    },
    {
        "id": 1837,
        "label": "Dente com 3 canais",
        "k": "25",
        "c": "40",
        "code": "38.00.01.03"
    },
    {
        "id": 1838,
        "label": "Endodontio que necessita várias sessões de tratamento (por sessão)",
        "k": "12",
        "c": "8",
        "code": "38.00.01.04"
    },
    {
        "id": 1839,
        "label": "Aplicação tópica de fluoretos (por sessão)",
        "k": "10",
        "c": "8",
        "code": "38.00.01.05"
    },
    {
        "id": 1840,
        "label": "Aplicação de compósitos para selagem de fisuras (por quadrante)",
        "k": "25",
        "c": "10",
        "code": "38.00.01.06"
    },
    {
        "id": 1841,
        "label": "Destartarização (por sessão de 1?2 hora)",
        "k": "15",
        "c": "10",
        "code": "38.01.00.01"
    },
    {
        "id": 1842,
        "label": "Curetagem sub-gengival (por quadrante) sem cirurgia",
        "k": "15",
        "c": "15",
        "code": "38.01.00.02"
    },
    {
        "id": 1843,
        "label": "Gengivectomia (por bloco anterior ou lateral)",
        "k": "15",
        "c": "25",
        "code": "38.01.00.03"
    },
    {
        "id": 1844,
        "label": "Cirurgia de retalho",
        "k": "15",
        "c": "35",
        "code": "38.01.00.04"
    },
    {
        "id": 1845,
        "label": "Enxertos pediculados",
        "k": "15",
        "c": "35",
        "code": "38.01.00.05"
    },
    {
        "id": 1846,
        "label": "Enxerto da mucosa bucal",
        "k": "15",
        "c": "35",
        "code": "38.01.00.06"
    },
    {
        "id": 1847,
        "label": "Auto-enxerto ósseo",
        "k": "15",
        "c": "35",
        "code": "38.01.00.07"
    },
    {
        "id": 1848,
        "label": "Estabilização de peças dentárias por qualquer técnica",
        "k": "25",
        "c": "35",
        "code": "38.01.01.01"
    },
    {
        "id": 1849,
        "label": "Exodontia simples de monorradicular",
        "k": "12",
        "c": "8",
        "code": "38.02.00.01"
    },
    {
        "id": 1850,
        "label": "Exodontia simples de multirradicular",
        "k": "13",
        "c": "12",
        "code": "38.02.00.02"
    },
    {
        "id": 1851,
        "label": "Exodontia complicada ou de siso incluso, não complicada (sem osteotomia)",
        "k": "20",
        "c": "20",
        "code": "38.02.00.03"
    },
    {
        "id": 1852,
        "label": "Exodontia de dentes inclusos",
        "k": "35",
        "c": "60",
        "code": "38.02.00.04"
    },
    {
        "id": 1853,
        "label": "Reimplantação dentária",
        "k": "25",
        "c": "25",
        "code": "38.02.00.05"
    },
    {
        "id": 1854,
        "label": "Germectomia",
        "k": "30",
        "c": "50",
        "code": "38.02.00.06"
    },
    {
        "id": 1855,
        "label": "Transplantação de germes dentários",
        "k": "40",
        "c": "50",
        "code": "38.02.00.07"
    },
    {
        "id": 1856,
        "label": "Exodontias múltiplas sob anestesia geral",
        "k": "100",
        "c": "0",
        "code": "38.02.00.08"
    },
    {
        "id": 1857,
        "label": "Exodoptia seguida de sutura",
        "k": "25",
        "c": "18",
        "code": "38.02.00.09"
    },
    {
        "id": 1858,
        "label": "Apicectomia de monorradiculares",
        "k": "25",
        "c": "35",
        "code": "38.02.00.10"
    },
    {
        "id": 1859,
        "label": "Apicectomia de multirradiculares",
        "k": "30",
        "c": "50",
        "code": "38.02.00.11"
    },
    {
        "id": 1860,
        "label": "Aprofundamento do vestíbulo (por quadrante)",
        "k": "30",
        "c": "40",
        "code": "38.02.00.12"
    },
    {
        "id": 1861,
        "label": "Desinserção e alongamento do freio labial",
        "k": "15",
        "c": "35",
        "code": "38.02.00.13"
    },
    {
        "id": 1862,
        "label": "Excisão de bridas gengivais (por quadrante)",
        "k": "20",
        "c": "35",
        "code": "38.02.00.14"
    },
    {
        "id": 1863,
        "label": "Radiculectomia",
        "k": "30",
        "c": "35",
        "code": "38.02.00.15"
    },
    {
        "id": 1864,
        "label": "Quistos paradentários, com anestesia local ou regional",
        "k": "30",
        "c": "0",
        "code": "38.02.00.16"
    },
    {
        "id": 1865,
        "label": "Quistos paradentários, com anestesia geral",
        "k": "75",
        "c": "0",
        "code": "38.02.00.17"
    },
    {
        "id": 1866,
        "label": "Exérese de ranulas simples ou outros pequenos tumores dos tecidos moles da cavidade oral com anestesia local",
        "k": "20",
        "c": "40",
        "code": "38.02.00.18"
    },
    {
        "id": 1867,
        "label": "Exérese de ranulas simples ou outros pequenos tumores dos tecidos moles da cavidade oral com anestesia geral",
        "k": "50",
        "c": "0",
        "code": "38.02.00.19"
    },
    {
        "id": 1868,
        "label": "Curetagem de focos de osteite não simultânea com a exodontia",
        "k": "20",
        "c": "15",
        "code": "38.02.00.20"
    },
    {
        "id": 1869,
        "label": "Biópsia de tecidos moles",
        "k": "5",
        "c": "3",
        "code": "38.02.00.21"
    },
    {
        "id": 1870,
        "label": "Biópsia óssea",
        "k": "15",
        "c": "3",
        "code": "38.02.00.22"
    },
    {
        "id": 1871,
        "label": "Exérese de epulides, hiperplasia do rebordo alveolar",
        "k": "30",
        "c": "40",
        "code": "38.02.00.23"
    },
    {
        "id": 1872,
        "label": "Redução e contenção do dente luxado por trauma com regularização do bordo alveolar (por quadrante)",
        "k": "30",
        "c": "35",
        "code": "38.02.00.24"
    },
    {
        "id": 1873,
        "label": "Incisão e drenagem de abcessos de origem dentária, por via bucal",
        "k": "20",
        "c": "5",
        "code": "38.02.00.25"
    },
    {
        "id": 1874,
        "label": "Incisão e drenagem de abcessos de origem dentária, por via cutânea",
        "k": "30",
        "c": "30",
        "code": "38.02.00.26"
    },
    {
        "id": 1875,
        "label": "Radiografia apical",
        "k": "2",
        "c": "2",
        "code": "38.03.00.01"
    },
    {
        "id": 1876,
        "label": "Interpromixal (Bitewing)",
        "k": "2",
        "c": "3",
        "code": "38.03.00.02"
    },
    {
        "id": 1877,
        "label": "Radiografia oclusal",
        "k": "2",
        "c": "5",
        "code": "38.03.00.03"
    },
    {
        "id": 1878,
        "label": "Ortopantomografia",
        "k": "2",
        "c": "22",
        "code": "38.03.00.04"
    },
    {
        "id": 1879,
        "label": "Aparelhos removíveis",
        "k": "120",
        "c": "70",
        "code": "38.04.00.01"
    },
    {
        "id": 1880,
        "label": "Controle",
        "k": "7",
        "c": "10",
        "code": "38.04.00.02"
    },
    {
        "id": 1881,
        "label": "Aparelhos fixos",
        "k": "550",
        "c": "200",
        "code": "38.04.00.03"
    },
    {
        "id": 1882,
        "label": "Controle",
        "k": "15",
        "c": "20",
        "code": "38.04.00.04"
    },
    {
        "id": 1883,
        "label": "Conserto de aparelho removível, sem impressão",
        "k": "20",
        "c": "0",
        "code": "38.04.00.05"
    },
    {
        "id": 1884,
        "label": "Conserto de aparelho removível, com impressão",
        "k": "30",
        "c": "20",
        "code": "38.04.00.06"
    },
    {
        "id": 1885,
        "label": "Conjunção de fixação extra-oral",
        "k": "100",
        "c": "25",
        "code": "38.04.00.07"
    },
    {
        "id": 1886,
        "label": "Impressões e modelos de estudo",
        "k": "10",
        "c": "10",
        "code": "38.04.00.08"
    },
    {
        "id": 1887,
        "label": "Análise cefalométrica da telerradiografia e panorâmica",
        "k": "10",
        "c": "30",
        "code": "38.04.00.09"
    },
    {
        "id": 1888,
        "label": "Fotografia e estudo fotográfico",
        "k": "20",
        "c": "40",
        "code": "38.04.00.10"
    },
    {
        "id": 1889,
        "label": "Impressão el alginato e modelo de estudo",
        "k": "15",
        "c": "10",
        "code": "38.05.00.01"
    },
    {
        "id": 1890,
        "label": "Impressão em alginato em moldeira individual e modelo de trabalho",
        "k": "20",
        "c": "15",
        "code": "38.05.00.02"
    },
    {
        "id": 1891,
        "label": "Impressão em elastrómero de síntese ou hidrocoloide reversível (com moldeira ajustada ou equivalente)",
        "k": "45",
        "c": "15",
        "code": "38.05.00.03"
    },
    {
        "id": 1892,
        "label": "Impressão funcional usando base ajustada, material termoplástico e outro",
        "k": "45",
        "c": "20",
        "code": "38.05.00.04"
    },
    {
        "id": 1893,
        "label": "Impressão de preparação com espigões intradentários paralelos",
        "k": "60",
        "c": "45",
        "code": "38.05.00.05"
    },
    {
        "id": 1894,
        "label": "Placa para registo de relação intermaxilar",
        "k": "5",
        "c": "10",
        "code": "38.05.00.06"
    },
    {
        "id": 1895,
        "label": "Registo da relação intermaxilar usando cera em base estabilizada numa arcada",
        "k": "10",
        "c": "10",
        "code": "38.05.00.07"
    },
    {
        "id": 1896,
        "label": "Idem em duas arcadas em (p.p.)",
        "k": "10",
        "c": "10",
        "code": "38.05.00.08"
    },
    {
        "id": 1897,
        "label": "Idem numa arcada (P.T.)",
        "k": "15",
        "c": "15",
        "code": "38.05.00.09"
    },
    {
        "id": 1898,
        "label": "1 dente",
        "k": "28",
        "c": "30",
        "code": "38.05.01.01"
    },
    {
        "id": 1899,
        "label": "2 dentes",
        "k": "31",
        "c": "30",
        "code": "38.05.01.02"
    },
    {
        "id": 1900,
        "label": "3 dentes",
        "k": "35",
        "c": "35",
        "code": "38.05.01.03"
    },
    {
        "id": 1901,
        "label": "4 dentes",
        "k": "38",
        "c": "40",
        "code": "38.05.01.04"
    },
    {
        "id": 1902,
        "label": "5 dentes",
        "k": "42",
        "c": "45",
        "code": "38.05.01.05"
    },
    {
        "id": 1903,
        "label": "6 dentes",
        "k": "46",
        "c": "45",
        "code": "38.05.01.06"
    },
    {
        "id": 1904,
        "label": "7 dentes",
        "k": "50",
        "c": "50",
        "code": "38.05.01.07"
    },
    {
        "id": 1905,
        "label": "8 dentes",
        "k": "54",
        "c": "50",
        "code": "38.05.01.08"
    },
    {
        "id": 1906,
        "label": "9 dentes",
        "k": "58",
        "c": "55",
        "code": "38.05.01.09"
    },
    {
        "id": 1907,
        "label": "10 dentes",
        "k": "61",
        "c": "55",
        "code": "38.05.01.10"
    },
    {
        "id": 1908,
        "label": "11 dentes",
        "k": "65",
        "c": "60",
        "code": "38.05.01.11"
    },
    {
        "id": 1909,
        "label": "12 dentes",
        "k": "69",
        "c": "60",
        "code": "38.05.01.12"
    },
    {
        "id": 1910,
        "label": "13 dentes",
        "k": "72",
        "c": "60",
        "code": "38.05.01.13"
    },
    {
        "id": 1911,
        "label": "14 dentes",
        "k": "75",
        "c": "65",
        "code": "38.05.01.14"
    },
    {
        "id": 1912,
        "label": "28 dentes",
        "k": "160",
        "c": "100",
        "code": "38.05.01.15"
    },
    {
        "id": 1913,
        "label": "1 dente",
        "k": "55",
        "c": "42",
        "code": "38.05.02.01"
    },
    {
        "id": 1914,
        "label": "2 dentes",
        "k": "68",
        "c": "54",
        "code": "38.05.02.02"
    },
    {
        "id": 1915,
        "label": "3 dentes",
        "k": "76",
        "c": "61",
        "code": "38.05.02.03"
    },
    {
        "id": 1916,
        "label": "4 dentes",
        "k": "86",
        "c": "71",
        "code": "38.05.02.04"
    },
    {
        "id": 1917,
        "label": "5 dentes",
        "k": "98",
        "c": "80",
        "code": "38.05.02.05"
    },
    {
        "id": 1918,
        "label": "6 dentes",
        "k": "113",
        "c": "93",
        "code": "38.05.02.06"
    },
    {
        "id": 1919,
        "label": "7 dentes",
        "k": "122",
        "c": "98",
        "code": "38.05.02.07"
    },
    {
        "id": 1920,
        "label": "8 dentes",
        "k": "132",
        "c": "106",
        "code": "38.05.02.08"
    },
    {
        "id": 1921,
        "label": "9 dentes",
        "k": "139",
        "c": "111",
        "code": "38.05.02.09"
    },
    {
        "id": 1922,
        "label": "10 dentes",
        "k": "143",
        "c": "115",
        "code": "38.05.02.10"
    },
    {
        "id": 1923,
        "label": "11 dentes",
        "k": "148",
        "c": "118",
        "code": "38.05.02.11"
    },
    {
        "id": 1924,
        "label": "12 dentes",
        "k": "143",
        "c": "120",
        "code": "38.05.02.12"
    },
    {
        "id": 1925,
        "label": "13 dentes",
        "k": "156",
        "c": "122",
        "code": "38.05.02.13"
    },
    {
        "id": 1926,
        "label": "14 dentes",
        "k": "158",
        "c": "124",
        "code": "38.05.02.14"
    },
    {
        "id": 1927,
        "label": "Preparação dentária para coroa de revestimento total",
        "k": "25",
        "c": "30",
        "code": "38.05.03.01"
    },
    {
        "id": 1928,
        "label": "Idem para a coroa em auro-cerâmica",
        "k": "25",
        "c": "35",
        "code": "38.05.03.02"
    },
    {
        "id": 1929,
        "label": "Idem para a coroa com espigão intraradicular",
        "k": "25",
        "c": "35",
        "code": "38.05.03.03"
    },
    {
        "id": 1930,
        "label": "Idem para coroa tipo ‘’Jacket’’",
        "k": "25",
        "c": "35",
        "code": "38.05.03.04"
    },
    {
        "id": 1931,
        "label": "Idem para coroa 3?4 ou 4/5",
        "k": "25",
        "c": "40",
        "code": "38.05.03.05"
    },
    {
        "id": 1932,
        "label": "Idem para coroa com espigões paralelos intradentinários",
        "k": "50",
        "c": "50",
        "code": "38.05.03.06"
    },
    {
        "id": 1933,
        "label": "Idem para falso-côto fundido",
        "k": "25",
        "c": "25",
        "code": "38.05.03.07"
    },
    {
        "id": 1934,
        "label": "Preparação gengival com vista à tomada de impressão imediata: retracção gengival, cirurgia, hemostase, remoção de mucosidade e coágulos (em cada elemento)",
        "k": "30",
        "c": "25",
        "code": "38.05.03.08"
    },
    {
        "id": 1935,
        "label": "Prova ou inserção de cada elemento protético (por sessão)",
        "k": "15",
        "c": "25",
        "code": "38.05.03.09"
    },
    {
        "id": 1936,
        "label": "Elaboração de prótese provisória em resina para protecção de côto preparado",
        "k": "30",
        "c": "20",
        "code": "38.05.03.10"
    },
    {
        "id": 1937,
        "label": "Gancho em aço inoxidável",
        "k": "4",
        "c": "9",
        "code": "38.06.00.01"
    },
    {
        "id": 1938,
        "label": "Rebaseamento em prótese superior ou inferior",
        "k": "50",
        "c": "20",
        "code": "38.06.00.02"
    },
    {
        "id": 1939,
        "label": "Rebaseamento em resina mole",
        "k": "60",
        "c": "20",
        "code": "38.06.00.03"
    },
    {
        "id": 1940,
        "label": "Barra em aço inoxidável",
        "k": "12",
        "c": "12",
        "code": "38.06.00.04"
    },
    {
        "id": 1941,
        "label": "Conserto de fractura de prótese acrílica",
        "k": "21",
        "c": "15",
        "code": "38.06.00.05"
    },
    {
        "id": 1942,
        "label": "Acrescentar um dente numa prótese",
        "k": "23",
        "c": "15",
        "code": "38.06.00.06"
    },
    {
        "id": 1943,
        "label": "Acrescentar mais de um dente numa prótese: por cada dente mais",
        "k": "4",
        "c": "15",
        "code": "38.06.00.07"
    },
    {
        "id": 1944,
        "label": "Goteira oclusal simples",
        "k": "20",
        "c": "50",
        "code": "38.06.00.08"
    },
    {
        "id": 1945,
        "label": "Soldadura em prótese de cromo-cobalto",
        "k": "10",
        "c": "14",
        "code": "38.06.00.09"
    },
    {
        "id": 1946,
        "label": "Rede de cromo-cobalto",
        "k": "20",
        "c": "24",
        "code": "38.06.00.10"
    },
    {
        "id": 1947,
        "label": "Barra lingual ou palatina",
        "k": "20",
        "c": "18",
        "code": "38.06.00.11"
    },
    {
        "id": 1948,
        "label": "Dente fundido em prótese em cromo-cobalto",
        "k": "10",
        "c": "14",
        "code": "38.06.00.12"
    },
    {
        "id": 1949,
        "label": "Acrescentar uma cela em prótese de cromo-cobalto",
        "k": "30",
        "c": "24",
        "code": "38.06.00.13"
    },
    {
        "id": 1950,
        "label": "Gancho fundido",
        "k": "10",
        "c": "14",
        "code": "38.06.00.14"
    },
    {
        "id": 1951,
        "label": "Face oclusal fundida",
        "k": "8",
        "c": "13",
        "code": "38.06.00.15"
    },
    {
        "id": 1952,
        "label": "Obtenção de modelos para análise oclusal",
        "k": "20",
        "c": "20",
        "code": "38.07.00.01"
    },
    {
        "id": 1953,
        "label": "Montagem de modelos em articulador semifuncional sem registos individuais mas com arco facial (valores médicos) e análise",
        "k": "80",
        "c": "80",
        "code": "38.07.00.02"
    },
    {
        "id": 1954,
        "label": "Equilíbrio oclusal clínico (por sessão)",
        "k": "50",
        "c": "50",
        "code": "38.07.00.03"
    },
    {
        "id": 1955,
        "label": "Montagem de modelos em articulador semifuncional com uso de arco facial ajustado e de arco localizador cinemático, e com registos individuais",
        "k": "300",
        "c": "250",
        "code": "38.07.00.04"
    },
    {
        "id": 1956,
        "label": "Equilíbrio oclusal do paciente de acordo com os valores obtidos no articulador",
        "k": "100",
        "c": "100",
        "code": "38.07.00.05"
    },
    {
        "id": 1957,
        "label": "Cirurgia para colocação de implantes",
        "k": "50",
        "c": "60",
        "code": "38.08.00.01"
    },
    {
        "id": 1958,
        "label": "Implante utilizado (por cada implante)",
        "k": "0",
        "c": "300",
        "code": "38.08.00.02"
    },
    {
        "id": 1959,
        "label": "Ressecção do bordo livre com avanço da mucosa",
        "k": "80",
        "c": "0",
        "code": "39.00.00.01"
    },
    {
        "id": 1960,
        "label": "Excisão em cunha com encerramento directo",
        "k": "70",
        "c": "0",
        "code": "39.00.00.02"
    },
    {
        "id": 1961,
        "label": "Ressecção maior que 1?4 com reconstrução",
        "k": "150",
        "c": "0",
        "code": "39.00.00.03"
    },
    {
        "id": 1962,
        "label": "Ressecção total do lábio inferior ou superior com reconstrução",
        "k": "250",
        "c": "0",
        "code": "39.00.00.04"
    },
    {
        "id": 1963,
        "label": "Tratamento cirúrgico de fenda labial completa unilateral",
        "k": "160",
        "c": "0",
        "code": "39.00.00.05"
    },
    {
        "id": 1964,
        "label": "Tratamento cirúrgico de fenda palatina parcial",
        "k": "130",
        "c": "0",
        "code": "39.00.00.06"
    },
    {
        "id": 2405,
        "label": "Uretrectomia total",
        "k": "150",
        "c": "0",
        "code": "40.04.00.26"
    },
    {
        "id": 1965,
        "label": "Tratamento cirúrgico da fenda labial bilateral",
        "k": "240",
        "c": "0",
        "code": "39.00.00.07"
    },
    {
        "id": 1966,
        "label": "Tratamento cirúrgico de fenda labial tempos complementares",
        "k": "90",
        "c": "0",
        "code": "39.00.00.08"
    },
    {
        "id": 1967,
        "label": "Tratamento de outras malformações congénitas dos lábios cada tempo",
        "k": "100",
        "c": "0",
        "code": "39.00.00.09"
    },
    {
        "id": 1968,
        "label": "Tratamento cirúrgico de fenda completa unilateral do paladar primário",
        "k": "140",
        "c": "0",
        "code": "39.00.00.10"
    },
    {
        "id": 1969,
        "label": "Tratamento cirúrgico de fenda bilateral (cada lado) do paladar primário",
        "k": "110",
        "c": "0",
        "code": "39.00.00.11"
    },
    {
        "id": 1970,
        "label": "Tratamento cirúrgico de fenda do paladar primário tempos complementares",
        "k": "80",
        "c": "0",
        "code": "39.00.00.12"
    },
    {
        "id": 1971,
        "label": "Fístulas congénitas labiais",
        "k": "90",
        "c": "0",
        "code": "39.00.00.13"
    },
    {
        "id": 1972,
        "label": "Drenagem de quistos, abcessos, hematomas",
        "k": "20",
        "c": "0",
        "code": "39.01.00.01"
    },
    {
        "id": 1973,
        "label": "Plastia do freio lingual",
        "k": "25",
        "c": "0",
        "code": "39.01.00.02"
    },
    {
        "id": 1974,
        "label": "Excisão de lesão da mucosa ou sub-mucosa",
        "k": "30",
        "c": "0",
        "code": "39.01.00.03"
    },
    {
        "id": 1975,
        "label": "Excisão de lesão da mucosa ou sub-mucosa com plastia",
        "k": "55",
        "c": "0",
        "code": "39.01.00.04"
    },
    {
        "id": 1976,
        "label": "Sutura de laceração superficial",
        "k": "25",
        "c": "0",
        "code": "39.01.00.05"
    },
    {
        "id": 1977,
        "label": "Sutura de laceração com mais de 2 cm, profunda",
        "k": "30",
        "c": "0",
        "code": "39.01.00.06"
    },
    {
        "id": 1978,
        "label": "Vestibuloplastia por quadrante",
        "k": "30",
        "c": "0",
        "code": "39.01.00.07"
    },
    {
        "id": 1979,
        "label": "Incisão e drenagem de quistos, abcessos intra-orais ou hematomas da língua ou pavimento da boca - superficiais",
        "k": "20",
        "c": "0",
        "code": "39.02.00.01"
    },
    {
        "id": 1980,
        "label": "Incisão e drenagem de quistos, abcessos intra-orais ou hematomas da língua ou pavimento da boca - profundos",
        "k": "25",
        "c": "0",
        "code": "39.02.00.02"
    },
    {
        "id": 1981,
        "label": "Incisão e drenagem extra-oral de abcesso, quisto e/ou hematoma do pavimento da boca ou sublingual",
        "k": "30",
        "c": "0",
        "code": "39.02.00.03"
    },
    {
        "id": 1982,
        "label": "Excisão de lesão da língua localizada nos 2/3 anteriores",
        "k": "35",
        "c": "0",
        "code": "39.02.00.04"
    },
    {
        "id": 1983,
        "label": "Excisão de lesão da língua localizada no 1/3 posterior",
        "k": "50",
        "c": "0",
        "code": "39.02.00.05"
    },
    {
        "id": 1984,
        "label": "Excisão de lesão do pavimento da boca",
        "k": "30",
        "c": "0",
        "code": "39.02.00.06"
    },
    {
        "id": 1985,
        "label": "Glossectomia menor que 1?2 da língua",
        "k": "70",
        "c": "0",
        "code": "39.02.00.07"
    },
    {
        "id": 1986,
        "label": "Hemiglossectomia",
        "k": "100",
        "c": "0",
        "code": "39.02.00.08"
    },
    {
        "id": 1987,
        "label": "Hemiglossectomia com esvasiamento unilateral do pescoço",
        "k": "220",
        "c": "0",
        "code": "39.02.00.09"
    },
    {
        "id": 1988,
        "label": "Glossectomia total, sem esvasiamento cervical",
        "k": "150",
        "c": "0",
        "code": "39.02.00.10"
    },
    {
        "id": 1989,
        "label": "Glossectomia total, com esvasiamento unilateral",
        "k": "220",
        "c": "0",
        "code": "39.02.00.11"
    },
    {
        "id": 1990,
        "label": "Glossectomia total com esvasiamento bilateral",
        "k": "320",
        "c": "0",
        "code": "39.02.00.12"
    },
    {
        "id": 1991,
        "label": "Glossectomia com ressecção do pavimento da boca e mandíbula",
        "k": "250",
        "c": "0",
        "code": "39.02.00.13"
    },
    {
        "id": 1992,
        "label": "Glossectomia com ressecção do pavimento da boca e mandíbula com esvaziamento cervical",
        "k": "320",
        "c": "0",
        "code": "39.02.00.14"
    },
    {
        "id": 1993,
        "label": "Reparação de laceração até 2 cm do pavimento ou dos 2/3 anteriores da língua",
        "k": "20",
        "c": "0",
        "code": "39.02.00.15"
    },
    {
        "id": 1994,
        "label": "Reparação de laceração do 1/3 posterior da língua",
        "k": "25",
        "c": "0",
        "code": "39.02.00.16"
    },
    {
        "id": 1995,
        "label": "Reparação de laceração do pavimento ou língua (mais de 2 cm)",
        "k": "30",
        "c": "0",
        "code": "39.02.00.17"
    },
    {
        "id": 1996,
        "label": "Drenagem de abcesso do palato ou úvula",
        "k": "20",
        "c": "0",
        "code": "39.03.00.01"
    },
    {
        "id": 1997,
        "label": "Excisão de lesão do palato ou úvula",
        "k": "30",
        "c": "0",
        "code": "39.03.00.02"
    },
    {
        "id": 1998,
        "label": "Excisão de exostose do palato",
        "k": "25",
        "c": "0",
        "code": "39.03.00.03"
    },
    {
        "id": 1999,
        "label": "Sutura de laceração do palato até 2 cm",
        "k": "25",
        "c": "0",
        "code": "39.03.00.04"
    },
    {
        "id": 2000,
        "label": "Sutura de laceração do palato mais de 2 cm",
        "k": "50",
        "c": "0",
        "code": "39.03.00.05"
    },
    {
        "id": 2001,
        "label": "Palotoplastia para tratamento de ferida (palato mole)",
        "k": "110",
        "c": "0",
        "code": "39.03.00.06"
    },
    {
        "id": 2002,
        "label": "Retalho osteo periósteo ou enxerto ósseo em fenda alveolo palatina",
        "k": "120",
        "c": "0",
        "code": "39.03.00.07"
    },
    {
        "id": 2003,
        "label": "Estafilorrafia por fenda palatina incompleta ou estafilorrafia simples",
        "k": "125",
        "c": "0",
        "code": "39.03.00.08"
    },
    {
        "id": 2004,
        "label": "Uranoestafilorrafia por fenda palatina completa",
        "k": "150",
        "c": "0",
        "code": "39.03.00.09"
    },
    {
        "id": 2005,
        "label": "Reconstrução do palato anterior em fenda alveolo-palatina",
        "k": "125",
        "c": "0",
        "code": "39.03.00.10"
    },
    {
        "id": 2006,
        "label": "Tratamento cirúrgico de fístula oroantral",
        "k": "110",
        "c": "0",
        "code": "39.03.00.11"
    },
    {
        "id": 2007,
        "label": "Palatoplastia para correcção de roncopatia",
        "k": "120",
        "c": "0",
        "code": "39.03.00.12"
    },
    {
        "id": 2008,
        "label": "Adenoidectomia (Laforce-Beckman)",
        "k": "20",
        "c": "0",
        "code": "39.04.00.01"
    },
    {
        "id": 2009,
        "label": "Idem, com anestesia geral e intubação endotraqueal",
        "k": "60",
        "c": "0",
        "code": "39.04.00.02"
    },
    {
        "id": 2010,
        "label": "Amigdalectomia por Sluder",
        "k": "30",
        "c": "0",
        "code": "39.04.00.03"
    },
    {
        "id": 2011,
        "label": "Idem, por dissecção, com anestesia geral e intubação endotraqueal",
        "k": "100",
        "c": "0",
        "code": "39.04.00.04"
    },
    {
        "id": 2012,
        "label": "Adenoidectomia com amigdalectomia por Sluder-Laforce-Beckman",
        "k": "40",
        "c": "0",
        "code": "39.04.00.05"
    },
    {
        "id": 2013,
        "label": "Idem, por dissecção (com anestesia geral e intubação endotraqueal)",
        "k": "130",
        "c": "0",
        "code": "39.04.00.06"
    },
    {
        "id": 2014,
        "label": "Extracção de corpo estranho da orofaringe",
        "k": "15",
        "c": "0",
        "code": "39.04.00.07"
    },
    {
        "id": 2015,
        "label": "Idem, da hipofaringe",
        "k": "25",
        "c": "0",
        "code": "39.04.00.08"
    },
    {
        "id": 2016,
        "label": "Drenagem de abcesso amigdalino",
        "k": "20",
        "c": "0",
        "code": "39.04.00.09"
    },
    {
        "id": 2017,
        "label": "Idem, abcesso retro ou parafaríngeo, por via oral",
        "k": "30",
        "c": "0",
        "code": "39.04.00.10"
    },
    {
        "id": 2018,
        "label": "Idem, por via externa",
        "k": "40",
        "c": "0",
        "code": "39.04.00.11"
    },
    {
        "id": 2019,
        "label": "Faringoplastia em sequela de ferida palatina",
        "k": "130",
        "c": "0",
        "code": "39.04.00.12"
    },
    {
        "id": 2020,
        "label": "Faringoplastia em sequela de fenda palatina",
        "k": "130",
        "c": "0",
        "code": "39.04.00.13"
    },
    {
        "id": 2021,
        "label": "Encerramento de faringostoma, por cada tempo operatório",
        "k": "100",
        "c": "0",
        "code": "39.04.00.14"
    },
    {
        "id": 2022,
        "label": "Faringotomia",
        "k": "100",
        "c": "0",
        "code": "39.04.00.15"
    },
    {
        "id": 2023,
        "label": "Extirpação das apófises estiloideias",
        "k": "70",
        "c": "0",
        "code": "39.04.00.16"
    },
    {
        "id": 2024,
        "label": "Extirpação de fístula ou quisto branquial, amigdalino, etc.",
        "k": "110",
        "c": "0",
        "code": "39.04.00.17"
    },
    {
        "id": 2025,
        "label": "Correcção de faringotomia com retalho",
        "k": "160",
        "c": "0",
        "code": "39.04.00.18"
    },
    {
        "id": 2026,
        "label": "Exérese de tumor parafaringeo",
        "k": "210",
        "c": "0",
        "code": "39.04.00.19"
    },
    {
        "id": 2027,
        "label": "Faringoplastia em sequela de fenda do paladar secundário",
        "k": "130",
        "c": "0",
        "code": "39.04.00.20"
    },
    {
        "id": 2028,
        "label": "Drenagem simples de abcessos (parótida, submaxilar ou sublingual)",
        "k": "15",
        "c": "0",
        "code": "39.05.00.01"
    },
    {
        "id": 2029,
        "label": "Marsupialização de quisto sublingual (rânula)",
        "k": "15",
        "c": "0",
        "code": "39.05.00.02"
    },
    {
        "id": 2030,
        "label": "Excisão de quisto sublingual ou do pavimento",
        "k": "50",
        "c": "0",
        "code": "39.05.00.03"
    },
    {
        "id": 2031,
        "label": "Parotidectomia superficial",
        "k": "210",
        "c": "0",
        "code": "39.05.00.04"
    },
    {
        "id": 2032,
        "label": "Parotidectomia total com sacrifício do nervo facial",
        "k": "210",
        "c": "0",
        "code": "39.05.00.05"
    },
    {
        "id": 2033,
        "label": "Parotidectomia total com dissecção e conservação do nervo facial",
        "k": "310",
        "c": "0",
        "code": "39.05.00.06"
    },
    {
        "id": 2034,
        "label": "Parotidectomia total com reconstrução do nervo facial",
        "k": "320",
        "c": "0",
        "code": "39.05.00.07"
    },
    {
        "id": 2035,
        "label": "Excisão de glândula submaxilar",
        "k": "90",
        "c": "0",
        "code": "39.05.00.08"
    },
    {
        "id": 2036,
        "label": "Excisão de glândula sublingual",
        "k": "70",
        "c": "0",
        "code": "39.05.00.09"
    },
    {
        "id": 2037,
        "label": "Injecção para sialografia com dilatação dos canais salivares",
        "k": "15",
        "c": "0",
        "code": "39.05.00.10"
    },
    {
        "id": 2038,
        "label": "Excisão de cálculos dos canais salivares por via endobucal",
        "k": "40",
        "c": "0",
        "code": "39.05.00.11"
    },
    {
        "id": 2039,
        "label": "Excisão de glândulas salivares aberrantes",
        "k": "70",
        "c": "0",
        "code": "39.05.00.12"
    },
    {
        "id": 2040,
        "label": "Esofagotomia cervical",
        "k": "110",
        "c": "0",
        "code": "39.06.00.01"
    },
    {
        "id": 2041,
        "label": "Esofagotomia torácica",
        "k": "180",
        "c": "0",
        "code": "39.06.00.02"
    },
    {
        "id": 2042,
        "label": "Miotomia cricofaríngea",
        "k": "110",
        "c": "0",
        "code": "39.06.00.03"
    },
    {
        "id": 2043,
        "label": "Operação de Heller",
        "k": "200",
        "c": "0",
        "code": "39.06.00.04"
    },
    {
        "id": 2044,
        "label": "Esofagectomia cervical (operação tipo Wookey)",
        "k": "160",
        "c": "0",
        "code": "39.06.00.05"
    },
    {
        "id": 2045,
        "label": "Esofagectomia sub-total com reconstituição da continuidade",
        "k": "400",
        "c": "0",
        "code": "39.06.00.06"
    },
    {
        "id": 2046,
        "label": "Esofagectomia da 1/3 inferior com reconstituição da continuidade",
        "k": "250",
        "c": "0",
        "code": "39.06.00.07"
    },
    {
        "id": 2047,
        "label": "Diverticulectomia de Zenker",
        "k": "180",
        "c": "0",
        "code": "39.06.00.08"
    },
    {
        "id": 2048,
        "label": "Esofagostomia",
        "k": "110",
        "c": "0",
        "code": "39.06.00.09"
    },
    {
        "id": 2049,
        "label": "Esofagoplastia, por atrésia do esófago",
        "k": "400",
        "c": "0",
        "code": "39.06.00.10"
    },
    {
        "id": 2050,
        "label": "Laqueação de fístula esófago-traqueal",
        "k": "300",
        "c": "0",
        "code": "39.06.00.11"
    },
    {
        "id": 2051,
        "label": "Sutura de varizes esofágicas",
        "k": "200",
        "c": "0",
        "code": "39.06.00.12"
    },
    {
        "id": 2052,
        "label": "Diverticulectomia do terço médio e inferior",
        "k": "250",
        "c": "0",
        "code": "39.06.00.13"
    },
    {
        "id": 2053,
        "label": "Gastrotomia",
        "k": "110",
        "c": "0",
        "code": "39.07.00.01"
    },
    {
        "id": 2054,
        "label": "Piloromiotomia",
        "k": "130",
        "c": "0",
        "code": "39.07.00.02"
    },
    {
        "id": 2055,
        "label": "Gastrotomia com excisão de úlcera ou tumor",
        "k": "120",
        "c": "0",
        "code": "39.07.00.03"
    },
    {
        "id": 2056,
        "label": "Gastrectomia parcial ou sub-total",
        "k": "200",
        "c": "0",
        "code": "39.07.00.04"
    },
    {
        "id": 2057,
        "label": "Gastrectomia total",
        "k": "300",
        "c": "0",
        "code": "39.07.00.05"
    },
    {
        "id": 2058,
        "label": "Desgastrogastrectomia",
        "k": "300",
        "c": "0",
        "code": "39.07.00.06"
    },
    {
        "id": 2059,
        "label": "Gastrectomia sub-total radical",
        "k": "250",
        "c": "0",
        "code": "39.07.00.07"
    },
    {
        "id": 2060,
        "label": "Gastrenterostomia",
        "k": "130",
        "c": "0",
        "code": "39.07.00.08"
    },
    {
        "id": 2061,
        "label": "Gastrorrafia, sutura de úlcera perfurada ou ferida",
        "k": "130",
        "c": "0",
        "code": "39.07.00.09"
    },
    {
        "id": 2062,
        "label": "Piloroplastia",
        "k": "130",
        "c": "0",
        "code": "39.07.00.10"
    },
    {
        "id": 2063,
        "label": "Gastrostomia",
        "k": "130",
        "c": "0",
        "code": "39.07.00.11"
    },
    {
        "id": 2064,
        "label": "Revisão de anastomose gastroduodenal ou gastrojejunal com reconstrução",
        "k": "250",
        "c": "0",
        "code": "39.07.00.12"
    },
    {
        "id": 2065,
        "label": "Vagotomia troncular ou selectiva",
        "k": "160",
        "c": "0",
        "code": "39.07.00.13"
    },
    {
        "id": 2066,
        "label": "Vagotomia super selectiva",
        "k": "180",
        "c": "0",
        "code": "39.07.00.14"
    },
    {
        "id": 2067,
        "label": "Enterolise de aderências",
        "k": "110",
        "c": "0",
        "code": "39.08.00.01"
    },
    {
        "id": 2068,
        "label": "Duodenotomia",
        "k": "110",
        "c": "0",
        "code": "39.08.00.02"
    },
    {
        "id": 2069,
        "label": "Enterotomia",
        "k": "110",
        "c": "0",
        "code": "39.08.00.03"
    },
    {
        "id": 2070,
        "label": "Colotomia",
        "k": "110",
        "c": "0",
        "code": "39.08.00.04"
    },
    {
        "id": 2071,
        "label": "Enterostomia ou cecostomia",
        "k": "120",
        "c": "0",
        "code": "39.08.00.05"
    },
    {
        "id": 2072,
        "label": "Ileostomia «continente»",
        "k": "180",
        "c": "0",
        "code": "39.08.00.06"
    },
    {
        "id": 2073,
        "label": "Revisão da ileostomia",
        "k": "100",
        "c": "0",
        "code": "39.08.00.07"
    },
    {
        "id": 2074,
        "label": "Colostomia",
        "k": "140",
        "c": "0",
        "code": "39.08.00.08"
    },
    {
        "id": 2075,
        "label": "Revisão da colostomia, simples",
        "k": "110",
        "c": "0",
        "code": "39.08.00.09"
    },
    {
        "id": 2076,
        "label": "Excisão de pequenas lesões não requerendo anastomose ou exteriorização",
        "k": "120",
        "c": "0",
        "code": "39.08.00.10"
    },
    {
        "id": 2077,
        "label": "Enterectomia",
        "k": "140",
        "c": "0",
        "code": "39.08.00.11"
    },
    {
        "id": 2078,
        "label": "Enteroenterostomia",
        "k": "130",
        "c": "0",
        "code": "39.08.00.12"
    },
    {
        "id": 2079,
        "label": "Colectomia segmentar",
        "k": "180",
        "c": "0",
        "code": "39.08.00.13"
    },
    {
        "id": 2080,
        "label": "Hemicolectomia",
        "k": "200",
        "c": "0",
        "code": "39.08.00.14"
    },
    {
        "id": 2081,
        "label": "Colectomia com coloproctostomia",
        "k": "300",
        "c": "0",
        "code": "39.08.00.15"
    },
    {
        "id": 2082,
        "label": "Colectomia tipo Hartmann",
        "k": "160",
        "c": "0",
        "code": "39.08.00.16"
    },
    {
        "id": 2083,
        "label": "Colectomia com colostomia e criação de fístula mucosa",
        "k": "160",
        "c": "0",
        "code": "39.08.00.17"
    },
    {
        "id": 2084,
        "label": "Colectomia total",
        "k": "300",
        "c": "0",
        "code": "39.08.00.20"
    },
    {
        "id": 2085,
        "label": "Proctolectomia",
        "k": "350",
        "c": "0",
        "code": "39.08.00.21"
    },
    {
        "id": 2086,
        "label": "Tratamento cirúrgico de duplicação intestinal simples",
        "k": "120",
        "c": "0",
        "code": "39.08.00.22"
    },
    {
        "id": 2087,
        "label": "Tratamento cirúrgico de duplicação intestinal complexa",
        "k": "200",
        "c": "0",
        "code": "39.08.00.23"
    },
    {
        "id": 2088,
        "label": "Tratamento cirúrgico de ileus meconial",
        "k": "220",
        "c": "0",
        "code": "39.08.00.24"
    },
    {
        "id": 2089,
        "label": "Enterorrafia",
        "k": "130",
        "c": "0",
        "code": "39.08.00.25"
    },
    {
        "id": 2090,
        "label": "Encerramento de enterostomia ou colostomia",
        "k": "130",
        "c": "0",
        "code": "39.08.00.26"
    },
    {
        "id": 2091,
        "label": "Encerramento de fistulas intestinais",
        "k": "150",
        "c": "0",
        "code": "39.08.00.27"
    },
    {
        "id": 2092,
        "label": "Plicatura do intestino (tipo Noble)",
        "k": "150",
        "c": "0",
        "code": "39.08.00.28"
    },
    {
        "id": 2093,
        "label": "Tratamento cirúrgico da atrésia do duodeno, jejuno, ileon ou colon",
        "k": "220",
        "c": "0",
        "code": "39.08.00.29"
    },
    {
        "id": 2094,
        "label": "Coloprotectomia conservadora com reservatório ileo-anal",
        "k": "380",
        "c": "0",
        "code": "39.08.00.30"
    },
    {
        "id": 2095,
        "label": "Diverticulectomia",
        "k": "130",
        "c": "0",
        "code": "39.09.00.01"
    },
    {
        "id": 2096,
        "label": "Exérese de tumor do mesentério",
        "k": "160",
        "c": "0",
        "code": "39.09.00.02"
    },
    {
        "id": 2097,
        "label": "Sutura de mesentério (laceração e hérnia interna)",
        "k": "130",
        "c": "0",
        "code": "39.09.00.03"
    },
    {
        "id": 2098,
        "label": "Apendicectomia",
        "k": "110",
        "c": "0",
        "code": "39.09.00.04"
    },
    {
        "id": 2099,
        "label": "Incisão e drenagem de abcesso apendicular",
        "k": "90",
        "c": "0",
        "code": "39.09.00.05"
    },
    {
        "id": 2100,
        "label": "Tratamento cirúrgico de malrotação intestinal",
        "k": "160",
        "c": "0",
        "code": "39.09.00.06"
    },
    {
        "id": 2101,
        "label": "Drenagem Transrectal de abcesso perirectal",
        "k": "90",
        "c": "0",
        "code": "39.10.00.01"
    },
    {
        "id": 2102,
        "label": "Ressecção anterior de recto",
        "k": "250",
        "c": "0",
        "code": "39.10.00.02"
    },
    {
        "id": 2103,
        "label": "Ressecção anterior de recto (1/3 médio e inferior)",
        "k": "300",
        "c": "0",
        "code": "39.10.00.03"
    },
    {
        "id": 2104,
        "label": "Ressecção abdominoperineal do recto",
        "k": "300",
        "c": "0",
        "code": "39.10.00.04"
    },
    {
        "id": 2105,
        "label": "Protectomia com anastomose anal (Pull-Through)",
        "k": "300",
        "c": "0",
        "code": "39.10.00.05"
    },
    {
        "id": 2106,
        "label": "Tratamento de prolapso rectal por via abdominal ou perineal",
        "k": "160",
        "c": "0",
        "code": "39.10.00.06"
    },
    {
        "id": 2107,
        "label": "Tratamento cirúrgico de doença de Hirschsprung",
        "k": "300",
        "c": "0",
        "code": "39.10.00.07"
    },
    {
        "id": 2108,
        "label": "Ressecção de tumor benigno por via transagrada e/ou transcoccígea (tipo Kraske)",
        "k": "180",
        "c": "0",
        "code": "39.10.00.08"
    },
    {
        "id": 2109,
        "label": "Ressecção de tumor maligno por via transagrada e/ou transcoccigea (tipo Kraske)",
        "k": "250",
        "c": "0",
        "code": "39.10.00.09"
    },
    {
        "id": 2110,
        "label": "Excisão, electrocoagulação, criocoagulação ou laser de tumor do recto",
        "k": "70",
        "c": "0",
        "code": "39.10.00.10"
    },
    {
        "id": 2111,
        "label": "Ressecção de teratoma pré sagrado",
        "k": "220",
        "c": "0",
        "code": "39.10.00.11"
    },
    {
        "id": 2112,
        "label": "Incisão e drenagem de abcesso da margem do anus",
        "k": "20",
        "c": "0",
        "code": "39.11.00.01"
    },
    {
        "id": 2113,
        "label": "Esfincterotomia com ou sem fissurectomia",
        "k": "70",
        "c": "0",
        "code": "39.11.00.02"
    },
    {
        "id": 2114,
        "label": "Hemorroidectomia",
        "k": "100",
        "c": "0",
        "code": "39.11.00.03"
    },
    {
        "id": 2115,
        "label": "Fistulectomia por fístula perineo-rectal",
        "k": "120",
        "c": "0",
        "code": "39.11.00.04"
    },
    {
        "id": 2116,
        "label": "Criptectomia",
        "k": "40",
        "c": "0",
        "code": "39.11.00.05"
    },
    {
        "id": 2117,
        "label": "Cerclage do anus",
        "k": "50",
        "c": "0",
        "code": "39.11.00.06"
    },
    {
        "id": 2118,
        "label": "Dilatação anal, sob anestesia geral",
        "k": "20",
        "c": "0",
        "code": "39.11.00.07"
    },
    {
        "id": 2119,
        "label": "Tratamento cirúrgico da agenesia ano-rectal (forma alta)",
        "k": "300",
        "c": "0",
        "code": "39.11.00.08"
    },
    {
        "id": 2120,
        "label": "Tratamento cirúrgico da agenesia ano-rectal (forma baixa)",
        "k": "100",
        "c": "0",
        "code": "39.11.00.09"
    },
    {
        "id": 2121,
        "label": "Esfincteroplastia, por incontinência anal",
        "k": "110",
        "c": "0",
        "code": "39.11.00.10"
    },
    {
        "id": 2122,
        "label": "Transplante do recto interno",
        "k": "180",
        "c": "0",
        "code": "39.11.00.11"
    },
    {
        "id": 2123,
        "label": "Transplante muscular livre",
        "k": "220",
        "c": "0",
        "code": "39.11.00.12"
    },
    {
        "id": 2124,
        "label": "Incisão de trombose hemorroidária",
        "k": "20",
        "c": "0",
        "code": "39.11.00.13"
    },
    {
        "id": 2125,
        "label": "Hepatectomia parcial atípica",
        "k": "190",
        "c": "0",
        "code": "39.12.00.01"
    },
    {
        "id": 2126,
        "label": "Hepatectomia regrada direita",
        "k": "450",
        "c": "0",
        "code": "39.12.00.02"
    },
    {
        "id": 2127,
        "label": "Hepatectomia regrada esquerda",
        "k": "350",
        "c": "0",
        "code": "39.12.00.03"
    },
    {
        "id": 2128,
        "label": "Marsupialização ou excisão de quisto ou absesso",
        "k": "130",
        "c": "0",
        "code": "39.12.00.04"
    },
    {
        "id": 2129,
        "label": "Segmentectomia hepática",
        "k": "220",
        "c": "0",
        "code": "39.12.00.05"
    },
    {
        "id": 2130,
        "label": "Cateterização cirúrgica da artéria hepática para tratamento complementar",
        "k": "220",
        "c": "0",
        "code": "39.12.00.06"
    },
    {
        "id": 2131,
        "label": "Tratamento de quisto hidático simples",
        "k": "150",
        "c": "0",
        "code": "39.12.00.07"
    },
    {
        "id": 2132,
        "label": "Periquistectomia",
        "k": "300",
        "c": "0",
        "code": "39.12.00.08"
    },
    {
        "id": 2133,
        "label": "Tratamento dos traumatismos hepáticos grau 1 e 2",
        "k": "200",
        "c": "0",
        "code": "39.12.00.09"
    },
    {
        "id": 2134,
        "label": "Tratamento de traumatismos hepáticos grau 3, 4 e 5",
        "k": "350",
        "c": "0",
        "code": "39.12.00.10"
    },
    {
        "id": 2135,
        "label": "Colecistectomia com ou sem colangiografia",
        "k": "160",
        "c": "0",
        "code": "39.13.00.01"
    },
    {
        "id": 2136,
        "label": "Colecistectomia com coledocotomia",
        "k": "180",
        "c": "0",
        "code": "39.13.00.02"
    },
    {
        "id": 2137,
        "label": "Colecistectomia com esfincteroplastia",
        "k": "230",
        "c": "0",
        "code": "39.13.00.03"
    },
    {
        "id": 2138,
        "label": "Coledocotomia com ou sem colecistectomia",
        "k": "180",
        "c": "0",
        "code": "39.13.00.04"
    },
    {
        "id": 2139,
        "label": "Coledocotomia com esfincteroplastia",
        "k": "240",
        "c": "0",
        "code": "39.13.00.05"
    },
    {
        "id": 2140,
        "label": "Hepaticotomia para excisão de cálculo",
        "k": "200",
        "c": "0",
        "code": "39.13.00.06"
    },
    {
        "id": 2141,
        "label": "Esfincteroplastia transduodenal (operação isolada)",
        "k": "190",
        "c": "0",
        "code": "39.13.00.07"
    },
    {
        "id": 2142,
        "label": "Colecistoenterostomia",
        "k": "120",
        "c": "0",
        "code": "39.13.00.08"
    },
    {
        "id": 2143,
        "label": "Colecocoenterostomia",
        "k": "200",
        "c": "0",
        "code": "39.13.00.09"
    },
    {
        "id": 2144,
        "label": "Hepaticojejunostomia (Roux)",
        "k": "350",
        "c": "0",
        "code": "39.13.00.10"
    },
    {
        "id": 2145,
        "label": "Anastomose topo a topo das vias biliares",
        "k": "250",
        "c": "0",
        "code": "39.13.00.11"
    },
    {
        "id": 2146,
        "label": "Anastomose entre os ductos intra-hepáticos e o tubo digestivo",
        "k": "350",
        "c": "0",
        "code": "39.13.00.12"
    },
    {
        "id": 2147,
        "label": "Colecistostomia (operação isolada)",
        "k": "110",
        "c": "0",
        "code": "39.13.00.13"
    },
    {
        "id": 2148,
        "label": "Tratamento cirúrgico de quisto do colédoco",
        "k": "300",
        "c": "0",
        "code": "39.13.00.14"
    },
    {
        "id": 2149,
        "label": "Excisão de tumor de Klatskin",
        "k": "400",
        "c": "0",
        "code": "39.13.00.15"
    },
    {
        "id": 2150,
        "label": "Entubação transtumoral de tumor das vias biliares",
        "k": "180",
        "c": "0",
        "code": "39.13.00.16"
    },
    {
        "id": 2151,
        "label": "Duodenopancreatectomia (tipo Whipple)",
        "k": "450",
        "c": "0",
        "code": "39.14.00.01"
    },
    {
        "id": 2152,
        "label": "Pancreatectomia distal com esplenectomia",
        "k": "250",
        "c": "0",
        "code": "39.14.00.02"
    },
    {
        "id": 2153,
        "label": "Pancreatectomia distal sem esplenectomia",
        "k": "310",
        "c": "0",
        "code": "39.14.00.03"
    },
    {
        "id": 2154,
        "label": "Pancreatectomia «quase total» (tipo Chili)",
        "k": "350",
        "c": "0",
        "code": "39.14.00.04"
    },
    {
        "id": 2155,
        "label": "Exérese de lesão tumoral do pâncreas",
        "k": "220",
        "c": "0",
        "code": "39.14.00.05"
    },
    {
        "id": 2156,
        "label": "Pancreato jejunostomia (tipo Puestow)",
        "k": "350",
        "c": "0",
        "code": "39.14.00.06"
    },
    {
        "id": 2157,
        "label": "Pancreato jejunostomia (tipo Duval)",
        "k": "200",
        "c": "0",
        "code": "39.14.00.07"
    },
    {
        "id": 2158,
        "label": "Cistojejunostomia ou cistogastrostomia",
        "k": "200",
        "c": "0",
        "code": "39.14.00.08"
    },
    {
        "id": 2159,
        "label": "Laparotomia exploradora (operação isolada)",
        "k": "100",
        "c": "0",
        "code": "39.15.00.01"
    },
    {
        "id": 2160,
        "label": "Laparotomia para drenagem de abcesso peritoneal ou retroperitoneal (excepto apêndice)",
        "k": "120",
        "c": "0",
        "code": "39.15.00.02"
    },
    {
        "id": 2161,
        "label": "Laparotomia por perfuração de víscera oca (excepto apêndice)",
        "k": "130",
        "c": "0",
        "code": "39.15.00.03"
    },
    {
        "id": 2162,
        "label": "Exérese de tumor benigno ou quistos retroperitoneais, via abdominal",
        "k": "250",
        "c": "0",
        "code": "39.15.00.04"
    },
    {
        "id": 2163,
        "label": "Exérese de tumor maligno retroperitoneal via abdominal",
        "k": "320",
        "c": "0",
        "code": "39.15.00.05"
    },
    {
        "id": 2164,
        "label": "Exérese de tumor ou quistos retroperitoneais, via toracoabdominal",
        "k": "350",
        "c": "0",
        "code": "39.15.00.06"
    },
    {
        "id": 2165,
        "label": "Omentectomia total (operação isolada)",
        "k": "160",
        "c": "0",
        "code": "39.15.00.07"
    },
    {
        "id": 2166,
        "label": "Tratamento cirurgico de onfalocelo - vários tempos",
        "k": "300",
        "c": "0",
        "code": "39.15.00.08"
    },
    {
        "id": 2167,
        "label": "Tratamento cirurgico de onfalocelo - um tempo",
        "k": "100",
        "c": "0",
        "code": "39.15.00.09"
    },
    {
        "id": 2168,
        "label": "Tratamento de hérnia inguinal",
        "k": "100",
        "c": "0",
        "code": "39.15.00.10"
    },
    {
        "id": 2169,
        "label": "Tratamento de hérnia crural",
        "k": "110",
        "c": "0",
        "code": "39.15.00.11"
    },
    {
        "id": 2170,
        "label": "Tratamento de hérnia lombar, obturadora ou isquiática",
        "k": "150",
        "c": "0",
        "code": "39.15.00.12"
    },
    {
        "id": 2171,
        "label": "Tratamento de hérnia umbilical",
        "k": "90",
        "c": "0",
        "code": "39.15.00.13"
    },
    {
        "id": 2172,
        "label": "Tratamento de hérnia epigástrica",
        "k": "90",
        "c": "0",
        "code": "39.15.00.14"
    },
    {
        "id": 2173,
        "label": "Tratamento de hérnia de Spiegel",
        "k": "120",
        "c": "0",
        "code": "39.15.00.15"
    },
    {
        "id": 2174,
        "label": "Tratamento de hérnia incisional",
        "k": "130",
        "c": "0",
        "code": "39.15.00.16"
    },
    {
        "id": 2175,
        "label": "Tratamento de hérnia estrangulada, a acrescentar ao valor da respectiva localização",
        "k": "25",
        "c": "0",
        "code": "39.15.00.17"
    },
    {
        "id": 2176,
        "label": "Tratamento de hérnia com ressecção intestinal, a acrescentar ao valor da respectiva localização",
        "k": "45",
        "c": "0",
        "code": "39.15.00.18"
    },
    {
        "id": 2177,
        "label": "Omentoplastia pediculada",
        "k": "160",
        "c": "0",
        "code": "39.15.00.19"
    },
    {
        "id": 2178,
        "label": "Sutura de evisceração post-operatória",
        "k": "90",
        "c": "0",
        "code": "39.15.00.20"
    },
    {
        "id": 2179,
        "label": "Tratamento de perda de substância da parede abdominal-enxertos (fascia lata, dérmico, rede, etc.)",
        "k": "160",
        "c": "0",
        "code": "39.15.00.21"
    },
    {
        "id": 2180,
        "label": "Lombotomia exploradora e exploração cirúrgica retroperitoneal",
        "k": "120",
        "c": "0",
        "code": "40.00.00.01"
    },
    {
        "id": 2181,
        "label": "Drenagem cirúrgica de hematoma, urinoma ou abcesso retroperitoneal",
        "k": "100",
        "c": "0",
        "code": "40.00.00.02"
    },
    {
        "id": 2182,
        "label": "Excisão de tumor retroperitoneal",
        "k": "180",
        "c": "0",
        "code": "40.00.00.03"
    },
    {
        "id": 2183,
        "label": "Idem por via toraco-abdominal",
        "k": "240",
        "c": "0",
        "code": "40.00.00.04"
    },
    {
        "id": 2184,
        "label": "Linfadenectomia retroperitoneal para-aórtica-cava",
        "k": "280",
        "c": "0",
        "code": "40.00.00.05"
    },
    {
        "id": 2185,
        "label": "Linfadenectomia retroperitoneal pélvica unilateral",
        "k": "145",
        "c": "0",
        "code": "40.00.00.06"
    },
    {
        "id": 2186,
        "label": "Linfadenectomia retroperitoneal pélvica bilateral",
        "k": "200",
        "c": "0",
        "code": "40.00.00.07"
    },
    {
        "id": 2187,
        "label": "Linfadenectomia retroperitoneal para-aórtico-cava e pélvica",
        "k": "350",
        "c": "0",
        "code": "40.00.00.08"
    },
    {
        "id": 2188,
        "label": "Suprarenalectomia por patologia suprarenal",
        "k": "160",
        "c": "0",
        "code": "40.00.00.09"
    },
    {
        "id": 2189,
        "label": "Suprarenalectomia no decorrer de nefrectomia radical",
        "k": "80",
        "c": "0",
        "code": "40.00.00.10"
    },
    {
        "id": 2190,
        "label": "Suprarenalectomia bilateral",
        "k": "240",
        "c": "0",
        "code": "40.00.00.11"
    },
    {
        "id": 2191,
        "label": "Cirurgia da artéria renal",
        "k": "280",
        "c": "0",
        "code": "40.00.00.12"
    },
    {
        "id": 2192,
        "label": "Cirurgia da veia renal",
        "k": "200",
        "c": "0",
        "code": "40.00.00.13"
    },
    {
        "id": 2193,
        "label": "\"Cirurgia renal \"\"ex-situ\"\"\"",
        "k": "400",
        "c": "0",
        "code": "40.00.00.14"
    },
    {
        "id": 2194,
        "label": "Auto-transplantação",
        "k": "400",
        "c": "0",
        "code": "40.00.00.15"
    },
    {
        "id": 2195,
        "label": "Transplantação de rim de cadáver ou de rim vivo",
        "k": "400",
        "c": "0",
        "code": "40.00.00.16"
    },
    {
        "id": 2196,
        "label": "Colheita de rim para transplante (de rim de cadáver ou de rim vivo)",
        "k": "180",
        "c": "0",
        "code": "40.00.00.17"
    },
    {
        "id": 2197,
        "label": "Biópsia renal cirúrgica",
        "k": "100",
        "c": "0",
        "code": "40.00.00.18"
    },
    {
        "id": 2198,
        "label": "Nefro(lito)tomia",
        "k": "180",
        "c": "0",
        "code": "40.00.00.19"
    },
    {
        "id": 2199,
        "label": "Nefro(lito)tomia anatrófica",
        "k": "250",
        "c": "0",
        "code": "40.00.00.20"
    },
    {
        "id": 2200,
        "label": "Pielo(lito)tomia simples",
        "k": "130",
        "c": "0",
        "code": "40.00.00.21"
    },
    {
        "id": 2201,
        "label": "Pielocalico(lito)tomia ou pielonefro(lito)tomia por litíase coraliforme ou précoraliforme",
        "k": "200",
        "c": "0",
        "code": "40.00.00.22"
    },
    {
        "id": 2202,
        "label": "Pielo(lito)tomia secundária (iterativa)",
        "k": "180",
        "c": "0",
        "code": "40.00.00.23"
    },
    {
        "id": 2203,
        "label": "Pielo(lito)tomia em malformação renal",
        "k": "180",
        "c": "0",
        "code": "40.00.00.24"
    },
    {
        "id": 2204,
        "label": "Nefrostomia ou pielostomia aberta",
        "k": "110",
        "c": "0",
        "code": "40.00.00.25"
    },
    {
        "id": 2205,
        "label": "Nefrorrafia por traumatismo–renal",
        "k": "160",
        "c": "0",
        "code": "40.00.00.26"
    },
    {
        "id": 2206,
        "label": "Encerramento da fistula pielo-cutânea",
        "k": "120",
        "c": "0",
        "code": "40.00.00.27"
    },
    {
        "id": 2207,
        "label": "Encerramento de fístula pielo-visceral",
        "k": "160",
        "c": "0",
        "code": "40.00.00.28"
    },
    {
        "id": 2208,
        "label": "Calico-ureterostomia",
        "k": "160",
        "c": "0",
        "code": "40.00.00.29"
    },
    {
        "id": 2209,
        "label": "Calicorrafia ou calicoplastia",
        "k": "160",
        "c": "0",
        "code": "40.00.00.30"
    },
    {
        "id": 2210,
        "label": "Pieloureterolise",
        "k": "130",
        "c": "0",
        "code": "40.00.00.31"
    },
    {
        "id": 2211,
        "label": "Pielorrafia",
        "k": "130",
        "c": "0",
        "code": "40.00.00.32"
    },
    {
        "id": 2212,
        "label": "Pieloplastia desmembrada tipo Anderson Hynes",
        "k": "180",
        "c": "0",
        "code": "40.00.00.33"
    },
    {
        "id": 2213,
        "label": "Outra pieloplastia desmembrada",
        "k": "180",
        "c": "0",
        "code": "40.00.00.34"
    },
    {
        "id": 2214,
        "label": "Pieloplastia não desmembrada",
        "k": "160",
        "c": "0",
        "code": "40.00.00.35"
    },
    {
        "id": 2215,
        "label": "Pieloplastia em malformação renal",
        "k": "180",
        "c": "0",
        "code": "40.00.00.36"
    },
    {
        "id": 2216,
        "label": "Nefropexia",
        "k": "110",
        "c": "0",
        "code": "40.00.00.37"
    },
    {
        "id": 2217,
        "label": "Quistectomia ou marsupialização de quisto renal",
        "k": "130",
        "c": "0",
        "code": "40.00.00.38"
    },
    {
        "id": 2218,
        "label": "Enucleação de tumor do rim",
        "k": "180",
        "c": "0",
        "code": "40.00.00.39"
    },
    {
        "id": 2219,
        "label": "Nefrectomia parcial (inclui heminefrectomia)",
        "k": "200",
        "c": "0",
        "code": "40.00.00.40"
    },
    {
        "id": 2220,
        "label": "Nefrectomia total",
        "k": "160",
        "c": "0",
        "code": "40.00.00.41"
    },
    {
        "id": 2221,
        "label": "Nefrectomia radical",
        "k": "200",
        "c": "0",
        "code": "40.00.00.42"
    },
    {
        "id": 2222,
        "label": "Nefrectomia radical com linfadenectomia para aórtico-cava",
        "k": "320",
        "c": "0",
        "code": "40.00.00.43"
    },
    {
        "id": 2223,
        "label": "Nefrectomia secundária",
        "k": "200",
        "c": "0",
        "code": "40.00.00.44"
    },
    {
        "id": 2224,
        "label": "Nefrectomia de rim ectópico",
        "k": "180",
        "c": "0",
        "code": "40.00.00.45"
    },
    {
        "id": 2225,
        "label": "Nefrectomia de rim transplantado",
        "k": "160",
        "c": "0",
        "code": "40.00.00.46"
    },
    {
        "id": 2226,
        "label": "Nefro-ureterectomia sub-total",
        "k": "200",
        "c": "0",
        "code": "40.00.00.47"
    },
    {
        "id": 2227,
        "label": "Nefro-ureterectomia com cistectomia perimeática",
        "k": "250",
        "c": "0",
        "code": "40.00.00.48"
    },
    {
        "id": 2228,
        "label": "Pielectomia com excisão de tumor piélico",
        "k": "160",
        "c": "0",
        "code": "40.00.00.49"
    },
    {
        "id": 2229,
        "label": "Cirurgia endoscópica do segmento pielo-ureteral (SPU), bacinete ou cálices com ureterorrenoscópio",
        "k": "160",
        "c": "200",
        "code": "40.00.00.50"
    },
    {
        "id": 2230,
        "label": "Biópsia renal percutânea com controle RX-Eco",
        "k": "65",
        "c": "0",
        "code": "40.00.00.51"
    },
    {
        "id": 2231,
        "label": "Nefrostomia percutânea",
        "k": "110",
        "c": "0",
        "code": "40.00.00.52"
    },
    {
        "id": 2232,
        "label": "Tratamento percutâneo de quisto renal",
        "k": "110",
        "c": "0",
        "code": "40.00.00.53"
    },
    {
        "id": 2233,
        "label": "Nefroscopia percutânea",
        "k": "160",
        "c": "200",
        "code": "40.00.00.54"
    },
    {
        "id": 2234,
        "label": "Nefro(lito)extracção percutânea com pinças ou sondas-cesto",
        "k": "180",
        "c": "200",
        "code": "40.00.00.55"
    },
    {
        "id": 2235,
        "label": "Nefro(lito)extracção percutânea com litotritor ultra-sónico, electro-hidráulico ou laser",
        "k": "200",
        "c": "300",
        "code": "40.00.00.56"
    },
    {
        "id": 2236,
        "label": "Pieloureterotomia interna",
        "k": "160",
        "c": "200",
        "code": "40.00.00.57"
    },
    {
        "id": 2237,
        "label": "Infundibulocalicotomia",
        "k": "150",
        "c": "200",
        "code": "40.00.00.58"
    },
    {
        "id": 2238,
        "label": "Ressecção percutânea de tumor do bacinete ou cálices",
        "k": "160",
        "c": "200",
        "code": "40.00.00.59"
    },
    {
        "id": 2239,
        "label": "Fotorradiação percutânea com laser de cálices, bacinete ou SPU",
        "k": "160",
        "c": "500",
        "code": "40.00.00.60"
    },
    {
        "id": 2240,
        "label": "Litotrícia extracorporal por ondas de choque (por unidade renal)",
        "k": "150",
        "c": "3000",
        "code": "40.00.00.61"
    },
    {
        "id": 2241,
        "label": "Litotrícia extracorporal por ondas de choque (sessões complementares - dentro de um periodo de 3 meses)",
        "k": "130",
        "c": "1000",
        "code": "40.00.00.62"
    },
    {
        "id": 2242,
        "label": "Uretero(lito)tomia lombar",
        "k": "130",
        "c": "0",
        "code": "40.01.00.01"
    },
    {
        "id": 2243,
        "label": "Uretero(lito)tomia ilíaca",
        "k": "120",
        "c": "0",
        "code": "40.01.00.02"
    },
    {
        "id": 2244,
        "label": "Uretero(lito)tomia pélvica",
        "k": "160",
        "c": "0",
        "code": "40.01.00.03"
    },
    {
        "id": 2245,
        "label": "Uretero(lito)tomia transvesical",
        "k": "120",
        "c": "0",
        "code": "40.01.00.04"
    },
    {
        "id": 2246,
        "label": "Uretero(lito)tomia transvaginal",
        "k": "120",
        "c": "0",
        "code": "40.01.00.05"
    },
    {
        "id": 2247,
        "label": "Ureterostomia intubada",
        "k": "120",
        "c": "0",
        "code": "40.01.00.06"
    },
    {
        "id": 2248,
        "label": "Ureterostomia cutânea directa unilateral",
        "k": "120",
        "c": "0",
        "code": "40.01.00.07"
    },
    {
        "id": 2249,
        "label": "Ureterostomia cutânea directa bilateral",
        "k": "160",
        "c": "0",
        "code": "40.01.00.08"
    },
    {
        "id": 2250,
        "label": "Ureterostomia cutânea indirecta transileal (ureteroileostomia cutânea-operação de Bricker)",
        "k": "280",
        "c": "0",
        "code": "40.01.00.09"
    },
    {
        "id": 2251,
        "label": "Ureterostomia cutânea indirecta transcólica (ureterocolostomia cutânea)",
        "k": "280",
        "c": "0",
        "code": "40.01.00.10"
    },
    {
        "id": 2252,
        "label": "Ureterostomia cutânea indirecta com bolsa intestinal continente",
        "k": "350",
        "c": "0",
        "code": "40.01.00.11"
    },
    {
        "id": 2253,
        "label": "Revisão de ureterostomia cutânea",
        "k": "120",
        "c": "0",
        "code": "40.01.00.12"
    },
    {
        "id": 2254,
        "label": "Revisão de anastomose uretero intestinal",
        "k": "200",
        "c": "0",
        "code": "40.01.00.13"
    },
    {
        "id": 2255,
        "label": "Ureterosigmoidostomia",
        "k": "180",
        "c": "0",
        "code": "40.01.00.14"
    },
    {
        "id": 2256,
        "label": "Ureterorrectostomia (bexiga rectal) com abaixamento intestinal",
        "k": "320",
        "c": "0",
        "code": "40.01.00.15"
    },
    {
        "id": 2257,
        "label": "Desderivação urinária",
        "k": "300",
        "c": "0",
        "code": "40.01.00.16"
    },
    {
        "id": 2258,
        "label": "Colocação cirúrgica de tutor ureteral",
        "k": "120",
        "c": "0",
        "code": "40.01.00.17"
    },
    {
        "id": 2260,
        "label": "Ureterocistoneostomia (Reimplantação ureterovesical) ou operação anti-refluxo sem ureteroneocistostomia",
        "k": "160",
        "c": "0",
        "code": "40.01.00.19"
    },
    {
        "id": 2261,
        "label": "Idem bilateral",
        "k": "200",
        "c": "0",
        "code": "40.01.00.20"
    },
    {
        "id": 2262,
        "label": "Idem com modelagem ureteral",
        "k": "170",
        "c": "0",
        "code": "40.01.00.21"
    },
    {
        "id": 2263,
        "label": "Idem com modelagem ureteral bilateral",
        "k": "220",
        "c": "0",
        "code": "40.01.00.22"
    },
    {
        "id": 2264,
        "label": "Idem com plastia vesical (tipo Boari)",
        "k": "180",
        "c": "0",
        "code": "40.01.00.23"
    },
    {
        "id": 2265,
        "label": "Cirurgia do ureterocele (sem uretero cistoneostomia)",
        "k": "140",
        "c": "0",
        "code": "40.01.00.24"
    },
    {
        "id": 2266,
        "label": "Ureterorrafia",
        "k": "150",
        "c": "0",
        "code": "40.01.00.25"
    },
    {
        "id": 2267,
        "label": "Encerramento de fístula uretero-cutânea",
        "k": "110",
        "c": "0",
        "code": "40.01.00.26"
    },
    {
        "id": 2268,
        "label": "Encerramento de fístula uretero-visceral",
        "k": "180",
        "c": "0",
        "code": "40.01.00.27"
    },
    {
        "id": 2269,
        "label": "Ureteroplastia (inclui ureteroplastia intubada-Davies)",
        "k": "160",
        "c": "0",
        "code": "40.01.00.28"
    },
    {
        "id": 2270,
        "label": "Substituição ureteral por intestino",
        "k": "300",
        "c": "0",
        "code": "40.01.00.29"
    },
    {
        "id": 2271,
        "label": "Ureterectomia de coto ureteral ou ureter acessório",
        "k": "150",
        "c": "0",
        "code": "40.01.00.30"
    },
    {
        "id": 2272,
        "label": "Ureterolise",
        "k": "130",
        "c": "0",
        "code": "40.01.00.31"
    },
    {
        "id": 2273,
        "label": "Descruzamento uretero-vascular",
        "k": "160",
        "c": "0",
        "code": "40.01.00.32"
    },
    {
        "id": 2274,
        "label": "Cirurgia do ureter retro-cava",
        "k": "180",
        "c": "0",
        "code": "40.01.00.33"
    },
    {
        "id": 2275,
        "label": "Ureterolise por fibrose retroperitoneal",
        "k": "160",
        "c": "0",
        "code": "40.01.00.34"
    },
    {
        "id": 2276,
        "label": "Intraperitonealizarão de ureter",
        "k": "200",
        "c": "0",
        "code": "40.01.00.35"
    },
    {
        "id": 2277,
        "label": "Dilatação endoscópica do meato ureteral",
        "k": "40",
        "c": "60",
        "code": "40.01.00.36"
    },
    {
        "id": 2278,
        "label": "Meatotomia ureteral endoscópica",
        "k": "50",
        "c": "60",
        "code": "40.01.00.37"
    },
    {
        "id": 2279,
        "label": "Extracção de corpos estranhos do ureter com citoscópio",
        "k": "50",
        "c": "60",
        "code": "40.01.00.38"
    },
    {
        "id": 2280,
        "label": "Cirurgia endoscópica de ureterocele (unilateral) com ureterocelotomia",
        "k": "80",
        "c": "100",
        "code": "40.01.00.39"
    },
    {
        "id": 2281,
        "label": "Idem com ressecção de ureterocele",
        "k": "80",
        "c": "100",
        "code": "40.01.00.40"
    },
    {
        "id": 2282,
        "label": "Cirurgia endoscópica do refluxo vesico-ureteral (unilateral)",
        "k": "80",
        "c": "100",
        "code": "40.01.00.41"
    },
    {
        "id": 2283,
        "label": "Idem bilateral",
        "k": "100",
        "c": "100",
        "code": "40.01.00.42"
    },
    {
        "id": 2284,
        "label": "Cateterismo endoscópico ureteral terapêutico unilateral (incluí dilatação endoscópica sem visão e inclui drenagem)",
        "k": "40",
        "c": "60",
        "code": "40.01.00.43"
    },
    {
        "id": 2285,
        "label": "Idem bilateral",
        "k": "65",
        "c": "60",
        "code": "40.01.00.44"
    },
    {
        "id": 2286,
        "label": "Colocação endoscópica retrógada de tutor ureteral (unilateral)",
        "k": "50",
        "c": "60",
        "code": "40.01.00.45"
    },
    {
        "id": 2287,
        "label": "Idem bilateral",
        "k": "80",
        "c": "60",
        "code": "40.01.00.46"
    },
    {
        "id": 2288,
        "label": "Ureterolitoextracção endoscópica sem visão",
        "k": "80",
        "c": "60",
        "code": "40.01.00.47"
    },
    {
        "id": 2289,
        "label": "Fulguração endoscópica do ureter com ureterorrenoscópico (URC)",
        "k": "120",
        "c": "200",
        "code": "40.01.00.48"
    },
    {
        "id": 2290,
        "label": "Ureterotomia interna sob visão com URC",
        "k": "140",
        "c": "200",
        "code": "40.01.00.49"
    },
    {
        "id": 2291,
        "label": "Ureterolitoextracção sob visão com URC com pinças ou sondas-cesto",
        "k": "140",
        "c": "200",
        "code": "40.01.00.50"
    },
    {
        "id": 2292,
        "label": "Ureterolitoextracção sob visão com URC com litotritor ultra-sónico, electro-hidráulico ou laser",
        "k": "140",
        "c": "300",
        "code": "40.01.00.51"
    },
    {
        "id": 2293,
        "label": "Ressecção de tumor ureteral com URC",
        "k": "140",
        "c": "200",
        "code": "40.01.00.52"
    },
    {
        "id": 2294,
        "label": "Fotorradiação endoscópica com laser com URC",
        "k": "120",
        "c": "500",
        "code": "40.01.00.53"
    },
    {
        "id": 2295,
        "label": "Colocação percutânea anterógrada de tutor ureteral",
        "k": "120",
        "c": "150",
        "code": "40.01.00.54"
    },
    {
        "id": 2296,
        "label": "Uretero(lito)extracção percutânea com pinças ou sondas-cesto",
        "k": "160",
        "c": "200",
        "code": "40.01.00.55"
    },
    {
        "id": 2297,
        "label": "Uretero(lito)extracção percutânea com litotritor ultra-sónico, electro-hidráulico ou laser",
        "k": "160",
        "c": "300",
        "code": "40.01.00.56"
    },
    {
        "id": 2298,
        "label": "Ureterotomia interna percutânea",
        "k": "160",
        "c": "200",
        "code": "40.01.00.57"
    },
    {
        "id": 2299,
        "label": "Ressecção percutânea de tumor do ureter",
        "k": "160",
        "c": "200",
        "code": "40.01.00.58"
    },
    {
        "id": 2300,
        "label": "Fotoradiação percutânea com laser do ureter",
        "k": "160",
        "c": "500",
        "code": "40.01.00.59"
    },
    {
        "id": 2301,
        "label": "Litotrícia extracorporal por ondas de choque",
        "k": "140",
        "c": "3000",
        "code": "40.01.00.60"
    },
    {
        "id": 2302,
        "label": "Idem, sessão complementar",
        "k": "120",
        "c": "1000",
        "code": "40.01.00.61"
    },
    {
        "id": 2303,
        "label": "Exploração cirúrgica da bexiga e perivesical",
        "k": "110",
        "c": "0",
        "code": "40.02.00.01"
    },
    {
        "id": 2304,
        "label": "Drenagem cirúrgica peri-vesical",
        "k": "110",
        "c": "0",
        "code": "40.02.00.02"
    },
    {
        "id": 2305,
        "label": "Cisto(lito)tomia",
        "k": "110",
        "c": "0",
        "code": "40.02.00.03"
    },
    {
        "id": 2306,
        "label": "Cistostomia ou vesicostomia",
        "k": "110",
        "c": "0",
        "code": "40.02.00.04"
    },
    {
        "id": 2307,
        "label": "Cistorrafia",
        "k": "110",
        "c": "0",
        "code": "40.02.00.05"
    },
    {
        "id": 2308,
        "label": "Encerramento de fístula vesicocutânea (inclui encerramento de cistosmia)",
        "k": "110",
        "c": "0",
        "code": "40.02.00.06"
    },
    {
        "id": 2309,
        "label": "Encerramento de fístula vesicoentérica",
        "k": "180",
        "c": "0",
        "code": "40.02.00.07"
    },
    {
        "id": 2310,
        "label": "Encerramento de fístula vesico-ginecológica",
        "k": "180",
        "c": "0",
        "code": "40.02.00.08"
    },
    {
        "id": 2311,
        "label": "Idem complexa com retalho tecidular",
        "k": "200",
        "c": "0",
        "code": "40.02.00.09"
    },
    {
        "id": 2312,
        "label": "Enterocitoplastia de alargamento (qualquer tipo de segmento intestinal)",
        "k": "280",
        "c": "0",
        "code": "40.02.00.10"
    },
    {
        "id": 2313,
        "label": "Enterocistoplastia de substituição destubularizada",
        "k": "320",
        "c": "0",
        "code": "40.02.00.11"
    },
    {
        "id": 2314,
        "label": "Plastia de redução vesical",
        "k": "200",
        "c": "0",
        "code": "40.02.00.12"
    },
    {
        "id": 2315,
        "label": "Cirurgia do diverticulo vesical com diverticulo plastia",
        "k": "110",
        "c": "0",
        "code": "40.02.00.13"
    },
    {
        "id": 2316,
        "label": "Diverticulolectomia",
        "k": "150",
        "c": "0",
        "code": "40.02.00.14"
    },
    {
        "id": 2317,
        "label": "Excisão do úraco",
        "k": "110",
        "c": "0",
        "code": "40.02.00.15"
    },
    {
        "id": 2318,
        "label": "Cistectomia parcial com ressecção transvesical de tumor",
        "k": "140",
        "c": "0",
        "code": "40.02.00.16"
    },
    {
        "id": 2319,
        "label": "Cistectomia parcial segmentar",
        "k": "150",
        "c": "0",
        "code": "40.02.00.17"
    },
    {
        "id": 2320,
        "label": "Cistectomia sub-total",
        "k": "180",
        "c": "0",
        "code": "40.02.00.18"
    },
    {
        "id": 2321,
        "label": "Cistectomia total",
        "k": "180",
        "c": "0",
        "code": "40.02.00.19"
    },
    {
        "id": 2322,
        "label": "Cistectomia radical (ureterectomia não incluida)",
        "k": "225",
        "c": "0",
        "code": "40.02.00.20"
    },
    {
        "id": 2323,
        "label": "Cistectomia radical com linfadenectomia pélvica",
        "k": "320",
        "c": "0",
        "code": "40.02.00.21"
    },
    {
        "id": 2324,
        "label": "Exenteração pélvica anterior",
        "k": "320",
        "c": "0",
        "code": "40.02.00.22"
    },
    {
        "id": 2325,
        "label": "Aplicação cirúrgica de radioisótopos na bexiga",
        "k": "110",
        "c": "0",
        "code": "40.02.00.23"
    },
    {
        "id": 2326,
        "label": "Cirurgia da bexiga extrofiada",
        "k": "300",
        "c": "0",
        "code": "40.02.00.24"
    },
    {
        "id": 2327,
        "label": "Idem com osteotomia bi-ilíaca",
        "k": "400",
        "c": "0",
        "code": "40.02.00.25"
    },
    {
        "id": 2328,
        "label": "Drenagem cirúrgica periutretal feminina",
        "k": "20",
        "c": "0",
        "code": "40.02.00.26"
    },
    {
        "id": 2329,
        "label": "Uretrotomia feminina",
        "k": "30",
        "c": "0",
        "code": "40.02.00.27"
    },
    {
        "id": 2330,
        "label": "Uretrorrafia feminina",
        "k": "50",
        "c": "0",
        "code": "40.02.00.28"
    },
    {
        "id": 2331,
        "label": "Encerramento de fístula uretrovaginal",
        "k": "100",
        "c": "0",
        "code": "40.02.00.29"
    },
    {
        "id": 2332,
        "label": "Cervicouretroplastia feminina",
        "k": "100",
        "c": "0",
        "code": "40.02.00.30"
    },
    {
        "id": 2333,
        "label": "Reconstrução da uretra feminina (inclui neouretra)",
        "k": "180",
        "c": "0",
        "code": "40.02.00.31"
    },
    {
        "id": 2334,
        "label": "Colpoperineorrafioplastia anterior",
        "k": "100",
        "c": "0",
        "code": "40.02.00.32"
    },
    {
        "id": 2335,
        "label": "Cervicouretropexia por via vaginal",
        "k": "110",
        "c": "0",
        "code": "40.02.00.33"
    },
    {
        "id": 2336,
        "label": "Cervicouretropexia por via suprapúbica",
        "k": "150",
        "c": "0",
        "code": "40.02.00.34"
    },
    {
        "id": 2337,
        "label": "Cervicouretropexia por via mista",
        "k": "160",
        "c": "0",
        "code": "40.02.00.35"
    },
    {
        "id": 2338,
        "label": "Uretrotomia feminina",
        "k": "100",
        "c": "0",
        "code": "40.02.00.36"
    },
    {
        "id": 2339,
        "label": "Exerése de divertículo uretral feminino (uretrocele)",
        "k": "100",
        "c": "0",
        "code": "40.02.00.37"
    },
    {
        "id": 2340,
        "label": "Excisão de carúncula ou prolapso uretral feminino",
        "k": "30",
        "c": "0",
        "code": "40.02.00.38"
    },
    {
        "id": 2341,
        "label": "Fulguração endoscópica vesical",
        "k": "35",
        "c": "75",
        "code": "40.02.00.39"
    },
    {
        "id": 2342,
        "label": "Ressecção-biópsia endoscópica de tumor vesical",
        "k": "50",
        "c": "100",
        "code": "40.02.00.40"
    },
    {
        "id": 2343,
        "label": "Ressecção endoscópica de tumor vesical (RTU-V)",
        "k": "140",
        "c": "100",
        "code": "40.02.00.41"
    },
    {
        "id": 2344,
        "label": "Aplicação de laser por via endoscópica",
        "k": "140",
        "c": "500",
        "code": "40.02.00.42"
    },
    {
        "id": 2345,
        "label": "Extracção endoscópica de cálculo, coágulo ou corpo estranho vesical",
        "k": "80",
        "c": "60",
        "code": "40.02.00.43"
    },
    {
        "id": 2346,
        "label": "Litotrícia endoscópica vesical com litotritor mecânico sem visão",
        "k": "80",
        "c": "40",
        "code": "40.02.00.44"
    },
    {
        "id": 2347,
        "label": "Litotrícia endoscópica vesical com litotritor mecânico com visão",
        "k": "140",
        "c": "100",
        "code": "40.02.00.45"
    },
    {
        "id": 2348,
        "label": "Litotrícia endoscópica vesical com litotritor ultra-sónico, electro-hidráulico ou laser",
        "k": "140",
        "c": "300",
        "code": "40.02.00.46"
    },
    {
        "id": 2349,
        "label": "Cirurgia endoscópica de divertículo vesical",
        "k": "120",
        "c": "100",
        "code": "40.02.00.47"
    },
    {
        "id": 2350,
        "label": "Dilatação endoscópica da bexiga",
        "k": "50",
        "c": "50",
        "code": "40.02.00.48"
    },
    {
        "id": 2351,
        "label": "Alargamento endoscópico do colo vesical feminino com incisão de colo vesical",
        "k": "50",
        "c": "80",
        "code": "40.02.00.49"
    },
    {
        "id": 2352,
        "label": "Idem com ressecção do colo vesical",
        "k": "60",
        "c": "100",
        "code": "40.02.00.50"
    },
    {
        "id": 2353,
        "label": "Tratamento endoscópico de incontinência urinária feminina",
        "k": "140",
        "c": "100",
        "code": "40.02.00.51"
    },
    {
        "id": 2354,
        "label": "Cistostomia suprapúbica percutânea",
        "k": "30",
        "c": "0",
        "code": "40.02.00.52"
    },
    {
        "id": 2355,
        "label": "Litotrícia extracorporal por ondas de choque",
        "k": "140",
        "c": "3000",
        "code": "40.02.00.53"
    },
    {
        "id": 2356,
        "label": "Idem sessão complementar",
        "k": "120",
        "c": "1000",
        "code": "40.02.00.54"
    },
    {
        "id": 2357,
        "label": "Colocação de prótese para tratamento de incontinência urinária (esfincter artificial)",
        "k": "180",
        "c": "0",
        "code": "40.02.00.55"
    },
    {
        "id": 2358,
        "label": "Reeducação perineo-esfincteriana, por incontinência urinária, biofeedback ou electroestimulação, por sessão",
        "k": "10",
        "c": "15",
        "code": "40.02.00.56"
    },
    {
        "id": 2359,
        "label": "Cirurgia aberta do colo vesical com incisão ou excisão do colo",
        "k": "110",
        "c": "0",
        "code": "40.03.00.01"
    },
    {
        "id": 2360,
        "label": "Plastia Y-V do colo vesical",
        "k": "160",
        "c": "0",
        "code": "40.03.00.02"
    },
    {
        "id": 2361,
        "label": "Prostatectomia suprapúbica ou retro púbica por HBP",
        "k": "160",
        "c": "0",
        "code": "40.03.00.03"
    },
    {
        "id": 2362,
        "label": "Prostatectomia perineal por HBP",
        "k": "180",
        "c": "0",
        "code": "40.03.00.04"
    },
    {
        "id": 2363,
        "label": "Prostatectomia radical retropúbica",
        "k": "200",
        "c": "0",
        "code": "40.03.00.05"
    },
    {
        "id": 2364,
        "label": "Prostatectomia radical retropúbica com linfadenectomia pélvica",
        "k": "280",
        "c": "0",
        "code": "40.03.00.06"
    },
    {
        "id": 2365,
        "label": "Prostatectomia radical perineal",
        "k": "200",
        "c": "0",
        "code": "40.03.00.07"
    },
    {
        "id": 2366,
        "label": "Aplicação cirúrgica de radioisótopos na próstata",
        "k": "110",
        "c": "0",
        "code": "40.03.00.08"
    },
    {
        "id": 2367,
        "label": "Cirurgia da incontinência urinária do homem (exclui próteses e cirurgia endoscópica)",
        "k": "180",
        "c": "0",
        "code": "40.03.00.09"
    },
    {
        "id": 2368,
        "label": "Limpeza cirúrgica de osteíte do púbis",
        "k": "90",
        "c": "0",
        "code": "40.03.00.10"
    },
    {
        "id": 2369,
        "label": "Drenagem endoscópica de abcesso da próstata",
        "k": "100",
        "c": "100",
        "code": "40.03.00.11"
    },
    {
        "id": 2370,
        "label": "Ressecção endoscópica de próstata (RTUP)",
        "k": "160",
        "c": "100",
        "code": "40.03.00.12"
    },
    {
        "id": 2371,
        "label": "Alargamento endoscópico da loca prostática com incisão ou ressecção de fibrose da loca",
        "k": "60",
        "c": "80",
        "code": "40.03.00.13"
    },
    {
        "id": 2372,
        "label": "Alargamento endoscópico de colo vesical masculino com incisão ou ressecção de colo vesical",
        "k": "70",
        "c": "80",
        "code": "40.03.00.14"
    },
    {
        "id": 2373,
        "label": "Colocação endoscópica de prótese de alargamento de colo vesical de uretra prostática",
        "k": "70",
        "c": "60",
        "code": "40.03.00.15"
    },
    {
        "id": 2374,
        "label": "Tratamento endoscópico da incontinência urinária masculina",
        "k": "140",
        "c": "100",
        "code": "40.03.00.16"
    },
    {
        "id": 2375,
        "label": "Colocação endoscópica de prótese uretral expansível reepitelizável (exclui o custo da prótese)",
        "k": "120",
        "c": "60",
        "code": "40.03.00.17"
    },
    {
        "id": 2376,
        "label": "Colocação de prótese para tratamento de incontinência urinária (esfincter artificial)",
        "k": "150",
        "c": "0",
        "code": "40.03.00.18"
    },
    {
        "id": 2377,
        "label": "Hipertermia prostática (Independentemente do número de sessões)",
        "k": "80",
        "c": "800",
        "code": "40.03.00.19"
    },
    {
        "id": 2378,
        "label": "Termoterapia prostática transuretral (independentemente do número de sessões - não inclui sonda aplicadora)",
        "k": "80",
        "c": "1400",
        "code": "40.03.00.20"
    },
    {
        "id": 2379,
        "label": "Laser próstático transuretral (não incluí fibras nem mangas)",
        "k": "130",
        "c": "500",
        "code": "40.03.00.21"
    },
    {
        "id": 2380,
        "label": "Exploração cirúrgica da uretra",
        "k": "70",
        "c": "0",
        "code": "40.04.00.01"
    },
    {
        "id": 2381,
        "label": "Drenagem cirúrgica peri-uretral",
        "k": "25",
        "c": "0",
        "code": "40.04.00.02"
    },
    {
        "id": 2382,
        "label": "Meatomia",
        "k": "30",
        "c": "0",
        "code": "40.04.00.03"
    },
    {
        "id": 2383,
        "label": "Uretrolitotomia",
        "k": "50",
        "c": "0",
        "code": "40.04.00.04"
    },
    {
        "id": 2384,
        "label": "Uretrotomia externa",
        "k": "100",
        "c": "0",
        "code": "40.04.00.05"
    },
    {
        "id": 2385,
        "label": "Operação de Monseur",
        "k": "150",
        "c": "0",
        "code": "40.04.00.06"
    },
    {
        "id": 2386,
        "label": "Uretrostomia",
        "k": "80",
        "c": "0",
        "code": "40.04.00.07"
    },
    {
        "id": 2387,
        "label": "Intubação e recanalização uretral",
        "k": "90",
        "c": "0",
        "code": "40.04.00.08"
    },
    {
        "id": 2388,
        "label": "Uretrorrafia",
        "k": "90",
        "c": "0",
        "code": "40.04.00.09"
    },
    {
        "id": 2389,
        "label": "Encerramento da uretrostomia",
        "k": "100",
        "c": "0",
        "code": "40.04.00.10"
    },
    {
        "id": 2390,
        "label": "Encerramento de fístula uretro-cutânea",
        "k": "100",
        "c": "0",
        "code": "40.04.00.11"
    },
    {
        "id": 2391,
        "label": "Encerramento de fistula uretro-rectal",
        "k": "200",
        "c": "0",
        "code": "40.04.00.12"
    },
    {
        "id": 2392,
        "label": "Meatoplastia",
        "k": "50",
        "c": "0",
        "code": "40.04.00.13"
    },
    {
        "id": 2393,
        "label": "Uretroplastia de uretra anterior termino terminal",
        "k": "150",
        "c": "0",
        "code": "40.04.00.14"
    },
    {
        "id": 2394,
        "label": "Idem com retalho pediculado",
        "k": "160",
        "c": "0",
        "code": "40.04.00.15"
    },
    {
        "id": 2395,
        "label": "Idem com retalho livre",
        "k": "160",
        "c": "0",
        "code": "40.04.00.16"
    },
    {
        "id": 2396,
        "label": "Idem 1o. Tempo",
        "k": "150",
        "c": "0",
        "code": "40.04.00.17"
    },
    {
        "id": 2397,
        "label": "Idem 2o. Tempo",
        "k": "150",
        "c": "0",
        "code": "40.04.00.18"
    },
    {
        "id": 2398,
        "label": "Uretroplastia da uretra posterior termino-terminal",
        "k": "200",
        "c": "0",
        "code": "40.04.00.19"
    },
    {
        "id": 2399,
        "label": "Idem com retalho pediculado",
        "k": "200",
        "c": "0",
        "code": "40.04.00.20"
    },
    {
        "id": 2400,
        "label": "Idem com retalho livre",
        "k": "200",
        "c": "0",
        "code": "40.04.00.21"
    },
    {
        "id": 2401,
        "label": "Idem 1o. Tempo",
        "k": "200",
        "c": "0",
        "code": "40.04.00.22"
    },
    {
        "id": 2402,
        "label": "Idem 2o. Tempo",
        "k": "180",
        "c": "0",
        "code": "40.04.00.23"
    },
    {
        "id": 2403,
        "label": "Diverticulectomia uretral",
        "k": "100",
        "c": "0",
        "code": "40.04.00.24"
    },
    {
        "id": 2406,
        "label": "Uretrectomia de uretra acessória",
        "k": "150",
        "c": "0",
        "code": "40.04.00.27"
    },
    {
        "id": 2407,
        "label": "Extracção cirúrgica de corpos estranhos uretrais",
        "k": "50",
        "c": "0",
        "code": "40.04.00.28"
    },
    {
        "id": 2408,
        "label": "Cirurgia do hipospadias e da uretra curta congénita proximal num só tempo",
        "k": "220",
        "c": "0",
        "code": "40.04.00.29"
    },
    {
        "id": 2409,
        "label": "Idem distal num só tempo",
        "k": "150",
        "c": "0",
        "code": "40.04.00.30"
    },
    {
        "id": 2410,
        "label": "Idem em, 2 tempos 1o. Tempo (endireitamento)",
        "k": "100",
        "c": "0",
        "code": "40.04.00.31"
    },
    {
        "id": 2411,
        "label": "Idem em 2 tempos 2o. Tempo (neouretroplastia)",
        "k": "160",
        "c": "0",
        "code": "40.04.00.32"
    },
    {
        "id": 2412,
        "label": "Cirurgia do epispádias",
        "k": "230",
        "c": "0",
        "code": "40.04.00.33"
    },
    {
        "id": 2413,
        "label": "Fulguração endoscópica uretral",
        "k": "35",
        "c": "75",
        "code": "40.04.00.34"
    },
    {
        "id": 2414,
        "label": "Extracção endoscópica de cálculo ou corpo estranho uretral",
        "k": "50",
        "c": "60",
        "code": "40.04.00.35"
    },
    {
        "id": 2415,
        "label": "Uretrotomia interna sem visão",
        "k": "50",
        "c": "20",
        "code": "40.04.00.36"
    },
    {
        "id": 2416,
        "label": "Uretrotomia interna sob visão",
        "k": "90",
        "c": "80",
        "code": "40.04.00.37"
    },
    {
        "id": 2417,
        "label": "Ressecção endoscópica de estenose da uretra",
        "k": "90",
        "c": "100",
        "code": "40.04.00.38"
    },
    {
        "id": 2418,
        "label": "Ressecção endoscópica de tumor uretral",
        "k": "90",
        "c": "100",
        "code": "40.04.00.39"
    },
    {
        "id": 2419,
        "label": "Esfincterotomia endoscópica",
        "k": "60",
        "c": "100",
        "code": "40.04.00.40"
    },
    {
        "id": 2420,
        "label": "Incisão-ressecção endoscópica de valvas uretrais",
        "k": "90",
        "c": "100",
        "code": "40.04.00.41"
    },
    {
        "id": 2421,
        "label": "Colocação endoscópica de prótese uretral expansível reepitelizável (exclui o custo da prótese)",
        "k": "100",
        "c": "60",
        "code": "40.04.00.42"
    },
    {
        "id": 2422,
        "label": "Corte do freio do pénis",
        "k": "20",
        "c": "0",
        "code": "41.00.00.01"
    },
    {
        "id": 2423,
        "label": "Incisão para redução da parafimose",
        "k": "20",
        "c": "0",
        "code": "41.00.00.02"
    },
    {
        "id": 2424,
        "label": "Postectomia (circuncisão)",
        "k": "40",
        "c": "0",
        "code": "41.00.00.03"
    },
    {
        "id": 2425,
        "label": "Cirurgia de angulação e mal-rotação peniana e da doença de Peyronie com operação de Nesbit",
        "k": "100",
        "c": "0",
        "code": "41.00.00.04"
    },
    {
        "id": 2426,
        "label": "Idem com excisão da placa e colocação de retalho",
        "k": "130",
        "c": "0",
        "code": "41.00.00.05"
    },
    {
        "id": 2427,
        "label": "Idem com excisão da placa e colocação de prótese",
        "k": "160",
        "c": "0",
        "code": "41.00.00.06"
    },
    {
        "id": 2428,
        "label": "Cirurgia de priapismo com anastomose safeno-cavernosa unilateral",
        "k": "150",
        "c": "0",
        "code": "41.00.00.07"
    },
    {
        "id": 2429,
        "label": "Idem com anastomose safeno-cavernosa bilateral",
        "k": "200",
        "c": "0",
        "code": "41.00.00.08"
    },
    {
        "id": 2430,
        "label": "Idem com anastomose caverno esponjosa",
        "k": "150",
        "c": "0",
        "code": "41.00.00.09"
    },
    {
        "id": 2431,
        "label": "Idem com fistula caverno-esponjosa",
        "k": "100",
        "c": "0",
        "code": "41.00.00.10"
    },
    {
        "id": 2432,
        "label": "Punção - esvaziamento - lavagem dos corpos cavernosos para tratamento do priapismo",
        "k": "30",
        "c": "0",
        "code": "41.00.00.11"
    },
    {
        "id": 2433,
        "label": "Amputação peniana parcial",
        "k": "75",
        "c": "0",
        "code": "41.00.00.12"
    },
    {
        "id": 2434,
        "label": "Amputação peniana total",
        "k": "120",
        "c": "0",
        "code": "41.00.00.13"
    },
    {
        "id": 2435,
        "label": "Emasculação",
        "k": "160",
        "c": "0",
        "code": "41.00.00.14"
    },
    {
        "id": 2436,
        "label": "Amputação peniana com linfadenectomia inguinal unilateral",
        "k": "160",
        "c": "0",
        "code": "41.00.00.15"
    },
    {
        "id": 2437,
        "label": "Amputação peniana com linfadenectomia inguinal bilateral",
        "k": "250",
        "c": "0",
        "code": "41.00.00.16"
    },
    {
        "id": 2438,
        "label": "Idem com linfadectomia inguino-pélvica bilateral",
        "k": "320",
        "c": "0",
        "code": "41.00.00.17"
    },
    {
        "id": 2439,
        "label": "Reconstrução do pénis (tempo principal)",
        "k": "150",
        "c": "0",
        "code": "41.00.00.18"
    },
    {
        "id": 2440,
        "label": "Idem outros tempos (cada)",
        "k": "65",
        "c": "0",
        "code": "41.00.00.19"
    },
    {
        "id": 2441,
        "label": "Laqueação de veias penianas na cirurgia da disfunção eréctil",
        "k": "100",
        "c": "0",
        "code": "41.00.00.20"
    },
    {
        "id": 2442,
        "label": "Revascularização peniana",
        "k": "150",
        "c": "0",
        "code": "41.00.00.21"
    },
    {
        "id": 2443,
        "label": "Idem, com microcirurgia",
        "k": "160",
        "c": "300",
        "code": "41.00.00.22"
    },
    {
        "id": 2444,
        "label": "Colocação de prótese peniana rígida",
        "k": "150",
        "c": "0",
        "code": "41.00.00.23"
    },
    {
        "id": 2445,
        "label": "Colocação de prótese peniana semi-rígida",
        "k": "150",
        "c": "0",
        "code": "41.00.00.24"
    },
    {
        "id": 2446,
        "label": "Colocação de prótese peniana insuflável",
        "k": "180",
        "c": "0",
        "code": "41.00.00.25"
    },
    {
        "id": 2447,
        "label": "Aplicação externa de raios laser",
        "k": "25",
        "c": "250",
        "code": "41.00.00.26"
    },
    {
        "id": 2448,
        "label": "Cirurgia do interesexo e transsexual masculino para feminino",
        "k": "300",
        "c": "0",
        "code": "41.00.00.27"
    },
    {
        "id": 2449,
        "label": "Idem feminino para masculino, completa",
        "k": "450",
        "c": "0",
        "code": "41.00.00.28"
    },
    {
        "id": 2450,
        "label": "Exploração do conteúdo escrotal (celotomia exploradora)",
        "k": "60",
        "c": "0",
        "code": "41.00.00.29"
    },
    {
        "id": 2451,
        "label": "Drenagem cirúrgica da bolsa escrotal",
        "k": "25",
        "c": "0",
        "code": "41.00.00.30"
    },
    {
        "id": 2452,
        "label": "Drenagem de fleimão urinoso",
        "k": "80",
        "c": "0",
        "code": "41.00.00.31"
    },
    {
        "id": 2453,
        "label": "Cirurgia da pele e invólucros da bolsa escrotal",
        "k": "50",
        "c": "0",
        "code": "41.00.00.32"
    },
    {
        "id": 2454,
        "label": "Cirurgia de hidrocele",
        "k": "75",
        "c": "0",
        "code": "41.00.00.33"
    },
    {
        "id": 2455,
        "label": "Punção de hidrocele com injecção de esclerosante",
        "k": "25",
        "c": "0",
        "code": "41.00.00.34"
    },
    {
        "id": 2456,
        "label": "Cirurgia do hematocele",
        "k": "75",
        "c": "0",
        "code": "41.00.00.35"
    },
    {
        "id": 2457,
        "label": "Cirurgia do varicocele com laqueação alta da veia espermática",
        "k": "75",
        "c": "0",
        "code": "41.00.00.36"
    },
    {
        "id": 2458,
        "label": "Cirurgia do varicocele com laqueação-ressecção múltipla de veias varicosas",
        "k": "90",
        "c": "0",
        "code": "41.00.00.37"
    },
    {
        "id": 2459,
        "label": "Orquidorrafia por traumatismo",
        "k": "100",
        "c": "0",
        "code": "41.00.00.38"
    },
    {
        "id": 2460,
        "label": "Orquidopexia escrotal sem funiculolise",
        "k": "80",
        "c": "0",
        "code": "41.00.00.39"
    },
    {
        "id": 2461,
        "label": "Orquidectomia escrotal",
        "k": "80",
        "c": "0",
        "code": "41.00.00.40"
    },
    {
        "id": 2462,
        "label": "Orquidectomia sub-albugínea bilateral",
        "k": "100",
        "c": "0",
        "code": "41.00.00.41"
    },
    {
        "id": 2463,
        "label": "Orquidectomia intra-abdominal",
        "k": "110",
        "c": "0",
        "code": "41.00.00.42"
    },
    {
        "id": 2464,
        "label": "Orquidectomia inguinal simples",
        "k": "120",
        "c": "0",
        "code": "41.00.00.43"
    },
    {
        "id": 2465,
        "label": "Orquidectomia inguinal radical sem linfadenectomia",
        "k": "150",
        "c": "0",
        "code": "41.00.00.44"
    },
    {
        "id": 2466,
        "label": "Idem com Linfadenectomia para-aórtico-cava e pélvica",
        "k": "350",
        "c": "0",
        "code": "41.00.00.45"
    },
    {
        "id": 2467,
        "label": "Autotransplante testicular",
        "k": "250",
        "c": "0",
        "code": "41.00.00.46"
    },
    {
        "id": 2468,
        "label": "Colocação de prótese testicular unilateral",
        "k": "75",
        "c": "0",
        "code": "41.00.00.47"
    },
    {
        "id": 2469,
        "label": "Colocação de prótese testicular bilateral",
        "k": "120",
        "c": "0",
        "code": "41.00.00.48"
    },
    {
        "id": 2470,
        "label": "Cirurgia para deferento vesiculografia",
        "k": "50",
        "c": "0",
        "code": "41.00.00.49"
    },
    {
        "id": 2471,
        "label": "Cirurgia da obstrução espermática com anastomose epididimo-deferencial (epididimo-vasostomia)",
        "k": "160",
        "c": "0",
        "code": "41.00.00.50"
    },
    {
        "id": 2472,
        "label": "Idem com anastomose deferento-deferencial (vaso-vasostomia)",
        "k": "160",
        "c": "0",
        "code": "41.00.00.51"
    },
    {
        "id": 2473,
        "label": "Idem com microcirurgia",
        "k": "180",
        "c": "300",
        "code": "41.00.00.52"
    },
    {
        "id": 2474,
        "label": "Excisão de espermatocele ou quisto para testicular epididimário ou do cordão espermático",
        "k": "75",
        "c": "0",
        "code": "41.00.00.53"
    },
    {
        "id": 2475,
        "label": "Epididimectomia",
        "k": "75",
        "c": "0",
        "code": "41.00.00.54"
    },
    {
        "id": 2476,
        "label": "Vasectomia, bilateral(ou laqueação dos deferentes)",
        "k": "40",
        "c": "0",
        "code": "41.00.00.55"
    },
    {
        "id": 2477,
        "label": "Inguinotomia exploradora",
        "k": "90",
        "c": "0",
        "code": "41.00.00.56"
    },
    {
        "id": 2478,
        "label": "Funicololise (e orquidopexia)",
        "k": "120",
        "c": "0",
        "code": "41.00.00.57"
    },
    {
        "id": 2479,
        "label": "Cirurgia das vesículas seminais",
        "k": "150",
        "c": "0",
        "code": "41.00.00.58"
    },
    {
        "id": 2480,
        "label": "Perineoplastia não obstétrica (operação isolada)",
        "k": "80",
        "c": "0",
        "code": "42.00.00.01"
    },
    {
        "id": 2481,
        "label": "Colpoperineorrafia por rasgadura incompleta do perineo e vagina (não obstétrica)",
        "k": "80",
        "c": "0",
        "code": "42.00.00.02"
    },
    {
        "id": 2482,
        "label": "Colpoperrineorrafia com sutura do recto, esfíncter anal, por rasgadura completa do perineo (não obstétrica)",
        "k": "120",
        "c": "0",
        "code": "42.00.00.03"
    },
    {
        "id": 2483,
        "label": "Marsupialiazação da glândula da Bartholin",
        "k": "30",
        "c": "0",
        "code": "42.01.00.01"
    },
    {
        "id": 2484,
        "label": "Excisão cirúrgica de condilomas",
        "k": "40",
        "c": "0",
        "code": "42.01.00.02"
    },
    {
        "id": 2485,
        "label": "Vulvectomia parcial",
        "k": "60",
        "c": "0",
        "code": "42.01.00.03"
    },
    {
        "id": 2486,
        "label": "Vulvectomia total",
        "k": "130",
        "c": "0",
        "code": "42.01.00.04"
    },
    {
        "id": 2487,
        "label": "Vulvectomia radical, com esvaziamento ganglionar",
        "k": "250",
        "c": "0",
        "code": "42.01.00.05"
    },
    {
        "id": 2488,
        "label": "Clitoridectomia",
        "k": "50",
        "c": "0",
        "code": "42.01.00.06"
    },
    {
        "id": 2489,
        "label": "Clitoridoplastia",
        "k": "110",
        "c": "0",
        "code": "42.01.00.07"
    },
    {
        "id": 2490,
        "label": "Exérese de glândula de Bartholin",
        "k": "40",
        "c": "0",
        "code": "42.01.00.08"
    },
    {
        "id": 2491,
        "label": "Exérese de caruncula uretral",
        "k": "15",
        "c": "0",
        "code": "42.01.00.09"
    },
    {
        "id": 2492,
        "label": "Excisão de pequeno lábio",
        "k": "30",
        "c": "0",
        "code": "42.01.00.10"
    },
    {
        "id": 2493,
        "label": "Himenotomia ou himenectomia parcial",
        "k": "15",
        "c": "0",
        "code": "42.01.00.11"
    },
    {
        "id": 2494,
        "label": "Correcção plástica do intróito",
        "k": "60",
        "c": "0",
        "code": "42.01.00.12"
    },
    {
        "id": 2495,
        "label": "Cirurgia laser da vulva",
        "k": "30",
        "c": "75",
        "code": "42.01.00.13"
    },
    {
        "id": 2496,
        "label": "Colpotomia com drenagem de abcesso",
        "k": "25",
        "c": "0",
        "code": "42.02.00.01"
    },
    {
        "id": 2497,
        "label": "Drenagem de hematocolpos",
        "k": "15",
        "c": "0",
        "code": "42.02.00.02"
    },
    {
        "id": 2498,
        "label": "Colpectomia para encerramento parcial da vagina",
        "k": "80",
        "c": "0",
        "code": "42.02.00.03"
    },
    {
        "id": 2499,
        "label": "Colpectomia para encerramento total da vagina (Colpocleisis)",
        "k": "120",
        "c": "0",
        "code": "42.02.00.04"
    },
    {
        "id": 2500,
        "label": "Excisão de septo vaginal e plastia",
        "k": "90",
        "c": "0",
        "code": "42.02.00.05"
    },
    {
        "id": 2501,
        "label": "Exérese de tumor ou quisto",
        "k": "30",
        "c": "0",
        "code": "42.02.00.06"
    },
    {
        "id": 2502,
        "label": "Colporrafia por ferida não obstétrica",
        "k": "75",
        "c": "0",
        "code": "42.02.00.07"
    },
    {
        "id": 2503,
        "label": "Colporrafia anterior por cistocelo",
        "k": "110",
        "c": "0",
        "code": "42.02.00.08"
    },
    {
        "id": 2504,
        "label": "Colporrafia posterior por rectocelo",
        "k": "60",
        "c": "0",
        "code": "42.02.00.09"
    },
    {
        "id": 2505,
        "label": "Vesicouretropexia anterior ou uretropexia, via abdominal (tipo Marshall-Marchetti)",
        "k": "120",
        "c": "0",
        "code": "42.02.00.10"
    },
    {
        "id": 2506,
        "label": "Suspensão uretral (fáscia ou sintético) por incontinência urinária ao esforço (tipo Stockel)",
        "k": "150",
        "c": "0",
        "code": "42.02.00.11"
    },
    {
        "id": 2507,
        "label": "Plastia do esfíncter uretral (tipo plicatura uretral de Kelli)",
        "k": "80",
        "c": "0",
        "code": "42.02.00.12"
    },
    {
        "id": 2508,
        "label": "Correcção de enterocelo, via abdominal (operação isolada)",
        "k": "110",
        "c": "0",
        "code": "42.02.00.13"
    },
    {
        "id": 2509,
        "label": "Colpopexia por abordagem abdominal",
        "k": "110",
        "c": "0",
        "code": "42.02.00.14"
    },
    {
        "id": 2510,
        "label": "Intervenção cirúrgica para neovagina, em tempo único, simples com ou sem enxerto cutâneo",
        "k": "150",
        "c": "0",
        "code": "42.02.00.15"
    },
    {
        "id": 2511,
        "label": "Intervenção cirúrgica para neovagina, em tempos múltiplos ou com plastia complexa (retalhos loco-regionais)",
        "k": "250",
        "c": "0",
        "code": "42.02.00.16"
    },
    {
        "id": 2512,
        "label": "Correcção de fístula recto-vaginal, via vaginal",
        "k": "120",
        "c": "0",
        "code": "42.02.00.17"
    },
    {
        "id": 2513,
        "label": "Correcção de fístula vesico-vaginal, via vaginal",
        "k": "200",
        "c": "0",
        "code": "42.02.00.18"
    },
    {
        "id": 2514,
        "label": "Idem, via transvesical",
        "k": "200",
        "c": "0",
        "code": "42.02.00.19"
    },
    {
        "id": 2515,
        "label": "Cirurgia laser da vagina",
        "k": "30",
        "c": "75",
        "code": "42.02.00.20"
    },
    {
        "id": 2516,
        "label": "Cirurgia Laser CO2 - Vaporização",
        "k": "30",
        "c": "75",
        "code": "42.03.00.01"
    },
    {
        "id": 2517,
        "label": "Electrocoagulação ou criocoagulação",
        "k": "10",
        "c": "0",
        "code": "42.03.00.02"
    },
    {
        "id": 2518,
        "label": "Conização",
        "k": "60",
        "c": "0",
        "code": "42.03.00.03"
    },
    {
        "id": 2519,
        "label": "Cervicectomia (operação isolada)",
        "k": "75",
        "c": "0",
        "code": "42.03.00.04"
    },
    {
        "id": 2520,
        "label": "Exérese do colo restante",
        "k": "140",
        "c": "0",
        "code": "42.03.00.05"
    },
    {
        "id": 2521,
        "label": "Traquelorrafia",
        "k": "75",
        "c": "0",
        "code": "42.03.00.06"
    },
    {
        "id": 2522,
        "label": "Polipectomia cervical",
        "k": "10",
        "c": "0",
        "code": "42.03.00.07"
    },
    {
        "id": 2523,
        "label": "Conização laser CO2",
        "k": "60",
        "c": "75",
        "code": "42.03.00.08"
    },
    {
        "id": 2524,
        "label": "Conização com ansa diatérmica",
        "k": "40",
        "c": "50",
        "code": "42.03.00.09"
    },
    {
        "id": 2525,
        "label": "Curetagem por aspiração (tipo Vabra)",
        "k": "30",
        "c": "0",
        "code": "42.04.00.01"
    },
    {
        "id": 2526,
        "label": "Dilatação e curetagem",
        "k": "30",
        "c": "0",
        "code": "42.04.00.02"
    },
    {
        "id": 2527,
        "label": "Miomectomia por via abdominal ou vaginal",
        "k": "110",
        "c": "0",
        "code": "42.04.00.03"
    },
    {
        "id": 2528,
        "label": "Histerectomia total, com anexectomia via abdominal",
        "k": "180",
        "c": "0",
        "code": "42.04.00.04"
    },
    {
        "id": 2529,
        "label": "Histerectomia sub-total com anexectomia, via abdominal",
        "k": "140",
        "c": "0",
        "code": "42.04.00.05"
    },
    {
        "id": 2530,
        "label": "Histerectomia vaginal",
        "k": "140",
        "c": "0",
        "code": "42.04.00.06"
    },
    {
        "id": 2531,
        "label": "Histerectomia vaginal com correcção de enterocelo",
        "k": "240",
        "c": "0",
        "code": "42.04.00.07"
    },
    {
        "id": 2532,
        "label": "Histerectomia vaginal radical (tipo Schauta)",
        "k": "300",
        "c": "0",
        "code": "42.04.00.08"
    },
    {
        "id": 2533,
        "label": "Histerectomia vaginal com colporrafia anterior e/ou posterior",
        "k": "180",
        "c": "0",
        "code": "42.04.00.09"
    },
    {
        "id": 2534,
        "label": "Histerectomia radical com linfadenectomia pélvica bilateral (tipo Wertheim-Meigs)",
        "k": "300",
        "c": "0",
        "code": "42.04.00.10"
    },
    {
        "id": 2535,
        "label": "Exenteração pélvica",
        "k": "450",
        "c": "0",
        "code": "42.04.00.11"
    },
    {
        "id": 2536,
        "label": "Histerotomia abdominal",
        "k": "100",
        "c": "0",
        "code": "42.04.00.12"
    },
    {
        "id": 2537,
        "label": "Histeropexia",
        "k": "120",
        "c": "0",
        "code": "42.04.00.13"
    },
    {
        "id": 2538,
        "label": "Ligamentopexia",
        "k": "120",
        "c": "0",
        "code": "42.04.00.14"
    },
    {
        "id": 2539,
        "label": "Histeroplastia por anomalia uterina (tipo Stassman)",
        "k": "150",
        "c": "0",
        "code": "42.04.00.15"
    },
    {
        "id": 2540,
        "label": "Sutura de rotura uterina",
        "k": "110",
        "c": "0",
        "code": "42.04.00.16"
    },
    {
        "id": 2541,
        "label": "Intervenção cirúrgica por inversão uterina (não obstétrica)",
        "k": "110",
        "c": "0",
        "code": "42.04.00.17"
    },
    {
        "id": 2542,
        "label": "Oclusão de fistula vesico-uterina",
        "k": "130",
        "c": "0",
        "code": "42.04.00.18"
    },
    {
        "id": 2543,
        "label": "Laparotomia exploradora com biópsias para estadiamento por neoplasia ginecológica",
        "k": "120",
        "c": "0",
        "code": "42.04.00.19"
    },
    {
        "id": 2544,
        "label": "Secção de sinéquias uterinas - via vaginal",
        "k": "100",
        "c": "0",
        "code": "42.04.00.20"
    },
    {
        "id": 2545,
        "label": "Correcção de septo por via vaginal",
        "k": "100",
        "c": "0",
        "code": "42.04.00.21"
    },
    {
        "id": 2546,
        "label": "Histerectomia total com conservação de anexos",
        "k": "180",
        "c": "0",
        "code": "42.04.00.22"
    },
    {
        "id": 2547,
        "label": "Microcirurgia tubar",
        "k": "200",
        "c": "0",
        "code": "42.05.00.01"
    },
    {
        "id": 2548,
        "label": "Drenagem de abcesso tubo-ovárico",
        "k": "110",
        "c": "0",
        "code": "42.05.00.02"
    },
    {
        "id": 2549,
        "label": "Secção ou laqueação da trompa, abdominal uni ou bilateral",
        "k": "50",
        "c": "0",
        "code": "42.05.00.03"
    },
    {
        "id": 2550,
        "label": "Salpingectomia, uni ou bilateral (operação isolada)",
        "k": "110",
        "c": "0",
        "code": "42.05.00.04"
    },
    {
        "id": 2551,
        "label": "Anexectomia, uni ou bilateral",
        "k": "110",
        "c": "0",
        "code": "42.05.00.05"
    },
    {
        "id": 2552,
        "label": "Salpingoplastia, uni ou bilateral",
        "k": "180",
        "c": "0",
        "code": "42.05.00.06"
    },
    {
        "id": 2553,
        "label": "Tratamento cirúrgico da gravidez ectópica",
        "k": "110",
        "c": "0",
        "code": "42.05.00.07"
    },
    {
        "id": 2554,
        "label": "Lise de aderências pélvicas",
        "k": "110",
        "c": "0",
        "code": "42.05.00.08"
    },
    {
        "id": 2555,
        "label": "Ressecção em cunha, uni ou bilateral",
        "k": "100",
        "c": "0",
        "code": "42.06.00.01"
    },
    {
        "id": 2556,
        "label": "Cistectomia do ovário, uni ou bilateral",
        "k": "110",
        "c": "0",
        "code": "42.06.00.02"
    },
    {
        "id": 2557,
        "label": "Ovariectomia, uni ou bilateral",
        "k": "110",
        "c": "0",
        "code": "42.06.00.03"
    },
    {
        "id": 2558,
        "label": "Ovariectomia, uni ou bilateral com omentectomia",
        "k": "140",
        "c": "0",
        "code": "42.06.00.04"
    },
    {
        "id": 2559,
        "label": "Citoredução do carcinoma do ovário em estadios superiores ou igual ao IIB",
        "k": "300",
        "c": "0",
        "code": "42.06.00.05"
    },
    {
        "id": 2560,
        "label": "Coagulação de ovários",
        "k": "100",
        "c": "0",
        "code": "42.06.00.06"
    },
    {
        "id": 2561,
        "label": "Simpaticectomia pélvica",
        "k": "150",
        "c": "0",
        "code": "42.07.00.01"
    },
    {
        "id": 2562,
        "label": "Reparação de episiotomia e/ou rasgadura incompleta do períneo e/ou rasgadura da vagina, simples",
        "k": "25",
        "c": "0",
        "code": "43.00.00.01"
    },
    {
        "id": 2563,
        "label": "Extensa",
        "k": "30",
        "c": "0",
        "code": "43.00.00.02"
    },
    {
        "id": 2564,
        "label": "Colpoperineorrafia e reparação do esfíncter anal por rasgadura completa do perineo consecutiva a parto",
        "k": "80",
        "c": "0",
        "code": "43.00.00.03"
    },
    {
        "id": 2565,
        "label": "Histerorrafia por rotura do útero (obstétrica)",
        "k": "120",
        "c": "0",
        "code": "43.00.00.04"
    },
    {
        "id": 2566,
        "label": "Operação por inversão uterina de causa obstétrica",
        "k": "110",
        "c": "0",
        "code": "43.00.00.05"
    },
    {
        "id": 2567,
        "label": "Parto normal (com ou sem episiotomia) compreendida anestesia feita pelo próprio médico",
        "k": "65",
        "c": "0",
        "code": "43.01.00.01"
    },
    {
        "id": 2568,
        "label": "Parto gemelar normal por cada gémeo",
        "k": "65",
        "c": "0",
        "code": "43.01.00.02"
    },
    {
        "id": 2569,
        "label": "Parto distócico, compreendidas todas as intervenções, tais como: fórceps, ventosa, versão grande,  extracção pélvica, dequitadura artificial, episeorrafia, desencadeamento médico ou instrumental do trabalho",
        "k": "80",
        "c": "0",
        "code": "43.01.00.03"
    },
    {
        "id": 2570,
        "label": "Fetotomia (embriotomia)",
        "k": "100",
        "c": "0",
        "code": "43.01.00.04"
    },
    {
        "id": 2571,
        "label": "Dequitadura manual",
        "k": "25",
        "c": "0",
        "code": "43.01.00.05"
    },
    {
        "id": 2572,
        "label": "Traquelorrafia",
        "k": "50",
        "c": "0",
        "code": "43.01.00.06"
    },
    {
        "id": 2573,
        "label": "Cesariana",
        "k": "130",
        "c": "0",
        "code": "43.02.00.01"
    },
    {
        "id": 2574,
        "label": "Cesariana com histerectomia, sub-total",
        "k": "200",
        "c": "0",
        "code": "43.02.00.02"
    },
    {
        "id": 2575,
        "label": "Cesariana com histerectomia, total",
        "k": "220",
        "c": "0",
        "code": "43.02.00.03"
    },
    {
        "id": 2576,
        "label": "Lobectomia subtotal da tiroide",
        "k": "120",
        "c": "0",
        "code": "44.00.00.01"
    },
    {
        "id": 2577,
        "label": "Lobectomia total da tiroide",
        "k": "160",
        "c": "0",
        "code": "44.00.00.02"
    },
    {
        "id": 2578,
        "label": "Tiroidectomia subtotal",
        "k": "200",
        "c": "0",
        "code": "44.00.00.03"
    },
    {
        "id": 2579,
        "label": "Tiroidectomia total",
        "k": "250",
        "c": "0",
        "code": "44.00.00.04"
    },
    {
        "id": 2580,
        "label": "Tiroidectomia total ou sub-total com esvaziamento cervical conservador",
        "k": "300",
        "c": "0",
        "code": "44.00.00.05"
    },
    {
        "id": 2581,
        "label": "Idem, com esvaziamento cervical radical",
        "k": "350",
        "c": "0",
        "code": "44.00.00.06"
    },
    {
        "id": 2582,
        "label": "Tiroidectomia subesternal com esternotomia",
        "k": "300",
        "c": "0",
        "code": "44.00.00.07"
    },
    {
        "id": 2583,
        "label": "Paratiroidectomia e/ou exploração da paratiroideia",
        "k": "225",
        "c": "0",
        "code": "44.00.00.08"
    },
    {
        "id": 2584,
        "label": "Paratiroidectomia com exploração mediastínica por abordagem torácica",
        "k": "300",
        "c": "0",
        "code": "44.00.00.09"
    },
    {
        "id": 2585,
        "label": "Timectomia",
        "k": "370",
        "c": "0",
        "code": "44.00.00.10"
    },
    {
        "id": 2586,
        "label": "Adrenalectomia unilateral",
        "k": "220",
        "c": "0",
        "code": "44.00.00.11"
    },
    {
        "id": 2587,
        "label": "Excisão de tumor do corpo carotideo",
        "k": "250",
        "c": "0",
        "code": "44.00.00.12"
    },
    {
        "id": 2588,
        "label": "Excisão de quisto do canal tireoglosso",
        "k": "120",
        "c": "0",
        "code": "44.00.00.13"
    },
    {
        "id": 2589,
        "label": "Excisão de quisto ou adenoma da tiroideia",
        "k": "120",
        "c": "0",
        "code": "44.00.00.14"
    },
    {
        "id": 2590,
        "label": "Trepanação simples",
        "k": "100",
        "c": "0",
        "code": "45.00.00.01"
    },
    {
        "id": 2591,
        "label": "Craniotomia por hematoma epidural",
        "k": "200",
        "c": "0",
        "code": "45.00.00.02"
    },
    {
        "id": 2592,
        "label": "Craniotomia por hematoma subdural",
        "k": "200",
        "c": "0",
        "code": "45.00.00.03"
    },
    {
        "id": 2593,
        "label": "Esquirolectomia simples",
        "k": "120",
        "c": "0",
        "code": "45.00.00.04"
    },
    {
        "id": 2594,
        "label": "Esquirolectomia com reparação dural e tratamento encefálico",
        "k": "220",
        "c": "0",
        "code": "45.00.00.05"
    },
    {
        "id": 2595,
        "label": "Lobectomia",
        "k": "250",
        "c": "0",
        "code": "45.00.00.06"
    },
    {
        "id": 2596,
        "label": "Craniectomia ou craniotomia para remoção de corpo estranho no encéfalo (bala, etc)",
        "k": "250",
        "c": "0",
        "code": "45.00.00.07"
    },
    {
        "id": 2597,
        "label": "Reparação de fístula de LCR",
        "k": "180",
        "c": "0",
        "code": "45.01.00.01"
    },
    {
        "id": 2598,
        "label": "Reparação de fistula de L.C.R. por via transfenoidal",
        "k": "300",
        "c": "0",
        "code": "45.01.00.02"
    },
    {
        "id": 2599,
        "label": "Fístula de L.C.R. da fossa posterior",
        "k": "300",
        "c": "0",
        "code": "45.01.00.03"
    },
    {
        "id": 2600,
        "label": "Cranioplastia com osso",
        "k": "220",
        "c": "0",
        "code": "45.01.00.04"
    },
    {
        "id": 2601,
        "label": "Cranioplastia com material sintético",
        "k": "250",
        "c": "0",
        "code": "45.01.00.05"
    },
    {
        "id": 2602,
        "label": "Tratamento de craniossinostose de uma sutura",
        "k": "250",
        "c": "0",
        "code": "45.01.00.06"
    },
    {
        "id": 2603,
        "label": "Tratamento de craniossinostose complexa",
        "k": "300",
        "c": "0",
        "code": "45.01.00.07"
    },
    {
        "id": 2604,
        "label": "Tratamento cirúrgico de encefalocelo",
        "k": "250",
        "c": "0",
        "code": "45.01.00.08"
    },
    {
        "id": 2605,
        "label": "Tratamento cirúrgico de disrrafismo espinal",
        "k": "350",
        "c": "0",
        "code": "45.01.00.09"
    },
    {
        "id": 2606,
        "label": "Correcção cirúrgica de lesões de osteite craniana",
        "k": "70",
        "c": "0",
        "code": "45.02.00.01"
    },
    {
        "id": 2607,
        "label": "Trepanação para drenagem de abcesso cerebral",
        "k": "150",
        "c": "0",
        "code": "45.02.00.02"
    },
    {
        "id": 2608,
        "label": "Craniotomia para tratamento de abcesso cerebral",
        "k": "250",
        "c": "0",
        "code": "45.02.00.03"
    },
    {
        "id": 2609,
        "label": "Craniotomia para abcesso subdural ou epidural",
        "k": "250",
        "c": "0",
        "code": "45.02.00.04"
    },
    {
        "id": 2610,
        "label": "Abcesso intra-raquidiano via posterior",
        "k": "250",
        "c": "0",
        "code": "45.02.00.05"
    },
    {
        "id": 2611,
        "label": "Abcesso intra-raquidiano via anterior",
        "k": "300",
        "c": "0",
        "code": "45.02.00.06"
    },
    {
        "id": 2612,
        "label": "Abcesso intra-raquidiano cervical via anterior",
        "k": "300",
        "c": "0",
        "code": "45.02.00.07"
    },
    {
        "id": 2613,
        "label": "Abcesso intramedular",
        "k": "350",
        "c": "0",
        "code": "45.02.00.08"
    },
    {
        "id": 2614,
        "label": "Remoção de tumores atingindo a calote sem cranioplastia",
        "k": "100",
        "c": "0",
        "code": "45.03.00.01"
    },
    {
        "id": 2615,
        "label": "Remoção de tumores atingindo a calote com cranioplastia",
        "k": "200",
        "c": "0",
        "code": "45.03.00.02"
    },
    {
        "id": 2616,
        "label": "Buracos de trepano, com drenagem ventricular",
        "k": "70",
        "c": "0",
        "code": "45.04.00.01"
    },
    {
        "id": 2617,
        "label": "Abordagem transfenoidal",
        "k": "350",
        "c": "0",
        "code": "45.04.00.02"
    },
    {
        "id": 2618,
        "label": "Tumores da órbitra - abordagem transcraniana",
        "k": "320",
        "c": "0",
        "code": "45.04.00.03"
    },
    {
        "id": 2619,
        "label": "Glioma supratentorial",
        "k": "300",
        "c": "0",
        "code": "45.04.00.04"
    },
    {
        "id": 2620,
        "label": "Glioma infratentorial",
        "k": "350",
        "c": "0",
        "code": "45.04.00.05"
    },
    {
        "id": 2621,
        "label": "Tumor intraventricular",
        "k": "400",
        "c": "0",
        "code": "45.04.00.06"
    },
    {
        "id": 2622,
        "label": "Tumor selar, supra-selar e para-selar",
        "k": "400",
        "c": "0",
        "code": "45.04.00.07"
    },
    {
        "id": 2623,
        "label": "Tumores da região pineal",
        "k": "400",
        "c": "0",
        "code": "45.04.00.08"
    },
    {
        "id": 2624,
        "label": "Tumores do ânglo pronto-cerebeloso",
        "k": "400",
        "c": "0",
        "code": "45.04.00.09"
    },
    {
        "id": 2625,
        "label": "Gliomas do tronco cerebral",
        "k": "400",
        "c": "0",
        "code": "45.04.00.10"
    },
    {
        "id": 2626,
        "label": "Tumores do IV ventrículo",
        "k": "400",
        "c": "0",
        "code": "45.04.00.11"
    },
    {
        "id": 2627,
        "label": "Tumores da base do crânio",
        "k": "450",
        "c": "0",
        "code": "45.04.00.12"
    },
    {
        "id": 2628,
        "label": "Biópsia tumoral estereotáxica",
        "k": "250",
        "c": "0",
        "code": "45.04.00.13"
    },
    {
        "id": 2629,
        "label": "Outras lesões expansivas intracranianas",
        "k": "350",
        "c": "0",
        "code": "45.04.00.14"
    },
    {
        "id": 2630,
        "label": "Hematomas intracerebrais supratentoriais",
        "k": "250",
        "c": "0",
        "code": "45.05.00.01"
    },
    {
        "id": 2631,
        "label": "Hematomas intracerebrais infratentoriais",
        "k": "300",
        "c": "0",
        "code": "45.05.00.02"
    },
    {
        "id": 2632,
        "label": "Laqueação da carótida interna intracraniana para tratamento de aneurismas e fistulas carótido-cavernosas",
        "k": "250",
        "c": "0",
        "code": "45.05.00.03"
    },
    {
        "id": 2633,
        "label": "Aneurismas intracranianos da circulação anterior",
        "k": "400",
        "c": "0",
        "code": "45.05.00.04"
    },
    {
        "id": 2634,
        "label": "Aneurismas intracranianos da circulação posterior",
        "k": "450",
        "c": "0",
        "code": "45.05.00.05"
    },
    {
        "id": 2635,
        "label": "MAV supratentorial",
        "k": "400",
        "c": "0",
        "code": "45.05.00.06"
    },
    {
        "id": 2636,
        "label": "MAV infratentorial",
        "k": "450",
        "c": "0",
        "code": "45.05.00.07"
    },
    {
        "id": 2637,
        "label": "Processo de revascularização",
        "k": "400",
        "c": "0",
        "code": "45.05.00.08"
    },
    {
        "id": 2638,
        "label": "Tumores da coluna vertebral",
        "k": "300",
        "c": "0",
        "code": "45.06.00.01"
    },
    {
        "id": 2639,
        "label": "Tumores da coluna vertebral com estabilização",
        "k": "400",
        "c": "0",
        "code": "45.06.00.02"
    },
    {
        "id": 2640,
        "label": "Tumores intradurais extramedulares",
        "k": "300",
        "c": "0",
        "code": "45.06.00.03"
    },
    {
        "id": 2641,
        "label": "Tumores intradurais intramedulares",
        "k": "400",
        "c": "0",
        "code": "45.06.00.04"
    },
    {
        "id": 2642,
        "label": "MAV espinal",
        "k": "450",
        "c": "0",
        "code": "45.06.00.05"
    },
    {
        "id": 2643,
        "label": "Malformações da charneira, abordagem anterior",
        "k": "400",
        "c": "0",
        "code": "45.06.00.06"
    },
    {
        "id": 2644,
        "label": "Malformações da charneira, abordagem posterior",
        "k": "400",
        "c": "0",
        "code": "45.06.00.07"
    },
    {
        "id": 2645,
        "label": "Tratamento cirúrgico de siringomilia",
        "k": "300",
        "c": "0",
        "code": "45.06.00.08"
    },
    {
        "id": 2646,
        "label": "Outras malformações congénitas",
        "k": "300",
        "c": "0",
        "code": "45.06.00.09"
    },
    {
        "id": 2647,
        "label": "Torkildsen",
        "k": "250",
        "c": "0",
        "code": "45.07.00.01"
    },
    {
        "id": 2648,
        "label": "Derivações ventrículo-atriais",
        "k": "220",
        "c": "0",
        "code": "45.07.00.02"
    },
    {
        "id": 2649,
        "label": "Derivações ventrículo-peritoneais",
        "k": "170",
        "c": "0",
        "code": "45.07.00.03"
    },
    {
        "id": 2650,
        "label": "Derivações cisto-peritoneais",
        "k": "200",
        "c": "0",
        "code": "45.07.00.04"
    },
    {
        "id": 2651,
        "label": "Derivações lombo-peritoneais",
        "k": "200",
        "c": "0",
        "code": "45.07.00.05"
    },
    {
        "id": 2652,
        "label": "Ventrículostomia endoscópica",
        "k": "300",
        "c": "0",
        "code": "45.07.00.06"
    },
    {
        "id": 2653,
        "label": "Revisões das derivações",
        "k": "140",
        "c": "0",
        "code": "45.07.00.07"
    },
    {
        "id": 2654,
        "label": "Leucotomia estereotáxica",
        "k": "200",
        "c": "0",
        "code": "45.08.00.01"
    },
    {
        "id": 2655,
        "label": "Hemisferectomia",
        "k": "380",
        "c": "0",
        "code": "45.08.00.02"
    },
    {
        "id": 2656,
        "label": "Intervenções estereotáxicas talamicas",
        "k": "300",
        "c": "0",
        "code": "45.08.00.03"
    },
    {
        "id": 2657,
        "label": "Cordotomias",
        "k": "220",
        "c": "0",
        "code": "45.08.00.04"
    },
    {
        "id": 2658,
        "label": "Cirurgia da epilepsia com registo operatório",
        "k": "400",
        "c": "0",
        "code": "45.08.00.05"
    },
    {
        "id": 2659,
        "label": "Calosotomia",
        "k": "300",
        "c": "0",
        "code": "45.08.00.06"
    },
    {
        "id": 2660,
        "label": "Descompressão nicrovascular de pares cranianos",
        "k": "300",
        "c": "0",
        "code": "45.08.00.07"
    },
    {
        "id": 2661,
        "label": "Tratamento percutâneo da nevralgia do trigémio",
        "k": "200",
        "c": "0",
        "code": "45.08.00.08"
    },
    {
        "id": 2662,
        "label": "Lesão da DREZ",
        "k": "300",
        "c": "0",
        "code": "45.08.00.09"
    },
    {
        "id": 2663,
        "label": "Rizotomia",
        "k": "200",
        "c": "0",
        "code": "45.08.00.10"
    },
    {
        "id": 2664,
        "label": "Comissurotomia",
        "k": "300",
        "c": "0",
        "code": "45.08.00.11"
    },
    {
        "id": 2665,
        "label": "Outras cirurgias percutâneas da dor",
        "k": "200",
        "c": "0",
        "code": "45.08.00.12"
    },
    {
        "id": 2666,
        "label": "Neurólises",
        "k": "90",
        "c": "0",
        "code": "45.09.00.01"
    },
    {
        "id": 2667,
        "label": "Transposições",
        "k": "110",
        "c": "0",
        "code": "45.09.00.02"
    },
    {
        "id": 2668,
        "label": "Neurorrafias com microcirurgia",
        "k": "150",
        "c": "0",
        "code": "45.09.00.03"
    },
    {
        "id": 2669,
        "label": "Cirurgia do plexo braquial",
        "k": "350",
        "c": "0",
        "code": "45.09.00.04"
    },
    {
        "id": 2670,
        "label": "Sindroma do túnel cárpico ou do canal de Guyon",
        "k": "120",
        "c": "0",
        "code": "45.09.00.05"
    },
    {
        "id": 2671,
        "label": "Tratamento cirúrgico da meralgia parestésica",
        "k": "120",
        "c": "0",
        "code": "45.09.00.06"
    },
    {
        "id": 2672,
        "label": "Excisão de neuroma traumático dos nervos periféricos",
        "k": "180",
        "c": "0",
        "code": "45.09.00.07"
    },
    {
        "id": 2673,
        "label": "Excisão de neuroma traumático dos nervos periféricos com enxerto",
        "k": "300",
        "c": "0",
        "code": "45.09.00.08"
    },
    {
        "id": 2674,
        "label": "Excisão de tumores de nervos periféricos sem reparação",
        "k": "200",
        "c": "0",
        "code": "45.09.00.09"
    },
    {
        "id": 2675,
        "label": "Excisão de tumores de nervos periféricos com reparação",
        "k": "300",
        "c": "0",
        "code": "45.09.00.10"
    },
    {
        "id": 2676,
        "label": "Excisão de neuroma post-traumático",
        "k": "120",
        "c": "0",
        "code": "45.09.00.11"
    },
    {
        "id": 2677,
        "label": "Excisão de neuroma post-traumático, com microcirurgia",
        "k": "160",
        "c": "0",
        "code": "45.09.00.12"
    },
    {
        "id": 2678,
        "label": "Excisão de tumores dos nervos periféricos (não incluindo reparação)",
        "k": "120",
        "c": "0",
        "code": "45.09.00.13"
    },
    {
        "id": 2679,
        "label": "Evisceração do globo ocular sem implante",
        "k": "80",
        "c": "0",
        "code": "46.00.00.01"
    },
    {
        "id": 2680,
        "label": "Evisceração do globo ocular com implante",
        "k": "100",
        "c": "0",
        "code": "46.00.00.02"
    },
    {
        "id": 2681,
        "label": "Enucleação do globo ocular sem implante",
        "k": "80",
        "c": "0",
        "code": "46.00.00.03"
    },
    {
        "id": 2682,
        "label": "Enucleação do globo ocular com implante",
        "k": "120",
        "c": "0",
        "code": "46.00.00.04"
    },
    {
        "id": 2683,
        "label": "Exenteração da órbita",
        "k": "200",
        "c": "0",
        "code": "46.00.00.05"
    },
    {
        "id": 2684,
        "label": "Exenteração da órbita com remoção de partes ósseas ou com transplante muscular",
        "k": "220",
        "c": "0",
        "code": "46.00.00.06"
    },
    {
        "id": 2685,
        "label": "Remoção de implante ocular",
        "k": "50",
        "c": "0",
        "code": "46.00.00.07"
    },
    {
        "id": 2686,
        "label": "Queratectomia lamelar, parcial, excepto pterígio (ex. quisto dermóide)",
        "k": "70",
        "c": "0",
        "code": "46.01.00.01"
    },
    {
        "id": 2687,
        "label": "Biópsia da córnea (ex: leucoplasia)",
        "k": "20",
        "c": "0",
        "code": "46.01.00.02"
    },
    {
        "id": 2688,
        "label": "Excisão ou transposição de pterígio, sem enxerto",
        "k": "60",
        "c": "0",
        "code": "46.01.00.03"
    },
    {
        "id": 2689,
        "label": "Excisão ou transposição de pterígio recidivado com enxerto",
        "k": "100",
        "c": "0",
        "code": "46.01.00.04"
    },
    {
        "id": 2690,
        "label": "Excisão ou transposição de pterígio recidivado com queratoplastia parcial",
        "k": "240",
        "c": "0",
        "code": "46.01.00.05"
    },
    {
        "id": 2691,
        "label": "Raspagem da córnea para diagnóstico",
        "k": "6",
        "c": "0",
        "code": "46.01.00.06"
    },
    {
        "id": 2692,
        "label": "Remoção do epitélio corneano",
        "k": "8",
        "c": "0",
        "code": "46.01.00.07"
    },
    {
        "id": 2693,
        "label": "Aplicação de agentes químicos e/ou físicos",
        "k": "10",
        "c": "0",
        "code": "46.01.00.08"
    },
    {
        "id": 2694,
        "label": "Tatuagem da córnea, mecânica ou química",
        "k": "40",
        "c": "0",
        "code": "46.01.00.09"
    },
    {
        "id": 2695,
        "label": "Remoção de corpo estranho superficial",
        "k": "8",
        "c": "0",
        "code": "46.01.00.10"
    },
    {
        "id": 2696,
        "label": "Sutura de ferida da córnea",
        "k": "120",
        "c": "0",
        "code": "46.01.00.11"
    },
    {
        "id": 2697,
        "label": "Queratoplastia lamelar (inclui preparação do material de enxerto)",
        "k": "240",
        "c": "0",
        "code": "46.01.00.12"
    },
    {
        "id": 2698,
        "label": "Queratoplastia penetrante (inclui preparação do material de enxerto)",
        "k": "240",
        "c": "0",
        "code": "46.01.00.13"
    },
    {
        "id": 2699,
        "label": "Queratoplastia lamelar na afaquia (inclui preparação do material de enxerto)",
        "k": "240",
        "c": "0",
        "code": "46.01.00.14"
    },
    {
        "id": 2700,
        "label": "Queratoplastia penetrante e queratoprótese (inclui preparação do material de enxerto)",
        "k": "280",
        "c": "0",
        "code": "46.01.00.15"
    },
    {
        "id": 2701,
        "label": "Queratomia refractiva para correcção óptica",
        "k": "90",
        "c": "0",
        "code": "46.01.00.16"
    },
    {
        "id": 2702,
        "label": "Queratomileusis",
        "k": "250",
        "c": "100",
        "code": "46.01.00.17"
    },
    {
        "id": 2703,
        "label": "Epiqueratoplastia",
        "k": "200",
        "c": "100",
        "code": "46.01.00.18"
    },
    {
        "id": 2704,
        "label": "Queratofaquia",
        "k": "250",
        "c": "100",
        "code": "46.01.00.19"
    },
    {
        "id": 2705,
        "label": "Fotoqueratectomia refractiva ou terapêutica",
        "k": "150",
        "c": "120",
        "code": "46.01.00.20"
    },
    {
        "id": 2706,
        "label": "Termoqueratoplastia",
        "k": "40",
        "c": "0",
        "code": "46.01.00.21"
    },
    {
        "id": 2707,
        "label": "Termoqueratoplastia refractiva",
        "k": "145",
        "c": "120",
        "code": "46.01.00.22"
    },
    {
        "id": 2708,
        "label": "Topografia Corneana",
        "k": "25",
        "c": "15",
        "code": "46.01.00.23"
    },
    {
        "id": 2709,
        "label": "Paracentese da câmara anterior para remoção ou aspiração de humor aquoso, hipópion ou hifema",
        "k": "50",
        "c": "0",
        "code": "46.02.00.01"
    },
    {
        "id": 2710,
        "label": "Paracentese da câmara anterior para remoção de humor vítreo e/ou libertação de sinéquias e/ou discisão da hialoideia anterior, com ou sem injecção de ar",
        "k": "90",
        "c": "0",
        "code": "46.02.00.02"
    },
    {
        "id": 2711,
        "label": "Goniotomia com ou sem goniopunção",
        "k": "145",
        "c": "0",
        "code": "46.02.00.03"
    },
    {
        "id": 2712,
        "label": "Goniopunção sem goniotomia",
        "k": "55",
        "c": "0",
        "code": "46.02.00.04"
    },
    {
        "id": 2713,
        "label": "Trabeculotomia ab externo",
        "k": "140",
        "c": "0",
        "code": "46.02.00.05"
    },
    {
        "id": 2714,
        "label": "Trabeculoplastia Laser",
        "k": "80",
        "c": "70",
        "code": "46.02.00.06"
    },
    {
        "id": 2715,
        "label": "Remoção de corpo estranho magnético",
        "k": "60",
        "c": "0",
        "code": "46.02.00.07"
    },
    {
        "id": 2716,
        "label": "Remoção de corpo estranho não magnético",
        "k": "90",
        "c": "0",
        "code": "46.02.00.08"
    },
    {
        "id": 2717,
        "label": "Introdução de lente intra-ocular para correcção da ametropia em olho fáquico",
        "k": "200",
        "c": "0",
        "code": "46.02.00.09"
    },
    {
        "id": 2718,
        "label": "Lise de sinéquias do segmento anterior, incluindo goniosinéquias, por incisão com ou sem injecção de ar/líquido (técnica isolada)",
        "k": "70",
        "c": "0",
        "code": "46.02.00.10"
    },
    {
        "id": 2719,
        "label": "Lise de sinéquias anteriores ou de sinéquias posteriores ou aderências corneovítreas com ou sem injecção de ar/líquido",
        "k": "55",
        "c": "0",
        "code": "46.02.00.11"
    },
    {
        "id": 2720,
        "label": "Remoção de invasão epitelial, câmara anterior",
        "k": "160",
        "c": "0",
        "code": "46.02.00.12"
    },
    {
        "id": 2721,
        "label": "Remoção de material de implante, segmento anterior",
        "k": "100",
        "c": "0",
        "code": "46.02.00.13"
    },
    {
        "id": 2722,
        "label": "Remoção de coágulo sanguíneo, segmento anterior",
        "k": "70",
        "c": "0",
        "code": "46.02.00.14"
    },
    {
        "id": 2723,
        "label": "Injecção de ar/líquido ou medicamento na câmara anterior",
        "k": "20",
        "c": "0",
        "code": "46.02.00.15"
    },
    {
        "id": 2724,
        "label": "Operação fistulizante para glaucoma com iridectomia",
        "k": "140",
        "c": "0",
        "code": "46.03.00.01"
    },
    {
        "id": 2725,
        "label": "Trabeculectomia ab externo (fistulizante protegida)",
        "k": "180",
        "c": "0",
        "code": "46.03.00.02"
    },
    {
        "id": 2726,
        "label": "Fistulização da esclerótica no glaucoma, iridencleisis",
        "k": "130",
        "c": "0",
        "code": "46.03.00.03"
    },
    {
        "id": 2727,
        "label": "Fistulização da esclerótica no glaucoma, trabeculectomia ab externo com encravamento escleral",
        "k": "190",
        "c": "0",
        "code": "46.03.00.04"
    },
    {
        "id": 2728,
        "label": "Fistulização esclerótica no glaucoma com colocação de tubo de Molteno ou similar",
        "k": "200",
        "c": "0",
        "code": "46.03.00.05"
    },
    {
        "id": 2729,
        "label": "Esclerotomia Holmium (cada sessão)",
        "k": "160",
        "c": "120",
        "code": "46.03.00.06"
    },
    {
        "id": 2730,
        "label": "Reconstrução da esclerótica por estafiloma sem enxerto",
        "k": "120",
        "c": "0",
        "code": "46.03.00.07"
    },
    {
        "id": 2731,
        "label": "Reconstrução da esclerótica por estafiloma com enxerto",
        "k": "200",
        "c": "0",
        "code": "46.03.00.08"
    },
    {
        "id": 2732,
        "label": "Remoção de corpo estranho superficial",
        "k": "8",
        "c": "0",
        "code": "46.03.00.09"
    },
    {
        "id": 2733,
        "label": "Sutura de ferida sem lesão da úvea",
        "k": "100",
        "c": "0",
        "code": "46.03.00.10"
    },
    {
        "id": 2734,
        "label": "Sutura de ferida com reposição ou ressecção da úvea",
        "k": "150",
        "c": "0",
        "code": "46.03.00.11"
    },
    {
        "id": 2735,
        "label": "Iridotomia simples/transfixiva",
        "k": "105",
        "c": "0",
        "code": "46.04.00.01"
    },
    {
        "id": 2736,
        "label": "Iridectomia com ciclectomia",
        "k": "150",
        "c": "0",
        "code": "46.04.00.02"
    },
    {
        "id": 2737,
        "label": "Iridectomia periférica ou em sector no glaucoma",
        "k": "120",
        "c": "0",
        "code": "46.04.00.03"
    },
    {
        "id": 2738,
        "label": "Iridectomia óptica",
        "k": "120",
        "c": "0",
        "code": "46.04.00.04"
    },
    {
        "id": 2739,
        "label": "Correcção de iridodiálise",
        "k": "150",
        "c": "0",
        "code": "46.04.00.05"
    },
    {
        "id": 2740,
        "label": "Ciclodiatermia",
        "k": "100",
        "c": "0",
        "code": "46.04.00.06"
    },
    {
        "id": 2741,
        "label": "Ciclocrioterapia",
        "k": "100",
        "c": "0",
        "code": "46.04.00.07"
    },
    {
        "id": 2742,
        "label": "Ciclodiálise",
        "k": "120",
        "c": "0",
        "code": "46.04.00.08"
    },
    {
        "id": 2743,
        "label": "Laserterapia (coreoplastia, gonioplastia e iridotomia (1 ou mais sessões))",
        "k": "65",
        "c": "70",
        "code": "46.04.00.09"
    },
    {
        "id": 2744,
        "label": "Fotocoagulação dos processos ciliares (1 ou mais sessões)",
        "k": "150",
        "c": "120",
        "code": "46.04.00.10"
    },
    {
        "id": 2745,
        "label": "Destruição de lesões quísticas ou outras da Íris e/ou do corpo ciliar por meios não cruentos",
        "k": "150",
        "c": "70",
        "code": "46.04.00.11"
    },
    {
        "id": 2746,
        "label": "Discisão do cristalino",
        "k": "90",
        "c": "0",
        "code": "46.05.00.01"
    },
    {
        "id": 2747,
        "label": "Discisão de catarata secundária e/ou membrana hialoideia anterior",
        "k": "90",
        "c": "0",
        "code": "46.05.00.02"
    },
    {
        "id": 2748,
        "label": "Remoção de catarata secundária com ou sem iridectomia (iridocapsulectomia ou iridocapsulotomia)",
        "k": "180",
        "c": "0",
        "code": "46.05.00.03"
    },
    {
        "id": 2749,
        "label": "Aspiração de material lenticular na sequência ou não de facofragmentação mecânica",
        "k": "180",
        "c": "0",
        "code": "46.05.00.04"
    },
    {
        "id": 2750,
        "label": "Facoemulsificação do cristalino com aspiração de material lenticular",
        "k": "200",
        "c": "50",
        "code": "46.05.00.05"
    },
    {
        "id": 2751,
        "label": "Facoemulsificação do cristalino com implantação de lente intraocular",
        "k": "280",
        "c": "50",
        "code": "46.05.00.06"
    },
    {
        "id": 2752,
        "label": "Extracção extracapsular programada",
        "k": "200",
        "c": "0",
        "code": "46.05.00.07"
    },
    {
        "id": 2753,
        "label": "Extracção intracapsular de catarata, com ou sem enzimas",
        "k": "180",
        "c": "0",
        "code": "46.05.00.08"
    },
    {
        "id": 2754,
        "label": "Extracção de cristalino luxado",
        "k": "200",
        "c": "0",
        "code": "46.05.00.09"
    },
    {
        "id": 2755,
        "label": "Extracção intracapsular ou extracapsular na presença de ampola de filtração",
        "k": "200",
        "c": "0",
        "code": "46.05.00.10"
    },
    {
        "id": 2756,
        "label": "Aplicação de qualquer lente intraocular simultaneamente à extracção de catarata",
        "k": "250",
        "c": "0",
        "code": "46.05.00.11"
    },
    {
        "id": 2757,
        "label": "Implantação secundária de lente intra-ocular",
        "k": "190",
        "c": "0",
        "code": "46.05.00.12"
    },
    {
        "id": 2758,
        "label": "Remoção de lente intraocular de câmara posterior",
        "k": "145",
        "c": "0",
        "code": "46.05.00.13"
    },
    {
        "id": 2759,
        "label": "Lentes intraoculares de suspensão escleral",
        "k": "240",
        "c": "0",
        "code": "46.05.00.14"
    },
    {
        "id": 2760,
        "label": "Capsulotomia Yag (por sessão)",
        "k": "65",
        "c": "80",
        "code": "46.05.00.15"
    },
    {
        "id": 2761,
        "label": "Vitrectomia parcial da câmara anterior, a céu aberto",
        "k": "100",
        "c": "0",
        "code": "46.06.00.01"
    },
    {
        "id": 2762,
        "label": "Vitrectomia sub-total, via anterior, utilizando vitrectomo mecânico",
        "k": "180",
        "c": "0",
        "code": "46.06.00.02"
    },
    {
        "id": 2763,
        "label": "Aspiração de vítreo ou de liquido sub-retiniano ou coroideu (esclerotomia posterior)",
        "k": "120",
        "c": "0",
        "code": "46.06.00.03"
    },
    {
        "id": 2764,
        "label": "Injecção de substituto de vítreo, via plana (pneumopexia)",
        "k": "80",
        "c": "0",
        "code": "46.06.00.04"
    },
    {
        "id": 2765,
        "label": "Discisão de bandas de vítreo sem remoção, via pars plana",
        "k": "150",
        "c": "0",
        "code": "46.06.00.05"
    },
    {
        "id": 2766,
        "label": "Liga de bandas de vítreo, adesões da interface do vítreo, bainhas, membranas ou opacidades por cirurgia laser",
        "k": "85",
        "c": "50",
        "code": "46.06.00.06"
    },
    {
        "id": 2767,
        "label": "Vitrectomia mecânica, via pars plana",
        "k": "250",
        "c": "50",
        "code": "46.06.00.07"
    },
    {
        "id": 2768,
        "label": "Remoção de corpo estranho magnético",
        "k": "180",
        "c": "0",
        "code": "46.06.00.08"
    },
    {
        "id": 2769,
        "label": "Remoção de corpo estranho, com vitrectomia",
        "k": "250",
        "c": "50",
        "code": "46.06.00.09"
    },
    {
        "id": 2770,
        "label": "Vitrectomia via pars plana associada à extracção do cristalino",
        "k": "250",
        "c": "50",
        "code": "46.06.00.10"
    },
    {
        "id": 2771,
        "label": "Vitrectomia via pars plana associada à extracção de cristalino com introdução de lente intraocular",
        "k": "360",
        "c": "50",
        "code": "46.06.00.11"
    },
    {
        "id": 2772,
        "label": "Vitrectomia mecânica complicada via pars plana, com tamponamento interno com ou sem extracção de corpo estranho intraocular, com ou sem cirurgia de cristalino",
        "k": "360",
        "c": "50",
        "code": "46.06.00.12"
    },
    {
        "id": 2773,
        "label": "Remoção de substituto de vítreo",
        "k": "95",
        "c": "0",
        "code": "46.06.00.13"
    },
    {
        "id": 2774,
        "label": "Crioterapia ou diatermia com ou sem drenagem de líquido subretiniano",
        "k": "130",
        "c": "0",
        "code": "46.07.00.01"
    },
    {
        "id": 2775,
        "label": "Depressão escleral localizada ou circular, com ou sem implante",
        "k": "240",
        "c": "0",
        "code": "46.07.00.02"
    },
    {
        "id": 2776,
        "label": "Qualquer técnica anterior associada à vitrectomia",
        "k": "280",
        "c": "50",
        "code": "46.07.00.03"
    },
    {
        "id": 2777,
        "label": "Cirurgia de descolamento de retina com vitrectomia associada a tamponamento",
        "k": "320",
        "c": "50",
        "code": "46.07.00.04"
    },
    {
        "id": 2778,
        "label": "Cirurgia de descolamento de retina com vitrectomia a céu aberto e tamponamento interno",
        "k": "360",
        "c": "50",
        "code": "46.07.00.05"
    },
    {
        "id": 2779,
        "label": "Cirurgia de descolamento de retina com vitrectomia, tamponamento interno e extracção de cristalino",
        "k": "360",
        "c": "50",
        "code": "46.07.00.06"
    },
    {
        "id": 2780,
        "label": "Cirurgia de descolamento de retina com vitrectomia e segmentação, delaminação e corte de membranas de vítreo ou subretinianas, neovasos com ou sem endolaser, com ou sem cirurgia do cristalino",
        "k": "400",
        "c": "50",
        "code": "46.07.00.07"
    },
    {
        "id": 2781,
        "label": "Reoperação de descolamento de retina sem vitrectomia",
        "k": "200",
        "c": "0",
        "code": "46.07.00.08"
    },
    {
        "id": 2782,
        "label": "Reoperação de descolamento de retina com vitrectomia",
        "k": "320",
        "c": "50",
        "code": "46.07.00.09"
    },
    {
        "id": 2783,
        "label": "Remoção de material implantado no segmento posterior",
        "k": "50",
        "c": "0",
        "code": "46.07.00.10"
    },
    {
        "id": 2784,
        "label": "Implante e remoção de fonte de radiações",
        "k": "160",
        "c": "0",
        "code": "46.07.00.11"
    },
    {
        "id": 2785,
        "label": "Crioterapia ou diatermia (por sessão)",
        "k": "95",
        "c": "0",
        "code": "46.07.00.12"
    },
    {
        "id": 2786,
        "label": "Fotocoagulação Xenon",
        "k": "80",
        "c": "40",
        "code": "46.07.00.13"
    },
    {
        "id": 2787,
        "label": "Laser Argon azul-verde",
        "k": "80",
        "c": "70",
        "code": "46.07.00.14"
    },
    {
        "id": 2788,
        "label": "Laser monocromático",
        "k": "80",
        "c": "90",
        "code": "46.07.00.15"
    },
    {
        "id": 2789,
        "label": "Laser Yag",
        "k": "80",
        "c": "80",
        "code": "46.07.00.16"
    },
    {
        "id": 2790,
        "label": "Esclerocoroidotomia para remoção de tumor com ou sem vitrectomia",
        "k": "360",
        "c": "50",
        "code": "46.07.00.17"
    },
    {
        "id": 2791,
        "label": "Biópsia de músculo oculo-motor",
        "k": "40",
        "c": "0",
        "code": "46.08.00.01"
    },
    {
        "id": 2792,
        "label": "Sutura de músculos oculomotores e tendões e/ou a cápsula de Tenon",
        "k": "60",
        "c": "0",
        "code": "46.08.00.02"
    },
    {
        "id": 2793,
        "label": "Enfraquecimento/reforço de um músculo",
        "k": "110",
        "c": "0",
        "code": "46.08.01.01"
    },
    {
        "id": 2794,
        "label": "Enfraquecimento/reforço de dois músculos",
        "k": "130",
        "c": "0",
        "code": "46.08.01.02"
    },
    {
        "id": 2795,
        "label": "Enfraquecimento/reforço de três músculos",
        "k": "145",
        "c": "0",
        "code": "46.08.01.03"
    },
    {
        "id": 2796,
        "label": "Enfraquecimento/reforço de quatro músculos",
        "k": "160",
        "c": "0",
        "code": "46.08.01.04"
    },
    {
        "id": 2797,
        "label": "Miopexia retroequatorial de um músculo",
        "k": "145",
        "c": "0",
        "code": "46.08.01.05"
    },
    {
        "id": 2798,
        "label": "Miopexia retroequatorial de dois músculos",
        "k": "175",
        "c": "0",
        "code": "46.08.01.06"
    },
    {
        "id": 2799,
        "label": "Miopexia retroequatorial de um músculo associado a enfraquecimento/reforço de dois músculos",
        "k": "190",
        "c": "0",
        "code": "46.08.01.07"
    },
    {
        "id": 2800,
        "label": "Miopexia retroequatorial de um músculo associada a enfraquecimento/reforço de três músculos",
        "k": "210",
        "c": "0",
        "code": "46.08.01.08"
    },
    {
        "id": 2801,
        "label": "Miopexia retroequatorial de dois músculos associada a enfraquecimento/reforço de um músculo",
        "k": "210",
        "c": "0",
        "code": "46.08.01.09"
    },
    {
        "id": 2802,
        "label": "Miopexia retroequatorial de dois músculos associada a enfraquecimento/reforço de dois músculos",
        "k": "225",
        "c": "0",
        "code": "46.08.01.10"
    },
    {
        "id": 2803,
        "label": "Cirurgia ajustável sobre um músculo (Incluí o ajuste a efectuar posteriormente)",
        "k": "165",
        "c": "0",
        "code": "46.08.01.11"
    },
    {
        "id": 2804,
        "label": "Cirurgia ajustável sobre dois músculos (incluí o ajuste a efectuar posterirmente)",
        "k": "190",
        "c": "0",
        "code": "46.08.01.12"
    },
    {
        "id": 2805,
        "label": "Cirurgia ajustável de um músculo associada a enfraquecimento/reforço/miopexia de um músculo (incluí ajuste a efectuar posteriormente)",
        "k": "200",
        "c": "0",
        "code": "46.08.01.13"
    },
    {
        "id": 2806,
        "label": "Cirurgia ajustável de um músculo associada a enfraquecimento/reforço/miopexia de dois músculos (incluí ajuste a efectuar posteriormente)",
        "k": "240",
        "c": "0",
        "code": "46.08.01.14"
    },
    {
        "id": 2807,
        "label": "Transposição muscular de um músculo no estrabismo paralítico",
        "k": "120",
        "c": "0",
        "code": "46.08.01.15"
    },
    {
        "id": 2808,
        "label": "Transposição muscular de um músculo no estrabismo paralítico associada a enfraquecimento/reforço/miopexia de um músculo)",
        "k": "145",
        "c": "0",
        "code": "46.08.01.16"
    },
    {
        "id": 2809,
        "label": "Transposição muscular de um músculo no estrabismo paralítico associada a enfraquecimento/reforço/miopexia de dois músculos)",
        "k": "175",
        "c": "0",
        "code": "46.08.01.17"
    },
    {
        "id": 2810,
        "label": "Transposição múscular de dois músculos no estrabismo paralítico",
        "k": "160",
        "c": "0",
        "code": "46.08.01.18"
    },
    {
        "id": 2811,
        "label": "Transposição muscular de dois músculos no estrabismo paralítico, associada a enfraquecimento/reforço de um músculo",
        "k": "175",
        "c": "0",
        "code": "46.08.01.19"
    },
    {
        "id": 2812,
        "label": "Transposição muscular de dois músculos no estrabismo paralítico, associada a enfraquecimento/reforço de dois músculos",
        "k": "225",
        "c": "0",
        "code": "46.08.01.20"
    },
    {
        "id": 2813,
        "label": "Injecção de toxina botulínica (cada sessão)",
        "k": "65",
        "c": "0",
        "code": "46.08.01.21"
    },
    {
        "id": 2814,
        "label": "Exploradora com ou sem biópsia",
        "k": "100",
        "c": "0",
        "code": "46.09.00.01"
    },
    {
        "id": 2815,
        "label": "Extracção de tumor",
        "k": "170",
        "c": "0",
        "code": "46.09.00.02"
    },
    {
        "id": 2816,
        "label": "Extracção de corpo estranho",
        "k": "200",
        "c": "0",
        "code": "46.09.00.03"
    },
    {
        "id": 2817,
        "label": "Biópsia por aspiração transconjuntival",
        "k": "20",
        "c": "0",
        "code": "46.09.00.04"
    },
    {
        "id": 2818,
        "label": "Remoção de tumor",
        "k": "250",
        "c": "0",
        "code": "46.09.01.01"
    },
    {
        "id": 2819,
        "label": "Extracção de corpo estranho",
        "k": "270",
        "c": "0",
        "code": "46.09.01.02"
    },
    {
        "id": 2820,
        "label": "Drenagem ou descompressão",
        "k": "200",
        "c": "0",
        "code": "46.09.01.03"
    },
    {
        "id": 2821,
        "label": "Exploradora com ou sem biópsia",
        "k": "200",
        "c": "0",
        "code": "46.09.01.04"
    },
    {
        "id": 2822,
        "label": "Extracção total ou parcial de tumor ou extracção de corpo estranho-participação de oftalmologista",
        "k": "100",
        "c": "0",
        "code": "46.09.02.01"
    },
    {
        "id": 2823,
        "label": "Injecção retrobulbar de álcool, ar, contraste ou outros agentes de terapêutica e de diagnóstico",
        "k": "9",
        "c": "0",
        "code": "46.09.03.01"
    },
    {
        "id": 2824,
        "label": "Injecção terapêutica na cápsula de Tenon",
        "k": "9",
        "c": "0",
        "code": "46.09.03.02"
    },
    {
        "id": 2825,
        "label": "Inserção de implante orbitário exterior ao cone muscular (ex: reconstituição de parede orbitária) colaboração de oftalmologista com neurocirurgião e/ou otorrinolaringologista e/ou cirurgião plástico",
        "k": "100",
        "c": "0",
        "code": "46.09.03.03"
    },
    {
        "id": 2826,
        "label": "Remoção ou revisão de implante da órbita, exterior ao cone muscular",
        "k": "80",
        "c": "0",
        "code": "46.09.03.04"
    },
    {
        "id": 2827,
        "label": "Drenagem de abcesso",
        "k": "15",
        "c": "0",
        "code": "46.10.00.01"
    },
    {
        "id": 2828,
        "label": "Extracção de chalázio ou de quisto palpebral único",
        "k": "30",
        "c": "0",
        "code": "46.10.00.02"
    },
    {
        "id": 2829,
        "label": "Extracção de chalázio ou de quisto palpebral, múltiplos",
        "k": "35",
        "c": "0",
        "code": "46.10.00.03"
    },
    {
        "id": 2830,
        "label": "Extracção de chalázio ou de quisto palpebral, com anestesia geral e/ou hospitalização",
        "k": "45",
        "c": "0",
        "code": "46.10.00.04"
    },
    {
        "id": 2831,
        "label": "Biópsias das pálpebras",
        "k": "10",
        "c": "0",
        "code": "46.10.00.05"
    },
    {
        "id": 2832,
        "label": "Electrocoagulação de cílios",
        "k": "10",
        "c": "0",
        "code": "46.10.00.06"
    },
    {
        "id": 2833,
        "label": "Correcção de triquíase e distriquiase",
        "k": "80",
        "c": "0",
        "code": "46.10.00.07"
    },
    {
        "id": 2834,
        "label": "Excisão de lesão palpebral sem plastia (excepto chalázio)",
        "k": "35",
        "c": "0",
        "code": "46.10.00.08"
    },
    {
        "id": 2835,
        "label": "Destruição física ou química de lesão do bordo palpebral",
        "k": "15",
        "c": "0",
        "code": "46.10.00.09"
    },
    {
        "id": 2836,
        "label": "Tarsorrafia",
        "k": "40",
        "c": "0",
        "code": "46.10.00.10"
    },
    {
        "id": 2837,
        "label": "Abertura da Tarsorrafia",
        "k": "10",
        "c": "0",
        "code": "46.10.00.11"
    },
    {
        "id": 2838,
        "label": "Correcção de ptose: técnica do músculo frontal com sutura (ex:Op. de Friedenwald)",
        "k": "100",
        "c": "0",
        "code": "46.10.00.12"
    },
    {
        "id": 2839,
        "label": "Correcção de ptose, outras técnicas",
        "k": "130",
        "c": "0",
        "code": "46.10.00.13"
    },
    {
        "id": 2840,
        "label": "Correcção de retracção palpebral",
        "k": "100",
        "c": "0",
        "code": "46.10.00.14"
    },
    {
        "id": 2841,
        "label": "Blefaroplastia com excisão de cunha tarsal (ectrópico e entrópio)",
        "k": "80",
        "c": "0",
        "code": "46.10.00.15"
    },
    {
        "id": 2842,
        "label": "Blefaroplastia extensa (ectrópio e entrópio) (ex: operações tipo Kuhnt Szymanowski e Wheeler-Fox)",
        "k": "150",
        "c": "0",
        "code": "46.10.00.16"
    },
    {
        "id": 2843,
        "label": "Blefaroplastia extensa para correcção da Blefarofimose e do epicantus",
        "k": "150",
        "c": "0",
        "code": "46.10.00.17"
    },
    {
        "id": 2844,
        "label": "Sutura de ferida incisa recente envolvendo as estruturas superficiais e bordo",
        "k": "40",
        "c": "0",
        "code": "46.10.00.18"
    },
    {
        "id": 2845,
        "label": "Sutura de ferida incisa recente envolvendo toda a espessura da pálpebra",
        "k": "80",
        "c": "0",
        "code": "46.10.00.19"
    },
    {
        "id": 2846,
        "label": "Remoção de corpo estranho",
        "k": "25",
        "c": "0",
        "code": "46.10.00.20"
    },
    {
        "id": 2847,
        "label": "Cantoplastia (reconstrução do canto)",
        "k": "40",
        "c": "0",
        "code": "46.10.00.21"
    },
    {
        "id": 2848,
        "label": "Reconstrução e sutura de ferida lacero-contusa, envolvendo todas as estruturas da pálpebra até 1/3 da sua extensão, podendo incluir enxerto de pele, simples ou pediculado",
        "k": "95",
        "c": "0",
        "code": "46.10.00.22"
    },
    {
        "id": 2849,
        "label": "Idem, envolvendo mais de 1/3 do bordo",
        "k": "120",
        "c": "0",
        "code": "46.10.00.23"
    },
    {
        "id": 2850,
        "label": "Reconstrução de toda a espessura palpebral por retalho tarso-conjuntival da palpebra oposta",
        "k": "140",
        "c": "0",
        "code": "46.10.00.24"
    },
    {
        "id": 2851,
        "label": "Incisão para drenagem de quisto",
        "k": "10",
        "c": "0",
        "code": "46.11.00.01"
    },
    {
        "id": 2852,
        "label": "Biópsia",
        "k": "10",
        "c": "0",
        "code": "46.11.00.02"
    },
    {
        "id": 2853,
        "label": "Excisão ou destruição de lesão da conjuntiva",
        "k": "20",
        "c": "0",
        "code": "46.11.00.03"
    },
    {
        "id": 2854,
        "label": "Injecção sub-conjuntival",
        "k": "9",
        "c": "0",
        "code": "46.11.00.04"
    },
    {
        "id": 2855,
        "label": "Conjuntivoplastia, por enxerto conjuntival ou por deslizamento",
        "k": "70",
        "c": "0",
        "code": "46.11.00.05"
    },
    {
        "id": 2856,
        "label": "Conjuntivoplastia com enxerto de mucosa",
        "k": "100",
        "c": "0",
        "code": "46.11.00.06"
    },
    {
        "id": 2857,
        "label": "Reconstrução de fundo de saco com mucosa",
        "k": "150",
        "c": "0",
        "code": "46.11.00.07"
    },
    {
        "id": 2858,
        "label": "Cirurgia de simblefaro, sem enxerto",
        "k": "60",
        "c": "0",
        "code": "46.11.00.08"
    },
    {
        "id": 2859,
        "label": "Cirurgia do simblefaro, com enxerto de mucosa labial",
        "k": "160",
        "c": "0",
        "code": "46.11.00.09"
    },
    {
        "id": 2860,
        "label": "Remoção de corpo estranho superficial",
        "k": "6",
        "c": "0",
        "code": "46.11.00.10"
    },
    {
        "id": 2861,
        "label": "Sutura de ferida da conjuntiva",
        "k": "15",
        "c": "0",
        "code": "46.11.00.11"
    },
    {
        "id": 2862,
        "label": "Biópsia da glândula lacrimal",
        "k": "30",
        "c": "0",
        "code": "46.12.00.01"
    },
    {
        "id": 2863,
        "label": "Incisão do saco lacrimal para drenagem(dacriocistomia)",
        "k": "15",
        "c": "0",
        "code": "46.12.00.02"
    },
    {
        "id": 2864,
        "label": "Exérese do saco lacrimal (dacriocistectotomia)",
        "k": "100",
        "c": "0",
        "code": "46.12.00.03"
    },
    {
        "id": 2865,
        "label": "Remoção de corpo estranho das vias lacrimais (dacriolito)",
        "k": "40",
        "c": "0",
        "code": "46.12.00.04"
    },
    {
        "id": 2866,
        "label": "Reconstrução dos canaliculos",
        "k": "160",
        "c": "0",
        "code": "46.12.00.05"
    },
    {
        "id": 2867,
        "label": "Correcção dos pontos lacrimais evertidos",
        "k": "80",
        "c": "0",
        "code": "46.12.00.06"
    },
    {
        "id": 2868,
        "label": "Dacriacistorinostomia (fistulização do saco lacrimal para a cavidade nasal)",
        "k": "160",
        "c": "0",
        "code": "46.12.00.07"
    },
    {
        "id": 2869,
        "label": "Conjuntivorinostomia com ou sem inserção de tubo",
        "k": "160",
        "c": "0",
        "code": "46.12.00.08"
    },
    {
        "id": 2870,
        "label": "Obturação permanente ou temporária das vias lacrimais",
        "k": "20",
        "c": "0",
        "code": "46.12.00.09"
    },
    {
        "id": 2871,
        "label": "Correcção de fístula lacrimal",
        "k": "40",
        "c": "0",
        "code": "46.12.00.10"
    },
    {
        "id": 2872,
        "label": "Sondagem do canal lacrimo-nasal, com ou sem irrigação",
        "k": "10",
        "c": "0",
        "code": "46.12.00.11"
    },
    {
        "id": 2873,
        "label": "Idem, exigindo anestesia geral",
        "k": "30",
        "c": "0",
        "code": "46.12.00.12"
    },
    {
        "id": 2874,
        "label": "Injecção do meio de contraste para da criocistografia",
        "k": "30",
        "c": "0",
        "code": "46.12.00.13"
    },
    {
        "id": 2875,
        "label": "Entubação prolongada das vias lacrimais",
        "k": "80",
        "c": "0",
        "code": "46.12.00.14"
    },
    {
        "id": 2876,
        "label": "Extracção de corpo estranho",
        "k": "7",
        "c": "0",
        "code": "47.00.00.01"
    },
    {
        "id": 2877,
        "label": "Extracção de corpo estranho c/anestesia geral",
        "k": "20",
        "c": "0",
        "code": "47.00.00.02"
    },
    {
        "id": 2878,
        "label": "Idem, por via retro-auricular",
        "k": "80",
        "c": "0",
        "code": "47.00.00.03"
    },
    {
        "id": 2879,
        "label": "Drenagem de abcesso, otohematoma",
        "k": "15",
        "c": "0",
        "code": "47.00.00.04"
    },
    {
        "id": 2880,
        "label": "Polipectomia do ouvido",
        "k": "20",
        "c": "0",
        "code": "47.00.00.05"
    },
    {
        "id": 2881,
        "label": "Miringotomia com anestesia geral ou local unilateral (sob visão microscópica)",
        "k": "30",
        "c": "0",
        "code": "47.00.00.06"
    },
    {
        "id": 2882,
        "label": "Miringotomia com anestesia geral ou local bilateral (sob visão microscópica)",
        "k": "45",
        "c": "0",
        "code": "47.00.00.07"
    },
    {
        "id": 2883,
        "label": "Miringotomia com aplicação de tubo de ventilação unilateral (sob visão microscópica)",
        "k": "50",
        "c": "0",
        "code": "47.00.00.08"
    },
    {
        "id": 2884,
        "label": "Miringotomia com aplicação de tubo de ventilação bilateral (sob visão microscópica)",
        "k": "80",
        "c": "0",
        "code": "47.00.00.09"
    },
    {
        "id": 2885,
        "label": "Correcção de exostose do canal auditivo externo",
        "k": "110",
        "c": "0",
        "code": "47.00.00.10"
    },
    {
        "id": 2886,
        "label": "Mastoidectomia",
        "k": "125",
        "c": "0",
        "code": "47.00.00.11"
    },
    {
        "id": 2887,
        "label": "Mastoidectomia radical",
        "k": "200",
        "c": "0",
        "code": "47.00.00.12"
    },
    {
        "id": 2888,
        "label": "Timpanomastoidectomia com conservação da parede do C.A.E. com timpanoplastia",
        "k": "300",
        "c": "0",
        "code": "47.00.00.13"
    },
    {
        "id": 2889,
        "label": "Timpanomastoidectomia sem conservação da parede do C.A.E. (com timpanoplastia)",
        "k": "350",
        "c": "0",
        "code": "47.00.00.14"
    },
    {
        "id": 2890,
        "label": "Timpanoplastia",
        "k": "200",
        "c": "0",
        "code": "47.00.00.15"
    },
    {
        "id": 2891,
        "label": "Timpanotomia exploradora",
        "k": "110",
        "c": "0",
        "code": "47.00.00.16"
    },
    {
        "id": 2892,
        "label": "Estapedectomia ou estapedotomia",
        "k": "200",
        "c": "0",
        "code": "47.00.00.17"
    },
    {
        "id": 2893,
        "label": "Labirintectomia transaural",
        "k": "200",
        "c": "0",
        "code": "47.00.00.18"
    },
    {
        "id": 2894,
        "label": "Descompressão do saco endolinfático",
        "k": "250",
        "c": "0",
        "code": "47.00.00.19"
    },
    {
        "id": 2895,
        "label": "Neurectomia vestibular (fossa média)",
        "k": "300",
        "c": "0",
        "code": "47.00.00.20"
    },
    {
        "id": 2896,
        "label": "Descompressão de 2a. e 3a. porções do nervo facial",
        "k": "300",
        "c": "0",
        "code": "47.00.00.21"
    },
    {
        "id": 2897,
        "label": "Descompressão da 1a. porção (fossa média)",
        "k": "280",
        "c": "0",
        "code": "47.00.00.22"
    },
    {
        "id": 2898,
        "label": "Enxerto facial (2a. e 3a. porções)",
        "k": "250",
        "c": "0",
        "code": "47.00.00.23"
    },
    {
        "id": 2899,
        "label": "Anastomose hipoglosso-facial",
        "k": "200",
        "c": "0",
        "code": "47.00.00.24"
    },
    {
        "id": 2900,
        "label": "Enxerto cruzado facio-facial",
        "k": "250",
        "c": "0",
        "code": "47.00.00.25"
    },
    {
        "id": 2901,
        "label": "Exérese neurinoma do acústico (via translabiríntica)",
        "k": "300",
        "c": "0",
        "code": "47.00.00.26"
    },
    {
        "id": 2902,
        "label": "Ressecção do pavilhão auricular sem reconstrução e sem esvaziamento ganglionar",
        "k": "80",
        "c": "0",
        "code": "47.00.00.27"
    },
    {
        "id": 2903,
        "label": "Idem, com esvaziamento ganglionar",
        "k": "200",
        "c": "0",
        "code": "47.00.00.28"
    },
    {
        "id": 2904,
        "label": "Reconstrução auricular por agenesia ou trauma (tempo principal)",
        "k": "120",
        "c": "0",
        "code": "47.00.00.29"
    },
    {
        "id": 2905,
        "label": "Idem, tempos complementares (cada)",
        "k": "60",
        "c": "0",
        "code": "47.00.00.30"
    },
    {
        "id": 2906,
        "label": "Otoplastia unilateral",
        "k": "80",
        "c": "0",
        "code": "47.00.00.31"
    },
    {
        "id": 2907,
        "label": "Otoplastia bilateral",
        "k": "120",
        "c": "0",
        "code": "47.00.00.32"
    },
    {
        "id": 2908,
        "label": "Petrosectomia com conservação do nervo facial",
        "k": "360",
        "c": "0",
        "code": "47.00.00.33"
    },
    {
        "id": 2909,
        "label": "Idem, sem conservação do nervo facial",
        "k": "320",
        "c": "0",
        "code": "47.00.00.34"
    },
    {
        "id": 2910,
        "label": "Exérese de tumor glómico timpânico",
        "k": "220",
        "c": "0",
        "code": "47.00.00.35"
    },
    {
        "id": 2911,
        "label": "Exérese de tumor jugular localizado",
        "k": "280",
        "c": "0",
        "code": "47.00.00.36"
    },
    {
        "id": 2912,
        "label": "Exérese de tumor jugular com invasão intracraniana",
        "k": "370",
        "c": "0",
        "code": "47.00.00.37"
    },
    {
        "id": 2913,
        "label": "Exérese de tumor na base do crânio",
        "k": "330",
        "c": "0",
        "code": "47.00.00.38"
    },
    {
        "id": 2914,
        "label": "Implante coclear",
        "k": "300",
        "c": "0",
        "code": "47.00.00.39"
    },
    {
        "id": 2915,
        "label": "Implante osteointegrado",
        "k": "200",
        "c": "0",
        "code": "47.00.00.40"
    },
    {
        "id": 2916,
        "label": "Reconstrução da cavidade de esvaziamento",
        "k": "160",
        "c": "0",
        "code": "47.00.00.41"
    },
    {
        "id": 2917,
        "label": "Reconstrução do C.A.E. por agenesia",
        "k": "280",
        "c": "0",
        "code": "47.00.00.42"
    },
    {
        "id": 2918,
        "label": "Pele",
        "k": "15",
        "c": "8",
        "code": "48.00.00.01"
    },
    {
        "id": 2919,
        "label": "Mama",
        "k": "20",
        "c": "0",
        "code": "48.00.00.02"
    },
    {
        "id": 2920,
        "label": "Tecidos Moles",
        "k": "20",
        "c": "0",
        "code": "48.00.00.03"
    },
    {
        "id": 2921,
        "label": "Músculo",
        "k": "20",
        "c": "0",
        "code": "48.00.00.04"
    },
    {
        "id": 2922,
        "label": "Nervo",
        "k": "20",
        "c": "0",
        "code": "48.00.00.05"
    },
    {
        "id": 2923,
        "label": "Pénis",
        "k": "15",
        "c": "0",
        "code": "48.00.00.06"
    },
    {
        "id": 2924,
        "label": "Testículo",
        "k": "30",
        "c": "0",
        "code": "48.00.00.07"
    },
    {
        "id": 2925,
        "label": "Vulva",
        "k": "15",
        "c": "0",
        "code": "48.00.00.08"
    },
    {
        "id": 2926,
        "label": "Vagina",
        "k": "20",
        "c": "0",
        "code": "48.00.00.09"
    },
    {
        "id": 2927,
        "label": "Osso",
        "k": "50",
        "c": "0",
        "code": "48.00.00.10"
    },
    {
        "id": 2928,
        "label": "Gânglio superficial",
        "k": "30",
        "c": "0",
        "code": "48.00.00.11"
    },
    {
        "id": 2929,
        "label": "Gânglio profundo",
        "k": "40",
        "c": "0",
        "code": "48.00.00.12"
    },
    {
        "id": 2930,
        "label": "Rectal",
        "k": "30",
        "c": "0",
        "code": "48.00.00.13"
    },
    {
        "id": 2931,
        "label": "Tiroideia",
        "k": "30",
        "c": "0",
        "code": "48.00.00.14"
    },
    {
        "id": 2932,
        "label": "Se cirurgia superior",
        "k": "300",
        "c": "0",
        "code": "50.00.00.01"
    },
    {
        "id": 2933,
        "label": "Se cirurgia de 900 K a 801 K",
        "k": "255",
        "c": "0",
        "code": "50.00.00.02"
    },
    {
        "id": 2934,
        "label": "Se cirurgia de 800 K a 701 K",
        "k": "225",
        "c": "0",
        "code": "50.00.00.03"
    },
    {
        "id": 2935,
        "label": "Se cirurgia de 700 K a 601 K",
        "k": "195",
        "c": "0",
        "code": "50.00.00.04"
    },
    {
        "id": 2936,
        "label": "Se cirurgia de 600 K a 561 K",
        "k": "175",
        "c": "0",
        "code": "50.00.00.05"
    },
    {
        "id": 2937,
        "label": "Se cirurgia de 560 K a 511 K",
        "k": "160",
        "c": "0",
        "code": "50.00.00.06"
    },
    {
        "id": 2938,
        "label": "Se cirurgia de 510 K a 481 K",
        "k": "150",
        "c": "0",
        "code": "50.00.00.07"
    },
    {
        "id": 2939,
        "label": "Se cirurgia de 480 K a 461 K",
        "k": "140",
        "c": "0",
        "code": "50.00.00.08"
    },
    {
        "id": 2940,
        "label": "Se cirurgia de 460 K a 421 K",
        "k": "130",
        "c": "0",
        "code": "50.00.00.09"
    },
    {
        "id": 2941,
        "label": "Se cirurgia de 420 K a 401 K",
        "k": "120",
        "c": "0",
        "code": "50.00.00.10"
    },
    {
        "id": 2942,
        "label": "Se cirurgia de 400 K a 341 K",
        "k": "110",
        "c": "0",
        "code": "50.00.00.11"
    },
    {
        "id": 2943,
        "label": "Se cirurgia de 340 K a 301 K",
        "k": "95",
        "c": "0",
        "code": "50.00.00.12"
    },
    {
        "id": 2944,
        "label": "Se cirurgia de 300 K a 281 K",
        "k": "87",
        "c": "0",
        "code": "50.00.00.13"
    },
    {
        "id": 2945,
        "label": "Se cirurgia de 280 K a 241 K",
        "k": "78",
        "c": "0",
        "code": "50.00.00.14"
    },
    {
        "id": 2946,
        "label": "Se cirurgia de 240 K a 201 K",
        "k": "66",
        "c": "0",
        "code": "50.00.00.15"
    },
    {
        "id": 2947,
        "label": "Se cirurgia de 200 K a 181 K",
        "k": "57",
        "c": "0",
        "code": "50.00.00.16"
    },
    {
        "id": 2948,
        "label": "Se cirurgia de 180 K a 161 K",
        "k": "51",
        "c": "0",
        "code": "50.00.00.17"
    },
    {
        "id": 2949,
        "label": "Se cirurgia de 160K a 141K",
        "k": "45",
        "c": "0",
        "code": "50.00.00.18"
    },
    {
        "id": 2950,
        "label": "Se cirurgia de 140K a 121K",
        "k": "39",
        "c": "0",
        "code": "50.00.00.19"
    },
    {
        "id": 2951,
        "label": "Se cirurgia de 120 K a 101 K",
        "k": "33",
        "c": "0",
        "code": "50.00.00.20"
    },
    {
        "id": 2952,
        "label": "Se cirurgia de 100 K a",
        "k": "27",
        "c": "0",
        "code": "50.00.00.21"
    },
    {
        "id": 2953,
        "label": "Se for inferior a 81 K",
        "k": "27",
        "c": "0",
        "code": "50.00.00.22"
    },
    {
        "id": 2954,
        "label": "Analgesia para trabalho de parto",
        "k": "35",
        "c": "0",
        "code": "50.01.00.01"
    },
    {
        "id": 2955,
        "label": "mais por hora",
        "k": "20",
        "c": "0",
        "code": "50.01.00.02"
    },
    {
        "id": 2956,
        "label": "Analgesia, sedação e/ou anestesia para exames complementares",
        "k": "35",
        "c": "0",
        "code": "50.01.00.03"
    },
    {
        "id": 2957,
        "label": "mais por hora",
        "k": "20",
        "c": "0",
        "code": "50.01.00.04"
    },
    {
        "id": 2958,
        "label": "Apoio de anestesista a actos cirúrgicos feitos sob,anestesia local",
        "k": "20",
        "c": "0",
        "code": "50.01.00.05"
    },
    {
        "id": 2959,
        "label": "mais por hora",
        "k": "20",
        "c": "0",
        "code": "50.01.00.06"
    },
    {
        "id": 2960,
        "label": "Anestesia para cardioversão",
        "k": "25",
        "c": "0",
        "code": "50.01.00.07"
    },
    {
        "id": 2961,
        "label": "Anestesia para convulsoterapia",
        "k": "25",
        "c": "0",
        "code": "50.01.00.08"
    },
    {
        "id": 2962,
        "label": "Bloqueio do gânglio estrelado-diag/terap.",
        "k": "18",
        "c": "0",
        "code": "50.02.00.01"
    },
    {
        "id": 2963,
        "label": "Bloqueio do gânglio estrelado-neurolítico",
        "k": "25",
        "c": "0",
        "code": "50.02.00.02"
    },
    {
        "id": 2964,
        "label": "Bloqueio do plexo celíaco-diag/terap",
        "k": "30",
        "c": "0",
        "code": "50.02.00.03"
    },
    {
        "id": 2965,
        "label": "Bloqueio do plexo celíaco-neurolítico",
        "k": "55",
        "c": "0",
        "code": "50.02.00.04"
    },
    {
        "id": 2966,
        "label": "Bloqueio do simpático lombar-diag/terap",
        "k": "30",
        "c": "0",
        "code": "50.02.00.05"
    },
    {
        "id": 2967,
        "label": "Bloqueio do simpático lombar-neurolítico",
        "k": "25",
        "c": "0",
        "code": "50.02.00.06"
    },
    {
        "id": 2968,
        "label": "Bloqueio extra-dural-diag/terap",
        "k": "12",
        "c": "0",
        "code": "50.02.01.01"
    },
    {
        "id": 2969,
        "label": "Bloqueio extra-dural-neurolítico",
        "k": "25",
        "c": "0",
        "code": "50.02.01.02"
    },
    {
        "id": 2970,
        "label": "Bloqueio sub-aracnoideu-diag/terap",
        "k": "18",
        "c": "0",
        "code": "50.02.01.03"
    },
    {
        "id": 2971,
        "label": "Bloqueio sub-aracnoideu-neurolitico",
        "k": "25",
        "c": "0",
        "code": "50.02.01.04"
    },
    {
        "id": 2972,
        "label": "V par – gânglio Gasser-diag/terap",
        "k": "30",
        "c": "0",
        "code": "50.02.02.01"
    },
    {
        "id": 2973,
        "label": "V par – gânglio Gasser-neurolítico",
        "k": "45",
        "c": "0",
        "code": "50.02.02.02"
    },
    {
        "id": 2974,
        "label": "De zona desencadeante",
        "k": "15",
        "c": "0",
        "code": "50.02.03.01"
    },
    {
        "id": 2975,
        "label": "Diag/terap",
        "k": "15",
        "c": "0",
        "code": "50.02.03.02"
    },
    {
        "id": 2976,
        "label": "Neurolítico",
        "k": "50",
        "c": "0",
        "code": "50.02.03.03"
    },
    {
        "id": 2977,
        "label": "Anestesia regional intravenosa (com fins terapêuticos)",
        "k": "25",
        "c": "0",
        "code": "50.02.04.01"
    },
    {
        "id": 2978,
        "label": "Estimulação transcutânea",
        "k": "10",
        "c": "0",
        "code": "50.02.04.02"
    },
    {
        "id": 2979,
        "label": "Hipertemia",
        "k": "80",
        "c": "0",
        "code": "50.02.04.03"
    },
    {
        "id": 2980,
        "label": "Intratecal drenagem do L.C.R.",
        "k": "25",
        "c": "0",
        "code": "50.02.04.04"
    },
    {
        "id": 2981,
        "label": "Intratecal com narcóticos",
        "k": "25",
        "c": "0",
        "code": "50.02.04.05"
    },
    {
        "id": 2982,
        "label": "Intratecal com soro gelado",
        "k": "50",
        "c": "0",
        "code": "50.02.04.06"
    },
    {
        "id": 2983,
        "label": "Intratecal com soro hipertónico",
        "k": "50",
        "c": "0",
        "code": "50.02.04.07"
    },
    {
        "id": 2984,
        "label": "Intratecal neuroadenolise hipofisária",
        "k": "150",
        "c": "0",
        "code": "50.02.04.08"
    },
    {
        "id": 2985,
        "label": "Anestesia local",
        "k": "3",
        "c": "0",
        "code": "50.02.04.09"
    },
    {
        "id": 2986,
        "label": "Reanimação cardio-respiratória e hemodinâmica em casos de paragem, shock, etc. 1a. Hora",
        "k": "35",
        "c": "0",
        "code": "50.03.00.01"
    },
    {
        "id": 2987,
        "label": "Idem, assistência permanente adicional, cada hora",
        "k": "15",
        "c": "0",
        "code": "50.03.00.02"
    },
    {
        "id": 2988,
        "label": "Idem, 2o. Dia e seguintes",
        "k": "20",
        "c": "0",
        "code": "50.03.00.03"
    },
    {
        "id": 2989,
        "label": "Desobstrução das vias aéreas",
        "k": "15",
        "c": "0",
        "code": "50.03.01.01"
    },
    {
        "id": 2990,
        "label": "Estabelecimento de ventilação assistida ou controlada com intubação nasal ou orotraqueal ou traqueotomia 1o dia",
        "k": "40",
        "c": "0",
        "code": "50.03.01.02"
    },
    {
        "id": 2991,
        "label": "Idem, 2o. Dia e seguintes",
        "k": "20",
        "c": "0",
        "code": "50.03.01.03"
    },
    {
        "id": 2992,
        "label": "Abdómen simples – 1 incidência",
        "k": "2",
        "c": "10",
        "code": "60.00.00.01"
    },
    {
        "id": 2993,
        "label": "Abdómen simples – 2 incidências",
        "k": "2",
        "c": "16",
        "code": "60.00.00.02"
    },
    {
        "id": 2994,
        "label": "Cavum ou Rino-Faringe",
        "k": "3",
        "c": "4",
        "code": "60.00.00.03"
    },
    {
        "id": 2995,
        "label": "Colangiografia endovenosa (excluindo estudo tomográfico)",
        "k": "8",
        "c": "27",
        "code": "60.00.00.04"
    },
    {
        "id": 2996,
        "label": "Colangiografia endovenosa com perfusão (excluindo estudo tomográfico)",
        "k": "8",
        "c": "27",
        "code": "60.00.00.05"
    },
    {
        "id": 2997,
        "label": "Colecistografia – 2 incidências + compressão doseada + Prova de Boyden",
        "k": "6",
        "c": "17",
        "code": "60.00.00.06"
    },
    {
        "id": 2998,
        "label": "Dentes – ortopantomografia facial",
        "k": "2",
        "c": "22",
        "code": "60.00.00.07"
    },
    {
        "id": 2999,
        "label": "Dentes todos em dentição completa",
        "k": "6",
        "c": "17",
        "code": "60.00.00.08"
    },
    {
        "id": 3000,
        "label": "Duodenografia hipotónica estudo complementar",
        "k": "6",
        "c": "15",
        "code": "60.00.00.09"
    },
    {
        "id": 3001,
        "label": "Esófago",
        "k": "4",
        "c": "20",
        "code": "60.00.00.10"
    },
    {
        "id": 3002,
        "label": "Estômago e Duodeno",
        "k": "10",
        "c": "27",
        "code": "60.00.00.11"
    },
    {
        "id": 3003,
        "label": "Estômago e Duodeno com duplo contraste",
        "k": "12",
        "c": "33",
        "code": "60.00.00.12"
    },
    {
        "id": 3004,
        "label": "Faringe e Laringe",
        "k": "3",
        "c": "6",
        "code": "60.00.00.13"
    },
    {
        "id": 3005,
        "label": "Fígado Simples – 1 incidência",
        "k": "2",
        "c": "5",
        "code": "60.00.00.14"
    },
    {
        "id": 3006,
        "label": "Fígado Simples – 2 incidências",
        "k": "2",
        "c": "9",
        "code": "60.00.00.15"
    },
    {
        "id": 3007,
        "label": "Intestino Delgado (trânsito)",
        "k": "10",
        "c": "48",
        "code": "60.00.00.16"
    },
    {
        "id": 3008,
        "label": "Intestino grosso (clister opaco) com esvaziamento",
        "k": "6",
        "c": "33",
        "code": "60.00.00.17"
    },
    {
        "id": 3009,
        "label": "Clister opaco duplo contraste",
        "k": "10",
        "c": "39",
        "code": "60.00.00.18"
    },
    {
        "id": 3010,
        "label": "Intestino grosso, por ingestão, trânsito intestinal",
        "k": "6",
        "c": "22",
        "code": "60.00.00.19"
    },
    {
        "id": 3011,
        "label": "Trânsito delgado + Trânsito cólon",
        "k": "10",
        "c": "66",
        "code": "60.00.00.20"
    },
    {
        "id": 3012,
        "label": "Região ileo-cecal ou ceco-apendicular",
        "k": "6",
        "c": "20",
        "code": "60.00.00.21"
    },
    {
        "id": 3013,
        "label": "Exame ileo-cecal ou ceco-apendicular quando associado aos trânsitos cólico ou delgado",
        "k": "2",
        "c": "10",
        "code": "60.00.00.22"
    },
    {
        "id": 3014,
        "label": "Pescoço, partes moles – 1 incidência",
        "k": "2",
        "c": "5",
        "code": "60.00.00.23"
    },
    {
        "id": 3015,
        "label": "Pescoço, partes moles – 2 incidências",
        "k": "3",
        "c": "9",
        "code": "60.00.00.24"
    },
    {
        "id": 3016,
        "label": "Gastroduodenal com pesquisa de hérnia e exame cardio-tuberositário",
        "k": "12",
        "c": "36",
        "code": "60.00.00.25"
    },
    {
        "id": 3017,
        "label": "Tórax, pulmões e coração 1 incidência",
        "k": "2",
        "c": "10",
        "code": "60.01.00.01"
    },
    {
        "id": 3018,
        "label": "Tórax, pulmões e coração 2 incidências",
        "k": "3",
        "c": "16",
        "code": "60.01.00.02"
    },
    {
        "id": 3019,
        "label": "Tórax, pulmões e coração 3 incidências",
        "k": "4",
        "c": "22",
        "code": "60.01.00.03"
    },
    {
        "id": 3020,
        "label": "Tórax, pulmões e coração 4 incidências",
        "k": "5",
        "c": "28",
        "code": "60.01.00.04"
    },
    {
        "id": 3021,
        "label": "Bexiga simples – 1 incidência",
        "k": "2",
        "c": "5",
        "code": "60.02.00.01"
    },
    {
        "id": 3022,
        "label": "Cistografia – 3 incidências para esvaziamento",
        "k": "6",
        "c": "17",
        "code": "60.02.00.02"
    },
    {
        "id": 3023,
        "label": "Cistografia com duplo contraste",
        "k": "4",
        "c": "14",
        "code": "60.02.00.03"
    },
    {
        "id": 3024,
        "label": "Cistografia com uretrografia retrógrada",
        "k": "6",
        "c": "17",
        "code": "60.02.00.04"
    },
    {
        "id": 3025,
        "label": "Rins simples – 1 incidência",
        "k": "2",
        "c": "10",
        "code": "60.02.00.05"
    },
    {
        "id": 3026,
        "label": "Rins simples–– 2 incidências",
        "k": "3",
        "c": "18",
        "code": "60.02.00.06"
    },
    {
        "id": 3027,
        "label": "Urografia endovenosa",
        "k": "6",
        "c": "41",
        "code": "60.02.00.07"
    },
    {
        "id": 3028,
        "label": "Urografia endovenosa minutada",
        "k": "8",
        "c": "63",
        "code": "60.02.00.08"
    },
    {
        "id": 3029,
        "label": "Filme pós-miccional",
        "k": "1",
        "c": "5",
        "code": "60.02.00.09"
    },
    {
        "id": 3030,
        "label": "Película de pé ou filme tardio ou incidência suplementar",
        "k": "2",
        "c": "7",
        "code": "60.02.00.10"
    },
    {
        "id": 3031,
        "label": "Urografia endovenosa com perfusão (excluindo o estudo tomográfico)",
        "k": "8",
        "c": "46",
        "code": "60.02.00.11"
    },
    {
        "id": 3032,
        "label": "Associação de cistogramas oblíquos eapós micção à urografia",
        "k": "2",
        "c": "12",
        "code": "60.02.00.12"
    },
    {
        "id": 3033,
        "label": "Pielografia ascendente unilateral (escluindo cataterismo)",
        "k": "6",
        "c": "11",
        "code": "60.02.00.13"
    },
    {
        "id": 3034,
        "label": "Uretrografia retrógrada",
        "k": "4",
        "c": "11",
        "code": "60.02.00.14"
    },
    {
        "id": 3035,
        "label": "Anca – 1 incidência",
        "k": "2",
        "c": "6",
        "code": "60.03.00.01"
    },
    {
        "id": 3036,
        "label": "Anca – 2 incidências",
        "k": "3",
        "c": "10",
        "code": "60.03.00.02"
    },
    {
        "id": 3037,
        "label": "Antebraço – 2 incidências",
        "k": "2",
        "c": "8",
        "code": "60.03.00.03"
    },
    {
        "id": 3038,
        "label": "Apófises estiloideias – cada incidência e lado",
        "k": "2",
        "c": "6",
        "code": "60.03.00.04"
    },
    {
        "id": 3039,
        "label": "Articulações têmporo-maxilares, boca aberta e fechada cada lado",
        "k": "2",
        "c": "12",
        "code": "60.03.00.05"
    },
    {
        "id": 3040,
        "label": "Bacia – 1 incidência",
        "k": "2",
        "c": "10",
        "code": "60.03.00.06"
    },
    {
        "id": 3041,
        "label": "Braço – 2 incidências",
        "k": "2",
        "c": "8",
        "code": "60.03.00.07"
    },
    {
        "id": 3042,
        "label": "Buracos ópticos – Bilateral",
        "k": "2",
        "c": "12",
        "code": "60.03.00.08"
    },
    {
        "id": 3043,
        "label": "Calcâneo – 2 incidências",
        "k": "2",
        "c": "8",
        "code": "60.03.00.09"
    },
    {
        "id": 3044,
        "label": "Charneira occipito-atloideia 2 incidências",
        "k": "2",
        "c": "10",
        "code": "60.03.00.10"
    },
    {
        "id": 3045,
        "label": "Clavícula – cada incidência",
        "k": "2",
        "c": "5",
        "code": "60.03.00.11"
    },
    {
        "id": 3046,
        "label": "Coluna cervical – 2 incidências",
        "k": "2",
        "c": "10",
        "code": "60.03.00.12"
    },
    {
        "id": 3047,
        "label": "Coluna cervical ou estudo funcional 4 incidências",
        "k": "2",
        "c": "20",
        "code": "60.03.00.13"
    },
    {
        "id": 3048,
        "label": "Coluna cervico-dorsal, zona de transição – 2 incidências (frente e obliqua)",
        "k": "2",
        "c": "10",
        "code": "60.03.00.14"
    },
    {
        "id": 3049,
        "label": "Coluna coccígea – 2 incidências",
        "k": "2",
        "c": "10",
        "code": "60.03.00.15"
    },
    {
        "id": 3050,
        "label": "Coluna dorsal – 2 incidências",
        "k": "4",
        "c": "15",
        "code": "60.03.00.16"
    },
    {
        "id": 3051,
        "label": "Coluna lombar – 2 incidências",
        "k": "4",
        "c": "15",
        "code": "60.03.00.17"
    },
    {
        "id": 3052,
        "label": "Coluna charneira lombo sagrada 2 incidências",
        "k": "2",
        "c": "15",
        "code": "60.03.00.18"
    },
    {
        "id": 3053,
        "label": "Coluna lombo-sagrada, em carga, com inclinações (estudo funcional) 4 incidências",
        "k": "6",
        "c": "30",
        "code": "60.03.00.19"
    },
    {
        "id": 3054,
        "label": "Coluna sagrada – 2 incidências",
        "k": "2",
        "c": "10",
        "code": "60.03.00.20"
    },
    {
        "id": 3055,
        "label": "Coluna vertebral, em filme extra-longo (30X90) – cada incidência em carga",
        "k": "4",
        "c": "20",
        "code": "60.03.00.21"
    },
    {
        "id": 3056,
        "label": "Costelas, cada hemitórax 2 incidências",
        "k": "2",
        "c": "15",
        "code": "60.03.00.22"
    },
    {
        "id": 3057,
        "label": "Cotovelo – 2 incidências",
        "k": "2",
        "c": "11",
        "code": "60.03.00.23"
    },
    {
        "id": 3058,
        "label": "Coxa ou fémur – 2 incidências",
        "k": "3",
        "c": "11",
        "code": "60.03.00.24"
    },
    {
        "id": 3059,
        "label": "Crânio – 2 incidências",
        "k": "3",
        "c": "11",
        "code": "60.03.00.25"
    },
    {
        "id": 3060,
        "label": "Esqueleto – 1 incidência em película 35X43 – recém nascido",
        "k": "3",
        "c": "11",
        "code": "60.03.00.26"
    },
    {
        "id": 3061,
        "label": "Esqueleto de adulto (1 incidência por sector mínimo de 9 películas)",
        "k": "8",
        "c": "80",
        "code": "60.03.00.27"
    },
    {
        "id": 3062,
        "label": "Esterno – 2 incidências",
        "k": "2",
        "c": "11",
        "code": "60.03.00.28"
    },
    {
        "id": 3063,
        "label": "Esterno-claviculares (articulações) 3 incidências",
        "k": "3",
        "c": "12",
        "code": "60.03.00.29"
    },
    {
        "id": 3064,
        "label": "Face – 2 incidências",
        "k": "3",
        "c": "9",
        "code": "60.03.00.30"
    },
    {
        "id": 3065,
        "label": "Joelho 2 incidências",
        "k": "2",
        "c": "10",
        "code": "60.03.00.31"
    },
    {
        "id": 3066,
        "label": "Mandíbula – cada incidência",
        "k": "2",
        "c": "4",
        "code": "60.03.00.32"
    },
    {
        "id": 3067,
        "label": "Mão – 2 incidências",
        "k": "2",
        "c": "8",
        "code": "60.03.00.33"
    },
    {
        "id": 3068,
        "label": "Mastoideias ou rochedos cada incidência e lado",
        "k": "2",
        "c": "10",
        "code": "60.03.00.34"
    },
    {
        "id": 3069,
        "label": "Maxilar superior – 2 incidências",
        "k": "2",
        "c": "8",
        "code": "60.03.00.35"
    },
    {
        "id": 3070,
        "label": "Ombro – 1 incidência",
        "k": "2",
        "c": "6",
        "code": "60.03.00.36"
    },
    {
        "id": 3071,
        "label": "Omoplata – 1 incidência",
        "k": "2",
        "c": "6",
        "code": "60.03.00.37"
    },
    {
        "id": 3072,
        "label": "Órbitas – cada incidência",
        "k": "2",
        "c": "8",
        "code": "60.03.00.38"
    },
    {
        "id": 3073,
        "label": "Ossos próprios do nariz cada incidência",
        "k": "2",
        "c": "6",
        "code": "60.03.00.39"
    },
    {
        "id": 3074,
        "label": "Pé – 2 incidências",
        "k": "2",
        "c": "8",
        "code": "60.03.00.40"
    },
    {
        "id": 3075,
        "label": "Perna – 2 incidências",
        "k": "2",
        "c": "14",
        "code": "60.03.00.41"
    },
    {
        "id": 3076,
        "label": "Punho – 2 incidências",
        "k": "2",
        "c": "6",
        "code": "60.03.00.42"
    },
    {
        "id": 3077,
        "label": "Punhos e mãos (idade) óssea 1 incidência",
        "k": "5",
        "c": "5",
        "code": "60.03.00.43"
    },
    {
        "id": 3078,
        "label": "Sacro-ilíacas (articulações) os dois lados – 1 incidência",
        "k": "2",
        "c": "8",
        "code": "60.03.00.44"
    },
    {
        "id": 3079,
        "label": "Sacro ilíacas (articulações) os dois lados face + 2 oblíquas",
        "k": "4",
        "c": "15",
        "code": "60.03.00.45"
    },
    {
        "id": 3080,
        "label": "Seios perinasais – 2 incidências",
        "k": "3",
        "c": "11",
        "code": "60.03.00.46"
    },
    {
        "id": 3081,
        "label": "Seios perinasais – 3 incidências",
        "k": "4",
        "c": "14",
        "code": "60.03.00.47"
    },
    {
        "id": 3082,
        "label": "Sela turca – incidência localizada perfil",
        "k": "2",
        "c": "4",
        "code": "60.03.00.48"
    },
    {
        "id": 3083,
        "label": "Tibio-tarsica – 2 incidências",
        "k": "2",
        "c": "8",
        "code": "60.03.00.49"
    },
    {
        "id": 3084,
        "label": "Artropneumografia do joelho, incluindo punção",
        "k": "10",
        "c": "36",
        "code": "60.04.00.01"
    },
    {
        "id": 3085,
        "label": "Broncografia cada incidência (só radiologia)",
        "k": "3",
        "c": "10",
        "code": "60.04.00.02"
    },
    {
        "id": 3086,
        "label": "Cálculos salivares, filme simples 2 incidências",
        "k": "3",
        "c": "9",
        "code": "60.04.00.03"
    },
    {
        "id": 3087,
        "label": "Colangiografia per-operatória",
        "k": "10",
        "c": "17",
        "code": "60.04.00.04"
    },
    {
        "id": 3088,
        "label": "Colangiografia pós-operatória",
        "k": "10",
        "c": "17",
        "code": "60.04.00.05"
    },
    {
        "id": 3089,
        "label": "Colangiografia endoscópica cada incidência",
        "k": "10",
        "c": "17",
        "code": "60.04.00.06"
    },
    {
        "id": 3090,
        "label": "Colangiografia percutânea cada incidência",
        "k": "13",
        "c": "18",
        "code": "60.04.00.07"
    },
    {
        "id": 3091,
        "label": "Dacriocistografia",
        "k": "14",
        "c": "18",
        "code": "60.04.00.08"
    },
    {
        "id": 3092,
        "label": "Fistulografia",
        "k": "8",
        "c": "27",
        "code": "60.04.00.09"
    },
    {
        "id": 3093,
        "label": "Gravidez – 1 incidência",
        "k": "2",
        "c": "10",
        "code": "60.04.00.10"
    },
    {
        "id": 3094,
        "label": "Gravidez – 2 incidências",
        "k": "3",
        "c": "18",
        "code": "60.04.00.11"
    },
    {
        "id": 3095,
        "label": "Histerosalpingografia",
        "k": "10",
        "c": "27",
        "code": "60.04.00.12"
    },
    {
        "id": 3096,
        "label": "Idade óssea fetal",
        "k": "2",
        "c": "10",
        "code": "60.04.00.13"
    },
    {
        "id": 3097,
        "label": "Intensificação de imagens",
        "k": "0",
        "c": "12",
        "code": "60.04.00.14"
    },
    {
        "id": 3098,
        "label": "Localização e extracção de corpos estranhos sob controlo radioscópico (radiocirurgia) com intensificador",
        "k": "10",
        "c": "15",
        "code": "60.04.00.15"
    },
    {
        "id": 3099,
        "label": "Localizarão de corpos estranhos intra oculares por meio de 4 imagens em posições diferentes",
        "k": "10",
        "c": "17",
        "code": "60.04.00.16"
    },
    {
        "id": 3100,
        "label": "Localização de corpos estranhos intra oculares pelo método de Comberg (lente de contacto)",
        "k": "10",
        "c": "15",
        "code": "60.04.00.17"
    },
    {
        "id": 3101,
        "label": "Macrorradiografia – 1 incidência preço da região +",
        "k": "0",
        "c": "8",
        "code": "60.04.00.18"
    },
    {
        "id": 3102,
        "label": "Membros inferiores – cada filme extra longo",
        "k": "4",
        "c": "20",
        "code": "60.04.00.19"
    },
    {
        "id": 3103,
        "label": "Métrico dos membros inferiores por sectores articulados",
        "k": "6",
        "c": "15",
        "code": "60.04.00.20"
    },
    {
        "id": 3104,
        "label": "Microrradiografia (película 10+10)",
        "k": "0.5",
        "c": "1.75",
        "code": "60.04.00.21"
    },
    {
        "id": 3105,
        "label": "Radiografia estereoscópica – preço da região +",
        "k": "0",
        "c": "4",
        "code": "60.04.00.22"
    },
    {
        "id": 3106,
        "label": "Sialografia",
        "k": "7",
        "c": "16",
        "code": "60.04.00.23"
    },
    {
        "id": 3107,
        "label": "Galactografia, cada lado",
        "k": "10",
        "c": "30",
        "code": "60.05.00.01"
    },
    {
        "id": 3108,
        "label": "Mamografia - 4 incidências, 2 de cada lado",
        "k": "10",
        "c": "30",
        "code": "60.05.00.02"
    },
    {
        "id": 3109,
        "label": "Quistografia gasosa, cada lado",
        "k": "6",
        "c": "18",
        "code": "60.05.00.03"
    },
    {
        "id": 3110,
        "label": "Mamografia com técnica de magnificação",
        "k": "12",
        "c": "45",
        "code": "60.05.00.04"
    },
    {
        "id": 3111,
        "label": "Angiografia da carótida externa por punção percutânea",
        "k": "10",
        "c": "90",
        "code": "60.06.00.01"
    },
    {
        "id": 3112,
        "label": "Angiografia da fossa posterior por cateterismo da umeral ou femoral",
        "k": "10",
        "c": "252",
        "code": "60.06.00.02"
    },
    {
        "id": 3113,
        "label": "Angiografia dos 4 vasos",
        "k": "15",
        "c": "360",
        "code": "60.06.00.03"
    },
    {
        "id": 3114,
        "label": "Angiografia percutânea da carótida",
        "k": "10",
        "c": "144",
        "code": "60.06.00.04"
    },
    {
        "id": 3115,
        "label": "Idem, por punção percutânea das 2 carótidas",
        "k": "10",
        "c": "198",
        "code": "60.06.00.05"
    },
    {
        "id": 3116,
        "label": "Angiografia da fossa posterior por punção percutânea da vertebral",
        "k": "10",
        "c": "196",
        "code": "60.06.00.06"
    },
    {
        "id": 3117,
        "label": "Angiografia medular",
        "k": "15",
        "c": "252",
        "code": "60.06.00.07"
    },
    {
        "id": 3118,
        "label": "Mielografia",
        "k": "15",
        "c": "210",
        "code": "60.06.00.08"
    },
    {
        "id": 3119,
        "label": "Angiopneumografia",
        "k": "15",
        "c": "120",
        "code": "60.07.00.01"
    },
    {
        "id": 3120,
        "label": "Aortografia (por punção de Reinaldo dos Santos ou por técnica de Sel dinger",
        "k": "15",
        "c": "180",
        "code": "60.07.00.02"
    },
    {
        "id": 3121,
        "label": "Aortoarteriografia periférica",
        "k": "15",
        "c": "180",
        "code": "60.07.00.03"
    },
    {
        "id": 3122,
        "label": "Arteriografia periférica por punção directa",
        "k": "15",
        "c": "120",
        "code": "60.07.00.04"
    },
    {
        "id": 3123,
        "label": "Arteriografias selectivas",
        "k": "25",
        "c": "120",
        "code": "60.07.00.05"
    },
    {
        "id": 3124,
        "label": "Arteriografias selectivas com embolização",
        "k": "25",
        "c": "120",
        "code": "60.07.00.06"
    },
    {
        "id": 3125,
        "label": "Arteriografias selectivas com dilatações arteriais",
        "k": "15",
        "c": "162",
        "code": "60.07.00.07"
    },
    {
        "id": 3126,
        "label": "Cavografias ou flebografias",
        "k": "10",
        "c": "162",
        "code": "60.07.00.08"
    },
    {
        "id": 3127,
        "label": "Flebografias selectivas",
        "k": "10",
        "c": "120",
        "code": "60.07.00.09"
    },
    {
        "id": 3128,
        "label": "Esplenoportografia",
        "k": "15",
        "c": "180",
        "code": "60.07.00.10"
    },
    {
        "id": 3129,
        "label": "Linfografias",
        "k": "30",
        "c": "162",
        "code": "60.07.00.11"
    },
    {
        "id": 3130,
        "label": "Fleborrafia orbitária por punção da veia frontal",
        "k": "40",
        "c": "120",
        "code": "60.07.00.12"
    },
    {
        "id": 3131,
        "label": "Tomografia, cada incidência ou lado mínimo 4 planos, filmes 18-24",
        "k": "6",
        "c": "14",
        "code": "60.08.00.01"
    },
    {
        "id": 3132,
        "label": "Cada plano mais",
        "k": "0",
        "c": "5",
        "code": "60.08.00.02"
    },
    {
        "id": 3133,
        "label": "Tomografia, cada incidência ou lado mínimo 4 planos, filmes 24-30",
        "k": "6",
        "c": "22",
        "code": "60.08.00.03"
    },
    {
        "id": 3134,
        "label": "Cada plano mais",
        "k": "0",
        "c": "8",
        "code": "60.08.00.04"
    },
    {
        "id": 3135,
        "label": "Tomografia, cada incidência ou lado, mínimo 4 planos, filmes 30x40, 35x35 ou medidas superiores",
        "k": "6",
        "c": "36",
        "code": "60.08.00.05"
    },
    {
        "id": 3136,
        "label": "Cada plano mais",
        "k": "0",
        "c": "11",
        "code": "60.08.00.06"
    },
    {
        "id": 3137,
        "label": "Osteodensitometria monofotónica primeira avaliação",
        "k": "5",
        "c": "20",
        "code": "60.09.00.01"
    },
    {
        "id": 3138,
        "label": "Osteodensitometria monofotónica estudos comparativos",
        "k": "10",
        "c": "30",
        "code": "60.09.00.02"
    },
    {
        "id": 3139,
        "label": "Osteodensitometria bifotónica primeira avaliação",
        "k": "20",
        "c": "80",
        "code": "60.09.00.03"
    },
    {
        "id": 3140,
        "label": "Osteodensitometria bifotónica estudos comparativos",
        "k": "30",
        "c": "120",
        "code": "60.09.00.04"
    },
    {
        "id": 3141,
        "label": "Osteodensitometria por dupla energia com utilização de ampolas de rx (coluna, femur ou esqueleto isoladamente)",
        "k": "30",
        "c": "150",
        "code": "60.09.00.05"
    },
    {
        "id": 3142,
        "label": "Angiocardiografia de radionuclídeos (ARN)",
        "k": "20",
        "c": "49",
        "code": "61.00.00.01"
    },
    {
        "id": 3143,
        "label": "Angiocardiografia de Radionuclídeos (ARN) com esforço ou stress",
        "k": "20",
        "c": "84",
        "code": "61.00.00.02"
    },
    {
        "id": 3144,
        "label": "Estudo de perfusão do miocárdio em repouso e esforço com SPECT/TEC",
        "k": "40",
        "c": "182",
        "code": "61.00.00.03"
    },
    {
        "id": 3145,
        "label": "Cintigrama cardíaco com àcidos gordos e SPECT/TEC",
        "k": "30",
        "c": "70",
        "code": "61.00.00.04"
    },
    {
        "id": 3146,
        "label": "Cintigrama de distribuição do 131I-MIBG cardíaco",
        "k": "20",
        "c": "28",
        "code": "61.00.00.05"
    },
    {
        "id": 3147,
        "label": "Cintigrama de distribuição do 123I-MIBG cardíaco",
        "k": "20",
        "c": "42",
        "code": "61.00.00.06"
    },
    {
        "id": 3148,
        "label": "Cisternoventrículo cintigrafia",
        "k": "20",
        "c": "84",
        "code": "61.01.00.01"
    },
    {
        "id": 3149,
        "label": "Cintigrama de perfusão cerebral com SPECT/TEC",
        "k": "30",
        "c": "126",
        "code": "61.01.00.02"
    },
    {
        "id": 3150,
        "label": "Pesquisa de perda de líquido cefalora-quidiano",
        "k": "20",
        "c": "84",
        "code": "61.01.00.03"
    },
    {
        "id": 3151,
        "label": "Cintigrama cerebral com SPECT/TEC",
        "k": "20",
        "c": "84",
        "code": "61.01.00.04"
    },
    {
        "id": 3152,
        "label": "Cintigrafia de tiroideia",
        "k": "15",
        "c": "14",
        "code": "61.02.00.01"
    },
    {
        "id": 3153,
        "label": "Estudo funcional da tiróide com 131I (Cint.+Curv. Fixação)",
        "k": "20",
        "c": "35",
        "code": "61.02.00.02"
    },
    {
        "id": 3154,
        "label": "Estudo da fixação do 131I na tiróide (curva fixação)",
        "k": "10",
        "c": "14",
        "code": "61.02.00.03"
    },
    {
        "id": 3155,
        "label": "Cintigrafia corporal com 131 I",
        "k": "20",
        "c": "119",
        "code": "61.02.00.04"
    },
    {
        "id": 3156,
        "label": "Cintigrama corporal com 99mTc-DMSA",
        "k": "20",
        "c": "28",
        "code": "61.02.00.05"
    },
    {
        "id": 3157,
        "label": "Estudo de distribuição do 131I-MIBG",
        "k": "20",
        "c": "98",
        "code": "61.02.00.06"
    },
    {
        "id": 3158,
        "label": "Estudos de distrinbuição do 123I-MIBG",
        "k": "20",
        "c": "56",
        "code": "61.02.00.07"
    },
    {
        "id": 3159,
        "label": "Cintigrama hepatobiliar com estimulação vesicular e quantificação",
        "k": "20",
        "c": "84",
        "code": "61.03.00.01"
    },
    {
        "id": 3160,
        "label": "Cintigrama hepatobiliar com quantificação da função",
        "k": "20",
        "c": "56",
        "code": "61.03.00.02"
    },
    {
        "id": 3161,
        "label": "Cintigrama hepático com globulos vermelhos marcados",
        "k": "20",
        "c": "56",
        "code": "61.03.00.03"
    },
    {
        "id": 3162,
        "label": "Cintigrama hepatoesplénico",
        "k": "20",
        "c": "28",
        "code": "61.03.00.04"
    },
    {
        "id": 3163,
        "label": "Estudo da permeabilidade de cateter",
        "k": "20",
        "c": "84",
        "code": "61.03.00.05"
    },
    {
        "id": 3164,
        "label": "Pesquisa de refluxo biliogástrico",
        "k": "20",
        "c": "84",
        "code": "61.03.00.06"
    },
    {
        "id": 3165,
        "label": "Cintigrafia esplénica",
        "k": "15",
        "c": "14",
        "code": "61.03.00.07"
    },
    {
        "id": 3166,
        "label": "Cintigrama esplénico com glubulos vermelhos fragilizados",
        "k": "30",
        "c": "21",
        "code": "61.03.00.08"
    },
    {
        "id": 3167,
        "label": "Estudo funcional das glândulas salivares (Cint. + Estimulação)",
        "k": "20",
        "c": "56",
        "code": "61.03.00.09"
    },
    {
        "id": 3168,
        "label": "Trânsito Esofágico",
        "k": "20",
        "c": "7",
        "code": "61.03.00.10"
    },
    {
        "id": 3169,
        "label": "Esvaziamento gástrico",
        "k": "20",
        "c": "42",
        "code": "61.03.00.11"
    },
    {
        "id": 3170,
        "label": "Pesquisa de refluxo gastroesofágico",
        "k": "20",
        "c": "42",
        "code": "61.03.00.12"
    },
    {
        "id": 3171,
        "label": "Cintigrama intestinal com leucócitos marcados",
        "k": "50",
        "c": "182",
        "code": "61.03.00.13"
    },
    {
        "id": 3172,
        "label": "Estudo da permeabilidade intestinal (EDTA)",
        "k": "20",
        "c": "84",
        "code": "61.03.00.14"
    },
    {
        "id": 3173,
        "label": "Determinação de perdas proteicas",
        "k": "20",
        "c": "28",
        "code": "61.03.00.15"
    },
    {
        "id": 3174,
        "label": "Pesquisa de hemorragia digestiva",
        "k": "20",
        "c": "42",
        "code": "61.03.00.16"
    },
    {
        "id": 3175,
        "label": "Pesquisa de divertículo de Meckel",
        "k": "20",
        "c": "42",
        "code": "61.03.00.17"
    },
    {
        "id": 3176,
        "label": "Prova da absorção intestinal do Fe 59",
        "k": "10",
        "c": "28",
        "code": "61.03.00.18"
    },
    {
        "id": 3177,
        "label": "Absorção de vitamina B12 (Teste Schilling)",
        "k": "10",
        "c": "28",
        "code": "61.03.00.19"
    },
    {
        "id": 3178,
        "label": "Renograma",
        "k": "20",
        "c": "28",
        "code": "61.04.00.01"
    },
    {
        "id": 3179,
        "label": "Renograma com prova diurética ou outra",
        "k": "20",
        "c": "49",
        "code": "61.04.00.02"
    },
    {
        "id": 3180,
        "label": "Cintigrama renal (DTPA; MAG3; HIPURAN)",
        "k": "20",
        "c": "42",
        "code": "61.04.00.03"
    },
    {
        "id": 3181,
        "label": "Cintigrama renal + renograma",
        "k": "20",
        "c": "42",
        "code": "61.04.00.04"
    },
    {
        "id": 3182,
        "label": "Cintigrafia renal com DMSA",
        "k": "20",
        "c": "21",
        "code": "61.04.00.05"
    },
    {
        "id": 3183,
        "label": "Cintigrama Renal com quant. função (método gamagráfico)",
        "k": "20",
        "c": "49",
        "code": "61.04.00.06"
    },
    {
        "id": 3184,
        "label": "\"Quantificação da função com 51 Cr-EDTA (\"\"in vitro\"\")\"",
        "k": "20",
        "c": "49",
        "code": "61.04.00.07"
    },
    {
        "id": 3185,
        "label": "Cintigrama Renal + Cistografia indirecta",
        "k": "20",
        "c": "49",
        "code": "61.04.00.08"
    },
    {
        "id": 3186,
        "label": "Cistocintigrafia directa",
        "k": "30",
        "c": "42",
        "code": "61.04.00.09"
    },
    {
        "id": 3187,
        "label": "Estudo de perfusão de rim transplantado",
        "k": "20",
        "c": "42",
        "code": "61.04.00.10"
    },
    {
        "id": 3188,
        "label": "Cinética do Ferro",
        "k": "20",
        "c": "42",
        "code": "61.05.00.01"
    },
    {
        "id": 3189,
        "label": "Estudo de cinética das plaquetas",
        "k": "30",
        "c": "42",
        "code": "61.05.00.02"
    },
    {
        "id": 3190,
        "label": "Estudo de distribuição de leucócitos marcados",
        "k": "50",
        "c": "168",
        "code": "61.05.00.03"
    },
    {
        "id": 3191,
        "label": "Cintigrama da medula óssea",
        "k": "20",
        "c": "84",
        "code": "61.05.00.04"
    },
    {
        "id": 3192,
        "label": "Semi-vida dos eritrocitos",
        "k": "20",
        "c": "42",
        "code": "61.05.00.05"
    },
    {
        "id": 3193,
        "label": "Volume plasmático",
        "k": "20",
        "c": "28",
        "code": "61.05.00.06"
    },
    {
        "id": 3194,
        "label": "Determinação do volume sanguíneo total ou volémia",
        "k": "20",
        "c": "28",
        "code": "61.05.00.07"
    },
    {
        "id": 3195,
        "label": "Cintigrama do Esqueleto (corpo inteiro ou parcelares)",
        "k": "20",
        "c": "49",
        "code": "61.06.00.01"
    },
    {
        "id": 3196,
        "label": "Vista parcelar óssea suplementar",
        "k": "15",
        "c": "7",
        "code": "61.06.00.02"
    },
    {
        "id": 3197,
        "label": "Cintigrama ósseo com estudo de perfusão de uma região (3 fases)",
        "k": "20",
        "c": "56",
        "code": "61.06.00.03"
    },
    {
        "id": 3198,
        "label": "Densitometria óssea bifotónica/DEXA (1 região)",
        "k": "15",
        "c": "14",
        "code": "61.06.00.04"
    },
    {
        "id": 3199,
        "label": "Densitometria óssea bifotónica/DEXA (corpo inteiro)",
        "k": "20",
        "c": "35",
        "code": "61.06.00.05"
    },
    {
        "id": 3281,
        "label": "Exame da charneira craniovertebral",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.03"
    },
    {
        "id": 3200,
        "label": "Densitometria óssea bifotónica/DEXA com análise evolutiva (comparação)",
        "k": "20",
        "c": "14",
        "code": "61.06.00.06"
    },
    {
        "id": 3201,
        "label": "Densitometria óssea bifotónica/DEXA + morfometria",
        "k": "20",
        "c": "42",
        "code": "61.06.00.07"
    },
    {
        "id": 3202,
        "label": "Cintigrama pulmonar de ventilação com 133Xe",
        "k": "20",
        "c": "63",
        "code": "61.07.00.01"
    },
    {
        "id": 3203,
        "label": "Cintigrama pulmonar de inalação (DTPA; Technegas)",
        "k": "20",
        "c": "56",
        "code": "61.07.00.02"
    },
    {
        "id": 3204,
        "label": "Cintigrafia pulmonar de perfusão",
        "k": "20",
        "c": "28",
        "code": "61.07.00.03"
    },
    {
        "id": 3205,
        "label": "Estudo da permeabilidade do epitélio pulmonar",
        "k": "20",
        "c": "84",
        "code": "61.07.00.04"
    },
    {
        "id": 3206,
        "label": "Estudo de distribuição com Gálio 67 (1 região)",
        "k": "15",
        "c": "14",
        "code": "61.08.00.01"
    },
    {
        "id": 3207,
        "label": "Estudo de distribuição com Gálio 67 (corpo inteiro)",
        "k": "20",
        "c": "140",
        "code": "61.08.00.02"
    },
    {
        "id": 3208,
        "label": "Estudo de distribuição de leucócitos marcados (1 região)",
        "k": "50",
        "c": "105",
        "code": "61.08.00.03"
    },
    {
        "id": 3209,
        "label": "Estudo de distribuição de leucócitos marcados (corpo inteiro)",
        "k": "50",
        "c": "182",
        "code": "61.08.00.04"
    },
    {
        "id": 3210,
        "label": "Cintigrama das paratiróides com 201 TI/99m Tc",
        "k": "20",
        "c": "63",
        "code": "61.09.00.01"
    },
    {
        "id": 3211,
        "label": "Cintigrama ósseo com 201TI (1 região)",
        "k": "15",
        "c": "14",
        "code": "61.09.00.02"
    },
    {
        "id": 3212,
        "label": "Cintigrama corporal com 201TI",
        "k": "20",
        "c": "140",
        "code": "61.09.00.03"
    },
    {
        "id": 3213,
        "label": "Cintigrama corporal com 99m Tc-DMSA",
        "k": "20",
        "c": "28",
        "code": "61.09.00.04"
    },
    {
        "id": 3214,
        "label": "Cintigrafia de órgão não especificado",
        "k": "15",
        "c": "28",
        "code": "61.09.00.05"
    },
    {
        "id": 3215,
        "label": "Dacriocintigrafia",
        "k": "20",
        "c": "28",
        "code": "61.09.00.06"
    },
    {
        "id": 3216,
        "label": "Estudo da fase vascular de um órgão ou região (complemento do estudo)",
        "k": "15",
        "c": "14",
        "code": "61.09.00.07"
    },
    {
        "id": 3217,
        "label": "Estudo de distribuição do lodo-colesterol",
        "k": "20",
        "c": "84",
        "code": "61.09.00.08"
    },
    {
        "id": 3218,
        "label": "Linfocintigrafia",
        "k": "20",
        "c": "42",
        "code": "61.09.00.09"
    },
    {
        "id": 3219,
        "label": "Tomografia de emissão computorizada (SPECT/TEC)",
        "k": "30",
        "c": "35",
        "code": "61.09.00.10"
    },
    {
        "id": 3220,
        "label": "Venografia isotópica",
        "k": "20",
        "c": "28",
        "code": "61.09.00.11"
    },
    {
        "id": 3221,
        "label": "Cintigrama corporal com receptores da somatostatina",
        "k": "30",
        "c": "126",
        "code": "61.09.00.12"
    },
    {
        "id": 3222,
        "label": "Cintigrafia da mama",
        "k": "30",
        "c": "35",
        "code": "61.09.00.13"
    },
    {
        "id": 3223,
        "label": "Cintigrama testicular",
        "k": "20",
        "c": "14",
        "code": "61.09.00.14"
    },
    {
        "id": 3224,
        "label": "Permeabilidade tubárica",
        "k": "20",
        "c": "84",
        "code": "61.09.00.15"
    },
    {
        "id": 3225,
        "label": "Imunocintigrama com anticorpos monoclonais",
        "k": "30",
        "c": "140",
        "code": "61.10.00.01"
    },
    {
        "id": 3226,
        "label": "Terapêutica com 32P (ambulatória)",
        "k": "9",
        "c": "0",
        "code": "61.10.00.03"
    },
    {
        "id": 3227,
        "label": "Terapêutica com Ytrium 1mCi (ambulatória)",
        "k": "9",
        "c": "0",
        "code": "61.10.00.04"
    },
    {
        "id": 3228,
        "label": "Terapêutica com Ytrium cada mCi a mais",
        "k": "9",
        "c": "0",
        "code": "61.10.00.05"
    },
    {
        "id": 3229,
        "label": "Terapêutica com estrôncio (Metastron)",
        "k": "9",
        "c": "0",
        "code": "61.10.00.06"
    },
    {
        "id": 3230,
        "label": "Terapêutica com 131 IMIBG",
        "k": "9",
        "c": "0",
        "code": "61.10.00.07"
    },
    {
        "id": 3231,
        "label": "Terapêutica com 131I até 10 mCi",
        "k": "9",
        "c": "0",
        "code": "61.10.00.08"
    },
    {
        "id": 3232,
        "label": "Terapêutica com 131I até 15 mCi",
        "k": "9",
        "c": "0",
        "code": "61.10.00.09"
    },
    {
        "id": 3233,
        "label": "Terapêutica com 131I até 50 mCi",
        "k": "18",
        "c": "0",
        "code": "61.10.00.10"
    },
    {
        "id": 3234,
        "label": "Terapêutica com 131I até 100 mCi",
        "k": "18",
        "c": "0",
        "code": "61.10.00.11"
    },
    {
        "id": 3235,
        "label": "Terapêutica com 131I de 100 a 150 mCi",
        "k": "18",
        "c": "0",
        "code": "61.10.00.12"
    },
    {
        "id": 3236,
        "label": "Terapêutica com 131I além de 150 mCi",
        "k": "18",
        "c": "0",
        "code": "61.10.00.13"
    },
    {
        "id": 3237,
        "label": "Abdominal",
        "k": "15",
        "c": "35",
        "code": "62.00.00.01"
    },
    {
        "id": 3238,
        "label": "Ginecológica",
        "k": "10",
        "c": "18",
        "code": "62.00.00.04"
    },
    {
        "id": 3239,
        "label": "Ginecológica c/ sonda vaginal",
        "k": "15",
        "c": "35",
        "code": "62.00.00.05"
    },
    {
        "id": 3240,
        "label": "Vagina",
        "k": "10",
        "c": "18",
        "code": "62.00.00.06"
    },
    {
        "id": 3241,
        "label": "Obstétrica",
        "k": "10",
        "c": "18",
        "code": "62.00.00.07"
    },
    {
        "id": 3242,
        "label": "Obstétrica c/ fluxometria",
        "k": "15",
        "c": "18",
        "code": "62.00.00.08"
    },
    {
        "id": 3243,
        "label": "Obstétrica c/ fluxometria umbilical",
        "k": "10",
        "c": "18",
        "code": "62.00.00.09"
    },
    {
        "id": 3244,
        "label": "Renal e suprarenal",
        "k": "15",
        "c": "35",
        "code": "62.00.00.10"
    },
    {
        "id": 3245,
        "label": "Vesical (suprapúbica)",
        "k": "10",
        "c": "18",
        "code": "62.00.00.11"
    },
    {
        "id": 3246,
        "label": "Vesical (transuretral)",
        "k": "15",
        "c": "35",
        "code": "62.00.00.12"
    },
    {
        "id": 3247,
        "label": "Vesículas seminais",
        "k": "10",
        "c": "18",
        "code": "62.00.00.13"
    },
    {
        "id": 3248,
        "label": "Prostática (suprapúbica)",
        "k": "10",
        "c": "18",
        "code": "62.00.00.14"
    },
    {
        "id": 3249,
        "label": "Prostática (transrectal)",
        "k": "15",
        "c": "35",
        "code": "62.00.00.15"
    },
    {
        "id": 3250,
        "label": "Escrotal",
        "k": "10",
        "c": "18",
        "code": "62.00.00.16"
    },
    {
        "id": 3251,
        "label": "Peniana",
        "k": "10",
        "c": "18",
        "code": "62.00.00.17"
    },
    {
        "id": 3252,
        "label": "Mamária (2 lados)",
        "k": "10",
        "c": "20",
        "code": "62.00.00.18"
    },
    {
        "id": 3253,
        "label": "Seios perinasais",
        "k": "10",
        "c": "18",
        "code": "62.00.00.19"
    },
    {
        "id": 3254,
        "label": "Tiroideia",
        "k": "10",
        "c": "18",
        "code": "62.00.00.20"
    },
    {
        "id": 3255,
        "label": "Encefálica",
        "k": "10",
        "c": "20",
        "code": "62.00.00.21"
    },
    {
        "id": 3256,
        "label": "Oftalmológica (A)",
        "k": "10",
        "c": "20",
        "code": "62.00.00.22"
    },
    {
        "id": 3257,
        "label": "Oftalmológica (A+B)",
        "k": "15",
        "c": "30",
        "code": "62.00.00.23"
    },
    {
        "id": 3258,
        "label": "Biometria ecográfica oftalmológica",
        "k": "15",
        "c": "20",
        "code": "62.00.00.24"
    },
    {
        "id": 3259,
        "label": "Partes moles",
        "k": "10",
        "c": "0",
        "code": "62.00.00.25"
    },
    {
        "id": 3260,
        "label": "Glândulas salivares",
        "k": "10",
        "c": "18",
        "code": "62.00.00.26"
    },
    {
        "id": 3261,
        "label": "Punção ou biópsia dirigida=preço da região +",
        "k": "20",
        "c": "0",
        "code": "62.00.00.27"
    },
    {
        "id": 3262,
        "label": "Per operatória (diagnostica)",
        "k": "30",
        "c": "35",
        "code": "62.00.00.28"
    },
    {
        "id": 3263,
        "label": "Ecografia osteoarticular",
        "k": "25",
        "c": "18",
        "code": "62.00.00.29"
    },
    {
        "id": 3264,
        "label": "Ecografia carotidea com Doppler",
        "k": "25",
        "c": "120",
        "code": "62.00.00.30"
    },
    {
        "id": 3265,
        "label": "Ecografia abdominal com Doppler",
        "k": "25",
        "c": "120",
        "code": "62.00.00.31"
    },
    {
        "id": 3266,
        "label": "Ecografia renal com Doppler",
        "k": "25",
        "c": "120",
        "code": "62.00.00.32"
    },
    {
        "id": 3267,
        "label": "Ecografia peniana com Doppler",
        "k": "20",
        "c": "120",
        "code": "62.00.00.33"
    },
    {
        "id": 3268,
        "label": "Ecografia arterial dos membros superiores com Doppler",
        "k": "25",
        "c": "120",
        "code": "62.00.00.34"
    },
    {
        "id": 3269,
        "label": "Ecografia venosa dos membros superiores com Doppler",
        "k": "20",
        "c": "100",
        "code": "62.00.00.35"
    },
    {
        "id": 3270,
        "label": "Ecografia arterial dos membros inferiores com Doppler",
        "k": "25",
        "c": "120",
        "code": "62.00.00.36"
    },
    {
        "id": 3271,
        "label": "Ecografia venosa dos membros inferiores com Doppler",
        "k": "20",
        "c": "100",
        "code": "62.00.00.37"
    },
    {
        "id": 3272,
        "label": "Crânio ou coluna",
        "k": "10",
        "c": "255",
        "code": "64.00.00.01"
    },
    {
        "id": 3273,
        "label": "Tórax ou abdómen",
        "k": "15",
        "c": "300",
        "code": "64.00.00.02"
    },
    {
        "id": 3274,
        "label": "Crânio ou coluna com cortes de menos de 2 milímetros",
        "k": "10",
        "c": "275",
        "code": "64.00.00.03"
    },
    {
        "id": 3275,
        "label": "Membros",
        "k": "10",
        "c": "210",
        "code": "64.00.00.04"
    },
    {
        "id": 3276,
        "label": "Punção dirigida = preço da região +",
        "k": "5",
        "c": "10",
        "code": "64.00.00.05"
    },
    {
        "id": 3277,
        "label": "Estudo dinâmico = preço da região +",
        "k": "5",
        "c": "10",
        "code": "64.00.00.06"
    },
    {
        "id": 3278,
        "label": "Plano de tratamento de radioterapia = preço da região +",
        "k": "0",
        "c": "20",
        "code": "64.00.00.07"
    },
    {
        "id": 3279,
        "label": "Exame cranio-encefálico",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.01"
    },
    {
        "id": 3280,
        "label": "Exame da fossa posterior",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.02"
    },
    {
        "id": 3282,
        "label": "Exame da coluna cervical",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.04"
    },
    {
        "id": 3283,
        "label": "Exame da coluna dorsal",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.05"
    },
    {
        "id": 3284,
        "label": "Exame da coluna lombosagrada",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.06"
    },
    {
        "id": 3285,
        "label": "Exame da totalidade da coluna (apenas no plano sagital)",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.07"
    },
    {
        "id": 3286,
        "label": "Exame do ouvido médio e labirinto membranoso",
        "k": "75",
        "c": "1350",
        "code": "65.00.00.08"
    },
    {
        "id": 3287,
        "label": "Exame da órbita",
        "k": "75",
        "c": "1350",
        "code": "65.00.00.09"
    },
    {
        "id": 3288,
        "label": "Exame da hipófise e seio cavernoso",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.10"
    },
    {
        "id": 3289,
        "label": "Exame do cavum faringeo e regiões vizinhas",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.11"
    },
    {
        "id": 3290,
        "label": "Exame da região craniofacial dos seios perinasais e glândulas salivares",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.12"
    },
    {
        "id": 3291,
        "label": "Exame dos troncos vasculares supra-aórticos",
        "k": "75",
        "c": "1350",
        "code": "65.00.00.13"
    },
    {
        "id": 3292,
        "label": "Exame do abdómen",
        "k": "60",
        "c": "1300",
        "code": "65.00.00.14"
    },
    {
        "id": 3293,
        "label": "Exame da pelve",
        "k": "60",
        "c": "1300",
        "code": "65.00.00.15"
    },
    {
        "id": 3294,
        "label": "Exame do tórax",
        "k": "60",
        "c": "1300",
        "code": "65.00.00.16"
    },
    {
        "id": 3295,
        "label": "Exame do coração e cardio—vasculares",
        "k": "75",
        "c": "1350",
        "code": "65.00.00.17"
    },
    {
        "id": 3296,
        "label": "\"Idem, em \"\"real-time\"\" (cine)\"",
        "k": "90",
        "c": "1400",
        "code": "65.00.00.18"
    },
    {
        "id": 3297,
        "label": "Exame osteo-muscular",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.19"
    },
    {
        "id": 3298,
        "label": "Exame das articulações",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.20"
    },
    {
        "id": 3299,
        "label": "Exame do pescoço",
        "k": "50",
        "c": "1300",
        "code": "65.00.00.21"
    },
    {
        "id": 3300,
        "label": "Espectroscopia clínica",
        "k": "100",
        "c": "1500",
        "code": "65.00.00.22"
    },
    {
        "id": 3301,
        "label": "Exame cranio-encefálico com indicação para estudo das cisternas da base craniana (fossa média e posterior)",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.01"
    },
    {
        "id": 3302,
        "label": "Exame cranio-encefálico com indicação para estudo de hidrocefalia",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.02"
    },
    {
        "id": 3303,
        "label": "Exame cranio-encefálico com indicação para estudo do hipótalamo e região optoquiasmática",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.03"
    },
    {
        "id": 3304,
        "label": "Exame cranio-encefálico com indicação para estudo da hipófise e veio cavernoso (incluindo situações de pós operatório)",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.04"
    },
    {
        "id": 3305,
        "label": "Exame cranio-encefálico com indicação para estudo do ângulo ponto cerebeloso (incluindo condutos auditivos internos)",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.05"
    },
    {
        "id": 3306,
        "label": "Exame cranio-encefálico com indicação para estudo do tronco cerebral (patologia tumoral, desmielinizante e vascular)",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.06"
    },
    {
        "id": 3307,
        "label": "Exame cranio-encefálico com indicação para estudo vascular dos territórios cerebrais e da fossa posterior",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.07"
    },
    {
        "id": 3308,
        "label": "Exame cranio-encefálico com indicação para estudo do aqueduto do Sylvius, região pineal e 4o. ventrículo",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.08"
    },
    {
        "id": 3309,
        "label": "Exame da charneira cranio-vertebral com indicação para estudo das amígdalas cerebelosas, de transição bulbo-medular e respectivas cisternas",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.09"
    },
    {
        "id": 3310,
        "label": "Exame da medula com indicação para despiste de lesões de pequena dimensão (cavitações, hematomas, malformações vasculares, anomalias, doenças infecciosas desmielinizantes e tumorais)",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.10"
    },
    {
        "id": 3311,
        "label": "Exame da coluna lombo-sagrada com indicação para estudo das raízes nervosas e suas relações intratecais e foraminais (patologia herniária, infecciosa e tumoral)",
        "k": "60",
        "c": "1450",
        "code": "65.01.00.11"
    },
    {
        "id": 3312,
        "label": "Exame do ouvido (particularmente do ouvido crónico complicado, degeneres-cência labiríntica, nervo facial intra e extrapetroso, tumores do conduto e caixa timpânica)",
        "k": "90",
        "c": "1500",
        "code": "65.01.00.12"
    },
    {
        "id": 3313,
        "label": "Exame da órbita (particularmente patologia intrínseca ou extrínseca do nervo óptico e suas relações com a artéria oftálmica, tumores oculares e seu diagnóstico diferencial)",
        "k": "90",
        "c": "1450",
        "code": "65.01.00.13"
    },
    {
        "id": 3314,
        "label": "Avaliação hemodinâmica dos membros superiores - Fluxometria Doppler (arterial ou venosa)",
        "k": "15",
        "c": "60",
        "code": "66.00.00.01"
    },
    {
        "id": 3315,
        "label": "Avaliação hemodinâmica dos membros inferiores - Fluxometria Doppler (arterial ou venosa)",
        "k": "15",
        "c": "60",
        "code": "66.00.00.02"
    },
    {
        "id": 3316,
        "label": "Avaliação hemodinâmica arterial dos membros - Fluxometria Doppler-compressões segmentares ou provas de hiperemia",
        "k": "20",
        "c": "60",
        "code": "66.00.00.03"
    },
    {
        "id": 3317,
        "label": "Avaliação hemodinâmica arterial cervico-encefálica - Fluxometria Doppler",
        "k": "20",
        "c": "60",
        "code": "66.00.00.04"
    },
    {
        "id": 3318,
        "label": "Avaliação da circulação digital com fotopletismografia",
        "k": "15",
        "c": "50",
        "code": "66.00.00.05"
    },
    {
        "id": 3319,
        "label": "Avaliação hemodinâmica da circulação venosa dos membros com pletismografia",
        "k": "15",
        "c": "50",
        "code": "66.00.00.06"
    },
    {
        "id": 3320,
        "label": "Angiodinografia (Doppler vascular colorido)",
        "k": "25",
        "c": "190",
        "code": "66.00.00.07"
    },
    {
        "id": 3321,
        "label": "\"Eco Doppler \"\"Duplex-Scan\"\" carotídeo\"",
        "k": "25",
        "c": "120",
        "code": "66.00.00.08"
    },
    {
        "id": 3322,
        "label": "Doppler Transcraniano",
        "k": "25",
        "c": "25",
        "code": "66.00.00.09"
    },
    {
        "id": 3323,
        "label": "Avaliação da circulação peniana (Doppler ou pletismografia) (Ver Cod. 16.02.00.02)",
        "k": "0",
        "c": "0",
        "code": "66.00.00.10"
    },
    {
        "id": 3324,
        "label": "Idem, circulação arterial ou venosa dos membros",
        "k": "25",
        "c": "120",
        "code": "66.00.00.11"
    },
    {
        "id": 3325,
        "label": "Idem, circulação visceral abdominal",
        "k": "25",
        "c": "120",
        "code": "66.00.00.12"
    },
    {
        "id": 3326,
        "label": "Angiografia ultra-sónica com análise espectral cerebrovascular carotídea",
        "k": "20",
        "c": "80",
        "code": "66.00.00.13"
    },
    {
        "id": 3327,
        "label": "Angiografia ultra-sónica com análise espectral dos membros",
        "k": "15",
        "c": "80",
        "code": "66.00.00.14"
    },
    {
        "id": 3328,
        "label": "Rigiscan",
        "k": "25",
        "c": "40",
        "code": "66.00.00.15"
    },
    {
        "id": 3329,
        "label": "Doppler Peniano",
        "k": "15",
        "c": "80",
        "code": "66.00.00.16"
    },
    {
        "id": 3330,
        "label": "Eco Doppler peniano",
        "k": "25",
        "c": "120",
        "code": "66.00.00.17"
    },
    {
        "id": 3331,
        "label": "Eco Doppler colorido peniano",
        "k": "25",
        "c": "190",
        "code": "66.00.00.18"
    },
    {
        "id": 3332,
        "label": "Teste PGE com papaverina ou prostaglandinas",
        "k": "15",
        "c": "10",
        "code": "66.00.00.19"
    },
    {
        "id": 3333,
        "label": "Artérias cerebrais – Panarteriografia",
        "k": "60",
        "c": "0",
        "code": "66.01.00.01"
    },
    {
        "id": 3334,
        "label": "Arteriografia carotidea por punção",
        "k": "30",
        "c": "0",
        "code": "66.01.00.02"
    },
    {
        "id": 3335,
        "label": "Arteriografia carotidea por cateterismo (Seldinger)",
        "k": "40",
        "c": "0",
        "code": "66.01.00.03"
    },
    {
        "id": 3336,
        "label": "Arteriografia vertebral / por punção umeral",
        "k": "25",
        "c": "0",
        "code": "66.01.00.04"
    },
    {
        "id": 3337,
        "label": "Arteriografia vertebral / por cateterismo (Seldinger)",
        "k": "35",
        "c": "0",
        "code": "66.01.00.05"
    },
    {
        "id": 3338,
        "label": "Membros superiores / por punção ou cateterismo",
        "k": "20",
        "c": "0",
        "code": "66.01.00.06"
    },
    {
        "id": 3339,
        "label": "Aortografia ou aortoarteriografia translombar",
        "k": "30",
        "c": "0",
        "code": "66.01.00.07"
    },
    {
        "id": 3340,
        "label": "Aortografia ou aortoarteriografia por cateterismo (Seldinger)",
        "k": "40",
        "c": "0",
        "code": "66.01.00.08"
    },
    {
        "id": 3341,
        "label": "Arteriografia selectiva de ramos da aorta",
        "k": "50",
        "c": "0",
        "code": "66.01.00.09"
    },
    {
        "id": 3342,
        "label": "Arteriografia do membro inferior",
        "k": "20",
        "c": "0",
        "code": "66.01.00.10"
    },
    {
        "id": 3343,
        "label": "Arteriografia das artérias genitais",
        "k": "40",
        "c": "0",
        "code": "66.01.00.11"
    },
    {
        "id": 3344,
        "label": "Flebografia cava superior",
        "k": "30",
        "c": "0",
        "code": "66.01.00.12"
    },
    {
        "id": 3345,
        "label": "Flebografia jugular interna",
        "k": "25",
        "c": "0",
        "code": "66.01.00.13"
    },
    {
        "id": 3346,
        "label": "Flebografia dos membros (unilateral)",
        "k": "10",
        "c": "0",
        "code": "66.01.00.14"
    },
    {
        "id": 3347,
        "label": "Iliocavografia",
        "k": "15",
        "c": "0",
        "code": "66.01.00.15"
    },
    {
        "id": 3348,
        "label": "Azigografia",
        "k": "15",
        "c": "0",
        "code": "66.01.00.16"
    },
    {
        "id": 3349,
        "label": "Flebografia mamária interna",
        "k": "15",
        "c": "0",
        "code": "66.01.00.17"
    },
    {
        "id": 3350,
        "label": "Flebografia renal",
        "k": "40",
        "c": "0",
        "code": "66.01.00.18"
    },
    {
        "id": 3351,
        "label": "Flebografia das veias pélvicas",
        "k": "20",
        "c": "0",
        "code": "66.01.00.19"
    },
    {
        "id": 3352,
        "label": "Esplenoportografia",
        "k": "30",
        "c": "0",
        "code": "66.01.00.20"
    },
    {
        "id": 3353,
        "label": "Portografia trans-hepática",
        "k": "50",
        "c": "0",
        "code": "66.01.00.21"
    },
    {
        "id": 3354,
        "label": "Flebografia supra-hepática",
        "k": "50",
        "c": "0",
        "code": "66.01.00.22"
    },
    {
        "id": 3355,
        "label": "Portografia transumbilical",
        "k": "30",
        "c": "0",
        "code": "66.01.00.23"
    },
    {
        "id": 3356,
        "label": "Arteriografia selectiva e embolização terapêutica, artéria carótida externa",
        "k": "80",
        "c": "0",
        "code": "66.02.00.01"
    },
    {
        "id": 3357,
        "label": "Arteriografia selectiva e embolização terapêutica, artéria do membro",
        "k": "50",
        "c": "0",
        "code": "66.02.00.02"
    },
    {
        "id": 3358,
        "label": "Arteriografia selectiva e embolização terapêutica, ramo visceral da aorta",
        "k": "80",
        "c": "0",
        "code": "66.02.00.03"
    },
    {
        "id": 3359,
        "label": "Arteriografia e dilatação de artéria carótida (*)",
        "k": "130",
        "c": "0",
        "code": "66.02.00.04"
    },
    {
        "id": 3360,
        "label": "Arteriografia e dilatação per operatória de artéria vertebral (*)",
        "k": "100",
        "c": "0",
        "code": "66.02.00.05"
    },
    {
        "id": 3361,
        "label": "Arteriografia selectiva e dilatação percutânea de artéria do membro",
        "k": "100",
        "c": "0",
        "code": "66.02.00.06"
    },
    {
        "id": 3362,
        "label": "Arteriografia selectiva e dilatação percutânea do tronco arterial braquiocefálico (*)",
        "k": "130",
        "c": "0",
        "code": "66.02.00.07"
    },
    {
        "id": 3363,
        "label": "Arteriografia selectiva e dilatação percutânea de um ramo visceral da aorta",
        "k": "130",
        "c": "0",
        "code": "66.02.00.08"
    },
    {
        "id": 3364,
        "label": "Dilatação per operatória de artéria de membro (*)",
        "k": "100",
        "c": "0",
        "code": "66.02.00.09"
    },
    {
        "id": 3365,
        "label": "Desobstrução intraluminal com Laser",
        "k": "120",
        "c": "75",
        "code": "66.02.00.10"
    },
    {
        "id": 3366,
        "label": "Desobstrução intraluminal com Rotablator (*) Adicionar o valor da abordagem cirúrgica se a houver",
        "k": "120",
        "c": "50",
        "code": "66.02.00.11"
    },
    {
        "id": 3367,
        "label": "Flebografia selectiva transhepática percutânea e embolização (Varizes gastro-esofágicas)",
        "k": "80",
        "c": "0",
        "code": "66.02.01.01"
    },
    {
        "id": 3368,
        "label": "Colocação de filtro na V.C.I. por via percutânea",
        "k": "70",
        "c": "0",
        "code": "66.02.01.02"
    },
    {
        "id": 3369,
        "label": "Crossografia aortica",
        "k": "30",
        "c": "420",
        "code": "66.03.00.01"
    },
    {
        "id": 3370,
        "label": "Idem, c/ Troncos supra-aorticos",
        "k": "30",
        "c": "650",
        "code": "66.03.00.02"
    },
    {
        "id": 3371,
        "label": "Idem, c/ pan-angiografia cerebral",
        "k": "30",
        "c": "650",
        "code": "66.03.00.03"
    },
    {
        "id": 3372,
        "label": "Flebografia orbito-cavernosa",
        "k": "20",
        "c": "280",
        "code": "66.03.00.04"
    },
    {
        "id": 3373,
        "label": "Carótida por punção directa (inclui angiografia cerebral)",
        "k": "20",
        "c": "500",
        "code": "66.03.01.01"
    },
    {
        "id": 3374,
        "label": "Troncos supra-aorticos por punção humeral",
        "k": "30",
        "c": "650",
        "code": "66.03.01.02"
    },
    {
        "id": 3375,
        "label": "Crossa aórtica e troncos supra aorticos",
        "k": "100",
        "c": "785",
        "code": "66.03.02.01"
    },
    {
        "id": 3376,
        "label": "Uma artéria (carótida interna, externa vertebral ou cervical profunda)",
        "k": "100",
        "c": "785",
        "code": "66.03.03.01"
    },
    {
        "id": 3377,
        "label": "Duas artérias",
        "k": "100",
        "c": "820",
        "code": "66.03.03.02"
    },
    {
        "id": 3378,
        "label": "Três artérias",
        "k": "100",
        "c": "855",
        "code": "66.03.03.03"
    },
    {
        "id": 3379,
        "label": "Quatro artérias",
        "k": "100",
        "c": "890",
        "code": "66.03.03.04"
    },
    {
        "id": 3380,
        "label": "Mais que quatro artérias (inclui estudo superselectivo dos ramos carotidos)",
        "k": "100",
        "c": "1000",
        "code": "66.03.03.05"
    },
    {
        "id": 3381,
        "label": "Angiografia radiculo-medular (por cada região: cervical, dorsal ou lombar)",
        "k": "100",
        "c": "1075",
        "code": "66.03.03.06"
    },
    {
        "id": 3382,
        "label": "Arco aórtico (arteriografia)",
        "k": "100",
        "c": "780",
        "code": "66.04.00.01"
    },
    {
        "id": 3383,
        "label": "Arteriografia brônquica",
        "k": "100",
        "c": "780",
        "code": "66.04.00.02"
    },
    {
        "id": 3384,
        "label": "Arteriografia Pulmonar",
        "k": "100",
        "c": "780",
        "code": "66.04.00.03"
    },
    {
        "id": 3385,
        "label": "Areteriografia da Subclávia e Humeral",
        "k": "100",
        "c": "780",
        "code": "66.04.00.04"
    },
    {
        "id": 3386,
        "label": "Arteriografia dos Membros Superiores",
        "k": "100",
        "c": "780",
        "code": "66.04.00.05"
    },
    {
        "id": 3387,
        "label": "Arteriografia Abdominal",
        "k": "100",
        "c": "780",
        "code": "66.04.00.06"
    },
    {
        "id": 3388,
        "label": "Tronco Celíaco",
        "k": "100",
        "c": "780",
        "code": "66.04.00.07"
    },
    {
        "id": 3389,
        "label": "Arteriografia Selectiva Esplénica",
        "k": "100",
        "c": "780",
        "code": "66.04.00.08"
    },
    {
        "id": 3390,
        "label": "Arteriografia Selectiva Coronária Estomáquica",
        "k": "100",
        "c": "780",
        "code": "66.04.00.09"
    },
    {
        "id": 3391,
        "label": "Arteriografia Selectiva Hepática",
        "k": "100",
        "c": "780",
        "code": "66.04.00.10"
    },
    {
        "id": 3392,
        "label": "Arteriografia Pancreática",
        "k": "100",
        "c": "780",
        "code": "66.04.00.11"
    },
    {
        "id": 3393,
        "label": "Pantografia por via arterial",
        "k": "100",
        "c": "780",
        "code": "66.04.00.12"
    },
    {
        "id": 3394,
        "label": "Arteriografia das Supra-Renais",
        "k": "100",
        "c": "780",
        "code": "66.04.00.13"
    },
    {
        "id": 3395,
        "label": "Flebografia das Supra-Renais",
        "k": "100",
        "c": "780",
        "code": "66.04.00.14"
    },
    {
        "id": 3396,
        "label": "Colheitas Selectivas Reninas (Renais)",
        "k": "100",
        "c": "780",
        "code": "66.04.00.15"
    },
    {
        "id": 3397,
        "label": "Colheitas Selectivas Hormonais (supra renais)",
        "k": "100",
        "c": "780",
        "code": "66.04.00.16"
    },
    {
        "id": 3398,
        "label": "Angiografia Ovárica, Testicular",
        "k": "100",
        "c": "780",
        "code": "66.04.00.17"
    },
    {
        "id": 3399,
        "label": "Arteriografia do Mesentério Superior",
        "k": "100",
        "c": "780",
        "code": "66.04.00.18"
    },
    {
        "id": 3400,
        "label": "Arteriografia do Mesentérico Inferior",
        "k": "100",
        "c": "780",
        "code": "66.04.00.19"
    },
    {
        "id": 3401,
        "label": "Arteriografia da Hipogástrica",
        "k": "100",
        "c": "780",
        "code": "66.04.00.20"
    },
    {
        "id": 3402,
        "label": "Arteriografia das íliacas",
        "k": "100",
        "c": "780",
        "code": "66.04.00.21"
    },
    {
        "id": 3403,
        "label": "Arteriografia Periférica dos Membros Inferiores",
        "k": "100",
        "c": "780",
        "code": "66.04.00.22"
    },
    {
        "id": 3404,
        "label": "Flebografia dos Membros Superiores",
        "k": "20",
        "c": "280",
        "code": "66.04.00.23"
    },
    {
        "id": 3405,
        "label": "Flebografia dos Membros Inferiores",
        "k": "20",
        "c": "280",
        "code": "66.04.00.24"
    },
    {
        "id": 3406,
        "label": "Flebografia da Veia-Cava superior",
        "k": "100",
        "c": "780",
        "code": "66.04.00.25"
    },
    {
        "id": 3407,
        "label": "Flebografia da Veia-Cava Inferior",
        "k": "100",
        "c": "780",
        "code": "66.04.00.26"
    },
    {
        "id": 3408,
        "label": "Intracraniana e Medular",
        "k": "250",
        "c": "1500",
        "code": "66.05.00.01"
    },
    {
        "id": 3409,
        "label": "Carótida Externa",
        "k": "250",
        "c": "1200",
        "code": "66.05.00.02"
    },
    {
        "id": 3410,
        "label": "Outros Territórios",
        "k": "200",
        "c": "1000",
        "code": "66.05.00.03"
    },
    {
        "id": 3411,
        "label": "Avaliação Clínica e decisão do tratamento",
        "k": "12",
        "c": "0",
        "code": "67.00.00.01"
    },
    {
        "id": 3412,
        "label": "Cobaltoterapia",
        "k": "3",
        "c": "12",
        "code": "67.00.00.02"
    },
    {
        "id": 3413,
        "label": "Simulação do tratamento",
        "k": "10",
        "c": "60",
        "code": "67.00.00.03"
    },
    {
        "id": 3414,
        "label": "Imobilização e moldes",
        "k": "0",
        "c": "50",
        "code": "67.00.00.04"
    },
    {
        "id": 3415,
        "label": "Dosimetria",
        "k": "0",
        "c": "80",
        "code": "67.00.00.05"
    },
    {
        "id": 3416,
        "label": "Consultas de acompanhamento",
        "k": "12",
        "c": "0",
        "code": "67.00.00.06"
    },
    {
        "id": 3417,
        "label": "Roentgenterapia",
        "k": "2",
        "c": "6",
        "code": "67.00.00.07"
    },
    {
        "id": 3418,
        "label": "Planeamento Clínico",
        "k": "14",
        "c": "0",
        "code": "67.00.00.08"
    },
    {
        "id": 3419,
        "label": "A.L. de particulas (baixa energia)",
        "k": "2",
        "c": "50",
        "code": "67.00.00.09"
    },
    {
        "id": 3568,
        "label": "Proteina C da coagulação (Ag)",
        "k": "0",
        "c": "63",
        "code": "70.25.00.10"
    },
    {
        "id": 3420,
        "label": "A.L. de partículas (média energia)",
        "k": "2",
        "c": "75",
        "code": "67.00.00.10"
    },
    {
        "id": 3421,
        "label": "A.L. de particulas (alta energia)",
        "k": "2",
        "c": "100",
        "code": "67.00.00.11"
    },
    {
        "id": 3422,
        "label": "Irradiação de meio corpo",
        "k": "12",
        "c": "200",
        "code": "67.00.00.12"
    },
    {
        "id": 3423,
        "label": "Irradiação de corpo inteiro",
        "k": "20",
        "c": "350",
        "code": "67.00.00.13"
    },
    {
        "id": 3424,
        "label": "Células Falciformes (Prova da Formação)",
        "k": "0",
        "c": "3",
        "code": "70.10.00.01"
    },
    {
        "id": 3425,
        "label": "Células falciformes (Prova da formação com agente redutor)",
        "k": "0",
        "c": "4",
        "code": "70.10.00.02"
    },
    {
        "id": 3426,
        "label": "Corpos de Heinz (Pesquisa)",
        "k": "0",
        "c": "3",
        "code": "70.10.00.03"
    },
    {
        "id": 3427,
        "label": "Corpos de Heinz (Susceptibilidade de Formação)",
        "k": "0",
        "c": "5",
        "code": "70.10.00.04"
    },
    {
        "id": 3428,
        "label": "Eritrograma (Eritrócitos+Hemoglobina+Hematócrito+Indíces Eritrocitários)",
        "k": "0",
        "c": "3",
        "code": "70.10.00.05"
    },
    {
        "id": 3429,
        "label": "Eritrograma + Leucócitos",
        "k": "0",
        "c": "4",
        "code": "70.10.00.06"
    },
    {
        "id": 3430,
        "label": "Estudo Morfológico dos Leucócitos pelo Método de Enriquecimento",
        "k": "0",
        "c": "8",
        "code": "70.10.00.07"
    },
    {
        "id": 3431,
        "label": "Hematócrito = Volume Globular Eritrocitário",
        "k": "0",
        "c": "2",
        "code": "70.10.00.08"
    },
    {
        "id": 3432,
        "label": "Hemograma com plaquetas (Eritrograma+leucócitos+ fórmula leucocitária+plaquetas)",
        "k": "0",
        "c": "10",
        "code": "70.10.00.09"
    },
    {
        "id": 3433,
        "label": "Hemograma (Eritrograma+leucócitos+fórmula leucocitária)",
        "k": "0",
        "c": "8",
        "code": "70.10.00.10"
    },
    {
        "id": 3434,
        "label": "Leucograma (Contagem dos Leucócitos + Fórmula Leucocitária)",
        "k": "0",
        "c": "6",
        "code": "70.10.00.11"
    },
    {
        "id": 3435,
        "label": "Plaquetas (Contagem)",
        "k": "0",
        "c": "2",
        "code": "70.10.00.12"
    },
    {
        "id": 3436,
        "label": "Reticulócitos (Contagem)",
        "k": "0",
        "c": "5",
        "code": "70.10.00.13"
    },
    {
        "id": 3437,
        "label": "Sangue periférico (Estudo morfológico do...)",
        "k": "0",
        "c": "8",
        "code": "70.10.00.14"
    },
    {
        "id": 3438,
        "label": "DNA dos leucócitos (Quantificação)",
        "k": "0",
        "c": "50",
        "code": "70.11.00.01"
    },
    {
        "id": 3439,
        "label": "Esterases não específicas (Alfa-naftil acetato; butirato; naftol ASD acetato), cada",
        "k": "0",
        "c": "10",
        "code": "70.11.00.02"
    },
    {
        "id": 3440,
        "label": "Fosfatase Ácida dos Leucócitos",
        "k": "0",
        "c": "10",
        "code": "70.11.00.03"
    },
    {
        "id": 3441,
        "label": "Fosfatase ácida dos leucócitos (com inibição pelo tartarato)",
        "k": "0",
        "c": "10",
        "code": "70.11.00.04"
    },
    {
        "id": 3442,
        "label": "Fosfatase Alcalina dos leucócitos",
        "k": "0",
        "c": "10",
        "code": "70.11.00.05"
    },
    {
        "id": 3443,
        "label": "P.A.S.",
        "k": "0",
        "c": "10",
        "code": "70.11.00.06"
    },
    {
        "id": 3444,
        "label": "Mieloperoxidases",
        "k": "0",
        "c": "10",
        "code": "70.11.00.07"
    },
    {
        "id": 3445,
        "label": "RNA (Identificação pela Reacção de Ribonuclease)",
        "k": "0",
        "c": "8",
        "code": "70.11.00.08"
    },
    {
        "id": 3446,
        "label": "Siderócitos no sangue periférico (Pesquisa)",
        "k": "0",
        "c": "6",
        "code": "70.11.00.09"
    },
    {
        "id": 3447,
        "label": "Eosinófilos no exsudado nasal (Pesquisa)",
        "k": "0",
        "c": "5",
        "code": "70.11.00.10"
    },
    {
        "id": 3448,
        "label": "Sudão Negro",
        "k": "0",
        "c": "10",
        "code": "70.11.00.11"
    },
    {
        "id": 3449,
        "label": "Esterases não específicas (Alfa-naftil acetato; butirato; naftol ASD acetato) com fluoreto, cada",
        "k": "0",
        "c": "10",
        "code": "70.11.00.12"
    },
    {
        "id": 3450,
        "label": "Esterase específica (Cloro acetato)",
        "k": "0",
        "c": "10",
        "code": "70.11.00.13"
    },
    {
        "id": 3451,
        "label": "Auto-Hemólise",
        "k": "0",
        "c": "10",
        "code": "70.12.00.01"
    },
    {
        "id": 3452,
        "label": "Carboxihemoglobina (Pesquisa)",
        "k": "0",
        "c": "5",
        "code": "70.12.00.02"
    },
    {
        "id": 3453,
        "label": "Electroforese das hemoglobinas (a pH alcalino; a pH neutro; a pH ácido), cada",
        "k": "0",
        "c": "15",
        "code": "70.12.00.03"
    },
    {
        "id": 3454,
        "label": "Electroforese das cadeias da globina (a pH alcalino; a pH ácido), cada",
        "k": "0",
        "c": "20",
        "code": "70.12.00.04"
    },
    {
        "id": 3455,
        "label": "Electroforese das hemoglobinas por focagem isoeléctrica",
        "k": "0",
        "c": "30",
        "code": "70.12.00.05"
    },
    {
        "id": 3456,
        "label": "Enzimas dos eritrócitos (Screening para deficiência), cada",
        "k": "0",
        "c": "7",
        "code": "70.12.00.06"
    },
    {
        "id": 3457,
        "label": "Fragilidade Osmótica = Resistência Osmótica",
        "k": "0",
        "c": "10",
        "code": "70.12.00.07"
    },
    {
        "id": 3458,
        "label": "Fragilidade Osmótica 24 h após incubação a 37o",
        "k": "0",
        "c": "10",
        "code": "70.12.00.08"
    },
    {
        "id": 3459,
        "label": "Glucose-6-Fosfato Desidrogenase (Screening para deficiência)",
        "k": "0",
        "c": "7",
        "code": "70.12.00.09"
    },
    {
        "id": 3460,
        "label": "Glucose-6-Fosfato Desidrogenase (doseamento)",
        "k": "0",
        "c": "20",
        "code": "70.12.00.10"
    },
    {
        "id": 3461,
        "label": "Glutatião (Prova de Estabilidade)",
        "k": "0",
        "c": "30",
        "code": "70.12.00.11"
    },
    {
        "id": 3462,
        "label": "Glutatião Reduzido",
        "k": "0",
        "c": "14",
        "code": "70.12.00.12"
    },
    {
        "id": 3463,
        "label": "Glutatião-Reductase",
        "k": "0",
        "c": "20",
        "code": "70.12.00.13"
    },
    {
        "id": 3464,
        "label": "Glutatião-Reductase (Pesquisa)",
        "k": "0",
        "c": "6",
        "code": "70.12.00.14"
    },
    {
        "id": 3465,
        "label": "Prova de Ham = Prova do soro acidificado",
        "k": "0",
        "c": "10",
        "code": "70.12.00.15"
    },
    {
        "id": 3466,
        "label": "Hemoglobinas instáveis (Pesquisa de: corpos de Heinz, Hemoglobina H, desnat. calor, prec. isopropanol), cada",
        "k": "0",
        "c": "5",
        "code": "70.12.00.16"
    },
    {
        "id": 3467,
        "label": "Hemoglobina A2 (Cromatografia)",
        "k": "0",
        "c": "20",
        "code": "70.12.00.17"
    },
    {
        "id": 3468,
        "label": "Hemoglobina fetal = Hemoglobina alcalino-resistente (Prova de desnaturação alcalina)",
        "k": "0",
        "c": "10",
        "code": "70.12.00.18"
    },
    {
        "id": 3469,
        "label": "Hemoglobina Fetal (Técnica da Eluição)",
        "k": "0",
        "c": "10",
        "code": "70.12.00.19"
    },
    {
        "id": 3470,
        "label": "Hemoglobina fetal (Pesquisa em esfregaço de sangue periférico - Teste de Kleihauer)",
        "k": "0",
        "c": "10",
        "code": "70.12.00.20"
    },
    {
        "id": 3471,
        "label": "Hemoglobina H (Pesquisa)",
        "k": "0",
        "c": "5",
        "code": "70.12.00.21"
    },
    {
        "id": 3472,
        "label": "Hemoglobina S (Pesquisa)",
        "k": "0",
        "c": "5",
        "code": "70.12.00.22"
    },
    {
        "id": 3473,
        "label": "Hemoglobina S (Quantificação)",
        "k": "0",
        "c": "20",
        "code": "70.12.00.23"
    },
    {
        "id": 3474,
        "label": "Metahemoglobina",
        "k": "0",
        "c": "10",
        "code": "70.12.00.24"
    },
    {
        "id": 3475,
        "label": "Metahemoglobina (Pesquisa)",
        "k": "0",
        "c": "5",
        "code": "70.12.00.25"
    },
    {
        "id": 3476,
        "label": "Metalbumina",
        "k": "0",
        "c": "6",
        "code": "70.12.00.26"
    },
    {
        "id": 3477,
        "label": "Oxihemoglobina",
        "k": "0",
        "c": "2",
        "code": "70.12.00.27"
    },
    {
        "id": 3478,
        "label": "Estudo espectrofotométrico dos pigmentos da hemoglobina (Oxi, Carboxi, Meta e Sulfa)",
        "k": "0",
        "c": "20",
        "code": "70.12.00.28"
    },
    {
        "id": 3479,
        "label": "Piruvato-Kinase = PK (Screening)",
        "k": "0",
        "c": "7",
        "code": "70.12.00.29"
    },
    {
        "id": 3480,
        "label": "Piruvato-Kinase = PK (doseamento)",
        "k": "0",
        "c": "20",
        "code": "70.12.00.30"
    },
    {
        "id": 3481,
        "label": "Prova da Sacarose = Prova de Hemólise pela Sacarose",
        "k": "0",
        "c": "12",
        "code": "70.12.00.31"
    },
    {
        "id": 3482,
        "label": "Sulfahemoglobina (Pesquisa)",
        "k": "0",
        "c": "5",
        "code": "70.12.00.32"
    },
    {
        "id": 3483,
        "label": "Estudo de uma anemia - (exames executados+valor da consulta) Ver Cód. 01.00.00.03 ou 01.00.00.04",
        "k": "0",
        "c": "0",
        "code": "70.12.00.33"
    },
    {
        "id": 3484,
        "label": "Hemoglobina Plasmática",
        "k": "0",
        "c": "8",
        "code": "70.13.00.01"
    },
    {
        "id": 3485,
        "label": "Velocidade de sedimentação eritrocitária = VS",
        "k": "0",
        "c": "5",
        "code": "70.13.00.02"
    },
    {
        "id": 3486,
        "label": "Viscosidade Plasmática",
        "k": "0",
        "c": "20",
        "code": "70.13.00.03"
    },
    {
        "id": 3487,
        "label": "Viscosidade Sanguínea",
        "k": "0",
        "c": "20",
        "code": "70.13.00.04"
    },
    {
        "id": 3488,
        "label": "Viscosidade Sérica",
        "k": "0",
        "c": "20",
        "code": "70.13.00.05"
    },
    {
        "id": 3489,
        "label": "Volémia Sanguínea",
        "k": "0",
        "c": "9",
        "code": "70.13.00.06"
    },
    {
        "id": 3490,
        "label": "Eritropoietina",
        "k": "0",
        "c": "60",
        "code": "70.13.00.07"
    },
    {
        "id": 3491,
        "label": "Adenograma (não inclui colheita)",
        "k": "0",
        "c": "40",
        "code": "70.14.00.01"
    },
    {
        "id": 3492,
        "label": "Esplenograma (não inclui colheita)",
        "k": "0",
        "c": "25",
        "code": "70.14.00.02"
    },
    {
        "id": 3493,
        "label": "Estudo do ferro na medula óssea - Reacção de perls. (não inclui colheita)",
        "k": "0",
        "c": "10",
        "code": "70.14.00.03"
    },
    {
        "id": 3494,
        "label": "Hemosiderina na urina (doseamento)",
        "k": "0",
        "c": "6",
        "code": "70.14.00.04"
    },
    {
        "id": 3495,
        "label": "Mielograma (não inclui colheita)",
        "k": "0",
        "c": "25",
        "code": "70.14.00.05"
    },
    {
        "id": 3496,
        "label": "Estudo citológico dos líquidos biológicos",
        "k": "0",
        "c": "8",
        "code": "70.14.00.06"
    },
    {
        "id": 3497,
        "label": "Imunofenotipagem celular (sangue periférico; medula óssea; gânglio), cada anticorpo",
        "k": "0",
        "c": "50",
        "code": "70.14.00.07"
    },
    {
        "id": 3498,
        "label": "Estudo de órgãos hematopoiéticos - (exames executados+valor da consulta) ver cód. 01.00.00.03 ou 01.00.00.04",
        "k": "0",
        "c": "0",
        "code": "70.14.00.08"
    },
    {
        "id": 3499,
        "label": "Prova do Laço = Prova de Rumpel-Leed",
        "k": "0",
        "c": "2",
        "code": "70.21.00.01"
    },
    {
        "id": 3500,
        "label": "Tempo de hemorragia (Ivy modificado, 2 determinações sem e com AAS)",
        "k": "0",
        "c": "30",
        "code": "70.21.00.02"
    },
    {
        "id": 3501,
        "label": "Tempo de hemorragia (Ivy modificado)",
        "k": "0",
        "c": "16",
        "code": "70.21.00.03"
    },
    {
        "id": 3502,
        "label": "A.P.T.T. = Tempo de Tromboplastina Parcial Activado = T.de Cefalina-Caulino",
        "k": "0",
        "c": "3",
        "code": "70.22.00.01"
    },
    {
        "id": 3503,
        "label": "A.P.T.T. para Estudo dos Tempos de Tromboplastina Parcial Alongados",
        "k": "0",
        "c": "15",
        "code": "70.22.00.02"
    },
    {
        "id": 3504,
        "label": "I.N.R. = R.N.I. - Ver Cód. 70.22.00.29",
        "k": "0",
        "c": "0",
        "code": "70.22.00.03"
    },
    {
        "id": 3505,
        "label": "Protrombina (Prova da Correcção do Consumo da...)",
        "k": "0",
        "c": "8",
        "code": "70.22.00.04"
    },
    {
        "id": 3506,
        "label": "Protrombina (Prova do Consumo da...)",
        "k": "0",
        "c": "6",
        "code": "70.22.00.05"
    },
    {
        "id": 3507,
        "label": "Protrombina (Taxa) = Tempo de Protrombina",
        "k": "0",
        "c": "4",
        "code": "70.22.00.06"
    },
    {
        "id": 3508,
        "label": "Prova da Correcção do Consumo de Protrombina Ver Cód.70.22.00.04",
        "k": "0",
        "c": "0",
        "code": "70.22.00.07"
    },
    {
        "id": 3509,
        "label": "Prova de Hicks-Pitney",
        "k": "0",
        "c": "9",
        "code": "70.22.00.08"
    },
    {
        "id": 3510,
        "label": "Prova do Consumo de Protrombina Ver Cód.70.22.00.05",
        "k": "0",
        "c": "0",
        "code": "70.22.00.10"
    },
    {
        "id": 3511,
        "label": "R.N.I. = I.N.R. - Ver Cód. 70.22.00.29",
        "k": "0",
        "c": "0",
        "code": "70.22.00.12"
    },
    {
        "id": 3512,
        "label": "Retracção do Coágulo (Avaliação Qualitativa da...)",
        "k": "0",
        "c": "2",
        "code": "70.22.00.13"
    },
    {
        "id": 3513,
        "label": "Retracçrão do Coágulo (Avaliação Quantitativa da...)",
        "k": "0",
        "c": "8",
        "code": "70.22.00.14"
    },
    {
        "id": 3514,
        "label": "Taxa de Protrombina = Tempo de Protrombina - Ver Cód. 70.22.00.06",
        "k": "0",
        "c": "0",
        "code": "70.22.00.16"
    },
    {
        "id": 3515,
        "label": "Tempo de Cefalina-Caulino = Tempo de Tromboplastina Parcial Activada = A.P.T.T. Ver Cód.70.22.00.01",
        "k": "0",
        "c": "0",
        "code": "70.22.00.17"
    },
    {
        "id": 3516,
        "label": "Tempo de Protrombina = Taxa de Protrombina Ver Cód.70.22.00.06",
        "k": "0",
        "c": "0",
        "code": "70.22.00.18"
    },
    {
        "id": 3517,
        "label": "Tempo de Quick = Taxa de Protrombina - Ver Cód. 70.22.00.06",
        "k": "0",
        "c": "0",
        "code": "70.22.00.19"
    },
    {
        "id": 3518,
        "label": "Tempo de Recalcificação do Plasma",
        "k": "0",
        "c": "2",
        "code": "70.22.00.20"
    },
    {
        "id": 3519,
        "label": "Tempo de Recalcificação do Plasma Activado",
        "k": "0",
        "c": "2",
        "code": "70.22.00.21"
    },
    {
        "id": 3520,
        "label": "Tempo de Reptilase",
        "k": "0",
        "c": "19",
        "code": "70.22.00.22"
    },
    {
        "id": 3521,
        "label": "Tempo de Stypven",
        "k": "0",
        "c": "6",
        "code": "70.22.00.23"
    },
    {
        "id": 3522,
        "label": "Tempo de Trombina",
        "k": "0",
        "c": "6",
        "code": "70.22.00.24"
    },
    {
        "id": 3523,
        "label": "Tempo de Trombina-Coagulase",
        "k": "0",
        "c": "6",
        "code": "70.22.00.25"
    },
    {
        "id": 3524,
        "label": "Tempo de Tromboplastina Parcial Activado = T.de Caulino- Cefalina = A.P.T.T. Ver Cód.70.22.00.01",
        "k": "0",
        "c": "0",
        "code": "70.22.00.26"
    },
    {
        "id": 3525,
        "label": "Tempo de trombina com sulfato de protamina",
        "k": "0",
        "c": "20",
        "code": "70.22.00.27"
    },
    {
        "id": 3526,
        "label": "Estudo da coagulação: Consulta (Acrescido das provas executadas) - Ver Cod. 01.00.00.03 ou 01.00.00.04",
        "k": "0",
        "c": "0",
        "code": "70.22.00.28"
    },
    {
        "id": 3527,
        "label": "Tempo de protrombina com terapêutica orientadora",
        "k": "2",
        "c": "4",
        "code": "70.22.00.29"
    },
    {
        "id": 3528,
        "label": "Antigénio Relacionado com o Factor IX = Factor IX Ag",
        "k": "0",
        "c": "30",
        "code": "70.23.00.01"
    },
    {
        "id": 3529,
        "label": "Antigénio Relacionado com o Factor VIII = Factor VIII Ag",
        "k": "0",
        "c": "30",
        "code": "70.23.00.02"
    },
    {
        "id": 3530,
        "label": "Criofibrinogénio",
        "k": "0",
        "c": "9",
        "code": "70.23.00.03"
    },
    {
        "id": 3531,
        "label": "Factor I = Fibrinogénio",
        "k": "0",
        "c": "15",
        "code": "70.23.00.04"
    },
    {
        "id": 3532,
        "label": "Factor II-C",
        "k": "0",
        "c": "20",
        "code": "70.23.00.05"
    },
    {
        "id": 3533,
        "label": "Factor IX-C",
        "k": "0",
        "c": "15",
        "code": "70.23.00.06"
    },
    {
        "id": 3534,
        "label": "Factor IX Ag = Antigénio Relacionado c/o Factor IX Ver Cód.70.23.00.01",
        "k": "0",
        "c": "0",
        "code": "70.23.00.07"
    },
    {
        "id": 3535,
        "label": "Factor V-C",
        "k": "0",
        "c": "15",
        "code": "70.23.00.08"
    },
    {
        "id": 3536,
        "label": "Factor VII Ag",
        "k": "0",
        "c": "63",
        "code": "70.23.00.09"
    },
    {
        "id": 3537,
        "label": "Factor VII-C",
        "k": "0",
        "c": "15",
        "code": "70.23.00.10"
    },
    {
        "id": 3538,
        "label": "Factor VIII Ag = Antigénio Relacionada c/o F.VIII Ver Cód.70.23.00.02",
        "k": "0",
        "c": "0",
        "code": "70.23.00.11"
    },
    {
        "id": 3539,
        "label": "Factor VIII-C",
        "k": "0",
        "c": "30",
        "code": "70.23.00.12"
    },
    {
        "id": 3540,
        "label": "Factor VIII-vW = Cofactor da Ristocetina",
        "k": "0",
        "c": "33",
        "code": "70.23.00.13"
    },
    {
        "id": 3541,
        "label": "Factor Von",
        "k": "0",
        "c": "8",
        "code": "70.23.00.14"
    },
    {
        "id": 3542,
        "label": "Factor X-C",
        "k": "0",
        "c": "40",
        "code": "70.23.00.15"
    },
    {
        "id": 3543,
        "label": "Factor XI-C",
        "k": "0",
        "c": "30",
        "code": "70.23.00.16"
    },
    {
        "id": 3544,
        "label": "Factor XII-C",
        "k": "0",
        "c": "60",
        "code": "70.23.00.17"
    },
    {
        "id": 3545,
        "label": "Factor XIII-C",
        "k": "0",
        "c": "35",
        "code": "70.23.00.18"
    },
    {
        "id": 3546,
        "label": "Fibrinogénio = Factor I - Ver Cód. 70.23.00.04",
        "k": "0",
        "c": "0",
        "code": "70.23.00.19"
    },
    {
        "id": 3547,
        "label": "P&P de Owren",
        "k": "0",
        "c": "6",
        "code": "70.23.00.20"
    },
    {
        "id": 3548,
        "label": "Tromboteste",
        "k": "0",
        "c": "5",
        "code": "70.23.00.21"
    },
    {
        "id": 3549,
        "label": "Two-seven-ten = T.S.T.",
        "k": "0",
        "c": "5",
        "code": "70.23.00.22"
    },
    {
        "id": 3550,
        "label": "Fibronectina",
        "k": "0",
        "c": "84",
        "code": "70.23.00.23"
    },
    {
        "id": 3551,
        "label": "Beta = Tromboglobulina = Beta-TG",
        "k": "0",
        "c": "100",
        "code": "70.24.00.01"
    },
    {
        "id": 3552,
        "label": "Complexo Trombina/Antitrombina III = TAT",
        "k": "0",
        "c": "150",
        "code": "70.24.00.02"
    },
    {
        "id": 3553,
        "label": "Factor Fletcher = Pré-Kalikreína",
        "k": "0",
        "c": "10",
        "code": "70.24.00.03"
    },
    {
        "id": 3554,
        "label": "Factor Plaquetário 4 = PF4",
        "k": "0",
        "c": "100",
        "code": "70.24.00.04"
    },
    {
        "id": 3555,
        "label": "Kalicreína",
        "k": "0",
        "c": "10",
        "code": "70.24.00.05"
    },
    {
        "id": 3556,
        "label": "Pré-Kalicreína = Factor Fletcher Ver Cód.70.24.00.03",
        "k": "0",
        "c": "0",
        "code": "70.24.00.06"
    },
    {
        "id": 3557,
        "label": "Prostaciclinas (Plasmáticas ou urinárias)",
        "k": "0",
        "c": "200",
        "code": "70.24.00.07"
    },
    {
        "id": 3558,
        "label": "Tromboxanos (Plasmáticos ou urinários)",
        "k": "0",
        "c": "200",
        "code": "70.24.00.08"
    },
    {
        "id": 3559,
        "label": "Anticoagulante Lúpico",
        "k": "0",
        "c": "40",
        "code": "70.25.00.01"
    },
    {
        "id": 3560,
        "label": "Anticoagulantes Circulantes (Pesquisa de...)",
        "k": "0",
        "c": "10",
        "code": "70.25.00.02"
    },
    {
        "id": 3561,
        "label": "Antitrombina III",
        "k": "0",
        "c": "15",
        "code": "70.25.00.03"
    },
    {
        "id": 3562,
        "label": "Heparina",
        "k": "0",
        "c": "13",
        "code": "70.25.00.04"
    },
    {
        "id": 3563,
        "label": "Heparina (Prova de Tolerância à...)",
        "k": "0",
        "c": "6",
        "code": "70.25.00.05"
    },
    {
        "id": 3564,
        "label": "Proteína C da Coagulaçao",
        "k": "0",
        "c": "15",
        "code": "70.25.00.06"
    },
    {
        "id": 3565,
        "label": "Proteína S total",
        "k": "0",
        "c": "60",
        "code": "70.25.00.07"
    },
    {
        "id": 3566,
        "label": "Prova de Tolerância à Heparina - Ver Cód. 70.25.00.05",
        "k": "0",
        "c": "0",
        "code": "70.25.00.08"
    },
    {
        "id": 3567,
        "label": "Antitrombina III modificada",
        "k": "0",
        "c": "67",
        "code": "70.25.00.09"
    },
    {
        "id": 3569,
        "label": "Proteina S (livre)",
        "k": "0",
        "c": "60",
        "code": "70.25.00.11"
    },
    {
        "id": 3570,
        "label": "Proteina S (funcional)",
        "k": "0",
        "c": "17",
        "code": "70.25.00.12"
    },
    {
        "id": 3571,
        "label": "C4 bBP",
        "k": "0",
        "c": "92",
        "code": "70.25.00.13"
    },
    {
        "id": 3572,
        "label": "Fragmentos 1 e 2 da protrombina (F1+2)",
        "k": "0",
        "c": "105",
        "code": "70.25.00.14"
    },
    {
        "id": 3573,
        "label": "Anticorpo anti-cardiolipina (ACA) (IgG ou IgM), cada",
        "k": "0",
        "c": "50",
        "code": "70.25.00.15"
    },
    {
        "id": 3574,
        "label": "Anticorpo anti-fosfolipido (APA)",
        "k": "0",
        "c": "50",
        "code": "70.25.00.16"
    },
    {
        "id": 3575,
        "label": "Anticorpo anti-lupico",
        "k": "0",
        "c": "70",
        "code": "70.25.00.17"
    },
    {
        "id": 3576,
        "label": "Resistência à Proteina C activada",
        "k": "0",
        "c": "20",
        "code": "70.25.00.18"
    },
    {
        "id": 3577,
        "label": "Dímero D da Fibrina, (Pesquisa de...)",
        "k": "0",
        "c": "7",
        "code": "70.26.00.01"
    },
    {
        "id": 3578,
        "label": "Fibrina (Dímero D da...) por Elisa",
        "k": "0",
        "c": "60",
        "code": "70.26.00.02"
    },
    {
        "id": 3579,
        "label": "Fibrina (Dímero D da ) (Pesquisa de ..) Ver Cód. 70.26.00.01",
        "k": "0",
        "c": "0",
        "code": "70.26.00.03"
    },
    {
        "id": 3580,
        "label": "Fibrina (Pesquisa de monómeros da...)",
        "k": "0",
        "c": "7",
        "code": "70.26.00.04"
    },
    {
        "id": 3581,
        "label": "Fibrinopeptídeo A",
        "k": "0",
        "c": "50",
        "code": "70.26.00.05"
    },
    {
        "id": 3582,
        "label": "Fibrinólise (Lise do Coágulo de Euglobulinas)",
        "k": "0",
        "c": "8",
        "code": "70.26.00.06"
    },
    {
        "id": 3583,
        "label": "Fibrinólise (Lise do Coágulo de Sangue Total)",
        "k": "0",
        "c": "2",
        "code": "70.26.00.07"
    },
    {
        "id": 3584,
        "label": "Gel-Etanol (Prova do...) = Pesquisa de Monómeros de Fibrina",
        "k": "0",
        "c": "3",
        "code": "70.26.00.08"
    },
    {
        "id": 3585,
        "label": "Lise das Euglobulinas",
        "k": "0",
        "c": "8",
        "code": "70.26.00.09"
    },
    {
        "id": 3586,
        "label": "Lise do Coágulo de Sangue Total Ver Cód.70.26.00.07",
        "k": "0",
        "c": "0",
        "code": "70.26.00.10"
    },
    {
        "id": 3587,
        "label": "Monómeros de Fibrina (Pesquisa de ...) - Ver Cód. 70.26.00.08",
        "k": "0",
        "c": "0",
        "code": "70.26.00.11"
    },
    {
        "id": 3588,
        "label": "Produtos de Degradaqão da Fibrina = FDP = PDF Ver Cód.70.26.00.04",
        "k": "0",
        "c": "0",
        "code": "70.26.00.12"
    },
    {
        "id": 3589,
        "label": "Protamina (Prova da...)",
        "k": "0",
        "c": "6",
        "code": "70.26.00.13"
    },
    {
        "id": 3590,
        "label": "Prova da Protamina - Ver Cód. 70.26.00.13",
        "k": "0",
        "c": "0",
        "code": "70.26.00.14"
    },
    {
        "id": 3591,
        "label": "Prova do Gel-Etanol = Pesquisa de Monómeros de Fibrina Ver Cód.70.26.00.08",
        "k": "0",
        "c": "0",
        "code": "70.26.00.15"
    },
    {
        "id": 3592,
        "label": "Alfa-2-Antiplasmina",
        "k": "0",
        "c": "18",
        "code": "70.27.00.01"
    },
    {
        "id": 3593,
        "label": "Antiplasmina = Inibidor da Plasmina",
        "k": "0",
        "c": "120",
        "code": "70.27.00.02"
    },
    {
        "id": 3594,
        "label": "Estreptoquinase",
        "k": "0",
        "c": "120",
        "code": "70.27.00.03"
    },
    {
        "id": 3595,
        "label": "Plasmina",
        "k": "0",
        "c": "120",
        "code": "70.27.00.04"
    },
    {
        "id": 3596,
        "label": "Plasminogénio",
        "k": "0",
        "c": "8",
        "code": "70.27.00.05"
    },
    {
        "id": 3597,
        "label": "Plasminogénio (Activador Tecidular do...) = tPA com ou sem estase (cada)",
        "k": "0",
        "c": "50",
        "code": "70.27.00.06"
    },
    {
        "id": 3598,
        "label": "Plasminogénio (Activador do...) = uPA(Urokinase)com ou sem estase (cada)",
        "k": "0",
        "c": "120",
        "code": "70.27.00.07"
    },
    {
        "id": 3599,
        "label": "Plasminogénio (Actividade do...) = PA",
        "k": "0",
        "c": "30",
        "code": "70.27.00.08"
    },
    {
        "id": 3600,
        "label": "Plasminogénio (Inibidor do Activador do...) = PAI",
        "k": "0",
        "c": "40",
        "code": "70.27.00.09"
    },
    {
        "id": 3601,
        "label": "Plasminogénio Ag.(Antigénio do Plasminogénio) = PA Ag",
        "k": "0",
        "c": "120",
        "code": "70.27.00.10"
    },
    {
        "id": 3602,
        "label": "Adesividade Plaquetária",
        "k": "0",
        "c": "13",
        "code": "70.29.00.01"
    },
    {
        "id": 3603,
        "label": "Agregação Plaquetária Espontânea",
        "k": "0",
        "c": "10",
        "code": "70.29.00.02"
    },
    {
        "id": 3604,
        "label": "Agregação Plaquetária Induzida pela Adrenalina",
        "k": "0",
        "c": "13",
        "code": "70.29.00.03"
    },
    {
        "id": 3605,
        "label": "Agregação Plaquetária Induzida pela Ristocetina (no P.R.P.)",
        "k": "0",
        "c": "17",
        "code": "70.29.00.04"
    },
    {
        "id": 3606,
        "label": "Agregação Plaquetária Induzida pelo ADP",
        "k": "0",
        "c": "14",
        "code": "70.29.00.05"
    },
    {
        "id": 3607,
        "label": "Agregação Plaquetária Induzida pelo Colagénio",
        "k": "0",
        "c": "17",
        "code": "70.29.00.06"
    },
    {
        "id": 3608,
        "label": "Factor Plaquetário 3",
        "k": "0",
        "c": "12",
        "code": "70.29.00.07"
    },
    {
        "id": 3609,
        "label": "Agregação plaquetária induzida pela ristocetina (FWR:Co/Plasmático)",
        "k": "0",
        "c": "33",
        "code": "70.29.00.08"
    },
    {
        "id": 3610,
        "label": "Agregação plaquetária induzida pelo ácido araquidónico",
        "k": "0",
        "c": "17",
        "code": "70.29.00.09"
    },
    {
        "id": 3611,
        "label": "ABO e Rh – (Grupo Sanguíneo – Sistema ABO e Rh)",
        "k": "0",
        "c": "5",
        "code": "70.31.00.01"
    },
    {
        "id": 3612,
        "label": "Aglutininas Eritrocitárias (Identificação das...)",
        "k": "0",
        "c": "30",
        "code": "70.31.00.02"
    },
    {
        "id": 3613,
        "label": "Aglutininas Eritrocitárias (Pesquisa c/Albumina)",
        "k": "0",
        "c": "6",
        "code": "70.31.00.03"
    },
    {
        "id": 3614,
        "label": "Aglutininas Eritrocitárias (Pesquisa com enzimas)",
        "k": "0",
        "c": "6",
        "code": "70.31.00.04"
    },
    {
        "id": 3615,
        "label": "Aglutininas Eritrocitárias (Pesquisa em meio salino)",
        "k": "0",
        "c": "5",
        "code": "70.31.00.05"
    },
    {
        "id": 3616,
        "label": "Aglutininas Eritrocitárias (Titulação c/albumina)",
        "k": "0",
        "c": "9",
        "code": "70.31.00.06"
    },
    {
        "id": 3617,
        "label": "Aglutininas Eritrocitárias (Titulação com enzimas)",
        "k": "0",
        "c": "9",
        "code": "70.31.00.07"
    },
    {
        "id": 3618,
        "label": "Aglutininas Eritrocitárias (Titulação em meio salino)",
        "k": "0",
        "c": "8",
        "code": "70.31.00.08"
    },
    {
        "id": 3619,
        "label": "Anticorpos anti-Leucocitários (Pesquisa c/Titulação, se necessário de.)",
        "k": "0",
        "c": "15",
        "code": "70.31.00.09"
    },
    {
        "id": 3620,
        "label": "Anticorpos anti-Plaquetários (Pesquisa c/Titulação se necessário de...) -Ver Cód. 75.01.00.01",
        "k": "0",
        "c": "0",
        "code": "70.31.00.10"
    },
    {
        "id": 3621,
        "label": "Anticorpos bi-fásicos de Donath-Landsteiner (Pesq.c/Titulação se nec.de)",
        "k": "0",
        "c": "8",
        "code": "70.31.00.11"
    },
    {
        "id": 3622,
        "label": "Antigénios Eritrocitários (excl.os do sist.ABO e Rh)",
        "k": "0",
        "c": "8",
        "code": "70.31.00.12"
    },
    {
        "id": 3623,
        "label": "Coombs Directa (Prova de...)",
        "k": "0",
        "c": "5",
        "code": "70.31.00.13"
    },
    {
        "id": 3624,
        "label": "Coombs Indirecta Qualitativa (Prova de...)",
        "k": "0",
        "c": "5",
        "code": "70.31.00.14"
    },
    {
        "id": 3625,
        "label": "Coombs Indirecta Quantitativa (Prova de...)",
        "k": "0",
        "c": "20",
        "code": "70.31.00.15"
    },
    {
        "id": 3626,
        "label": "Crioaglutininas (Pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "70.31.00.16"
    },
    {
        "id": 3627,
        "label": "Crioaglutininas (Titulação das...)",
        "k": "0",
        "c": "10",
        "code": "70.31.00.17"
    },
    {
        "id": 3628,
        "label": "Fenótipo Rhesus (aglutinogénios)",
        "k": "0",
        "c": "12",
        "code": "70.31.00.18"
    },
    {
        "id": 3629,
        "label": "Iso-hemaglutininas Naturais (Titulação)",
        "k": "0",
        "c": "10",
        "code": "70.31.00.19"
    },
    {
        "id": 3630,
        "label": "Rh (determinação do Genótipo)",
        "k": "0",
        "c": "15",
        "code": "70.31.00.20"
    },
    {
        "id": 3631,
        "label": "Ácido Láctico=Lactatos",
        "k": "0",
        "c": "10",
        "code": "72.01.00.01"
    },
    {
        "id": 3632,
        "label": "Ácido Láctico (Pesquisa de...)",
        "k": "0",
        "c": "3",
        "code": "72.01.00.02"
    },
    {
        "id": 3633,
        "label": "Ácido Pirúvico",
        "k": "0",
        "c": "10",
        "code": "72.01.00.03"
    },
    {
        "id": 3634,
        "label": "Açúcares (Estudo Cromatográfico)",
        "k": "0",
        "c": "10",
        "code": "72.01.00.04"
    },
    {
        "id": 3635,
        "label": "Frutosamina",
        "k": "0",
        "c": "20",
        "code": "72.01.00.05"
    },
    {
        "id": 3636,
        "label": "Frutose",
        "k": "0",
        "c": "6",
        "code": "72.01.00.06"
    },
    {
        "id": 3637,
        "label": "Frutose (Sobrecarga Endovenosa)",
        "k": "0",
        "c": "125",
        "code": "72.01.00.07"
    },
    {
        "id": 3638,
        "label": "Frutose-1,6 Difosfatase",
        "k": "0",
        "c": "50",
        "code": "72.01.00.08"
    },
    {
        "id": 3639,
        "label": "Galactose",
        "k": "0",
        "c": "8",
        "code": "72.01.00.09"
    },
    {
        "id": 3640,
        "label": "Galactose (Prova de Tolerância à...)",
        "k": "0",
        "c": "35",
        "code": "72.01.00.10"
    },
    {
        "id": 3641,
        "label": "Galactose - Sobrecarga Endovenosa",
        "k": "0",
        "c": "140",
        "code": "72.01.00.11"
    },
    {
        "id": 3642,
        "label": "Glicogénio",
        "k": "0",
        "c": "30",
        "code": "72.01.00.12"
    },
    {
        "id": 3643,
        "label": "Glicose",
        "k": "0",
        "c": "2",
        "code": "72.01.00.13"
    },
    {
        "id": 3644,
        "label": "Glicose Após Almoço",
        "k": "0",
        "c": "3",
        "code": "72.01.00.14"
    },
    {
        "id": 3645,
        "label": "Glucagina por Sobrecarga Endovenosa",
        "k": "0",
        "c": "64",
        "code": "72.01.00.15"
    },
    {
        "id": 3646,
        "label": "Glutamina",
        "k": "0",
        "c": "8",
        "code": "72.01.00.16"
    },
    {
        "id": 3647,
        "label": "Hemoglobina A1c = Hemoglobina Glicada",
        "k": "0",
        "c": "30",
        "code": "72.01.00.17"
    },
    {
        "id": 3648,
        "label": "Lactose",
        "k": "0",
        "c": "8",
        "code": "72.01.00.18"
    },
    {
        "id": 3649,
        "label": "Lactose (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.01.00.19"
    },
    {
        "id": 3650,
        "label": "Levulose",
        "k": "0",
        "c": "8",
        "code": "72.01.00.20"
    },
    {
        "id": 3651,
        "label": "Levulose (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.01.00.21"
    },
    {
        "id": 3652,
        "label": "Oligossacaridos - Pesquisa e Identificação",
        "k": "0",
        "c": "20",
        "code": "72.01.00.22"
    },
    {
        "id": 3653,
        "label": "Pentoses (Pesquisa de...)",
        "k": "0",
        "c": "4",
        "code": "72.01.00.23"
    },
    {
        "id": 3654,
        "label": "Açúcares redutores (pesquisa)",
        "k": "0",
        "c": "5",
        "code": "72.01.00.24"
    },
    {
        "id": 3655,
        "label": "Curva de hiperglicémia provocada 3h com 4 doseamentos de Glicose = Prova oral de tolerância à Glicose de 3h com 4 doseamentos de Glicose",
        "k": "0",
        "c": "11",
        "code": "72.01.00.25"
    },
    {
        "id": 3656,
        "label": "Curva de hiperglicémia provocada 4h com 5 doseamentos de Glicose = Prova oral de tolerância à Glicose de 4h com 5 doseamentos de Glicose",
        "k": "0",
        "c": "12",
        "code": "72.01.00.26"
    },
    {
        "id": 3657,
        "label": "Curva de hiperglicémia provocada 5h com 6 doseamentos de Glicose = Prova oral de tolerância à Glicose de 5h com 6 doseamentos de Glicose",
        "k": "0",
        "c": "14",
        "code": "72.01.00.27"
    },
    {
        "id": 3658,
        "label": "Exton-Rose (Prova de)",
        "k": "0",
        "c": "10",
        "code": "72.01.00.28"
    },
    {
        "id": 3659,
        "label": "Frutose 1 Fosfato Aldolase",
        "k": "0",
        "c": "80",
        "code": "72.01.00.29"
    },
    {
        "id": 3660,
        "label": "Frutose 1,6 Difosfato-Aldolase",
        "k": "0",
        "c": "80",
        "code": "72.01.00.30"
    },
    {
        "id": 3661,
        "label": "Lactose (Prova de tolerância à)",
        "k": "0",
        "c": "35",
        "code": "72.01.00.31"
    },
    {
        "id": 3662,
        "label": "Ácido Fenilpirúvico (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.02.00.01"
    },
    {
        "id": 3663,
        "label": "Ácido Glutâmico (Pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "72.02.00.02"
    },
    {
        "id": 3664,
        "label": "Ácido Homogentísico (Pesquisa de...)",
        "k": "0",
        "c": "3",
        "code": "72.02.00.03"
    },
    {
        "id": 3665,
        "label": "Ácido Oxálico",
        "k": "0",
        "c": "30",
        "code": "72.02.00.04"
    },
    {
        "id": 3666,
        "label": "Ácido Úrico",
        "k": "0",
        "c": "3",
        "code": "72.02.00.05"
    },
    {
        "id": 3667,
        "label": "Ácidos Aminados (sep.cromatog.bidimensional)",
        "k": "0",
        "c": "25",
        "code": "72.02.00.06"
    },
    {
        "id": 3668,
        "label": "Ácidos Aminados (sep.cromatog.unidimensional)",
        "k": "0",
        "c": "11",
        "code": "72.02.00.07"
    },
    {
        "id": 3669,
        "label": "Ácidos Orgânicos + Azoto Amoniacal",
        "k": "0",
        "c": "20",
        "code": "72.02.00.08"
    },
    {
        "id": 3670,
        "label": "Acidúrias Orgânicas (Pesquisa e Identificação)",
        "k": "0",
        "c": "50",
        "code": "72.02.00.09"
    },
    {
        "id": 3671,
        "label": "Alanina – Sobrecarga Oral",
        "k": "0",
        "c": "76",
        "code": "72.02.00.10"
    },
    {
        "id": 3672,
        "label": "Albumina",
        "k": "0",
        "c": "3",
        "code": "72.02.00.11"
    },
    {
        "id": 3673,
        "label": "Albumina (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.02.00.12"
    },
    {
        "id": 3674,
        "label": "Albumina e Globulinas",
        "k": "0",
        "c": "6",
        "code": "72.02.00.13"
    },
    {
        "id": 3675,
        "label": "Alfa-1 Antitripsina",
        "k": "0",
        "c": "12",
        "code": "72.02.00.14"
    },
    {
        "id": 3676,
        "label": "Alfa-1 Antitripsina (Fenotipagem)",
        "k": "0",
        "c": "40",
        "code": "72.02.00.15"
    },
    {
        "id": 3677,
        "label": "Alfa-1 Quimotripsina",
        "k": "0",
        "c": "12",
        "code": "72.02.00.16"
    },
    {
        "id": 3678,
        "label": "Alfa-2 Macroglobulina",
        "k": "0",
        "c": "12",
        "code": "72.02.00.17"
    },
    {
        "id": 3679,
        "label": "Aminoacidúria Total",
        "k": "0",
        "c": "20",
        "code": "72.02.00.18"
    },
    {
        "id": 3680,
        "label": "Amónia",
        "k": "0",
        "c": "10",
        "code": "72.02.00.19"
    },
    {
        "id": 3681,
        "label": "Apolipoproteína A",
        "k": "0",
        "c": "30",
        "code": "72.02.00.20"
    },
    {
        "id": 3682,
        "label": "Apolipoproteína C",
        "k": "0",
        "c": "40",
        "code": "72.02.00.21"
    },
    {
        "id": 3683,
        "label": "Apolipoproteína E",
        "k": "0",
        "c": "40",
        "code": "72.02.00.22"
    },
    {
        "id": 3684,
        "label": "Apolipoproteína Lp(a)",
        "k": "0",
        "c": "40",
        "code": "72.02.00.23"
    },
    {
        "id": 3685,
        "label": "Azoto Total não Proteico",
        "k": "0",
        "c": "2",
        "code": "72.02.00.24"
    },
    {
        "id": 3686,
        "label": "Azoto dos ácidos Aminados",
        "k": "0",
        "c": "8",
        "code": "72.02.00.25"
    },
    {
        "id": 3687,
        "label": "Beta-1 Glicoproteína",
        "k": "0",
        "c": "50",
        "code": "72.02.00.26"
    },
    {
        "id": 3688,
        "label": "Beta-2 Microglobulina",
        "k": "0",
        "c": "50",
        "code": "72.02.00.27"
    },
    {
        "id": 3689,
        "label": "Ceruloplasmina",
        "k": "0",
        "c": "12",
        "code": "72.02.00.28"
    },
    {
        "id": 3690,
        "label": "Cistina (Pesquisa de...)",
        "k": "0",
        "c": "3",
        "code": "72.02.00.29"
    },
    {
        "id": 3691,
        "label": "Cistinúria",
        "k": "0",
        "c": "20",
        "code": "72.02.00.30"
    },
    {
        "id": 3692,
        "label": "Creatina",
        "k": "0",
        "c": "9",
        "code": "72.02.00.31"
    },
    {
        "id": 3693,
        "label": "Creatinina",
        "k": "0",
        "c": "2",
        "code": "72.02.00.32"
    },
    {
        "id": 3694,
        "label": "Crioglobulinas (Caracterização das...)",
        "k": "0",
        "c": "20",
        "code": "72.02.00.33"
    },
    {
        "id": 3695,
        "label": "Crioglobulinas (Pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "72.02.00.34"
    },
    {
        "id": 3696,
        "label": "Electroforese das Proteínas em liq.biológicos, após sua concentração",
        "k": "0",
        "c": "15",
        "code": "72.02.00.35"
    },
    {
        "id": 3697,
        "label": "Fenilalanina",
        "k": "0",
        "c": "36",
        "code": "72.02.00.36"
    },
    {
        "id": 3698,
        "label": "Fenilcetonúria = PKU (Pesquisa de...)",
        "k": "0",
        "c": "12",
        "code": "72.02.00.37"
    },
    {
        "id": 3699,
        "label": "Ferritina",
        "k": "0",
        "c": "40",
        "code": "72.02.00.38"
    },
    {
        "id": 3700,
        "label": "Glicoproteínas (Electroforese das...)",
        "k": "0",
        "c": "15",
        "code": "72.02.00.39"
    },
    {
        "id": 3701,
        "label": "Haptoglobina",
        "k": "0",
        "c": "12",
        "code": "72.02.00.40"
    },
    {
        "id": 3702,
        "label": "Hemoglobina (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.02.00.41"
    },
    {
        "id": 3703,
        "label": "Hemopexina",
        "k": "0",
        "c": "12",
        "code": "72.02.00.42"
    },
    {
        "id": 3704,
        "label": "L-DOPA",
        "k": "0",
        "c": "40",
        "code": "72.02.00.43"
    },
    {
        "id": 3705,
        "label": "Melanina (Pesquisa de...)",
        "k": "0",
        "c": "4",
        "code": "72.02.00.44"
    },
    {
        "id": 3706,
        "label": "Microalbuminúria",
        "k": "0",
        "c": "18",
        "code": "72.02.00.45"
    },
    {
        "id": 3707,
        "label": "Mioglobina (Pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "72.02.00.46"
    },
    {
        "id": 3708,
        "label": "Mucopolissacaridases na Urina (est.cromat. camada fina e coluna)",
        "k": "0",
        "c": "50",
        "code": "72.02.00.47"
    },
    {
        "id": 3709,
        "label": "Mucopolissacáridos (Estudo Cromatográfico)",
        "k": "0",
        "c": "40",
        "code": "72.02.00.48"
    },
    {
        "id": 3710,
        "label": "Mucoproteínas",
        "k": "0",
        "c": "9",
        "code": "72.02.00.49"
    },
    {
        "id": 3711,
        "label": "Proteína Bence-Jones (Met-Quimico) - Cód. 75.02.00.02",
        "k": "0",
        "c": "0",
        "code": "72.02.00.50"
    },
    {
        "id": 3712,
        "label": "Proteínas Totais",
        "k": "0",
        "c": "3",
        "code": "72.02.00.51"
    },
    {
        "id": 3713,
        "label": "Proteínas (Pesquisa de ...)",
        "k": "0",
        "c": "2",
        "code": "72.02.00.52"
    },
    {
        "id": 3714,
        "label": "Transferrina",
        "k": "0",
        "c": "12",
        "code": "72.02.00.53"
    },
    {
        "id": 3715,
        "label": "Ureia",
        "k": "0",
        "c": "2",
        "code": "72.02.00.54"
    },
    {
        "id": 3716,
        "label": "Ureia (Depuração da...)",
        "k": "0",
        "c": "6",
        "code": "72.02.00.55"
    },
    {
        "id": 3717,
        "label": "ANP - Péptido natridiurético auricular",
        "k": "0",
        "c": "100",
        "code": "72.02.00.56"
    },
    {
        "id": 3718,
        "label": "Acetona (Pesquisa de)",
        "k": "0",
        "c": "2",
        "code": "72.02.00.57"
    },
    {
        "id": 3719,
        "label": "Ácido",
        "k": "0",
        "c": "2",
        "code": "72.02.00.58"
    },
    {
        "id": 3720,
        "label": "Ácido Gama-Aminobutirico = GABA",
        "k": "0",
        "c": "40",
        "code": "72.02.00.59"
    },
    {
        "id": 3721,
        "label": "AMP = Adenosina Monofosfato",
        "k": "0",
        "c": "20",
        "code": "72.02.00.60"
    },
    {
        "id": 3722,
        "label": "Apolipoproteina B",
        "k": "0",
        "c": "30",
        "code": "72.02.00.61"
    },
    {
        "id": 3723,
        "label": "BGP = Osteocalcina",
        "k": "0",
        "c": "70",
        "code": "72.02.00.62"
    },
    {
        "id": 3724,
        "label": "Clearence da Creatinina",
        "k": "0",
        "c": "6",
        "code": "72.02.00.63"
    },
    {
        "id": 3725,
        "label": "Electroforese das proteinas = Proteínograma",
        "k": "0",
        "c": "6",
        "code": "72.02.00.64"
    },
    {
        "id": 3726,
        "label": "Hemossiderina na urina (pesquisa de)",
        "k": "0",
        "c": "4",
        "code": "72.02.00.65"
    },
    {
        "id": 3727,
        "label": "Mucopolissacáridos (pesquisa de)",
        "k": "0",
        "c": "5",
        "code": "72.02.00.66"
    },
    {
        "id": 3728,
        "label": "Homocisteína (pesquisa de)",
        "k": "0",
        "c": "10",
        "code": "72.02.00.67"
    },
    {
        "id": 3729,
        "label": "Lp(a)",
        "k": "0",
        "c": "40",
        "code": "72.02.00.68"
    },
    {
        "id": 3730,
        "label": "Adenosinotrifosfato = ATP",
        "k": "0",
        "c": "9",
        "code": "72.02.00.69"
    },
    {
        "id": 3731,
        "label": "Acetona",
        "k": "0",
        "c": "5",
        "code": "72.03.00.01"
    },
    {
        "id": 3732,
        "label": "Ácido Beta-Hidroxibutírico",
        "k": "0",
        "c": "5",
        "code": "72.03.00.02"
    },
    {
        "id": 3733,
        "label": "Ácido Diacético",
        "k": "0",
        "c": "5",
        "code": "72.03.00.03"
    },
    {
        "id": 3734,
        "label": "Ácido Diacético (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.03.00.04"
    },
    {
        "id": 3735,
        "label": "Ácidos Gordos (cromatografia)",
        "k": "0",
        "c": "10",
        "code": "72.03.00.05"
    },
    {
        "id": 3736,
        "label": "Ácidos Gordos Esterificados",
        "k": "0",
        "c": "10",
        "code": "72.03.00.06"
    },
    {
        "id": 3737,
        "label": "Ácidos Gordos Livres",
        "k": "0",
        "c": "10",
        "code": "72.03.00.07"
    },
    {
        "id": 3738,
        "label": "Aspecto do Soro após Refrigeração= Supernatant Creaming",
        "k": "0",
        "c": "2",
        "code": "72.03.00.08"
    },
    {
        "id": 3739,
        "label": "Beta-Lipoproteínas",
        "k": "0",
        "c": "6",
        "code": "72.03.00.09"
    },
    {
        "id": 3740,
        "label": "Colesterol HDL 2",
        "k": "0",
        "c": "6",
        "code": "72.03.00.10"
    },
    {
        "id": 3741,
        "label": "Colesterol HDL 3",
        "k": "0",
        "c": "4",
        "code": "72.03.00.11"
    },
    {
        "id": 3742,
        "label": "Colesterol Total, Livre e Esterificado",
        "k": "0",
        "c": "6",
        "code": "72.03.00.12"
    },
    {
        "id": 3743,
        "label": "Colesterol VLDL",
        "k": "0",
        "c": "4",
        "code": "72.03.00.13"
    },
    {
        "id": 3744,
        "label": "Colesterol total",
        "k": "0",
        "c": "3",
        "code": "72.03.00.14"
    },
    {
        "id": 3745,
        "label": "Corpos Cetónicos = Acetona (Doseamento)",
        "k": "0",
        "c": "5",
        "code": "72.03.00.15"
    },
    {
        "id": 3746,
        "label": "Corpos Cetónicos = Acetona (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.03.00.16"
    },
    {
        "id": 3747,
        "label": "Esteres dos Ácidos Gordos",
        "k": "0",
        "c": "40",
        "code": "72.03.00.17"
    },
    {
        "id": 3748,
        "label": "Fosfolipídeos",
        "k": "0",
        "c": "40",
        "code": "72.03.00.18"
    },
    {
        "id": 3749,
        "label": "Gorduras Totais nas Fezes de 3 Dias",
        "k": "0",
        "c": "20",
        "code": "72.03.00.19"
    },
    {
        "id": 3750,
        "label": "Perfil Lipidico (separação por Ultracentrifugação)",
        "k": "0",
        "c": "60",
        "code": "72.03.00.20"
    },
    {
        "id": 3751,
        "label": "Triglicerídeos",
        "k": "0",
        "c": "6",
        "code": "72.03.00.21"
    },
    {
        "id": 3752,
        "label": "Aril Sulfatase A",
        "k": "0",
        "c": "115",
        "code": "72.03.00.22"
    },
    {
        "id": 3753,
        "label": "Colesterol HDL",
        "k": "0",
        "c": "4",
        "code": "72.03.00.23"
    },
    {
        "id": 3754,
        "label": "Apoproteina E total",
        "k": "0",
        "c": "67",
        "code": "72.03.00.24"
    },
    {
        "id": 3755,
        "label": "Colesterol LDL",
        "k": "0",
        "c": "4",
        "code": "72.03.00.25"
    },
    {
        "id": 3756,
        "label": "Apoproteina E - isomorfos",
        "k": "0",
        "c": "100",
        "code": "72.03.00.26"
    },
    {
        "id": 3757,
        "label": "Colesterol LDL (Det. Directa)",
        "k": "0",
        "c": "4",
        "code": "72.03.00.27"
    },
    {
        "id": 3758,
        "label": "Hexosaminidase total",
        "k": "0",
        "c": "67",
        "code": "72.03.00.28"
    },
    {
        "id": 3759,
        "label": "Electroforese das lipoproteínas = Lipoproteinograma = Lipidograma",
        "k": "0",
        "c": "25",
        "code": "72.03.00.29"
    },
    {
        "id": 3760,
        "label": "Lecitina-colesterol-acetiltransferase (LCAT)",
        "k": "0",
        "c": "225",
        "code": "72.03.00.30"
    },
    {
        "id": 3761,
        "label": "Ficha lípidica = Lipidograma + Colesterol + Trigliceridos + Colestrol HDL",
        "k": "0",
        "c": "38",
        "code": "72.03.00.31"
    },
    {
        "id": 3762,
        "label": "Razão Palmítica/esteária",
        "k": "0",
        "c": "13",
        "code": "72.03.00.32"
    },
    {
        "id": 3763,
        "label": "Lipoproteina lipase (LPL)",
        "k": "0",
        "c": "54",
        "code": "72.03.00.33"
    },
    {
        "id": 3764,
        "label": "Triglicérido-lipase-hepática TGHL",
        "k": "0",
        "c": "54",
        "code": "72.03.00.34"
    },
    {
        "id": 3765,
        "label": "VLDL Colesterol",
        "k": "0",
        "c": "4",
        "code": "72.03.00.35"
    },
    {
        "id": 3766,
        "label": "5-Nucleotídase = 5-NT",
        "k": "0",
        "c": "8",
        "code": "72.04.00.01"
    },
    {
        "id": 3767,
        "label": "Acetilcolinesterase",
        "k": "0",
        "c": "9",
        "code": "72.04.00.02"
    },
    {
        "id": 3768,
        "label": "Aldolase",
        "k": "0",
        "c": "9",
        "code": "72.04.00.03"
    },
    {
        "id": 3769,
        "label": "Alfa-L-HiaIoduronidase",
        "k": "0",
        "c": "50",
        "code": "72.04.00.04"
    },
    {
        "id": 3770,
        "label": "Amilase",
        "k": "0",
        "c": "4",
        "code": "72.04.00.05"
    },
    {
        "id": 3771,
        "label": "Aminopeptidase",
        "k": "0",
        "c": "6",
        "code": "72.04.00.06"
    },
    {
        "id": 3772,
        "label": "Aminopeptidase A",
        "k": "0",
        "c": "50",
        "code": "72.04.00.07"
    },
    {
        "id": 3773,
        "label": "Aril-Sulfatase A",
        "k": "0",
        "c": "50",
        "code": "72.04.00.08"
    },
    {
        "id": 3774,
        "label": "Aril-Sulfatase B",
        "k": "0",
        "c": "50",
        "code": "72.04.00.09"
    },
    {
        "id": 3775,
        "label": "Beta-Galactosídase",
        "k": "0",
        "c": "50",
        "code": "72.04.00.10"
    },
    {
        "id": 3776,
        "label": "Beta-Glucoronidase",
        "k": "0",
        "c": "50",
        "code": "72.04.00.11"
    },
    {
        "id": 3777,
        "label": "Beta-Glucosidase",
        "k": "0",
        "c": "50",
        "code": "72.04.00.12"
    },
    {
        "id": 3778,
        "label": "Colinesterase",
        "k": "0",
        "c": "9",
        "code": "72.04.00.13"
    },
    {
        "id": 3779,
        "label": "Desidrogenase Alfa-Hidroxibutírica = HBDH",
        "k": "0",
        "c": "8",
        "code": "72.04.00.14"
    },
    {
        "id": 3780,
        "label": "Desidrogenase Glutâmica = GLDH",
        "k": "0",
        "c": "8",
        "code": "72.04.00.15"
    },
    {
        "id": 3781,
        "label": "Desidrogenase Isocítrica = ICDH",
        "k": "0",
        "c": "8",
        "code": "72.04.00.16"
    },
    {
        "id": 3782,
        "label": "Desidrogenase Láctica = LDH = DHL",
        "k": "0",
        "c": "6",
        "code": "72.04.00.17"
    },
    {
        "id": 3783,
        "label": "Desidrogenase Láctica = LDH (Sep.Térmica das Iso-enzimas)",
        "k": "0",
        "c": "15",
        "code": "72.04.00.18"
    },
    {
        "id": 3784,
        "label": "Desidrogenase Málica = MDH",
        "k": "0",
        "c": "8",
        "code": "72.04.00.19"
    },
    {
        "id": 3785,
        "label": "Desidrogenase Sorbítica = SDH",
        "k": "0",
        "c": "12",
        "code": "72.04.00.20"
    },
    {
        "id": 3786,
        "label": "Dipeptidil-Aminopeptídase IV",
        "k": "0",
        "c": "50",
        "code": "72.04.00.21"
    },
    {
        "id": 3787,
        "label": "Dissacaridases",
        "k": "0",
        "c": "70",
        "code": "72.04.00.22"
    },
    {
        "id": 3788,
        "label": "Enzima Conversor da Angiotensina = SACE",
        "k": "0",
        "c": "40",
        "code": "72.04.00.23"
    },
    {
        "id": 3789,
        "label": "Fosfatase Ácida Total",
        "k": "0",
        "c": "3",
        "code": "72.04.00.24"
    },
    {
        "id": 3790,
        "label": "Fosfatase Alcalina",
        "k": "0",
        "c": "3",
        "code": "72.04.00.25"
    },
    {
        "id": 3791,
        "label": "Fosfatase Alcalina (Fraccionamento Térmico)",
        "k": "0",
        "c": "15",
        "code": "72.04.00.26"
    },
    {
        "id": 3792,
        "label": "Fosfatase Alcalina (Sep.Electroforética das Iso-enzimas da...)",
        "k": "0",
        "c": "30",
        "code": "72.04.00.27"
    },
    {
        "id": 3793,
        "label": "Fosfoglicero-mutase",
        "k": "0",
        "c": "12",
        "code": "72.04.00.28"
    },
    {
        "id": 3794,
        "label": "Fosfohexose-Isomerase = PHI",
        "k": "0",
        "c": "12",
        "code": "72.04.00.29"
    },
    {
        "id": 3795,
        "label": "Fosforilases",
        "k": "0",
        "c": "60",
        "code": "72.04.00.30"
    },
    {
        "id": 3796,
        "label": "Galacto Aminase (Pesquisa)",
        "k": "0",
        "c": "2",
        "code": "72.04.00.31"
    },
    {
        "id": 3797,
        "label": "Galacto-1-Fosfato-Uridiltransferase",
        "k": "0",
        "c": "8",
        "code": "72.04.00.32"
    },
    {
        "id": 3798,
        "label": "Galactose-1-Fosfato-Glutamil-Transferase",
        "k": "0",
        "c": "20",
        "code": "72.04.00.33"
    },
    {
        "id": 3799,
        "label": "Galactotransferase (Pesquisa de...) =Spot Test",
        "k": "0",
        "c": "15",
        "code": "72.04.00.34"
    },
    {
        "id": 3800,
        "label": "Glucose - 6 Fosfatase",
        "k": "0",
        "c": "20",
        "code": "72.04.00.35"
    },
    {
        "id": 3801,
        "label": "Hexosaminidase A",
        "k": "0",
        "c": "50",
        "code": "72.04.00.36"
    },
    {
        "id": 3802,
        "label": "Hexosaminidase A+B",
        "k": "0",
        "c": "60",
        "code": "72.04.00.37"
    },
    {
        "id": 3803,
        "label": "Isoamílase",
        "k": "0",
        "c": "10",
        "code": "72.04.00.38"
    },
    {
        "id": 3804,
        "label": "L-Fucosidase",
        "k": "0",
        "c": "50",
        "code": "72.04.00.39"
    },
    {
        "id": 3805,
        "label": "Lisozima = Muramidase",
        "k": "0",
        "c": "12",
        "code": "72.04.00.40"
    },
    {
        "id": 3806,
        "label": "Lipase",
        "k": "0",
        "c": "8",
        "code": "72.04.00.41"
    },
    {
        "id": 3807,
        "label": "Manosidase",
        "k": "0",
        "c": "50",
        "code": "72.04.00.42"
    },
    {
        "id": 3808,
        "label": "N-Acetil-Glucosaminidase",
        "k": "0",
        "c": "50",
        "code": "72.04.00.43"
    },
    {
        "id": 3809,
        "label": "Ornitino-Carbamiltransferase",
        "k": "0",
        "c": "12",
        "code": "72.04.00.44"
    },
    {
        "id": 3810,
        "label": "Pepsina",
        "k": "0",
        "c": "8",
        "code": "72.04.00.45"
    },
    {
        "id": 3811,
        "label": "Tripsina (Pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "72.04.00.46"
    },
    {
        "id": 3812,
        "label": "Tripsina",
        "k": "0",
        "c": "40",
        "code": "72.04.00.47"
    },
    {
        "id": 3813,
        "label": "Acetilcolinesterase Isoenzimas",
        "k": "0",
        "c": "13",
        "code": "72.04.00.48"
    },
    {
        "id": 3814,
        "label": "ALT = Alanina Aminotransferase = TGP",
        "k": "0",
        "c": "3",
        "code": "72.04.00.49"
    },
    {
        "id": 3815,
        "label": "AST = Aminotransferase Aspartato = GOT",
        "k": "0",
        "c": "3",
        "code": "72.04.00.50"
    },
    {
        "id": 3816,
        "label": "CK = CPK = Creatinafosfoquinase",
        "k": "0",
        "c": "8",
        "code": "72.04.00.51"
    },
    {
        "id": 3817,
        "label": "CK MB = Creatinafosfoquinase fracção MB",
        "k": "0",
        "c": "12",
        "code": "72.04.00.52"
    },
    {
        "id": 3818,
        "label": "CK MM = Creatinafosfoquinase fracção MM",
        "k": "0",
        "c": "30",
        "code": "72.04.00.53"
    },
    {
        "id": 3819,
        "label": "Isoenzimas da CK (Sep. Electrof. Das Iso-enzimas da CK)",
        "k": "0",
        "c": "30",
        "code": "72.04.00.54"
    },
    {
        "id": 3820,
        "label": "Desidrogenase da Glicose 6 Fosfato=G-6-PDH",
        "k": "0",
        "c": "6",
        "code": "72.04.00.55"
    },
    {
        "id": 3821,
        "label": "Desidrogenase Láctica (Separação electroforética das Iso-enzimas da...)",
        "k": "0",
        "c": "30",
        "code": "72.04.00.56"
    },
    {
        "id": 3822,
        "label": "Fosfatase ácida total e fracção prostática",
        "k": "0",
        "c": "6",
        "code": "72.04.00.57"
    },
    {
        "id": 3823,
        "label": "Galactotransferase Eritrocitária",
        "k": "0",
        "c": "58",
        "code": "72.04.00.58"
    },
    {
        "id": 3824,
        "label": "Gama glutamil transferase (GGT)",
        "k": "0",
        "c": "8",
        "code": "72.04.00.59"
    },
    {
        "id": 3825,
        "label": "Glucoroniltransferase da uridina difosfato",
        "k": "0",
        "c": "20",
        "code": "72.04.00.60"
    },
    {
        "id": 3826,
        "label": "LAP = Leucina-Aminopeptidase",
        "k": "0",
        "c": "8",
        "code": "72.04.00.61"
    },
    {
        "id": 3827,
        "label": "Quimotripsina",
        "k": "0",
        "c": "15",
        "code": "72.04.00.62"
    },
    {
        "id": 3828,
        "label": "Alfa-Amilase Pancreática",
        "k": "0",
        "c": "30",
        "code": "72.04.00.63"
    },
    {
        "id": 3829,
        "label": "Alfa-Amilase Salivar",
        "k": "0",
        "c": "30",
        "code": "72.04.00.64"
    },
    {
        "id": 3830,
        "label": "Ac.Clorídrico Livre e Acidez Tot.(Cont.Gástrico e/ou Duod.)s/ Colheita",
        "k": "0",
        "c": "15",
        "code": "72.05.00.01"
    },
    {
        "id": 3831,
        "label": "Bicarbonatos",
        "k": "0",
        "c": "5",
        "code": "72.05.00.02"
    },
    {
        "id": 3832,
        "label": "Cálcio",
        "k": "0",
        "c": "3",
        "code": "72.05.00.03"
    },
    {
        "id": 3833,
        "label": "Cálcio (absorção atómica)",
        "k": "0",
        "c": "40",
        "code": "72.05.00.04"
    },
    {
        "id": 3834,
        "label": "Cálcio Ionizado (Calculado)",
        "k": "0",
        "c": "7",
        "code": "72.05.00.05"
    },
    {
        "id": 3835,
        "label": "Cálcio Ionizado (Determinação Directa)",
        "k": "0",
        "c": "12",
        "code": "72.05.00.06"
    },
    {
        "id": 3836,
        "label": "Cloreto de Amónio",
        "k": "0",
        "c": "3",
        "code": "72.05.00.07"
    },
    {
        "id": 3837,
        "label": "Cloro",
        "k": "0",
        "c": "3",
        "code": "72.05.00.08"
    },
    {
        "id": 3838,
        "label": "Equilíbrio ácido-base (pH, pCO2, sat O2 e excesso de",
        "k": "0",
        "c": "40",
        "code": "72.05.00.09"
    },
    {
        "id": 3839,
        "label": "Ferro",
        "k": "0",
        "c": "4",
        "code": "72.05.00.10"
    },
    {
        "id": 3840,
        "label": "Ferro (Absorção Atómica)",
        "k": "0",
        "c": "40",
        "code": "72.05.00.11"
    },
    {
        "id": 3841,
        "label": "Fosforo Inorganico",
        "k": "0",
        "c": "2",
        "code": "72.05.00.12"
    },
    {
        "id": 3842,
        "label": "Magnésio",
        "k": "0",
        "c": "6",
        "code": "72.05.00.13"
    },
    {
        "id": 3843,
        "label": "Magnésio (Absorqão Atómica)",
        "k": "0",
        "c": "40",
        "code": "72.05.00.14"
    },
    {
        "id": 3844,
        "label": "Magnésio Eritrocitário (Absorsão Atómica)",
        "k": "0",
        "c": "50",
        "code": "72.05.00.15"
    },
    {
        "id": 3845,
        "label": "Osmolaridade",
        "k": "0",
        "c": "10",
        "code": "72.05.00.16"
    },
    {
        "id": 3846,
        "label": "pH (Determinação do)",
        "k": "0",
        "c": "2",
        "code": "72.05.00.17"
    },
    {
        "id": 3847,
        "label": "Potássio",
        "k": "0",
        "c": "3",
        "code": "72.05.00.18"
    },
    {
        "id": 3848,
        "label": "Sódio",
        "k": "0",
        "c": "3",
        "code": "72.05.00.19"
    },
    {
        "id": 3849,
        "label": "Capacidade total de fixação do ferro",
        "k": "0",
        "c": "6",
        "code": "72.05.00.20"
    },
    {
        "id": 3850,
        "label": "Determinação indirecta dos cloretos no suor pela prova da placa",
        "k": "0",
        "c": "3",
        "code": "72.05.00.21"
    },
    {
        "id": 3851,
        "label": "Gases no sangue e pH",
        "k": "0",
        "c": "40",
        "code": "72.05.00.22"
    },
    {
        "id": 3852,
        "label": "Suor (Determinação dos cloretos ou sódio no), após estimulação por iontoforese com pilocarpina",
        "k": "1",
        "c": "20",
        "code": "72.05.00.23"
    },
    {
        "id": 3853,
        "label": "Alumínio (Absorção Atómica)",
        "k": "0",
        "c": "40",
        "code": "72.06.00.01"
    },
    {
        "id": 3854,
        "label": "Cobre (Absorção Atómica)",
        "k": "0",
        "c": "40",
        "code": "72.06.00.02"
    },
    {
        "id": 3855,
        "label": "Cobre (dos. Quimica)",
        "k": "0",
        "c": "6",
        "code": "72.06.00.03"
    },
    {
        "id": 3856,
        "label": "Fluor",
        "k": "0",
        "c": "12",
        "code": "72.06.00.04"
    },
    {
        "id": 3857,
        "label": "Lítio",
        "k": "0",
        "c": "6",
        "code": "72.06.00.05"
    },
    {
        "id": 3858,
        "label": "Zinco (Absorção Atómica)",
        "k": "0",
        "c": "40",
        "code": "72.06.00.06"
    },
    {
        "id": 3859,
        "label": "Zinco (Doseamento Químico)",
        "k": "0",
        "c": "8",
        "code": "72.06.00.07"
    },
    {
        "id": 3860,
        "label": "Ferro (Capacidade de fixação)",
        "k": "0",
        "c": "6",
        "code": "72.06.00.08"
    },
    {
        "id": 3861,
        "label": "Reserva Alcalina",
        "k": "0",
        "c": "5",
        "code": "72.06.00.09"
    },
    {
        "id": 3862,
        "label": "Ácido Ascórbico = Vitamina C (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.07.00.01"
    },
    {
        "id": 3863,
        "label": "Ácido Fólico",
        "k": "0",
        "c": "60",
        "code": "72.07.00.02"
    },
    {
        "id": 3864,
        "label": "Caroteno",
        "k": "0",
        "c": "8",
        "code": "72.07.00.03"
    },
    {
        "id": 3865,
        "label": "Vitamina A",
        "k": "0",
        "c": "8",
        "code": "72.07.00.04"
    },
    {
        "id": 3866,
        "label": "Vitamina B12",
        "k": "0",
        "c": "40",
        "code": "72.07.00.05"
    },
    {
        "id": 3867,
        "label": "Vitamina D",
        "k": "0",
        "c": "50",
        "code": "72.07.00.06"
    },
    {
        "id": 3868,
        "label": "Vitamina E",
        "k": "0",
        "c": "50",
        "code": "72.07.00.07"
    },
    {
        "id": 3869,
        "label": "Vitaminas do Complexo B (B1; B2; B6;Ac.nicotinico) cada",
        "k": "0",
        "c": "50",
        "code": "72.07.00.08"
    },
    {
        "id": 3870,
        "label": "Àcido Formiminoglutâmico = FIGLU",
        "k": "0",
        "c": "40",
        "code": "72.07.00.09"
    },
    {
        "id": 3871,
        "label": "Vitamina C (pesquisa de) = Ácido Ascórbico (pesquisa de)",
        "k": "0",
        "c": "2",
        "code": "72.07.00.10"
    },
    {
        "id": 3872,
        "label": "Vitamina C = Ácido Ascórbico (doseamento)",
        "k": "0",
        "c": "50",
        "code": "72.07.00.11"
    },
    {
        "id": 3873,
        "label": "Amikacina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.01"
    },
    {
        "id": 3874,
        "label": "Aminofilina = Teofilina",
        "k": "0",
        "c": "20",
        "code": "72.08.00.02"
    },
    {
        "id": 3875,
        "label": "Anfetamina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.03"
    },
    {
        "id": 3876,
        "label": "Antiepilépticos (cada)",
        "k": "0",
        "c": "40",
        "code": "72.08.00.04"
    },
    {
        "id": 3877,
        "label": "Antiparkinsónicos (cada)",
        "k": "0",
        "c": "40",
        "code": "72.08.00.05"
    },
    {
        "id": 3878,
        "label": "Arsénio (Pesquisa de...)",
        "k": "0",
        "c": "6",
        "code": "72.08.00.06"
    },
    {
        "id": 3879,
        "label": "Barbitúricos (Pesquisa de...)",
        "k": "0",
        "c": "4",
        "code": "72.08.00.07"
    },
    {
        "id": 3880,
        "label": "Benzodiazepinas (cada)",
        "k": "0",
        "c": "40",
        "code": "72.08.00.08"
    },
    {
        "id": 3881,
        "label": "Cádmio (Doseamento por Abs.Atómica)",
        "k": "0",
        "c": "40",
        "code": "72.08.00.09"
    },
    {
        "id": 3882,
        "label": "Canabinoides",
        "k": "0",
        "c": "40",
        "code": "72.08.00.10"
    },
    {
        "id": 3883,
        "label": "Carbamazepina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.11"
    },
    {
        "id": 3884,
        "label": "Chumbo (Abs. Atómica)",
        "k": "0",
        "c": "40",
        "code": "72.08.00.12"
    },
    {
        "id": 3885,
        "label": "Chumbo (Ex. químico)",
        "k": "0",
        "c": "8",
        "code": "72.08.00.13"
    },
    {
        "id": 3886,
        "label": "Ciclosporina",
        "k": "0",
        "c": "25",
        "code": "72.08.00.14"
    },
    {
        "id": 3887,
        "label": "Clonazepan",
        "k": "0",
        "c": "40",
        "code": "72.08.00.15"
    },
    {
        "id": 3888,
        "label": "Cocaína",
        "k": "0",
        "c": "40",
        "code": "72.08.00.16"
    },
    {
        "id": 3889,
        "label": "Crómio",
        "k": "0",
        "c": "20",
        "code": "72.08.00.17"
    },
    {
        "id": 3890,
        "label": "Difenil-Hidantoína = Fenintoína = Hidantina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.18"
    },
    {
        "id": 3891,
        "label": "Digoxina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.19"
    },
    {
        "id": 3892,
        "label": "Disopiramida",
        "k": "0",
        "c": "40",
        "code": "72.08.00.20"
    },
    {
        "id": 3893,
        "label": "Fenobarbital",
        "k": "0",
        "c": "40",
        "code": "72.08.00.21"
    },
    {
        "id": 3894,
        "label": "Gentamicina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.22"
    },
    {
        "id": 3895,
        "label": "Kanamicina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.23"
    },
    {
        "id": 3896,
        "label": "Lidocaína",
        "k": "0",
        "c": "40",
        "code": "72.08.00.24"
    },
    {
        "id": 3897,
        "label": "Mercúrio (Absorção Atómica)",
        "k": "0",
        "c": "40",
        "code": "72.08.00.25"
    },
    {
        "id": 3898,
        "label": "Metadona",
        "k": "0",
        "c": "40",
        "code": "72.08.00.26"
    },
    {
        "id": 3899,
        "label": "Metrotexato",
        "k": "0",
        "c": "40",
        "code": "72.08.00.27"
    },
    {
        "id": 3900,
        "label": "Morfina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.28"
    },
    {
        "id": 3901,
        "label": "Netilmicina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.29"
    },
    {
        "id": 3902,
        "label": "Primidona",
        "k": "0",
        "c": "40",
        "code": "72.08.00.30"
    },
    {
        "id": 3903,
        "label": "Procainamida",
        "k": "0",
        "c": "40",
        "code": "72.08.00.31"
    },
    {
        "id": 3904,
        "label": "Propanolol",
        "k": "0",
        "c": "40",
        "code": "72.08.00.32"
    },
    {
        "id": 3905,
        "label": "Quinidina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.33"
    },
    {
        "id": 3906,
        "label": "Selénio (Abs.Atómica)",
        "k": "0",
        "c": "40",
        "code": "72.08.00.34"
    },
    {
        "id": 3907,
        "label": "Tobramicina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.35"
    },
    {
        "id": 3908,
        "label": "Warfarina",
        "k": "0",
        "c": "40",
        "code": "72.08.00.36"
    },
    {
        "id": 3909,
        "label": "Drogas de abuso (pesquisa), cada",
        "k": "0",
        "c": "40",
        "code": "72.08.00.37"
    },
    {
        "id": 3910,
        "label": "Etosuccimida",
        "k": "0",
        "c": "40",
        "code": "72.08.00.38"
    },
    {
        "id": 3911,
        "label": "Fármacos (não descriminados na tabela), cada doseamento",
        "k": "0",
        "c": "40",
        "code": "72.08.00.39"
    },
    {
        "id": 3912,
        "label": "Mercúrio",
        "k": "0",
        "c": "8",
        "code": "72.08.00.40"
    },
    {
        "id": 3913,
        "label": "Opiáceos, cada",
        "k": "0",
        "c": "40",
        "code": "72.08.00.41"
    },
    {
        "id": 3914,
        "label": "Ácidos Biliares (Pesquisa)",
        "k": "0",
        "c": "2",
        "code": "72.09.00.01"
    },
    {
        "id": 3915,
        "label": "Ácidos Biliares conjugados e não conjugados na Bilis (Pesquisa e Identificação)",
        "k": "0",
        "c": "40",
        "code": "72.09.00.02"
    },
    {
        "id": 3916,
        "label": "Bilirrubina (Pesquisa de)",
        "k": "0",
        "c": "2",
        "code": "72.09.00.03"
    },
    {
        "id": 3917,
        "label": "Bilirrubina Total",
        "k": "0",
        "c": "3",
        "code": "72.09.00.04"
    },
    {
        "id": 3918,
        "label": "Bilirrubina Total + Directa e Indirecta",
        "k": "0",
        "c": "6",
        "code": "72.09.00.05"
    },
    {
        "id": 3919,
        "label": "Coproporfirinas (Doseamento)",
        "k": "0",
        "c": "15",
        "code": "72.09.00.06"
    },
    {
        "id": 3920,
        "label": "Coproporfirinas (Pesquisa de...)",
        "k": "0",
        "c": "4",
        "code": "72.09.00.07"
    },
    {
        "id": 3921,
        "label": "Hiperbilirrubinemia Neo-Natal (Bilirrubina total+directa+albumina) 1a. Determinação",
        "k": "0",
        "c": "80",
        "code": "72.09.00.08"
    },
    {
        "id": 3922,
        "label": "Hiperbilirrubinemia Neo-Natal (Bilirrubina total+directa+albumina) Determinações seguintes",
        "k": "0",
        "c": "30",
        "code": "72.09.00.09"
    },
    {
        "id": 3923,
        "label": "Porfirina eritrocitária Livre",
        "k": "0",
        "c": "30",
        "code": "72.09.00.10"
    },
    {
        "id": 3924,
        "label": "Porfirinas (Pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "72.09.00.11"
    },
    {
        "id": 3925,
        "label": "Porfirinas (Uro + Coproporfirinas)",
        "k": "0",
        "c": "30",
        "code": "72.09.00.12"
    },
    {
        "id": 3926,
        "label": "Porfobilinogénio (doseamento)",
        "k": "0",
        "c": "20",
        "code": "72.09.00.13"
    },
    {
        "id": 3927,
        "label": "Porfobilinogénio (pesquisa)",
        "k": "0",
        "c": "3",
        "code": "72.09.00.14"
    },
    {
        "id": 3928,
        "label": "Protoporfirinas",
        "k": "0",
        "c": "30",
        "code": "72.09.00.15"
    },
    {
        "id": 3929,
        "label": "Sais Biliares (Dos)",
        "k": "0",
        "c": "40",
        "code": "72.09.00.16"
    },
    {
        "id": 3930,
        "label": "Urobilina (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.09.00.17"
    },
    {
        "id": 3931,
        "label": "Urobilinogénio (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.09.00.18"
    },
    {
        "id": 3932,
        "label": "Uroporfirinas (doseamento)",
        "k": "0",
        "c": "15",
        "code": "72.09.00.19"
    },
    {
        "id": 3933,
        "label": "Uroporfirinas (Pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "72.09.00.20"
    },
    {
        "id": 3934,
        "label": "Àcido Delta-Aminolevulítico = ALA",
        "k": "0",
        "c": "20",
        "code": "72.09.00.21"
    },
    {
        "id": 3935,
        "label": "Pigmentos biliares (pesquisa de)",
        "k": "0",
        "c": "10",
        "code": "72.09.00.22"
    },
    {
        "id": 3936,
        "label": "Addis (Contagem ou Prova de...)",
        "k": "0",
        "c": "5",
        "code": "72.10.00.01"
    },
    {
        "id": 3937,
        "label": "Alcool Etílico",
        "k": "0",
        "c": "12",
        "code": "72.10.00.02"
    },
    {
        "id": 3938,
        "label": "Amido (Prova de Tolerância ao...) – não inclui produtos administrados",
        "k": "0",
        "c": "30",
        "code": "72.10.00.03"
    },
    {
        "id": 3939,
        "label": "Cálculo urinário (Ex. químico Qualitativo) cada",
        "k": "0",
        "c": "8",
        "code": "72.10.00.04"
    },
    {
        "id": 3940,
        "label": "Cálculo urinário (Ex. Espectográfico)",
        "k": "0",
        "c": "40",
        "code": "72.10.00.05"
    },
    {
        "id": 3941,
        "label": "Concentração Urinária (Prova de...)",
        "k": "0",
        "c": "5",
        "code": "72.10.00.06"
    },
    {
        "id": 3942,
        "label": "Diluição Urinária (Prova de...)",
        "k": "0",
        "c": "5",
        "code": "72.10.00.07"
    },
    {
        "id": 3943,
        "label": "Gonadotrofinas Coriónicas (=HCG)",
        "k": "0",
        "c": "20",
        "code": "72.10.00.08"
    },
    {
        "id": 3944,
        "label": "Grau de Digestão dos Alimentos, nas Fezes",
        "k": "0",
        "c": "5",
        "code": "72.10.00.09"
    },
    {
        "id": 3945,
        "label": "Gravidez (Diagnóstico Imunológico da...)=D.I.G.=T.I.G",
        "k": "0",
        "c": "5",
        "code": "72.10.00.10"
    },
    {
        "id": 3946,
        "label": "Hidroxiprolina",
        "k": "0",
        "c": "40",
        "code": "72.10.00.11"
    },
    {
        "id": 3947,
        "label": "Oxalatos Urinários (Det.Enzimática)",
        "k": "0",
        "c": "30",
        "code": "72.10.00.12"
    },
    {
        "id": 3948,
        "label": "Prova da Estimulação pela Secretina",
        "k": "0",
        "c": "61",
        "code": "72.10.00.13"
    },
    {
        "id": 3949,
        "label": "Prova da Xilose",
        "k": "0",
        "c": "20",
        "code": "72.10.00.14"
    },
    {
        "id": 3950,
        "label": "Prova de Estimulação pela Pancreozimina",
        "k": "0",
        "c": "61",
        "code": "72.10.00.15"
    },
    {
        "id": 3951,
        "label": "Sangue Oculto (Pesquisa de...)",
        "k": "0",
        "c": "2",
        "code": "72.10.00.16"
    },
    {
        "id": 3952,
        "label": "Sedimento Urinário",
        "k": "0",
        "c": "2",
        "code": "72.10.00.17"
    },
    {
        "id": 3953,
        "label": "Substâncias Metacromáticas na Urina (Pesquisa de...)",
        "k": "0",
        "c": "20",
        "code": "72.10.00.18"
    },
    {
        "id": 3954,
        "label": "Análise sumária da urina (Urina II)",
        "k": "0",
        "c": "3",
        "code": "72.10.00.19"
    },
    {
        "id": 3955,
        "label": "Osteocalcina",
        "k": "0",
        "c": "60",
        "code": "72.10.00.20"
    },
    {
        "id": 3956,
        "label": "VIP - Vasoactive peptide intestinal",
        "k": "0",
        "c": "60",
        "code": "72.10.00.21"
    },
    {
        "id": 3957,
        "label": "Cloraminas",
        "k": "0",
        "c": "20",
        "code": "72.10.00.22"
    },
    {
        "id": 3958,
        "label": "Contagem minutada da urina",
        "k": "0",
        "c": "5",
        "code": "72.10.00.23"
    },
    {
        "id": 3959,
        "label": "Cristais (pesquisa de)",
        "k": "0",
        "c": "15",
        "code": "72.10.00.24"
    },
    {
        "id": 3960,
        "label": "Densidade de líquidos biológicos",
        "k": "0",
        "c": "3",
        "code": "72.10.00.25"
    },
    {
        "id": 3961,
        "label": "Prova de estimulação do suco gástrico pela Pentagastrina",
        "k": "0",
        "c": "55",
        "code": "72.10.00.26"
    },
    {
        "id": 3962,
        "label": "Prova de estimulação do suco gástrico pelo Histalog",
        "k": "0",
        "c": "55",
        "code": "72.10.00.27"
    },
    {
        "id": 3963,
        "label": "Secretina e Pancreozimina (Prova de estimulação pela) S/incluir produtos administrados ou utilização do RX",
        "k": "0",
        "c": "90",
        "code": "72.10.00.28"
    },
    {
        "id": 3964,
        "label": "Urina (Contagem minutada)",
        "k": "0",
        "c": "5",
        "code": "72.10.00.29"
    },
    {
        "id": 3965,
        "label": "Xilose (Prova da)",
        "k": "0",
        "c": "20",
        "code": "72.10.00.30"
    },
    {
        "id": 3966,
        "label": "ACTH (cada doseamento)",
        "k": "0",
        "c": "35",
        "code": "73.01.01.02"
    },
    {
        "id": 3967,
        "label": "F.S.H.=Hormona Foliculo-Estimulante",
        "k": "0",
        "c": "25",
        "code": "73.01.01.03"
    },
    {
        "id": 3968,
        "label": "Hormona do Crescimento = GH=STH= Somatotrofina",
        "k": "0",
        "c": "30",
        "code": "73.01.01.04"
    },
    {
        "id": 3969,
        "label": "Hormona do Crescimento = STH = GH- Ver Cód. 73.01.01.04",
        "k": "0",
        "c": "0",
        "code": "73.01.01.05"
    },
    {
        "id": 3970,
        "label": "Hormopa Folículo-Estimulante = FSH - Ver Cód.73.01.01.03",
        "k": "0",
        "c": "0",
        "code": "73.01.01.06"
    },
    {
        "id": 3971,
        "label": "Hormona Lactogénica Placentária = HPL",
        "k": "0",
        "c": "40",
        "code": "73.01.01.07"
    },
    {
        "id": 3972,
        "label": "Hormona Anti-Diurética = ADH =Vasopressina",
        "k": "0",
        "c": "60",
        "code": "73.01.01.08"
    },
    {
        "id": 3973,
        "label": "Hormona Luteo-Estimulante = LH",
        "k": "0",
        "c": "25",
        "code": "73.01.01.09"
    },
    {
        "id": 3974,
        "label": "Hormona Tireo-Estimulante = TSH",
        "k": "0",
        "c": "25",
        "code": "73.01.01.10"
    },
    {
        "id": 3975,
        "label": "HPL = Hormona Lactogénica Placentária- Ver Cód. 73.01.01.07",
        "k": "0",
        "c": "0",
        "code": "73.01.01.11"
    },
    {
        "id": 3976,
        "label": "LH = Hormona Luteo-Estimulante- Ver Cód. 73.01.01.10",
        "k": "0",
        "c": "0",
        "code": "73.01.01.12"
    },
    {
        "id": 3977,
        "label": "Progesterona = Prog = PRG",
        "k": "0",
        "c": "25",
        "code": "73.01.01.13"
    },
    {
        "id": 3978,
        "label": "Prolactina = PRL",
        "k": "0",
        "c": "25",
        "code": "73.01.01.14"
    },
    {
        "id": 3979,
        "label": "Somatomedina C",
        "k": "0",
        "c": "60",
        "code": "73.01.01.15"
    },
    {
        "id": 3980,
        "label": "Somototrofina = hGH = STH = GH = Hormona de Crescimento- Ver Cód. 73.01.01.04",
        "k": "0",
        "c": "0",
        "code": "73.01.01.16"
    },
    {
        "id": 3981,
        "label": "STH = Somatotrofina = hGH = GH = Hormona de Crescimento- Ver Cód. 73.01.01.04",
        "k": "0",
        "c": "0",
        "code": "73.01.01.17"
    },
    {
        "id": 3982,
        "label": "TSH = Hormona Tireo-Estimulante- Ver Cód. 73.01.01.10",
        "k": "0",
        "c": "0",
        "code": "73.01.01.18"
    },
    {
        "id": 3983,
        "label": "Vasopressina = ADH = Hormona Anti-Diurética- Ver Cód. 73.01.01.08",
        "k": "0",
        "c": "0",
        "code": "73.01.01.19"
    },
    {
        "id": 3984,
        "label": "Estudo de alterações endocrinológicas - (exames executados+valor da consulta) Ver Cód. 01.00.00.03 ou 01.00.00.04",
        "k": "0",
        "c": "0",
        "code": "73.01.01.20"
    },
    {
        "id": 3985,
        "label": "Calcitonina",
        "k": "0",
        "c": "75",
        "code": "73.01.02.01"
    },
    {
        "id": 3986,
        "label": "T3",
        "k": "0",
        "c": "18",
        "code": "73.01.02.02"
    },
    {
        "id": 3987,
        "label": "T3 Livre",
        "k": "0",
        "c": "18",
        "code": "73.01.02.03"
    },
    {
        "id": 3988,
        "label": "T3 Reverse",
        "k": "0",
        "c": "75",
        "code": "73.01.02.04"
    },
    {
        "id": 3989,
        "label": "T3 Uptake = Fixação do T3",
        "k": "0",
        "c": "15",
        "code": "73.01.02.05"
    },
    {
        "id": 3990,
        "label": "T4",
        "k": "0",
        "c": "18",
        "code": "73.01.02.06"
    },
    {
        "id": 3991,
        "label": "T4 Livre",
        "k": "0",
        "c": "18",
        "code": "73.01.02.07"
    },
    {
        "id": 3992,
        "label": "TBG = Globulina Ligada à Tiroxina",
        "k": "0",
        "c": "25",
        "code": "73.01.02.08"
    },
    {
        "id": 3993,
        "label": "Tiroglobulina",
        "k": "0",
        "c": "75",
        "code": "73.01.02.09"
    },
    {
        "id": 3994,
        "label": "Uptake da T3 = Fixação do T3 Ver Cód.73.01.02.05",
        "k": "0",
        "c": "0",
        "code": "73.01.02.10"
    },
    {
        "id": 3995,
        "label": "AMP Cíclico",
        "k": "0",
        "c": "100",
        "code": "73.01.03.01"
    },
    {
        "id": 3996,
        "label": "Parathormona = PTH",
        "k": "0",
        "c": "60",
        "code": "73.01.03.02"
    },
    {
        "id": 3997,
        "label": "17-Alfa-Hidroxiprogesterona",
        "k": "0",
        "c": "40",
        "code": "73.01.03.04"
    },
    {
        "id": 3998,
        "label": "17-Beta-estradiol",
        "k": "0",
        "c": "30",
        "code": "73.01.03.05"
    },
    {
        "id": 3999,
        "label": "Beta-HCG = Unidade Beta da Gonadotrofina Coriónica",
        "k": "0",
        "c": "50",
        "code": "73.01.03.06"
    },
    {
        "id": 4000,
        "label": "Estradiol",
        "k": "0",
        "c": "30",
        "code": "73.01.03.07"
    },
    {
        "id": 4001,
        "label": "Estriol Plasmático",
        "k": "0",
        "c": "30",
        "code": "73.01.03.08"
    },
    {
        "id": 4002,
        "label": "Estrogénios Totais",
        "k": "0",
        "c": "20",
        "code": "73.01.03.09"
    },
    {
        "id": 4003,
        "label": "Estrogénios Fraccionados na Urina",
        "k": "0",
        "c": "90",
        "code": "73.01.03.10"
    },
    {
        "id": 4004,
        "label": "Estrona",
        "k": "0",
        "c": "30",
        "code": "73.01.03.11"
    },
    {
        "id": 4005,
        "label": "Receptores Celulares de Estrogéneos",
        "k": "0",
        "c": "165",
        "code": "73.01.03.12"
    },
    {
        "id": 4006,
        "label": "Receptores Celulares de Progesterona",
        "k": "0",
        "c": "165",
        "code": "73.01.03.13"
    },
    {
        "id": 4007,
        "label": "S.H.B.G. - Globulina ligada às Hormonas Sexuais",
        "k": "0",
        "c": "60",
        "code": "73.01.03.14"
    },
    {
        "id": 4008,
        "label": "Testoterona (T)",
        "k": "0",
        "c": "25",
        "code": "73.01.03.15"
    },
    {
        "id": 4009,
        "label": "Testoterona Livre",
        "k": "0",
        "c": "30",
        "code": "73.01.03.16"
    },
    {
        "id": 4010,
        "label": "17-Cetosteroides Fraccionados",
        "k": "0",
        "c": "60",
        "code": "73.01.04.01"
    },
    {
        "id": 4011,
        "label": "17-Cetosteroides Totais = 17-Ks",
        "k": "0",
        "c": "12",
        "code": "73.01.04.02"
    },
    {
        "id": 4012,
        "label": "Ácido Homovanílico = HVA",
        "k": "0",
        "c": "20",
        "code": "73.01.04.03"
    },
    {
        "id": 4013,
        "label": "Ácido Vanililmandélico = VMA",
        "k": "0",
        "c": "20",
        "code": "73.01.04.04"
    },
    {
        "id": 4014,
        "label": "Aldosterona",
        "k": "0",
        "c": "40",
        "code": "73.01.04.05"
    },
    {
        "id": 4015,
        "label": "Angiotensina",
        "k": "0",
        "c": "100",
        "code": "73.01.04.06"
    },
    {
        "id": 4016,
        "label": "Catecolaminas Fraccionadas (Adrenalina e Nor-Adrenalina) cada",
        "k": "0",
        "c": "30",
        "code": "73.01.04.07"
    },
    {
        "id": 4017,
        "label": "Catecolaminas Fraccionadas (Adrenalina e Nor Adrenalina+Dopamina)",
        "k": "0",
        "c": "100",
        "code": "73.01.04.08"
    },
    {
        "id": 4018,
        "label": "Catecolaminas Totais",
        "k": "0",
        "c": "30",
        "code": "73.01.04.09"
    },
    {
        "id": 4019,
        "label": "Composto S = Desoxicortisol",
        "k": "0",
        "c": "30",
        "code": "73.01.04.10"
    },
    {
        "id": 4020,
        "label": "Cortisol = Hidrocortisona = Composto F",
        "k": "0",
        "c": "20",
        "code": "73.01.04.11"
    },
    {
        "id": 4021,
        "label": "Dehidroepiandrosterona = DHEA urinária",
        "k": "0",
        "c": "14",
        "code": "73.01.04.12"
    },
    {
        "id": 4022,
        "label": "Dehidroepiandrosterona Sulfato = DHEA-S04",
        "k": "0",
        "c": "40",
        "code": "73.01.04.13"
    },
    {
        "id": 4023,
        "label": "Delta-4-Androstenodiona=Delta-4-A",
        "k": "0",
        "c": "40",
        "code": "73.01.04.14"
    },
    {
        "id": 4024,
        "label": "Desoxicortisol = Composto S- Ver Cód. 73.01.04.10",
        "k": "0",
        "c": "0",
        "code": "73.01.04.15"
    },
    {
        "id": 4025,
        "label": "Epinefrina",
        "k": "0",
        "c": "30",
        "code": "73.01.04.16"
    },
    {
        "id": 4026,
        "label": "HVA = ácido Homovanilico- Ver Cód. 73.01.04.03",
        "k": "0",
        "c": "0",
        "code": "73.01.04.17"
    },
    {
        "id": 4027,
        "label": "Metanefrinas totais",
        "k": "0",
        "c": "30",
        "code": "73.01.04.18"
    },
    {
        "id": 4028,
        "label": "Metanefrinas totais (Metanefrina+Nor-Metanefrinas) por HPLC",
        "k": "0",
        "c": "100",
        "code": "73.01.04.19"
    },
    {
        "id": 4029,
        "label": "Pregnanetriol (triol)",
        "k": "0",
        "c": "18",
        "code": "73.01.04.20"
    },
    {
        "id": 4030,
        "label": "VMA = Ácido Vanililmandélico- Ver Cód. 73.01.04.04",
        "k": "0",
        "c": "0",
        "code": "73.01.04.21"
    },
    {
        "id": 4031,
        "label": "Glucagon = Glucagina",
        "k": "0",
        "c": "40",
        "code": "73.01.05.01"
    },
    {
        "id": 4032,
        "label": "Insulina (cada doseamento)",
        "k": "0",
        "c": "20",
        "code": "73.01.05.02"
    },
    {
        "id": 4033,
        "label": "Peptideo C",
        "k": "0",
        "c": "35",
        "code": "73.01.05.03"
    },
    {
        "id": 4034,
        "label": "Ácido 5-Hidroxi-Indolacético = 5HIAA",
        "k": "0",
        "c": "20",
        "code": "73.01.05.05"
    },
    {
        "id": 4035,
        "label": "Ácido 5-Hidroxi-Indolacético = 5-HIAA (Pesquisa de ...)",
        "k": "0",
        "c": "6",
        "code": "73.01.05.06"
    },
    {
        "id": 4036,
        "label": "Colecístoquinina",
        "k": "0",
        "c": "40",
        "code": "73.01.05.07"
    },
    {
        "id": 4037,
        "label": "Gastrina",
        "k": "0",
        "c": "50",
        "code": "73.01.05.08"
    },
    {
        "id": 4038,
        "label": "5-HIAA = Ácido 5-Hidroxi-Indolacético- Ver Cód. 73.01.05.05",
        "k": "0",
        "c": "0",
        "code": "73.01.05.09"
    },
    {
        "id": 4039,
        "label": "5-HIAA = Ácido 5-Hidroxi-Indolacético (Pesquisa de...)- Ver Cód. 73.01.05.06",
        "k": "0",
        "c": "0",
        "code": "73.01.05.10"
    },
    {
        "id": 4040,
        "label": "Secretina",
        "k": "0",
        "c": "40",
        "code": "73.01.05.11"
    },
    {
        "id": 4041,
        "label": "Serotonina",
        "k": "0",
        "c": "20",
        "code": "73.01.05.12"
    },
    {
        "id": 4042,
        "label": "Eritropoietina",
        "k": "0",
        "c": "60",
        "code": "73.01.06.01"
    },
    {
        "id": 4043,
        "label": "Renina (Actividade Plasmática da...), cada",
        "k": "0",
        "c": "30",
        "code": "73.01.06.02"
    },
    {
        "id": 4044,
        "label": "Beta-Endorfina",
        "k": "0",
        "c": "40",
        "code": "73.01.07.01"
    },
    {
        "id": 4045,
        "label": "Prova da Clonidina com Doseamentos Hormonais",
        "k": "100",
        "c": "0",
        "code": "73.02.01.01"
    },
    {
        "id": 4046,
        "label": "Prova da L-Dopa com ou sem Propanolol c/doseamento STH (cada doseamento)",
        "k": "0",
        "c": "30",
        "code": "73.02.01.02"
    },
    {
        "id": 4047,
        "label": "Prova de Clomifene Alargada (doseamentos de L.H.,FSH,Estradiol, Testosterona cada doseamento)",
        "k": "3",
        "c": "30",
        "code": "73.02.01.03"
    },
    {
        "id": 4048,
        "label": "Prova de Clomifene com 2 doseamentos de H.L., 2 de FSH, 2 de Estradiol, 2 de Testosterona",
        "k": "3",
        "c": "210",
        "code": "73.02.01.04"
    },
    {
        "id": 4049,
        "label": "Prova de Estim.da STH pelo Exercício, cada determ.de STH",
        "k": "3",
        "c": "30",
        "code": "73.02.01.05"
    },
    {
        "id": 4050,
        "label": "Prova.de Estimul.c/L.R.H. com 3 doseamentos de L.H. e 3 de FSH, cada",
        "k": "3",
        "c": "25",
        "code": "73.02.01.06"
    },
    {
        "id": 4051,
        "label": "Prova de Estimul.c/T.R.H. com doseamentos de TSH, cada",
        "k": "3",
        "c": "25",
        "code": "73.02.01.07"
    },
    {
        "id": 4052,
        "label": "Prova de estim. múltipla p/ trh, lrh e hipoglicémia (7/glicémia, 6/sth, 5/cortisol, 4/prl, 4/fsh, 4/l, 5/acth)",
        "k": "8",
        "c": "830",
        "code": "73.02.01.08"
    },
    {
        "id": 4053,
        "label": "Prova de estimulação múltipla alarg. pelo trh, lrh e hipoglic. c/ dos. prl, tsh, fsh, lh, acth, cortisol cada",
        "k": "8",
        "c": "30",
        "code": "73.02.01.09"
    },
    {
        "id": 4054,
        "label": "Prova de Glucagon com doseamentos de STH-cada doseamento",
        "k": "3",
        "c": "30",
        "code": "73.02.01.10"
    },
    {
        "id": 4055,
        "label": "Prova de Hipoglicémia Insulinica (I.V.) com doseamentos hormonais, cada determinação",
        "k": "8",
        "c": "30",
        "code": "73.02.01.11"
    },
    {
        "id": 4056,
        "label": "Prova de Inibiçâo da STH após sobrecarga Glúcidica, cada dos. De STH",
        "k": "3",
        "c": "30",
        "code": "73.02.01.12"
    },
    {
        "id": 4057,
        "label": "Prova da Metirapona c/2 dos.Comp. S/17 Cetosteroides, (cada)",
        "k": "3",
        "c": "30",
        "code": "73.02.02.01"
    },
    {
        "id": 4058,
        "label": "Prova de Estimulação com ACTH, com doseamentos de Cortisol (cada)",
        "k": "4",
        "c": "20",
        "code": "73.02.02.02"
    },
    {
        "id": 4059,
        "label": "Prova da Gonadotrofina Corionica com doseamentos de Testosterona e Estradiol, cada doseamento",
        "k": "0",
        "c": "30",
        "code": "73.02.03.01"
    },
    {
        "id": 4060,
        "label": "Prova de Hiperglicémia provocada com doseamentos de insulina simultâneos, cada",
        "k": "3",
        "c": "18",
        "code": "73.02.04.01"
    },
    {
        "id": 4061,
        "label": "Anaeróbios (Pesquisa e identificação de)",
        "k": "0",
        "c": "20",
        "code": "74.01.00.01"
    },
    {
        "id": 4062,
        "label": "Antibiograma = TSA",
        "k": "0",
        "c": "16",
        "code": "74.01.00.02"
    },
    {
        "id": 4063,
        "label": "Antibiograma para Bacilos ácido-Resistentes (cada Tuberculostático)",
        "k": "0",
        "c": "16",
        "code": "74.01.00.03"
    },
    {
        "id": 4064,
        "label": "Antibióticos (Determinação da Concentração Inibitória Minima, cada)",
        "k": "0",
        "c": "12",
        "code": "74.01.00.04"
    },
    {
        "id": 4065,
        "label": "Autovacina",
        "k": "0",
        "c": "0",
        "code": "74.01.00.05"
    },
    {
        "id": 4066,
        "label": "B.K. (Exame Directo com e sem Homogeneização para Pesquisa de...)",
        "k": "0",
        "c": "6",
        "code": "74.01.00.06"
    },
    {
        "id": 4067,
        "label": "B.K. (Exame Directo e Cultural)",
        "k": "0",
        "c": "12",
        "code": "74.01.00.07"
    },
    {
        "id": 4068,
        "label": "Bacilo Diftérico = Bacilo Loeffler, inclui exame cultural",
        "k": "0",
        "c": "20",
        "code": "74.01.00.08"
    },
    {
        "id": 4069,
        "label": "Bacilos de Hansen (Pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "74.01.00.09"
    },
    {
        "id": 4070,
        "label": "Bacteriológico (c/Identificação) + Micológico e Parasitológico",
        "k": "0",
        "c": "15",
        "code": "74.01.00.10"
    },
    {
        "id": 4071,
        "label": "Bacteriológico cult.em Aerobiose, com estudo paralelo em Anaerobiose",
        "k": "0",
        "c": "30",
        "code": "74.01.00.11"
    },
    {
        "id": 4072,
        "label": "Bacteriológico Directo (Coloração pelo Gram)",
        "k": "0",
        "c": "2",
        "code": "74.01.00.12"
    },
    {
        "id": 4073,
        "label": "Bacteriológico directo e Cultural c/Identificação",
        "k": "0",
        "c": "12",
        "code": "74.01.00.13"
    },
    {
        "id": 4074,
        "label": "Bactérias (Imunofluorescência para identificação de...)",
        "k": "0",
        "c": "25",
        "code": "74.01.00.14"
    },
    {
        "id": 4075,
        "label": "Bordetela pertussis (Exame cultural e identificação)",
        "k": "0",
        "c": "15",
        "code": "74.01.00.15"
    },
    {
        "id": 4076,
        "label": "Brucella (hemocultura p/)",
        "k": "0",
        "c": "20",
        "code": "74.01.00.16"
    },
    {
        "id": 4077,
        "label": "Chlamydia trachomatis (Pesq.)",
        "k": "0",
        "c": "42",
        "code": "74.01.00.18"
    },
    {
        "id": 4078,
        "label": "Chlamydia trachomatis (Pesquisa em cultura de células da...)",
        "k": "0",
        "c": "70",
        "code": "74.01.00.19"
    },
    {
        "id": 4079,
        "label": "Citobacteriologico (Ex. Directo e Cultura)",
        "k": "0",
        "c": "17",
        "code": "74.01.00.20"
    },
    {
        "id": 4080,
        "label": "Citobacteriologico de urina c/ contagem de colónias",
        "k": "0",
        "c": "15",
        "code": "74.01.00.21"
    },
    {
        "id": 4081,
        "label": "Coprocultura (incl.Pesq.de Salmonella, Shigella e Staphylococcus)",
        "k": "0",
        "c": "20",
        "code": "74.01.00.22"
    },
    {
        "id": 4082,
        "label": "Corynebacterium diphteriae (Pesquisa com Exame Cultural de...) Ver Cód.74.01.00.08",
        "k": "0",
        "c": "0",
        "code": "74.01.00.23"
    },
    {
        "id": 4083,
        "label": "Eosinófilos (pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "74.01.00.24"
    },
    {
        "id": 4084,
        "label": "Escherichia coli enteropatogénica (Exame Cultural e Identificação Serológica)",
        "k": "0",
        "c": "40",
        "code": "74.01.00.25"
    },
    {
        "id": 4085,
        "label": "Espermocultura",
        "k": "0",
        "c": "12",
        "code": "74.01.00.26"
    },
    {
        "id": 4086,
        "label": "Estreptococos (Identificação Imunológica dos...)",
        "k": "0",
        "c": "20",
        "code": "74.01.00.27"
    },
    {
        "id": 4087,
        "label": "Estreptococos Beta-hemolíticos (Pesquisa do Grupo A)",
        "k": "0",
        "c": "6",
        "code": "74.01.00.28"
    },
    {
        "id": 4088,
        "label": "Exame Bacteriológico de Fezes (incl.Pesq. de Salmonella,Shigella e Staphylococcus) Ver Cód.74.01.00.22",
        "k": "0",
        "c": "0",
        "code": "74.01.00.29"
    },
    {
        "id": 4089,
        "label": "Hansen (Pesquisa de Bacilos de...) - ver cód. 74.01.00.09",
        "k": "0",
        "c": "0",
        "code": "74.01.00.30"
    },
    {
        "id": 4090,
        "label": "Helicobacter (Exame cultural e Identificação)",
        "k": "0",
        "c": "40",
        "code": "74.01.00.31"
    },
    {
        "id": 4091,
        "label": "Hemocultura (inclui estudo em anaerobiose e respectivas subculturas)",
        "k": "0",
        "c": "35",
        "code": "74.01.00.32"
    },
    {
        "id": 4092,
        "label": "Hemocultura (incluindo 3 subculturas)",
        "k": "0",
        "c": "30",
        "code": "74.01.00.33"
    },
    {
        "id": 4093,
        "label": "Inoculação no cobaio",
        "k": "0",
        "c": "20",
        "code": "74.01.00.34"
    },
    {
        "id": 4094,
        "label": "Legionella sp-Pesq. e identif. (Cult.e Serologia por Imunofluorescência)",
        "k": "0",
        "c": "100",
        "code": "74.01.00.35"
    },
    {
        "id": 4095,
        "label": "Listeria (exame cultural e identificação)",
        "k": "0",
        "c": "40",
        "code": "74.01.00.36"
    },
    {
        "id": 4096,
        "label": "Mielocultura (sem colheita)",
        "k": "0",
        "c": "40",
        "code": "74.01.00.37"
    },
    {
        "id": 4097,
        "label": "Mycobacterium leprae (Pesquisa de...) - ver cód. 74.01.00.09",
        "k": "0",
        "c": "0",
        "code": "74.01.00.38"
    },
    {
        "id": 4098,
        "label": "Mycobacterium tuberculosis (Exame Directo com e sem Homogenização) Ver Cód. 74.01.00.06",
        "k": "0",
        "c": "0",
        "code": "74.01.00.39"
    },
    {
        "id": 4099,
        "label": "Mycobacterium tuberculosis (ExameDirecto e Cultural)- Ver Cód. 74.01.00.07",
        "k": "0",
        "c": "0",
        "code": "74.01.00.40"
    },
    {
        "id": 4100,
        "label": "Mycoplasma urealyticum (Exame Cultural)",
        "k": "0",
        "c": "40",
        "code": "74.01.00.41"
    },
    {
        "id": 4101,
        "label": "Neisseria gonorrhoae (exame directo e cultural)",
        "k": "0",
        "c": "20",
        "code": "74.01.00.42"
    },
    {
        "id": 4102,
        "label": "Neisseria meningitidis (exame directo e cultural)",
        "k": "0",
        "c": "20",
        "code": "74.01.00.43"
    },
    {
        "id": 4103,
        "label": "PCR (Polymerase chain Reaction) para pesquisa e identificação de bacteria",
        "k": "0",
        "c": "230",
        "code": "74.01.00.44"
    },
    {
        "id": 4104,
        "label": "Pesquisa Chlamydia Trachomatis por IF. Ver Cód.74.01.00.18",
        "k": "0",
        "c": "0",
        "code": "74.01.00.45"
    },
    {
        "id": 4105,
        "label": "Salmonella e Shigella (Exame Cultural e Identificação c/serotipagem)",
        "k": "0",
        "c": "40",
        "code": "74.01.00.46"
    },
    {
        "id": 4106,
        "label": "Staphylococcus (Exame Cultural e identificação da espécie)",
        "k": "0",
        "c": "30",
        "code": "74.01.00.47"
    },
    {
        "id": 4107,
        "label": "Streptococcus beta haemoliticcus (Exame Cultural e Identificação serológica)",
        "k": "0",
        "c": "30",
        "code": "74.01.00.48"
    },
    {
        "id": 4108,
        "label": "Teste de Sensibilidade aos Quimioterápios p’ Bacilos ácido-resistentes - Ver Cód.74.01.00.03",
        "k": "0",
        "c": "0",
        "code": "74.01.00.49"
    },
    {
        "id": 4109,
        "label": "Treponema (Pesquisa microscópica em fundo escuro do...)",
        "k": "0",
        "c": "6",
        "code": "74.01.00.50"
    },
    {
        "id": 4110,
        "label": "T.S.A. = Antibiograma- Ver Cód. 74.01.00.02",
        "k": "0",
        "c": "0",
        "code": "74.01.00.51"
    },
    {
        "id": 4111,
        "label": "Ureaplasma urealyticum (Exame Cultural)- Ver Cód. 74.01.00.41",
        "k": "0",
        "c": "0",
        "code": "74.01.00.52"
    },
    {
        "id": 4112,
        "label": "Vibrio cholerae (Exame Cultural e Identificação)",
        "k": "0",
        "c": "50",
        "code": "74.01.00.53"
    },
    {
        "id": 4113,
        "label": "Yersinia (Exame Cultural e Identificação)",
        "k": "0",
        "c": "40",
        "code": "74.01.00.54"
    },
    {
        "id": 4114,
        "label": "Estudo de sindrome febril indeterminado - (exames executados+valor da consulta) Ver Cód. 01.00.00.03 ou 01.00.00.04",
        "k": "0",
        "c": "0",
        "code": "74.01.00.55"
    },
    {
        "id": 4115,
        "label": "Exame micológico directo",
        "k": "0",
        "c": "3",
        "code": "74.02.00.01"
    },
    {
        "id": 4116,
        "label": "Exame micológico (Directo, cultura e identificação)",
        "k": "0",
        "c": "30",
        "code": "74.02.00.02"
    },
    {
        "id": 4117,
        "label": "Filaria (Pesquisa de...)",
        "k": "0",
        "c": "15",
        "code": "74.03.00.01"
    },
    {
        "id": 4118,
        "label": "Giardia lamblia (pesquisa no liquido de lavagem duodenal)-sem colheita",
        "k": "0",
        "c": "5",
        "code": "74.03.00.02"
    },
    {
        "id": 4119,
        "label": "Leishmania (Pesquisa de...)",
        "k": "0",
        "c": "15",
        "code": "74.03.00.03"
    },
    {
        "id": 4120,
        "label": "Parasitológico (Exame...) com e sem Enriquecimento",
        "k": "0",
        "c": "10",
        "code": "74.03.00.04"
    },
    {
        "id": 4121,
        "label": "Parasitológico (Exame...) por I.F.p’ sua identificação, cada",
        "k": "0",
        "c": "30",
        "code": "74.03.00.05"
    },
    {
        "id": 4122,
        "label": "Pesquisa de Ovos, Quistos e Parasitas nas Fezes (cada amostra)",
        "k": "0",
        "c": "6",
        "code": "74.03.00.06"
    },
    {
        "id": 4123,
        "label": "Plasmódio (pesquisa e Identificação de...)",
        "k": "0",
        "c": "15",
        "code": "74.03.00.07"
    },
    {
        "id": 4124,
        "label": "Toxoplasma (Pesquisa de...)",
        "k": "0",
        "c": "15",
        "code": "74.03.00.08"
    },
    {
        "id": 4125,
        "label": "Trypanossoma (Pesquisa de...)",
        "k": "0",
        "c": "15",
        "code": "74.03.00.09"
    },
    {
        "id": 4126,
        "label": "Rotavirus (Determinação",
        "k": "0",
        "c": "50",
        "code": "74.04.00.01"
    },
    {
        "id": 4127,
        "label": "Cultura de vírus não orientada e identificação",
        "k": "0",
        "c": "150",
        "code": "74.04.00.02"
    },
    {
        "id": 4128,
        "label": "Cultura de vírus orientada e identificação",
        "k": "0",
        "c": "100",
        "code": "74.04.00.03"
    },
    {
        "id": 4129,
        "label": "Rotavirus (Pesquisa por Hemaglutinação...)",
        "k": "0",
        "c": "25",
        "code": "74.04.00.04"
    },
    {
        "id": 4130,
        "label": "Vírus (Colheita,isolamento e identificação em cult.cel.de...)",
        "k": "0",
        "c": "84",
        "code": "74.04.00.05"
    },
    {
        "id": 4131,
        "label": "Pesquisa de vírus por técnica de aglutinação",
        "k": "0",
        "c": "10",
        "code": "74.04.00.06"
    },
    {
        "id": 4132,
        "label": "Vírus (Identificaqão por I.F. ou ELISA...), cada",
        "k": "0",
        "c": "34",
        "code": "74.04.00.07"
    },
    {
        "id": 4133,
        "label": "Pesquisa de vírus por técnica de imunofluorescência",
        "k": "0",
        "c": "20",
        "code": "74.04.00.08"
    },
    {
        "id": 4134,
        "label": "Vírus Responsáveis por Inf.respiratórias (Pesq.por I.F.ou ELISA), cada",
        "k": "0",
        "c": "84",
        "code": "74.04.00.09"
    },
    {
        "id": 4135,
        "label": "Pesquisa de vírus por técnica de E.I.A.",
        "k": "0",
        "c": "30",
        "code": "74.04.00.10"
    },
    {
        "id": 4136,
        "label": "Pesquisa de vírus por microscopia electrónica",
        "k": "0",
        "c": "100",
        "code": "74.04.00.11"
    },
    {
        "id": 4137,
        "label": "Vírus Sincicial (Pesquisa por I.F. ou ELISA do ...)",
        "k": "0",
        "c": "84",
        "code": "74.04.00.12"
    },
    {
        "id": 4138,
        "label": "Pesquisa de vírus por técnica de PCR",
        "k": "0",
        "c": "230",
        "code": "74.04.00.13"
    },
    {
        "id": 4139,
        "label": "HBV - Pesquisa de ADN do vírus B da hepatite por PCR ou técnica afim",
        "k": "0",
        "c": "150",
        "code": "74.04.00.14"
    },
    {
        "id": 4140,
        "label": "HCV - Pesquisa de ARN do vírus C da hepatite por RT-PCR ou outra técnica de amplificação",
        "k": "0",
        "c": "200",
        "code": "74.04.00.15"
    },
    {
        "id": 4141,
        "label": "HDV - Pesquisa de ADN do vírus D da hepatite por PCR ou outra técnica de amplificação",
        "k": "0",
        "c": "200",
        "code": "74.04.00.16"
    },
    {
        "id": 4142,
        "label": "HEV - Pesquisa de ADN do vírus E da hepatite por PCR ou outra técnica de amplificação",
        "k": "0",
        "c": "200",
        "code": "74.04.00.17"
    },
    {
        "id": 4143,
        "label": "HIV 1 - Pesquisa de ARN do vírus 1 da Imunodeficiência humana por RT-PCR ou técnica similar",
        "k": "0",
        "c": "200",
        "code": "74.04.00.18"
    },
    {
        "id": 4144,
        "label": "HIV 2 - Pesquisa de ARN do vírus 2 da imunodeficiência humana por RT-PCR ou técnica similar",
        "k": "0",
        "c": "200",
        "code": "74.04.00.19"
    },
    {
        "id": 4145,
        "label": "HCV (Quantificação da virémia ou “carga viral”)",
        "k": "0",
        "c": "300",
        "code": "74.04.00.20"
    },
    {
        "id": 4146,
        "label": "HIV 1 (Quantificação do ARN do vírus ou “carga viral”)",
        "k": "0",
        "c": "300",
        "code": "74.04.00.21"
    },
    {
        "id": 4147,
        "label": "Outras quantificações de ARN viral em amostras biológicas",
        "k": "0",
        "c": "300",
        "code": "74.04.00.22"
    },
    {
        "id": 4148,
        "label": "Outras quantificações de ADN viral em amostras biológicas",
        "k": "0",
        "c": "300",
        "code": "74.04.00.23"
    },
    {
        "id": 4149,
        "label": "Genotipagem do vírus C da hepatite com recurso a técnicas de RT-PCR e sondas moleculares específicas",
        "k": "0",
        "c": "300",
        "code": "74.04.00.24"
    },
    {
        "id": 4150,
        "label": "Anticorpos anti-leucocitários ou anti-plaquetários (cada)",
        "k": "0",
        "c": "100",
        "code": "75.01.00.01"
    },
    {
        "id": 4151,
        "label": "Antigénio HLA (Determinação da presença de um...)",
        "k": "0",
        "c": "40",
        "code": "75.01.00.02"
    },
    {
        "id": 4152,
        "label": "Citotoxicidade-Celular Mediada por Anticorpos (ADCC)",
        "k": "0",
        "c": "100",
        "code": "75.01.00.03"
    },
    {
        "id": 4153,
        "label": "Cultura linfocitária mista entre linfócitos de 2 individuos (MLC)",
        "k": "0",
        "c": "80",
        "code": "75.01.00.04"
    },
    {
        "id": 4154,
        "label": "Cultura linfocitária mista entre linfócitos de 2 indivíduos (MLC) - cada dador adicional",
        "k": "0",
        "c": "40",
        "code": "75.01.00.05"
    },
    {
        "id": 4155,
        "label": "Desgranulação dos Basófilos (Teste da...), cada antigénio",
        "k": "0",
        "c": "50",
        "code": "75.01.00.06"
    },
    {
        "id": 4156,
        "label": "Redução do NBT por leucócitos - Teste do NBT",
        "k": "0",
        "c": "12",
        "code": "75.01.00.07"
    },
    {
        "id": 4157,
        "label": "HLA classe II (HLA-DR, DQ, DP), cada grupo",
        "k": "0",
        "c": "70",
        "code": "75.01.00.09"
    },
    {
        "id": 4158,
        "label": "Iso-Hemaglutininas Naturais (Titulação das...)",
        "k": "0",
        "c": "10",
        "code": "75.01.00.10"
    },
    {
        "id": 4159,
        "label": "Prova cutânea de hipersensibilidade retardada (PCHR), mínimo 4 antigénios",
        "k": "0",
        "c": "40",
        "code": "75.01.00.11"
    },
    {
        "id": 4160,
        "label": "Linfócitos - Resposta a Antigénios ‘’in vitro’’ por estimulação em cultura",
        "k": "0",
        "c": "100",
        "code": "75.01.00.12"
    },
    {
        "id": 4161,
        "label": "Linfócitos B - Detecção Ig’s da Superf. Da Memb. (Sig’s-IF), cada anti-soro",
        "k": "0",
        "c": "50",
        "code": "75.01.00.13"
    },
    {
        "id": 4162,
        "label": "Linfócitos B - imunoglobulinas (Clg’s) intra-citoplasmáticas (Determ. Das ...),cada anti-soro",
        "k": "0",
        "c": "50",
        "code": "75.01.00.14"
    },
    {
        "id": 4163,
        "label": "Linfócitos B - ind. Blástica por mitogénio, cada mitogénio",
        "k": "0",
        "c": "100",
        "code": "75.01.00.15"
    },
    {
        "id": 4164,
        "label": "Linfócitos B - Receptores Fc (Estudos dos...)",
        "k": "0",
        "c": "50",
        "code": "75.01.00.16"
    },
    {
        "id": 4165,
        "label": "Leucócitos - Determinação dos receptores celulares",
        "k": "0",
        "c": "50",
        "code": "75.01.00.17"
    },
    {
        "id": 4166,
        "label": "Linfócitos B - Rosetas espontâneas com eritrócitos de ratinho",
        "k": "0",
        "c": "25",
        "code": "75.01.00.18"
    },
    {
        "id": 4167,
        "label": "Linfócitos B - Síntese das Imunoglobulinas (Ig’s) ‘’in vitro’’",
        "k": "0",
        "c": "200",
        "code": "75.01.00.19"
    },
    {
        "id": 4168,
        "label": "Citotoxicidade celular",
        "k": "0",
        "c": "100",
        "code": "75.01.00.20"
    },
    {
        "id": 4169,
        "label": "Linfócitos T - Inducção Blástica por mitogénios (PHA, Com A, PWN), resp. a cada",
        "k": "0",
        "c": "100",
        "code": "75.01.00.21"
    },
    {
        "id": 4170,
        "label": "Linfócitos T - Inibição da Migração após Estim. Por Mitogénios",
        "k": "0",
        "c": "80",
        "code": "75.01.00.22"
    },
    {
        "id": 4171,
        "label": "Linfócitos T - Linfólise Med. Por Células",
        "k": "0",
        "c": "100",
        "code": "75.01.00.23"
    },
    {
        "id": 4172,
        "label": "Linfócitos T - Rosetas espontâneas (E), com eritrócitos de carneiro",
        "k": "0",
        "c": "25",
        "code": "75.01.00.24"
    },
    {
        "id": 4173,
        "label": "Quantificação de populações celulares (linfocitárias/outras) com anticorpos monoclonais, cada marcador",
        "k": "0",
        "c": "50",
        "code": "75.01.00.25"
    },
    {
        "id": 4174,
        "label": "Test Linfocitário de Pré-Estimulação PTL",
        "k": "0",
        "c": "120",
        "code": "75.01.00.26"
    },
    {
        "id": 4175,
        "label": "Atc. Anti-Plaq. (Pesquisa contra painel plaq. C/HLA)",
        "k": "0",
        "c": "50",
        "code": "75.01.00.27"
    },
    {
        "id": 4176,
        "label": "Avaliação da paternidade, indíce de probabilidade por estudo grupos sanguíneos HW/Rh/Duffy/Lewis/Kell/P/MN/Ss/HLA A, B, C, DR",
        "k": "0",
        "c": "200",
        "code": "75.01.00.28"
    },
    {
        "id": 4177,
        "label": "Estudo da função fagocítica dos leucócitos (neutrófilos, Monócitos, Macrófagos), cada",
        "k": "0",
        "c": "80",
        "code": "75.01.00.29"
    },
    {
        "id": 4178,
        "label": "Estudo da função fagocítica e microbiocida dos leucócitos (neutrófilos, Monócitos, Macrófagos), cada",
        "k": "0",
        "c": "100",
        "code": "75.01.00.30"
    },
    {
        "id": 4179,
        "label": "Libertação leucocitária de histamina (Prova de)",
        "k": "0",
        "c": "50",
        "code": "75.01.00.31"
    },
    {
        "id": 4180,
        "label": "Quimiotaxia de células fagociticas (Neutrófilos/Monócitos/Macrófagos) - cada linha celular",
        "k": "0",
        "c": "80",
        "code": "75.01.00.32"
    },
    {
        "id": 4181,
        "label": "Tipagem HLA classe I (A,B e C)",
        "k": "0",
        "c": "100",
        "code": "75.01.00.33"
    },
    {
        "id": 4182,
        "label": "Estudo de doença imunológica - (exames executados+valor da consulta) ver cód 01.00.00.03 ou 01.00.00.04",
        "k": "0",
        "c": "0",
        "code": "75.01.00.34"
    },
    {
        "id": 4183,
        "label": "Tipagem de Alótipos de Imunoglobulinas (Gm/Inu/Gc)",
        "k": "0",
        "c": "50",
        "code": "75.02.00.01"
    },
    {
        "id": 4184,
        "label": "Cadeias leves de imunoglobulinas (Kappa e Lambda) na urina - Dos., cada",
        "k": "0",
        "c": "30",
        "code": "75.02.00.02"
    },
    {
        "id": 4185,
        "label": "Beta-1-Glicoproteína",
        "k": "0",
        "c": "50",
        "code": "75.02.00.03"
    },
    {
        "id": 4186,
        "label": "Beta-2-Microglobina",
        "k": "0",
        "c": "50",
        "code": "75.02.00.04"
    },
    {
        "id": 4187,
        "label": "Inactivador da esterase do C1",
        "k": "0",
        "c": "20",
        "code": "75.02.00.05"
    },
    {
        "id": 4188,
        "label": "C’3 (C’3c)",
        "k": "0",
        "c": "12",
        "code": "75.02.00.06"
    },
    {
        "id": 4189,
        "label": "C’3 (inactivador de...)",
        "k": "0",
        "c": "20",
        "code": "75.02.00.07"
    },
    {
        "id": 4190,
        "label": "C’3 PA (PRO-ACTIVADOR)",
        "k": "0",
        "c": "20",
        "code": "75.02.00.08"
    },
    {
        "id": 4191,
        "label": "C’4",
        "k": "0",
        "c": "12",
        "code": "75.02.00.09"
    },
    {
        "id": 4192,
        "label": "Complemento, factores (C1q, C2, C5, C6, C7, C8 e C9)",
        "k": "0",
        "c": "30",
        "code": "75.02.00.10"
    },
    {
        "id": 4193,
        "label": "Complemento total (Título de actividade hemolítica - CH 50), via clássica/via alterna, cada",
        "k": "0",
        "c": "40",
        "code": "75.02.00.11"
    },
    {
        "id": 4194,
        "label": "Complemento (fragmentos activados: C3a, C5a, etc), cada",
        "k": "0",
        "c": "80",
        "code": "75.02.00.12"
    },
    {
        "id": 4195,
        "label": "Crioglobulinas (Caracterização Imunoquimica)",
        "k": "0",
        "c": "20",
        "code": "75.02.00.13"
    },
    {
        "id": 4196,
        "label": "Crioglobulinas (pesquisa e caracterização imunoquímica, se necessário)",
        "k": "0",
        "c": "20",
        "code": "75.02.00.14"
    },
    {
        "id": 4197,
        "label": "Crioglobulinas (Pesquisa de...)",
        "k": "0",
        "c": "5",
        "code": "75.02.00.15"
    },
    {
        "id": 4198,
        "label": "Imunocomplexos, identificação dos componentes após precipitação pelo PEG",
        "k": "0",
        "c": "25",
        "code": "75.02.00.16"
    },
    {
        "id": 4199,
        "label": "Imunocomplexos (Téc.do Cons.do Complemento, medida pelo CH50)",
        "k": "0",
        "c": "25",
        "code": "75.02.00.17"
    },
    {
        "id": 4200,
        "label": "Imunocomplexos (Técnica de Fixação C’1q )",
        "k": "0",
        "c": "30",
        "code": "75.02.00.18"
    },
    {
        "id": 4201,
        "label": "Imunoelectroforese com Anti-Soro Polivalente",
        "k": "0",
        "c": "15",
        "code": "75.02.00.19"
    },
    {
        "id": 4202,
        "label": "Imunoelectroforese das proteínas (Total + IgG + IgA + IgM + C.L. Kappa + C.L. lambda)",
        "k": "0",
        "c": "40",
        "code": "75.02.00.20"
    },
    {
        "id": 4203,
        "label": "Imunoelectroforese das proteinas com concentração prévia da amostra (LCR, urina,...)",
        "k": "0",
        "c": "50",
        "code": "75.02.00.21"
    },
    {
        "id": 4204,
        "label": "Electroimunofixação das proteinas (Total+IgG + IgA + IgM + C.L. Kappa + C.L. lambda)",
        "k": "0",
        "c": "40",
        "code": "75.02.00.22"
    },
    {
        "id": 4205,
        "label": "Imunoglobulina A (IgA)",
        "k": "0",
        "c": "10",
        "code": "75.02.00.23"
    },
    {
        "id": 4206,
        "label": "Imunoglobulina A - secretora (pesq.)",
        "k": "0",
        "c": "10",
        "code": "75.02.00.24"
    },
    {
        "id": 4207,
        "label": "Imunoglobulina D (IgD)",
        "k": "0",
        "c": "25",
        "code": "75.02.00.25"
    },
    {
        "id": 4208,
        "label": "Imunoglobulina E (IgE)",
        "k": "0",
        "c": "25",
        "code": "75.02.00.26"
    },
    {
        "id": 4209,
        "label": "Imunoglobulina G (IgG)",
        "k": "0",
        "c": "10",
        "code": "75.02.00.27"
    },
    {
        "id": 4210,
        "label": "Imunoglobulina M (IgM)",
        "k": "0",
        "c": "10",
        "code": "75.02.00.28"
    },
    {
        "id": 4211,
        "label": "Imunoglobulinas (IgA+IgG+IgM)",
        "k": "0",
        "c": "30",
        "code": "75.02.00.29"
    },
    {
        "id": 4212,
        "label": "IgG1",
        "k": "0",
        "c": "50",
        "code": "75.02.00.30"
    },
    {
        "id": 4213,
        "label": "IgG2",
        "k": "0",
        "c": "50",
        "code": "75.02.00.31"
    },
    {
        "id": 4214,
        "label": "IgG3",
        "k": "0",
        "c": "50",
        "code": "75.02.00.32"
    },
    {
        "id": 4215,
        "label": "IgG4",
        "k": "0",
        "c": "50",
        "code": "75.02.00.33"
    },
    {
        "id": 4216,
        "label": "Proteína C- Reactiva (Doseamento da...)",
        "k": "0",
        "c": "20",
        "code": "75.02.00.34"
    },
    {
        "id": 4217,
        "label": "Prova de Sia",
        "k": "0",
        "c": "1",
        "code": "75.02.00.35"
    },
    {
        "id": 4218,
        "label": "IgE específica para um determinado alergénio (RAST Test), cada",
        "k": "0",
        "c": "54",
        "code": "75.02.00.36"
    },
    {
        "id": 4219,
        "label": "Waaler-Rose (Reacção de...)",
        "k": "0",
        "c": "15",
        "code": "75.02.00.37"
    },
    {
        "id": 4220,
        "label": "Alfa-1 Anti-Tripsina",
        "k": "0",
        "c": "12",
        "code": "75.02.00.38"
    },
    {
        "id": 4221,
        "label": "Alfa-1 Anti-Tripsina (fenótipos)",
        "k": "0",
        "c": "40",
        "code": "75.02.00.39"
    },
    {
        "id": 4222,
        "label": "Alfa-1 Glicoproteina ácida (ou orosomucóide)",
        "k": "0",
        "c": "12",
        "code": "75.02.00.40"
    },
    {
        "id": 4223,
        "label": "Alfa-2 Macroglobulina",
        "k": "0",
        "c": "12",
        "code": "75.02.00.41"
    },
    {
        "id": 4224,
        "label": "Anticorpos IgG4 específicos, cada antigénio",
        "k": "0",
        "c": "54",
        "code": "75.02.00.42"
    },
    {
        "id": 4225,
        "label": "Cadeias leves de imunoglobulinas (Kappa e lambda) - dos., cada",
        "k": "0",
        "c": "30",
        "code": "75.02.00.43"
    },
    {
        "id": 4226,
        "label": "Citocinas (Interfeões, interleucinas, outras), cada",
        "k": "0",
        "c": "60",
        "code": "75.02.00.44"
    },
    {
        "id": 4227,
        "label": "Complemento - Fragmentos de activação (C3d, C4d, MAC, outros), cada",
        "k": "0",
        "c": "50",
        "code": "75.02.00.45"
    },
    {
        "id": 4228,
        "label": "Electroimunofixação das proteinas após concentração, (mínimo 4 anti-soros)",
        "k": "0",
        "c": "50",
        "code": "75.02.00.46"
    },
    {
        "id": 4229,
        "label": "Factor reumatóide, doseamento",
        "k": "0",
        "c": "20",
        "code": "75.02.00.47"
    },
    {
        "id": 4230,
        "label": "Factor reumatóide, doseamento com determinação do tipo de cadeia pesada (A, G e M) - cada",
        "k": "0",
        "c": "50",
        "code": "75.02.00.48"
    },
    {
        "id": 4231,
        "label": "Histamina",
        "k": "0",
        "c": "50",
        "code": "75.02.00.49"
    },
    {
        "id": 4232,
        "label": "Identificação precipitinas, cada",
        "k": "0",
        "c": "20",
        "code": "75.02.00.50"
    },
    {
        "id": 4233,
        "label": "Imunocomplexos circulantes (técnica de inibição de factor reumatóide)",
        "k": "0",
        "c": "30",
        "code": "75.02.00.51"
    },
    {
        "id": 4234,
        "label": "Imunocomplexos circulantes (técnica de nefelometria simples)",
        "k": "0",
        "c": "20",
        "code": "75.02.00.52"
    },
    {
        "id": 4235,
        "label": "Inactivador da esterase do C1, teste funcional",
        "k": "0",
        "c": "60",
        "code": "75.02.00.53"
    },
    {
        "id": 4236,
        "label": "Metil-histamina",
        "k": "0",
        "c": "50",
        "code": "75.02.00.54"
    },
    {
        "id": 4237,
        "label": "Mieloperoxidase (doseamento)",
        "k": "0",
        "c": "50",
        "code": "75.02.00.55"
    },
    {
        "id": 4238,
        "label": "Proteina catiónica do eosinófilo (ECP)",
        "k": "0",
        "c": "50",
        "code": "75.02.00.56"
    },
    {
        "id": 4239,
        "label": "Proteina X do eosinófilo",
        "k": "0",
        "c": "50",
        "code": "75.02.00.57"
    },
    {
        "id": 4240,
        "label": "Receptores solúveis de citocinas",
        "k": "0",
        "c": "60",
        "code": "75.02.00.58"
    },
    {
        "id": 4241,
        "label": "Sub-classes de Imunoglobulina A (IgA1 e IgA2), cada",
        "k": "0",
        "c": "50",
        "code": "75.02.00.59"
    },
    {
        "id": 4242,
        "label": "Triptase",
        "k": "0",
        "c": "50",
        "code": "75.02.00.60"
    },
    {
        "id": 4243,
        "label": "ANCA = Anticorpos anti-citoplasma dos neutrófilos (IF)",
        "k": "0",
        "c": "50",
        "code": "75.03.00.01"
    },
    {
        "id": 4244,
        "label": "Anticorpos anti-AND nativo = ANTI-DNA ou anti-AND",
        "k": "0",
        "c": "35",
        "code": "75.03.00.02"
    },
    {
        "id": 4245,
        "label": "Anticorpos anti-cardiolipina (IgG, IgA, IgM), cada",
        "k": "0",
        "c": "50",
        "code": "75.03.00.03"
    },
    {
        "id": 4246,
        "label": "Anticorpos Anti-Célula Parietal Gástrica (c/tit. Quando necessário)",
        "k": "0",
        "c": "50",
        "code": "75.03.00.04"
    },
    {
        "id": 4247,
        "label": "Anticorpos anti-antigénios nucleares extraíveis (ENA) - Sm/Rnp/SS-A/SS-B/ outros",
        "k": "0",
        "c": "50",
        "code": "75.03.00.05"
    },
    {
        "id": 4248,
        "label": "Anticorpos Anti-Esperma",
        "k": "0",
        "c": "50",
        "code": "75.03.00.06"
    },
    {
        "id": 4249,
        "label": "Anticorpos Anti-Gliadina IgA ou IgG, cada",
        "k": "0",
        "c": "50",
        "code": "75.03.00.07"
    },
    {
        "id": 4250,
        "label": "Anticorpos Anti-Histonas",
        "k": "0",
        "c": "50",
        "code": "75.03.00.08"
    },
    {
        "id": 4251,
        "label": "Anticorpos Anti-Ilhéus de Langerhans",
        "k": "0",
        "c": "50",
        "code": "75.03.00.09"
    },
    {
        "id": 4252,
        "label": "Anticorpos Anti-Insulina",
        "k": "0",
        "c": "60",
        "code": "75.03.00.10"
    },
    {
        "id": 4253,
        "label": "Anticorpos Anti-LC1 (citosol hepático)",
        "k": "0",
        "c": "60",
        "code": "75.03.00.11"
    },
    {
        "id": 4254,
        "label": "Anticorpos Anti-Membrana Basal Glomérulo Renal",
        "k": "0",
        "c": "50",
        "code": "75.03.00.12"
    },
    {
        "id": 4255,
        "label": "Anticorpos Anti-Membrana Basal Tubular",
        "k": "0",
        "c": "50",
        "code": "75.03.00.13"
    },
    {
        "id": 4331,
        "label": "Anticorpos Anti-Rotavirus",
        "k": "0",
        "c": "100",
        "code": "75.04.00.48"
    },
    {
        "id": 4256,
        "label": "Anticorpos Anti-Mitocondria por I.F. (c/ titulação, se positivos)",
        "k": "0",
        "c": "30",
        "code": "75.03.00.14"
    },
    {
        "id": 4257,
        "label": "Anticorpos Anti-Músculo Estriado por I.F. (c/ titulaçâo, se positivos)",
        "k": "0",
        "c": "50",
        "code": "75.03.00.15"
    },
    {
        "id": 4258,
        "label": "Anticorpos Anti-Músculo Liso por I.F. (c/ titulaqão, se positivos)",
        "k": "0",
        "c": "30",
        "code": "75.03.00.16"
    },
    {
        "id": 4259,
        "label": "Anticorpos Anti-Nucleares por I.F. (c/ titulação, se positivos)",
        "k": "0",
        "c": "30",
        "code": "75.03.00.17"
    },
    {
        "id": 4260,
        "label": "Anticórpos Anti-Ovário",
        "k": "0",
        "c": "50",
        "code": "75.03.00.18"
    },
    {
        "id": 4261,
        "label": "Anticorpos Anti-Pâncreas Exócrino",
        "k": "0",
        "c": "50",
        "code": "75.03.00.19"
    },
    {
        "id": 4262,
        "label": "Anticorpos Anti-Queratina",
        "k": "0",
        "c": "50",
        "code": "75.03.00.20"
    },
    {
        "id": 4263,
        "label": "Anticorpos Anti-Reticulina",
        "k": "0",
        "c": "50",
        "code": "75.03.00.21"
    },
    {
        "id": 4264,
        "label": "Anticorpos Anti-Supra-Renal",
        "k": "0",
        "c": "50",
        "code": "75.03.00.22"
    },
    {
        "id": 4265,
        "label": "Anticorpos Anti-Testículo",
        "k": "0",
        "c": "50",
        "code": "75.03.00.23"
    },
    {
        "id": 4266,
        "label": "Anticorpos Anti-Tiroideus (Anti-Tiroglobul.+Anti-Micross,)",
        "k": "0",
        "c": "50",
        "code": "75.03.00.24"
    },
    {
        "id": 4267,
        "label": "Anticorpos anti-Centómetro",
        "k": "0",
        "c": "50",
        "code": "75.03.00.25"
    },
    {
        "id": 4268,
        "label": "Anticorpos anti-LKM - anti-liver, kidney microsome",
        "k": "0",
        "c": "60",
        "code": "75.03.00.26"
    },
    {
        "id": 4269,
        "label": "TRABs - anticorpos antireceptor de TSH",
        "k": "0",
        "c": "60",
        "code": "75.03.00.27"
    },
    {
        "id": 4270,
        "label": "Anticorpos anti-ducto salivar",
        "k": "0",
        "c": "50",
        "code": "75.03.00.28"
    },
    {
        "id": 4271,
        "label": "Anticorpos anti-elastina",
        "k": "0",
        "c": "50",
        "code": "75.03.00.29"
    },
    {
        "id": 4272,
        "label": "Anticorpos anti-endomísio",
        "k": "0",
        "c": "50",
        "code": "75.03.00.30"
    },
    {
        "id": 4273,
        "label": "Anticorpos anti-factor intrínseco",
        "k": "0",
        "c": "60",
        "code": "75.03.00.31"
    },
    {
        "id": 4274,
        "label": "Anticorpos anti-fosfolipídeo (IgG, IgM ou IGA), cada",
        "k": "0",
        "c": "50",
        "code": "75.03.00.32"
    },
    {
        "id": 4275,
        "label": "Anticorpos anti-hormona do crescimento (anti-HGH)",
        "k": "0",
        "c": "60",
        "code": "75.03.00.33"
    },
    {
        "id": 4276,
        "label": "Anticorpos anti-LKM",
        "k": "0",
        "c": "50",
        "code": "75.03.00.34"
    },
    {
        "id": 4277,
        "label": "Anticorpos anti-Membrana Basal Glomerular (GBM)",
        "k": "0",
        "c": "50",
        "code": "75.03.00.35"
    },
    {
        "id": 4278,
        "label": "Anticorpos anti-mieloperoxidase (MPO)",
        "k": "0",
        "c": "50",
        "code": "75.03.00.36"
    },
    {
        "id": 4279,
        "label": "Anticorpos anti-mitocôndriais (M1, M2, outros)",
        "k": "0",
        "c": "50",
        "code": "75.03.00.37"
    },
    {
        "id": 4280,
        "label": "Anticorpos anti-proteinase 3 (PR3)",
        "k": "0",
        "c": "50",
        "code": "75.03.00.38"
    },
    {
        "id": 4281,
        "label": "Anticorpos anti-receptor de acetilcolina",
        "k": "0",
        "c": "150",
        "code": "75.03.00.40"
    },
    {
        "id": 4282,
        "label": "Anticorpos anti-receptor da insulina",
        "k": "0",
        "c": "60",
        "code": "75.03.00.41"
    },
    {
        "id": 4283,
        "label": "Anticorpos anti-SCL70",
        "k": "0",
        "c": "50",
        "code": "75.03.00.43"
    },
    {
        "id": 4284,
        "label": "Anti-HVC",
        "k": "0",
        "c": "120",
        "code": "75.04.00.01"
    },
    {
        "id": 4285,
        "label": "Anti-HVD - Anticorpos Anti-Hepatite Delta",
        "k": "0",
        "c": "50",
        "code": "75.04.00.02"
    },
    {
        "id": 4286,
        "label": "Anti-HVD IgM - Anticorpos Anti-Hepatite Delta (IgM)",
        "k": "0",
        "c": "60",
        "code": "75.04.00.03"
    },
    {
        "id": 4287,
        "label": "Anti-HBc = Anticorpos Anti-HBc",
        "k": "0",
        "c": "40",
        "code": "75.04.00.04"
    },
    {
        "id": 4288,
        "label": "Anti-HBc IgM = Anticorpos Anti-HBc IgM",
        "k": "0",
        "c": "50",
        "code": "75.04.00.05"
    },
    {
        "id": 4289,
        "label": "Anti-HBe = Anticorpos Anti-Hbe",
        "k": "0",
        "c": "40",
        "code": "75.04.00.06"
    },
    {
        "id": 4290,
        "label": "Anti-HBs = Anticorpos anti-HBs",
        "k": "0",
        "c": "30",
        "code": "75.04.00.07"
    },
    {
        "id": 4291,
        "label": "Anti-HVA IgG ou IgM = Anticorpos anti-HVA IgM ou IgG, cada",
        "k": "0",
        "c": "40",
        "code": "75.04.00.08"
    },
    {
        "id": 4292,
        "label": "Anticorpos anti-HBc = Ver Anti-HBc",
        "k": "0",
        "c": "0",
        "code": "75.04.00.09"
    },
    {
        "id": 4293,
        "label": "Anticorpos anti-HBc IgM = Ver Anti—HBc IgM Ver Cód. 75.04.00.05",
        "k": "0",
        "c": "0",
        "code": "75.04.00.10"
    },
    {
        "id": 4294,
        "label": "Anticorpos anti-HBe = Ver Anti-Hbe Ver Cód. 75.04.00.06",
        "k": "0",
        "c": "0",
        "code": "75.04.00.11"
    },
    {
        "id": 4295,
        "label": "Anticorpos Anti-HBs = Ver Anti-HBs (RIA ou ELISA) Ver Cód. 75.04.00.07",
        "k": "0",
        "c": "0",
        "code": "75.04.00.12"
    },
    {
        "id": 4296,
        "label": "Anticorpos anti HC (Hepatite C) (IgG ou IgM) cada",
        "k": "0",
        "c": "40",
        "code": "75.04.00.13"
    },
    {
        "id": 4297,
        "label": "Anticorpos Anti HC (Hepatite C) Test Confirmativo",
        "k": "0",
        "c": "60",
        "code": "75.04.00.14"
    },
    {
        "id": 4298,
        "label": "Anticorpos Anti Hepatite Delta",
        "k": "0",
        "c": "50",
        "code": "75.04.00.15"
    },
    {
        "id": 4299,
        "label": "Anticorpos Anti-Adenovirus (Titulação por FC)",
        "k": "0",
        "c": "80",
        "code": "75.04.00.16"
    },
    {
        "id": 4300,
        "label": "Anticorpos Anti Agentes Microbianos, Viricos, Parasitários ou Fúngicos não icluídos nesta tabela",
        "k": "0",
        "c": "40",
        "code": "75.04.00.17"
    },
    {
        "id": 4301,
        "label": "Anticorpos anti-Brucella",
        "k": "0",
        "c": "40",
        "code": "75.04.00.18"
    },
    {
        "id": 4302,
        "label": "Anticorpos anti-Citomegalovirus",
        "k": "0",
        "c": "50",
        "code": "75.04.00.19"
    },
    {
        "id": 4303,
        "label": "Anticorpos anti-Clamydia Trachomatis",
        "k": "0",
        "c": "50",
        "code": "75.04.00.20"
    },
    {
        "id": 4304,
        "label": "Anticorpos anti-Coxiella Burnetii = Febre Q",
        "k": "0",
        "c": "50",
        "code": "75.04.00.21"
    },
    {
        "id": 4305,
        "label": "Anticorpos Anti-Diftéricos",
        "k": "0",
        "c": "30",
        "code": "75.04.00.22"
    },
    {
        "id": 4306,
        "label": "Anticorpos Anti-Enterovirus",
        "k": "0",
        "c": "50",
        "code": "75.04.00.23"
    },
    {
        "id": 4307,
        "label": "Anticorpos Anti-Epstein-Barr-Anti-VCA-EBNA",
        "k": "0",
        "c": "60",
        "code": "75.04.00.24"
    },
    {
        "id": 4308,
        "label": "Anticorpos anti-vírus de Epstein-Barr (IgG ou IgM), cada",
        "k": "0",
        "c": "60",
        "code": "75.04.00.25"
    },
    {
        "id": 4309,
        "label": "Anticorpos Anti-Epstein-Barr-Anti-VCA-Lg M",
        "k": "0",
        "c": "60",
        "code": "75.04.00.26"
    },
    {
        "id": 4310,
        "label": "Anticorpos anti-Equinococo",
        "k": "0",
        "c": "40",
        "code": "75.04.00.27"
    },
    {
        "id": 4311,
        "label": "Anticorpos Anti-Equinococo (Hema glutinação)",
        "k": "0",
        "c": "13",
        "code": "75.04.00.28"
    },
    {
        "id": 4312,
        "label": "Anticorpos Anti-Equinococo (IF)",
        "k": "0",
        "c": "30",
        "code": "75.04.00.29"
    },
    {
        "id": 4313,
        "label": "Anticorpos Anti-Estreptodornase",
        "k": "0",
        "c": "20",
        "code": "75.04.00.30"
    },
    {
        "id": 4314,
        "label": "Anticorpos Anti-Exoenzimas Estreptocócicos",
        "k": "0",
        "c": "10",
        "code": "75.04.00.31"
    },
    {
        "id": 4315,
        "label": "Anticorpos Anti-Exoenzimas Estreptocócicos (Titulação)",
        "k": "0",
        "c": "30",
        "code": "75.04.00.32"
    },
    {
        "id": 4316,
        "label": "Anticorpos Anti-Febre Q Ver Cód. 75.04.00.21",
        "k": "0",
        "c": "0",
        "code": "75.04.00.33"
    },
    {
        "id": 4317,
        "label": "Anticorpos Anti-HIV (HIV1 + HIV2)",
        "k": "0",
        "c": "100",
        "code": "75.04.00.34"
    },
    {
        "id": 4318,
        "label": "Anticorpos Anti-HIV (Test Confirmativo por Blotting)",
        "k": "0",
        "c": "190",
        "code": "75.04.00.35"
    },
    {
        "id": 4319,
        "label": "Anticorpos Anti-HTLV (HTLV1 + HTLV2)",
        "k": "0",
        "c": "100",
        "code": "75.04.00.36"
    },
    {
        "id": 4320,
        "label": "Anticorpos Anti-HVA IgG (ELISA)",
        "k": "0",
        "c": "40",
        "code": "75.04.00.37"
    },
    {
        "id": 4321,
        "label": "Anticorpos Anti-HVA IgM (ELISA)",
        "k": "0",
        "c": "40",
        "code": "75.04.00.38"
    },
    {
        "id": 4322,
        "label": "Anticorpos Anti-Hialuronidase",
        "k": "0",
        "c": "13",
        "code": "75.04.00.39"
    },
    {
        "id": 4323,
        "label": "Anticorpos Anti-Legionella (Tit. para 11 antigénios)",
        "k": "0",
        "c": "84",
        "code": "75.04.00.40"
    },
    {
        "id": 4324,
        "label": "Anticorpos Anti-Leptospira",
        "k": "0",
        "c": "80",
        "code": "75.04.00.41"
    },
    {
        "id": 4325,
        "label": "Anticorpos Anti-Listéria Monocytogenes",
        "k": "0",
        "c": "60",
        "code": "75.04.00.42"
    },
    {
        "id": 4326,
        "label": "Anticorpos Anti-Mycoplasma Pneumoniae",
        "k": "0",
        "c": "80",
        "code": "75.04.00.43"
    },
    {
        "id": 4327,
        "label": "Anticorpos Anti-Ornitose",
        "k": "0",
        "c": "80",
        "code": "75.04.00.44"
    },
    {
        "id": 4328,
        "label": "Anticorpos Anti-P 24",
        "k": "0",
        "c": "75",
        "code": "75.04.00.45"
    },
    {
        "id": 4329,
        "label": "Anticorpos anti-Plasmodium",
        "k": "0",
        "c": "80",
        "code": "75.04.00.46"
    },
    {
        "id": 4330,
        "label": "Anticorpos Anti-Ricketsia (Tit. por Imunofluorescência para 3 espécies)",
        "k": "0",
        "c": "42",
        "code": "75.04.00.47"
    },
    {
        "id": 4332,
        "label": "Anticorpos Anti-Tetânicos (Inc. Tit. se necessário)",
        "k": "0",
        "c": "30",
        "code": "75.04.00.49"
    },
    {
        "id": 4333,
        "label": "Anticorpos Anti-Toxoplasma (Inc. Tit.) IgG",
        "k": "0",
        "c": "30",
        "code": "75.04.00.50"
    },
    {
        "id": 4334,
        "label": "Anticorpos Anti-Toxoplasma",
        "k": "0",
        "c": "60",
        "code": "75.04.00.51"
    },
    {
        "id": 4335,
        "label": "Anticorpos Anti-Toxoplasma (Inc. Tit.) IgM",
        "k": "0",
        "c": "40",
        "code": "75.04.00.52"
    },
    {
        "id": 4336,
        "label": "Anticorpos anti-Treponema palidum (Inc.Tit.) Ver TPHA",
        "k": "0",
        "c": "50",
        "code": "75.04.00.53"
    },
    {
        "id": 4337,
        "label": "Anticorpos Anti-Treponema Palidum = FTA4ABS (IF)",
        "k": "0",
        "c": "50",
        "code": "75.04.00.54"
    },
    {
        "id": 4338,
        "label": "Anticorpos Anti - Tripanossoma",
        "k": "0",
        "c": "80",
        "code": "75.04.00.55"
    },
    {
        "id": 4339,
        "label": "Anticorpos Anti-Vírus da Coriomeningite Linfocítica",
        "k": "0",
        "c": "50",
        "code": "75.04.00.56"
    },
    {
        "id": 4340,
        "label": "Anticorpos Anti-Vírus da Influenza",
        "k": "0",
        "c": "50",
        "code": "75.04.00.57"
    },
    {
        "id": 4341,
        "label": "Anticorpos Anti-Vírus da Mononucleo se Infecciosa (Prova em Lâmina)",
        "k": "0",
        "c": "6",
        "code": "75.04.00.58"
    },
    {
        "id": 4342,
        "label": "Anticorpos Anti-Vírus da Papeira",
        "k": "0",
        "c": "34",
        "code": "75.04.00.59"
    },
    {
        "id": 4343,
        "label": "Anticorpos Anti-Vírus Parainfluenza",
        "k": "0",
        "c": "50",
        "code": "75.04.00.60"
    },
    {
        "id": 4344,
        "label": "Anticorpos Anti-Vírus da Rubéola (Inc. Tit.) IgM",
        "k": "0",
        "c": "30",
        "code": "75.04.00.61"
    },
    {
        "id": 4345,
        "label": "Anticorpos Anti-Vírus da Rubéola (Inc. Tit.) IgG",
        "k": "0",
        "c": "20",
        "code": "75.04.00.62"
    },
    {
        "id": 4346,
        "label": "Anticorpos Anti-Vírus da Varicela",
        "k": "0",
        "c": "50",
        "code": "75.04.00.63"
    },
    {
        "id": 4347,
        "label": "Anticorpos Anti-Vírus do Herpes I",
        "k": "0",
        "c": "50",
        "code": "75.04.00.64"
    },
    {
        "id": 4348,
        "label": "Anticorpos Anti-Vírus do Herpes II",
        "k": "0",
        "c": "50",
        "code": "75.04.00.65"
    },
    {
        "id": 4349,
        "label": "Anticorpos Anti-Vírus do Sarampo",
        "k": "0",
        "c": "50",
        "code": "75.04.00.66"
    },
    {
        "id": 4350,
        "label": "Anticorpos para qualq. outro ag.Microb. (Bact., Virus, Paras.)",
        "k": "0",
        "c": "40",
        "code": "75.04.00.67"
    },
    {
        "id": 4351,
        "label": "Antiestreptolisina O (Pesquisa)",
        "k": "0",
        "c": "2",
        "code": "75.04.00.68"
    },
    {
        "id": 4352,
        "label": "Anticorpos anti-Antiestreptolisina O (titulação/doseamento) = TASO",
        "k": "0",
        "c": "5",
        "code": "75.04.00.69"
    },
    {
        "id": 4353,
        "label": "Antigénio Vírus de Epstein – Barr",
        "k": "0",
        "c": "50",
        "code": "75.04.00.70"
    },
    {
        "id": 4354,
        "label": "Antigénio HBe = HBe Ag",
        "k": "0",
        "c": "30",
        "code": "75.04.00.71"
    },
    {
        "id": 4355,
        "label": "Antigénio HBs = HBs Ag",
        "k": "0",
        "c": "30",
        "code": "75.04.00.72"
    },
    {
        "id": 4356,
        "label": "Antigénio P 24",
        "k": "0",
        "c": "150",
        "code": "75.04.00.73"
    },
    {
        "id": 4357,
        "label": "Antigénio P 24 – (Pesquisa)",
        "k": "0",
        "c": "75",
        "code": "75.04.00.74"
    },
    {
        "id": 4358,
        "label": "Antigénio Rotavírus",
        "k": "0",
        "c": "50",
        "code": "75.04.00.75"
    },
    {
        "id": 4359,
        "label": "Blotting-Western; Southern; Northen (Técnicas de) para identificação de antigénios ou anticorpos",
        "k": "0",
        "c": "190",
        "code": "75.04.00.76"
    },
    {
        "id": 4360,
        "label": "Paul-Bunnel (Reacção de...)",
        "k": "0",
        "c": "8",
        "code": "75.04.00.77"
    },
    {
        "id": 4361,
        "label": "RPR (Método, rápido para pesq. de reaginas sifilíticas)",
        "k": "0",
        "c": "5",
        "code": "75.04.00.78"
    },
    {
        "id": 4362,
        "label": "Reacção de Casoni (não inclui ampola)",
        "k": "0",
        "c": "6",
        "code": "75.04.00.79"
    },
    {
        "id": 4363,
        "label": "Reacção de fix. compl. para o Mycoplasma pneumoniae",
        "k": "0",
        "c": "9",
        "code": "75.04.00.80"
    },
    {
        "id": 4364,
        "label": "Reacção de Hudlesson",
        "k": "0",
        "c": "5",
        "code": "75.04.00.81"
    },
    {
        "id": 4365,
        "label": "Reacção de Paul-Bunnell (Ver Paul Bunnell) Ver Cód. 75.04.00.77",
        "k": "0",
        "c": "0",
        "code": "75.04.00.82"
    },
    {
        "id": 4366,
        "label": "Reacção de Weil-Felix (3 antigénios)",
        "k": "0",
        "c": "10",
        "code": "75.04.00.83"
    },
    {
        "id": 4367,
        "label": "Reacção de Weinberg",
        "k": "0",
        "c": "10",
        "code": "75.04.00.84"
    },
    {
        "id": 4368,
        "label": "Reacção de Widal (4 antigénios)",
        "k": "0",
        "c": "8",
        "code": "75.04.00.85"
    },
    {
        "id": 4369,
        "label": "Reacção de Wright Ver Cód. 75.04.00.81",
        "k": "0",
        "c": "0",
        "code": "75.04.00.86"
    },
    {
        "id": 4370,
        "label": "VDRL (Reacção do...)",
        "k": "0",
        "c": "3",
        "code": "75.04.00.87"
    },
    {
        "id": 4371,
        "label": "Reacção para Fasciola Hepática (Fascioliase)",
        "k": "0",
        "c": "42",
        "code": "75.04.00.88"
    },
    {
        "id": 4372,
        "label": "Rotavirus, (Antigénio do...) pelo método de ELISA (Ver Antigénio do Rotavirus) Ver Cód. 75.04.00.75",
        "k": "0",
        "c": "0",
        "code": "75.04.00.89"
    },
    {
        "id": 4373,
        "label": "TASO - Titulo de Antiestreptolisina O - ver o cód. 70.04.00.69",
        "k": "0",
        "c": "0",
        "code": "75.04.00.90"
    },
    {
        "id": 4374,
        "label": "Teste Confirmativo da HC (Hepatite C)",
        "k": "0",
        "c": "120",
        "code": "75.04.00.91"
    },
    {
        "id": 4375,
        "label": "Monospot-test ou equivalente = Antic. Anti-Virus da Monon. Inf. (p. lamina)",
        "k": "0",
        "c": "6",
        "code": "75.04.00.92"
    },
    {
        "id": 4376,
        "label": "Toxoplasmose – Anticorpos – Lg G",
        "k": "0",
        "c": "30",
        "code": "75.04.00.93"
    },
    {
        "id": 4377,
        "label": "Anticorpos anti-Toxoplasmose IgG + IgM",
        "k": "0",
        "c": "60",
        "code": "75.04.00.94"
    },
    {
        "id": 4378,
        "label": "Toxoplasmose – Anticorpos – Lg M",
        "k": "0",
        "c": "40",
        "code": "75.04.00.95"
    },
    {
        "id": 4379,
        "label": "TPHA - ver cód. 75.04.00.53",
        "k": "0",
        "c": "0",
        "code": "75.04.00.96"
    },
    {
        "id": 4380,
        "label": "VDRL (incl. titulação, se necessário) - ver cód. 74.04.00.87",
        "k": "0",
        "c": "0",
        "code": "75.04.00.97"
    },
    {
        "id": 4381,
        "label": "Weil-Felix (reacção de...) Ver Cód. 75.04.00.83",
        "k": "0",
        "c": "0",
        "code": "75.04.00.98"
    },
    {
        "id": 4382,
        "label": "Weinberg (Reacção de...) Ver Cód. 75.04.00.84",
        "k": "0",
        "c": "0",
        "code": "75.04.00.99"
    },
    {
        "id": 4383,
        "label": "Western Blotting (técnicas de ) Ver Cód. 75.04.00.35",
        "k": "0",
        "c": "0",
        "code": "75.04.01.00"
    },
    {
        "id": 4384,
        "label": "Widal (Reacção de...) (4 antigénios) Ver cód. 75.04.00.85",
        "k": "0",
        "c": "0",
        "code": "75.04.01.01"
    },
    {
        "id": 4385,
        "label": "Wright (Reacção de...) Ver Cód. 75.04.00.81",
        "k": "0",
        "c": "0",
        "code": "75.04.01.02"
    },
    {
        "id": 4386,
        "label": "Diagnóstico serológico da Hepatite B (HBs + Anti-HBs + HBe + Anti-Hbe + Anti-HBc)",
        "k": "0",
        "c": "170",
        "code": "75.04.01.03"
    },
    {
        "id": 4387,
        "label": "Alfa-Fetoproteína",
        "k": "0",
        "c": "30",
        "code": "75.05.00.01"
    },
    {
        "id": 4388,
        "label": "Antigénio Carcino-Embrionário (CEA)",
        "k": "0",
        "c": "50",
        "code": "75.05.00.02"
    },
    {
        "id": 4389,
        "label": "Antigénio Específico da Próstata = SPA (RIA/EIA) = PSA",
        "k": "0",
        "c": "50",
        "code": "75.05.00.03"
    },
    {
        "id": 4390,
        "label": "CA – 125",
        "k": "0",
        "c": "50",
        "code": "75.05.00.04"
    },
    {
        "id": 4391,
        "label": "CA – 19.9",
        "k": "0",
        "c": "50",
        "code": "75.05.00.05"
    },
    {
        "id": 4392,
        "label": "CA 15.3",
        "k": "0",
        "c": "50",
        "code": "75.05.00.06"
    },
    {
        "id": 4393,
        "label": "CA 19.5",
        "k": "0",
        "c": "50",
        "code": "75.05.00.07"
    },
    {
        "id": 4394,
        "label": "CA 50",
        "k": "0",
        "c": "50",
        "code": "75.05.00.08"
    },
    {
        "id": 4395,
        "label": "CA 54.9",
        "k": "0",
        "c": "50",
        "code": "75.05.00.09"
    },
    {
        "id": 4396,
        "label": "CA 72.4",
        "k": "0",
        "c": "50",
        "code": "75.05.00.10"
    },
    {
        "id": 4397,
        "label": "MCA",
        "k": "0",
        "c": "50",
        "code": "75.05.00.11"
    },
    {
        "id": 4398,
        "label": "NSE",
        "k": "0",
        "c": "50",
        "code": "75.05.00.12"
    },
    {
        "id": 4399,
        "label": "PSA = SPA Ver Cód. 75.05.00.03",
        "k": "0",
        "c": "0",
        "code": "75.05.00.13"
    },
    {
        "id": 4400,
        "label": "Fosfatase ácida prostática - PAP",
        "k": "0",
        "c": "50",
        "code": "75.05.00.14"
    },
    {
        "id": 4401,
        "label": "Marcadores tumorais não incluidos nesta tabela",
        "k": "0",
        "c": "50",
        "code": "75.05.00.15"
    },
    {
        "id": 4402,
        "label": "PSA livre",
        "k": "0",
        "c": "50",
        "code": "75.05.00.16"
    },
    {
        "id": 4403,
        "label": "Ionograma (Na, K, Cl)",
        "k": "0",
        "c": "9",
        "code": "75.05.00.17"
    },
    {
        "id": 4404,
        "label": "Determinação Indirecta dos Cloretos pela Prova da placa (suor)",
        "k": "0",
        "c": "3",
        "code": "76.00.00.01"
    },
    {
        "id": 4405,
        "label": "Esperma-Ex.Macrosc. (Caract.Físicas, Coagulação-Liquefação e Volume)",
        "k": "0",
        "c": "10",
        "code": "76.00.00.02"
    },
    {
        "id": 4406,
        "label": "Esperma-Teste de Sims-Huhner (teste pós-coito)",
        "k": "0",
        "c": "9",
        "code": "76.00.00.03"
    },
    {
        "id": 4407,
        "label": "Espermograma (contagem, exame morfológico, motilidade)",
        "k": "0",
        "c": "20",
        "code": "76.00.00.04"
    },
    {
        "id": 4408,
        "label": "Imobilizinas-cada",
        "k": "0",
        "c": "15",
        "code": "76.00.00.05"
    },
    {
        "id": 4409,
        "label": "Líquido Amniótico (espectrofotometria do...)",
        "k": "0",
        "c": "10",
        "code": "76.00.00.06"
    },
    {
        "id": 4410,
        "label": "Líquido Amniótico (relação lecitina esfingomielina)",
        "k": "0",
        "c": "20",
        "code": "76.00.00.07"
    },
    {
        "id": 4411,
        "label": "Líquido Cérebro Espinal = Liquor (Ex.Macrosc.,Cont.de células)",
        "k": "0",
        "c": "12",
        "code": "76.00.00.08"
    },
    {
        "id": 4412,
        "label": "Líquido Pericardico, peritoneal ou pleural (ex. quimicos ou microbiológicos) ver secção respectiva",
        "k": "0",
        "c": "0",
        "code": "76.00.00.09"
    },
    {
        "id": 4413,
        "label": "Líquido pericárdico, peritoneal ou pleural (ex.macroscopico, ex.microscopico, cont cel.e cont.diferencial)",
        "k": "0",
        "c": "12",
        "code": "76.00.00.10"
    },
    {
        "id": 4414,
        "label": "Líquido Pericárdico Peritoneal pleural (Ex.Quim.+Microb.+Cel.cìif.)",
        "k": "0",
        "c": "30",
        "code": "76.00.00.11"
    },
    {
        "id": 4415,
        "label": "Líquido Sinovial (Ex.Macrosc.,Viscosidade e Test de Coagulação)",
        "k": "0",
        "c": "40",
        "code": "76.00.00.12"
    },
    {
        "id": 4416,
        "label": "Líquido Sinovial (Ex.Quimico, Imunológicos ou Microbiológicos)",
        "k": "0",
        "c": "30",
        "code": "76.00.00.13"
    },
    {
        "id": 4417,
        "label": "Mucopolisacáridos (pesquisa de )",
        "k": "0",
        "c": "5",
        "code": "76.00.00.14"
    },
    {
        "id": 4418,
        "label": "Razão Palmitica/Estearica",
        "k": "0",
        "c": "13",
        "code": "76.00.00.15"
    },
    {
        "id": 4419,
        "label": "Suco Gástrico e/ou Duodenal (Exame Macroscópico e Químico)",
        "k": "0",
        "c": "18",
        "code": "76.00.00.16"
    },
    {
        "id": 4420,
        "label": "Suco Gástrico-Prova de Estimulação pela Hipoglicemia induz. pela insulina",
        "k": "3",
        "c": "50",
        "code": "76.00.00.17"
    },
    {
        "id": 4421,
        "label": "Suco Gástrico-Prova de Estimulação pela Pentagastrina",
        "k": "3",
        "c": "55",
        "code": "76.00.00.18"
    },
    {
        "id": 4422,
        "label": "Suco Gástrico-Prova de Estimulação pelo Histalog",
        "k": "3",
        "c": "55",
        "code": "76.00.00.19"
    },
    {
        "id": 4423,
        "label": "Suor-Det. Cloretos ou Sódio no suor após Estim. por Iontof.c/Pilocarp.",
        "k": "1",
        "c": "20",
        "code": "76.00.00.20"
    },
    {
        "id": 4424,
        "label": "Deslocações domiciliárias urbanas",
        "k": "4",
        "c": "0",
        "code": "76.01.00.01"
    },
    {
        "id": 4425,
        "label": "Deslocações domiciliárias fora de área urbana+ 25%/litro gasolina super por Km",
        "k": "4",
        "c": "0",
        "code": "76.01.00.02"
    },
    {
        "id": 4426,
        "label": "Extracção do conteúdo gástrico (mais de uma colheita com uma única intubação)",
        "k": "9",
        "c": "0",
        "code": "76.01.00.03"
    },
    {
        "id": 4427,
        "label": "Colheita de faneras",
        "k": "1",
        "c": "0",
        "code": "76.01.00.04"
    },
    {
        "id": 4428,
        "label": "Punção óssea para extracção de medula",
        "k": "6",
        "c": "0",
        "code": "76.01.00.05"
    },
    {
        "id": 4429,
        "label": "Exsudados nasofaringeos (colheita)",
        "k": "2",
        "c": "0",
        "code": "76.01.00.06"
    },
    {
        "id": 4430,
        "label": "Exsudados purulentos superficiais (colheita)",
        "k": "1",
        "c": "0",
        "code": "76.01.00.07"
    },
    {
        "id": 4431,
        "label": "Exsudados vaginais e ureterais (colheita)",
        "k": "2",
        "c": "0",
        "code": "76.01.00.08"
    },
    {
        "id": 4432,
        "label": "Exames histológicos",
        "k": "10",
        "c": "20",
        "code": "80.00.00.01"
    },
    {
        "id": 4433,
        "label": "Exames cito-histológicos (exame citológico com inclusão)",
        "k": "10",
        "c": "20",
        "code": "80.00.00.02"
    },
    {
        "id": 4434,
        "label": "Exames citológicos",
        "k": "5",
        "c": "10",
        "code": "80.00.00.03"
    },
    {
        "id": 4435,
        "label": "Exames citohormonais por esfregaços seriados",
        "k": "10",
        "c": "20",
        "code": "80.00.00.04"
    },
    {
        "id": 4436,
        "label": "Exames histológicos extemporâneos per-operatórios",
        "k": "40",
        "c": "60",
        "code": "80.00.00.05"
    },
    {
        "id": 4437,
        "label": "Exames ultraestruturais (microscopia electrónica)",
        "k": "50",
        "c": "50",
        "code": "80.00.00.06"
    },
    {
        "id": 4438,
        "label": "Diagnóstico imuno-cito-químico",
        "k": "50",
        "c": "50",
        "code": "80.00.00.07"
    },
    {
        "id": 4439,
        "label": "Cariótipo de alta resoluçâo em fibro blastos",
        "k": "20",
        "c": "200",
        "code": "81.00.00.01"
    },
    {
        "id": 4440,
        "label": "Cariótipo de alta resolução em linfocitos com PHA",
        "k": "20",
        "c": "120",
        "code": "81.00.00.02"
    },
    {
        "id": 4441,
        "label": "Cariótipo de alta resolução em linfocitos sem PHA",
        "k": "20",
        "c": "130",
        "code": "81.00.00.03"
    },
    {
        "id": 4442,
        "label": "Cariótipo de células amnióticas",
        "k": "20",
        "c": "200",
        "code": "81.00.00.04"
    },
    {
        "id": 4443,
        "label": "Cariótipo de fibroblastos",
        "k": "0",
        "c": "150",
        "code": "81.00.00.05"
    },
    {
        "id": 4444,
        "label": "Cariótipo de linfócitos c/PHA",
        "k": "0",
        "c": "75",
        "code": "81.00.00.06"
    },
    {
        "id": 4445,
        "label": "Cariótipo de linfócitos s/PHA",
        "k": "0",
        "c": "85",
        "code": "81.00.00.07"
    },
    {
        "id": 4446,
        "label": "Cariótipo da medula óssea c/PHA",
        "k": "20",
        "c": "120",
        "code": "81.00.00.08"
    },
    {
        "id": 4447,
        "label": "Cariótipo da medula óssea s/PHA",
        "k": "20",
        "c": "130",
        "code": "81.00.00.09"
    },
    {
        "id": 4448,
        "label": "Cariótipo de meioses (Ver Cód. 81.00.00.17)",
        "k": "0",
        "c": "0",
        "code": "81.00.00.10"
    },
    {
        "id": 4449,
        "label": "Cariótipo de vilosidades coriónicas",
        "k": "20",
        "c": "250",
        "code": "81.00.00.11"
    },
    {
        "id": 4450,
        "label": "Conteúdo mediano de DNA nas células tumorais",
        "k": "0",
        "c": "20",
        "code": "81.00.00.12"
    },
    {
        "id": 4451,
        "label": "Cromatina sexual X ou Y no raspado lingual",
        "k": "0",
        "c": "8",
        "code": "81.00.00.13"
    },
    {
        "id": 4452,
        "label": "Cromatina sexual no ex. vaginal",
        "k": "0",
        "c": "8",
        "code": "81.00.00.14"
    },
    {
        "id": 4453,
        "label": "DNA em células tumorais ver conteúdo mediano de DNA (Ver Cód. 81.00.00.12)",
        "k": "0",
        "c": "0",
        "code": "81.00.00.15"
    },
    {
        "id": 4454,
        "label": "Estudo cromossómico ver cariótipo",
        "k": "0",
        "c": "0",
        "code": "81.00.00.16"
    },
    {
        "id": 4455,
        "label": "Estudo de meioses no esperma",
        "k": "0",
        "c": "75",
        "code": "81.00.00.17"
    },
    {
        "id": 4456,
        "label": "Estudo em biópsia testicular, pele, tecido de aborto",
        "k": "20",
        "c": "200",
        "code": "81.00.00.18"
    },
    {
        "id": 4457,
        "label": "Exame de marcha com registo gráfico",
        "k": "6",
        "c": "10",
        "code": "90.00.00.01"
    },
    {
        "id": 4458,
        "label": "Exame muscular com registo gráfico",
        "k": "6",
        "c": "10",
        "code": "90.00.00.02"
    },
    {
        "id": 4459,
        "label": "Raquimetria",
        "k": "6",
        "c": "10",
        "code": "90.00.00.03"
    },
    {
        "id": 4460,
        "label": "Electrodiagnóstico de estimulação",
        "k": "4",
        "c": "5",
        "code": "90.00.00.04"
    },
    {
        "id": 4461,
        "label": "Electromiografia (Ver Cód. 14.02)",
        "k": "0",
        "c": "0",
        "code": "90.00.00.05"
    },
    {
        "id": 4462,
        "label": "Ecotomografia das partes moles (Ver Cód. 62.00.00.25)",
        "k": "0",
        "c": "0",
        "code": "90.00.00.06"
    },
    {
        "id": 4463,
        "label": "Estudos urodinâmicos (Ver Cód. 16.)",
        "k": "0",
        "c": "0",
        "code": "90.00.00.07"
    },
    {
        "id": 4464,
        "label": "Provas Funcionais Respiratórias (Ver Cód. 10.01)",
        "k": "0",
        "c": "0",
        "code": "90.00.00.08"
    },
    {
        "id": 4465,
        "label": "Testes de Psicomotricidade",
        "k": "25",
        "c": "10",
        "code": "90.00.00.09"
    },
    {
        "id": 4466,
        "label": "Corrente contínua",
        "k": "1",
        "c": "1",
        "code": "90.01.00.01"
    },
    {
        "id": 4467,
        "label": "Corrente de baixa frequência",
        "k": "1",
        "c": "1",
        "code": "90.01.00.02"
    },
    {
        "id": 4468,
        "label": "Corrente de média frequência",
        "k": "1",
        "c": "1",
        "code": "90.01.00.03"
    },
    {
        "id": 4469,
        "label": "Corrente de alta frequência",
        "k": "1.5",
        "c": "2",
        "code": "90.01.00.04"
    },
    {
        "id": 4470,
        "label": "Ultra-som",
        "k": "1.5",
        "c": "2",
        "code": "90.01.00.05"
    },
    {
        "id": 4471,
        "label": "Estimulação eléctrica de pontos motores",
        "k": "1.5",
        "c": "2",
        "code": "90.01.00.06"
    },
    {
        "id": 4472,
        "label": "Magnetoterapia",
        "k": "1.5",
        "c": "2",
        "code": "90.01.00.07"
    },
    {
        "id": 4473,
        "label": "Biofeedback",
        "k": "2",
        "c": "3",
        "code": "90.01.00.08"
    },
    {
        "id": 4474,
        "label": "Raios infra-vermelhos",
        "k": "1",
        "c": "1",
        "code": "90.02.00.01"
    },
    {
        "id": 4475,
        "label": "Raios ultra-violetas",
        "k": "1",
        "c": "1",
        "code": "90.02.00.02"
    },
    {
        "id": 4476,
        "label": "Laserterapia de hélio-neon",
        "k": "1.5",
        "c": "2",
        "code": "90.02.00.03"
    },
    {
        "id": 4477,
        "label": "Laserterapia de raios infra-vermelhos",
        "k": "1.5",
        "c": "2",
        "code": "90.02.00.04"
    },
    {
        "id": 4478,
        "label": "Laserterapia de hélio-neon + raios infra-vermelhos",
        "k": "2",
        "c": "2",
        "code": "90.02.00.05"
    },
    {
        "id": 4479,
        "label": "Crioterapia",
        "k": "1",
        "c": "1",
        "code": "90.03.00.01"
    },
    {
        "id": 4480,
        "label": "Calor húmido",
        "k": "1",
        "c": "1",
        "code": "90.03.00.02"
    },
    {
        "id": 4481,
        "label": "Parafina",
        "k": "1",
        "c": "1.5",
        "code": "90.03.00.03"
    },
    {
        "id": 4482,
        "label": "Parafango",
        "k": "1",
        "c": "1.5",
        "code": "90.03.00.04"
    },
    {
        "id": 4483,
        "label": "Outros pelóides",
        "k": "1",
        "c": "1.5",
        "code": "90.03.00.05"
    },
    {
        "id": 4484,
        "label": "Hidrocinesiterapia",
        "k": "2.5",
        "c": "4",
        "code": "90.04.00.01"
    },
    {
        "id": 4485,
        "label": "Hidromassagem",
        "k": "1.5",
        "c": "4",
        "code": "90.04.00.02"
    },
    {
        "id": 4486,
        "label": "Banho de contraste",
        "k": "1",
        "c": "2",
        "code": "90.04.00.03"
    },
    {
        "id": 4487,
        "label": "Banho de turbilhão",
        "k": "1",
        "c": "2",
        "code": "90.04.00.04"
    },
    {
        "id": 4488,
        "label": "Banhos especiais",
        "k": "1",
        "c": "2",
        "code": "90.04.00.05"
    },
    {
        "id": 4489,
        "label": "Duches",
        "k": "1.5",
        "c": "3",
        "code": "90.04.00.06"
    },
    {
        "id": 4490,
        "label": "Tanque de hubbard",
        "k": "2",
        "c": "4",
        "code": "90.04.00.07"
    },
    {
        "id": 4491,
        "label": "Tanque de marcha",
        "k": "2",
        "c": "3",
        "code": "90.04.00.08"
    },
    {
        "id": 4492,
        "label": "Massagem manual de uma região",
        "k": "1.5",
        "c": "2",
        "code": "90.05.00.01"
    },
    {
        "id": 4493,
        "label": "Massagem manual de mais de uma região",
        "k": "2",
        "c": "2",
        "code": "90.05.00.02"
    },
    {
        "id": 4494,
        "label": "Massagem com técnicas especiais",
        "k": "2",
        "c": "2",
        "code": "90.05.00.03"
    },
    {
        "id": 4495,
        "label": "Massagem manual em imersão",
        "k": "2",
        "c": "2",
        "code": "90.05.00.04"
    },
    {
        "id": 4496,
        "label": "Vibromassagem",
        "k": "1",
        "c": "1",
        "code": "90.05.00.05"
    },
    {
        "id": 4497,
        "label": "Massagem com vácuo",
        "k": "1.5",
        "c": "1",
        "code": "90.05.00.06"
    },
    {
        "id": 4498,
        "label": "Cinesiterapia respiratória",
        "k": "2",
        "c": "3",
        "code": "90.06.00.01"
    },
    {
        "id": 4499,
        "label": "Cinésiterapia vertebral",
        "k": "2",
        "c": "2",
        "code": "90.06.00.02"
    },
    {
        "id": 4500,
        "label": "Cinesiterapia correctiva postural",
        "k": "2",
        "c": "2",
        "code": "90.06.00.03"
    },
    {
        "id": 4501,
        "label": "Cinesiterapia pré e pós parto",
        "k": "2",
        "c": "2",
        "code": "90.06.00.04"
    },
    {
        "id": 4502,
        "label": "Fortalecimento muscular manual",
        "k": "2",
        "c": "2",
        "code": "90.06.00.05"
    },
    {
        "id": 4503,
        "label": "Mobilização articular manual",
        "k": "1.5",
        "c": "2",
        "code": "90.06.00.06"
    },
    {
        "id": 4504,
        "label": "Técnicas especiais de Cinesiterapia",
        "k": "2",
        "c": "3",
        "code": "90.06.00.07"
    },
    {
        "id": 4505,
        "label": "Reeducação do equilíbrio e/ou marcha",
        "k": "2",
        "c": "2",
        "code": "90.06.00.08"
    },
    {
        "id": 4506,
        "label": "Qualquer destas modalidades terapêuticas quando feita em grupo (máximo de 6 doentes)",
        "k": "1",
        "c": "2",
        "code": "90.06.00.09"
    },
    {
        "id": 4507,
        "label": "Aerossóis",
        "k": "1",
        "c": "1",
        "code": "90.07.00.01"
    },
    {
        "id": 4508,
        "label": "Aerossóis ultra-sónicos",
        "k": "1.5",
        "c": "2",
        "code": "90.07.00.02"
    },
    {
        "id": 4509,
        "label": "IPPB",
        "k": "1.5",
        "c": "2",
        "code": "90.07.00.03"
    },
    {
        "id": 4510,
        "label": "Oxigenoterapia",
        "k": "1",
        "c": "1",
        "code": "90.07.00.04"
    },
    {
        "id": 4511,
        "label": "Tracção vertebral mecânica",
        "k": "1.5",
        "c": "1",
        "code": "90.08.00.01"
    },
    {
        "id": 4512,
        "label": "Tracção vertebral motorizada",
        "k": "1.5",
        "c": "2",
        "code": "90.08.00.02"
    },
    {
        "id": 4513,
        "label": "Pressões alternas positivas",
        "k": "1.5",
        "c": "2",
        "code": "90.08.00.03"
    },
    {
        "id": 4514,
        "label": "Pressões alternas positivas com monitorização contínua",
        "k": "2",
        "c": "5",
        "code": "90.08.00.04"
    },
    {
        "id": 4515,
        "label": "Fortalecimento muscular/mobilização articular",
        "k": "1.5",
        "c": "2",
        "code": "90.08.00.05"
    },
    {
        "id": 4516,
        "label": "Fortalecimento muscular/mobilização articular com monitorização contínua",
        "k": "5",
        "c": "5",
        "code": "90.08.00.06"
    },
    {
        "id": 4517,
        "label": "Fortalecimento muscular isocinético",
        "k": "5",
        "c": "5",
        "code": "90.08.00.07"
    },
    {
        "id": 4518,
        "label": "Uso de próteses",
        "k": "2",
        "c": "5",
        "code": "90.09.00.01"
    },
    {
        "id": 4519,
        "label": "Uso de ortóteses",
        "k": "2",
        "c": "5",
        "code": "90.09.00.02"
    },
    {
        "id": 4520,
        "label": "Actividades de vida diária",
        "k": "2",
        "c": "5",
        "code": "90.09.00.03"
    },
    {
        "id": 4521,
        "label": "Terapia ocupacional",
        "k": "2",
        "c": "5",
        "code": "90.09.00.04"
    },
    {
        "id": 4522,
        "label": "Terapia da fala/comunicação",
        "k": "2",
        "c": "5",
        "code": "90.09.00.05"
    },
    {
        "id": 4523,
        "label": "Readaptação ao esforço com monitorização contínua",
        "k": "6",
        "c": "5",
        "code": "90.09.00.06"
    },
    {
        "id": 4524,
        "label": "Manipulação vertebral",
        "k": "8",
        "c": "0",
        "code": "90.10.00.01"
    },
    {
        "id": 4525,
        "label": "Manipulação de membros",
        "k": "6",
        "c": "0",
        "code": "90.10.00.02"
    },
    {
        "id": 4526,
        "label": "Acupuntura",
        "k": "6",
        "c": "0",
        "code": "90.10.00.03"
    },
    {
        "id": 4527,
        "label": "Infiltração",
        "k": "6",
        "c": "0",
        "code": "90.10.00.04"
    },
    {
        "id": 4528,
        "label": "Mesoterapia",
        "k": "6",
        "c": "0",
        "code": "90.10.00.05"
    },
    {
        "id": 4529,
        "label": "Estimulação transcutânea",
        "k": "5",
        "c": "0",
        "code": "90.10.00.06"
    },
    {
        "id": 4530,
        "label": "Confecção de ligadura funcional",
        "k": "7",
        "c": "0",
        "code": "90.10.00.07"
    },
    {
        "id": 4531,
        "label": "Confecção de ortóteses",
        "k": "7",
        "c": "0",
        "code": "90.10.00.08"
    }
];