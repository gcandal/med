var subProcedures = 0;
var valuePerK = $('#valuePerK');
var anesthetistRemun = $('#anesthetistRemun');
var totalRemun = $('#totalRemun');
var totalType = $('#totalType');
var payerType = $("#payerType");
var newPrivatePayer = $("#newPrivatePayer");
var idPayer = $('#idPayer');
var generalRemun = $("#generalRemun");
var firstAssistantRemun = $('#firstAssistantRemun');
var firstAssistantName = $('#firstAssistantName');
var secondAssistantRemun = $('#secondAssistantRemun');
var secondAssistantName = $('#secondAssistantName');
var instrumentistRemun = $('#instrumentistRemun');
var instrumentistName = $('#instrumentistName');
var anesthetistName = $('#anesthetistName');
var anesthetistK = $('#anesthetistK');
var generalK = $('#generalK');
var nSubProcedures = $('#nSubProcedures');
var submitButton = $("#submitButton");
var role = $('#role');
var idPatient = $("#idPatient");
var localAnesthesia = $("#localanesthesia");
var anesthetistRow = $("#AnesthetistRow");
var patientForm = $("#patientForm");
var namePatient = $("#namePatient");
var nifPatient = $("#nifPatient");
var namePrivate = $("#namePrivate");
var cellphonePatient = $("#cellphonePatient");
var beneficiaryNrPatient = $("#beneficiaryNrPatient");
var errorMessageNifPatient = $("#errorMessageNifPatient");
var errorMessageNamePatient = $("#errorMessageNamePatient");
var errorMessageCellphonePatient = $("#errorMessageCellphonePatient");
var errorMessageNamePrivate = $('#errorMessageNamePrivate');
var subProcedureTemplate = Handlebars.compile($('#subProcedure-template').html());

//Defined in separate file
var subProceduresList;
var subProceduresList2;

var enableField = function (field, disable) {
    field.prop('readonly', disable);
    if (disable)
        field.css('background-color', "lightgrey");
    else
        field.css('background-color', "");
};

$(document).ready(function () {
    $('#addSubProcedure').click(function (e) {
        e.preventDefault();
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

    idPayer.change(function () {
        updatePayerVisibility();
        updateRemunerations();
    });
    updatePayerVisibility();

    idPatient.change(function () {
        updatePatientInfo();
    });
    updatePatientInfo();

    localAnesthesia.change(function () {
        disableAnesthetistRow(localAnesthesia.prop("checked"));
        fillInstrumentistRemuneration();
        fillGeneralRemuneration();
    });
    disableAnesthetistRow(localAnesthesia.prop("checked"));

    fillProfessionalRow(role.val());
    role.change(function () {
        fillProfessionalRow($(this).val());
    });

    var subProcedures = $("#subProcedures");
    subProcedures.on('change', '.subProcedure', function () {
        fillSubProcedure($(this));
    });

    subProcedures.on('click', '.removeSubProcedureButton', function (e) {
        e.preventDefault();
        removeSubProcedure($(this).parent().parent().parent().attr("id").split("subProcedure")[1]);
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
        idPayer.val(editProcedurePayerId);
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
    } else {
        editValuePerK = 0;
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
                    licenseid: item['licenseid']
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

var fillSubProcedure = function (selectField) {
    selectField.parent().parent().siblings().eq(3).children().children().last().val(selectField.find(":selected").text());
    selectField.parent().parent().siblings().eq(1).children().children().last().val(subProceduresList[selectField.val() - 1].k);
    selectField.parent().parent().siblings().eq(2).children().children().last().val(subProceduresList[selectField.val() - 1].c);
    selectField.parent().parent().siblings().eq(0).children().children().last().val(subProceduresList[selectField.val() - 1].code);

    updateRemunerations();
};

var disableAnesthetistRow = function (disable) {
    if (disable) {
        anesthetistName.val("");
        anesthetistRow.hide();
    } else anesthetistRow.show();

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
    //$(".subProcedure").hide();

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

    var selectField = newSubP.children().first().children().children().last();
    selectField.val(id);
    fillSubProcedure(selectField);

    addNSubProcedureById(id, n - 1);
};

var updatePatientInfo = function () {
    var id = idPatient.val();

    switch (id) {
        //Novo
        case "-2":
            disablePatientForm(false);
            erasePatientForm();

            break;
        //Nenhum
        case "-1":
            disablePatientForm(true);
            erasePatientForm();

            break;
        //Já existente
        default:
            fillPatientForm(id);
            disablePatientForm(true);

            break;
    }

    checkSubmitButton();
};

var disablePatientForm = function (disable) {
    patientForm.find("input").attr("disabled", disable);

    disablePatientValidations(disable);
};

var disablePatientValidations = function (disable) {
    if (disable) {
        errorMessageNifPatient.parent().hide();
        errorMessageNamePatient.parent().hide();
        errorMessageCellphonePatient.parent().hide();
        errorMessageNifPatient.text("");
        errorMessageNamePatient.text("");
        errorMessageCellphonePatient.text("");
        patientForm.find("input").css("border", "");
    } else {
        isInvalidPatient(namePatient, "Nome obrigatório", errorMessageNamePatient);
        isValidPatient(nifPatient, errorMessageNifPatient);
        isValidPatient(cellphonePatient, errorMessageCellphonePatient);
    }
};

var disablePayerValidations = function(disable) {
    if (disable) {
        errorMessageNamePrivate.parent().hide();
        errorMessageNamePrivate.text("");
        newPrivatePayer.find("input").css("border", "");
    } else {
        isInvalidPayer(namePrivate, "Nome obrigatório", errorMessageNamePrivate);
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
        case 'none':
            curreantPayerValuePerK = 0;
            break;
        default:
            break;
    }

    valuePerK.val(curreantPayerValuePerK);

    if (curreantPayerValuePerK === 0) {
        if(editValuePerK > 0)
            valuePerK.val(editValuePerK);
        else
            enableField(valuePerK, false);
    }

};

var getPrivateValuePerK = function () {
    for (var i = 0; i < privatePayers.length; i++) {
        if (privatePayers[i].idprivatepayer == idPayer.val()) {
            if (isNumeric(privatePayers[i].valueperk)) {
                return privatePayers[i].valueperk;
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
    switch (idPayer.val()) {
        case 'NewPrivate':
            console.log("novo")
            disablePayerValidations(false);
            newPrivatePayer.show();

            enableField(valuePerK, false);
            fillValuePerK('none');
            payerType.val("NewPrivate");

            checkSubmitButton();
            break;
        default:
            console.log("velho")
            disablePayerValidations(true);
            newPrivatePayer.hide();

            enableField(valuePerK, true);
            fillValuePerK('private');
            payerType.val("Private");

            checkSubmitButton();
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
    return $('.errorMessage').text() === '';
};

var checkSubmitButton = function () {
    submitButton.attr('disabled', !noErrorMessages());
};

$(document).on("focus", ".subProcedureName:not(.ui-autocomplete-input)", function () {
    $(this).autocomplete({
        source: subProceduresList,
        select: function (event, ui) {
            if (ui.item) {
                var selectField = $(this).parent().parent().siblings().eq(0).children().children();
                selectField.val(ui.item.id);
                fillSubProcedure(selectField);
            }
        }
    });
}).on("focus", ".subProcedureCode:not(.ui-autocomplete-input)", function () {
    $(this).autocomplete({
        source: function (request, response) {
            response(subProceduresList.filter(function (e) {
                return new RegExp('^' + request.term).test(e.code);
            }));
        },
        select: function (event, ui) {
            if (ui.item) {
                var selectField = $(this).parent().parent().siblings().eq(0).children().children();
                selectField.val(ui.item.id);
                fillSubProcedure(selectField);
            }
        }
    });
});
