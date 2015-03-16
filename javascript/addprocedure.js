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
var kValues = $(".kValue");
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

    if (isReadOnly)
        return;

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

    kValues.change(function () {
        updateRemunerations();
    });

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
                minLength: 1,
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

var subProcedureTypes = [];
var getSubProcedureTypes = function () {
    if (subProcedureTypes.length > 0)
        return subProcedureTypes;

    var result = "";
    for (var i = 0; i < subProceduresList.length; i++) {
        result += '<option value = "' + subProceduresList[i].id + '">' + subProceduresList[i].label + '</option>';
    }

    subProcedureTypes = result;
    return result;
};

var addSubProcedureCallback = function(subProcedure) {
    subProcedure.on("paste drop input change cut", (function() {
        var before = "01.00.00.01";

        return function() {
            var text = $(this).val();

            if(text.length > 11)
                $(this).val(text.slice(0, 11));

            if (before.length < text.length && (text.length == 2 || text.length == 5 || text.length == 8) )
                $(this).val(text + '.');
            else if (before.length > text.length && text[text.length - 1] == '.')
                $(this).val(text.slice(0, text.length - 1));
            else if (before.length < text.length && (text.length == 3 || text.length == 6 || text.length == 9))
                $(this).val(text.slice(0, text.length - 1) + '.' + text.slice(text.length - 1));

            if (text[text.length - 1] == '.')
                before = text.slice(0, text.length - 1);
            else
                before = text;
        }
    })());
};

var addSubProcedure = function () {
    nSubProcedures.val(++subProcedures);
    $(subProcedureTemplate({number: subProcedures, type: getSubProcedureTypes()}))
        .fadeIn('slow').appendTo('#subProcedures');

    addSubProcedureCallback($("#subProcedures .subProcedure:last-child .subProcedureCode").last());
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
    if(disable)
        patientForm.hide();
    else
        patientForm.show();

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

var disablePayerValidations = function (disable) {
    if (disable) {
        errorMessageNamePrivate.parent().hide();
        errorMessageNamePrivate.text("");
        newPrivatePayer.find("input").css("border", "");
    } else {
        errorMessageNamePrivate.parent().show();
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
        if (editValuePerK > 0)
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
    const roles = ['#general', '#firstAssistant', '#secondAssistant', '#anesthetist', '#instrumentist'];

    fillTotalRemuneration();
    const total = totalRemun.val();

    roles.forEach(function(role) {
        console.log(role);
        console.log(total);
        console.log($(role + "Remun").val());
        console.log($(role + "K").val());
        console.log($(role + "K").val());
        if($(role + "Name").val() !== '')
            $(role + "Remun").val(total * $(role + "K").val() / 100.0);
        else
            $(role + "Remun").val(0);
    });

    /*
    fillFirstAssistantRemuneration();
    fillSecondAssistantRemuneration();
    fillInstrumentistRemuneration();
    fillAnesthetistRemuneration();
    fillGeneralRemuneration();
    */
};


/*
        switch (anesthetistK.val()) {
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
        */

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
                for (var i = 0; i < subProceduresList.length; i++) {
                    if ($(this).val() == subProceduresList[i].id) {
                        total = total + parseInt(subProceduresList[i].k);
                    }
                }
            });
        }
        total *= valuePerK.val();
        totalRemun.val(total);
    }
};

var updatePayerVisibility = function () {
    switch (idPayer.val()) {
        case 'NewPrivate':
            disablePayerValidations(false);
            newPrivatePayer.show();

            enableField(valuePerK, false);
            fillValuePerK('none');
            payerType.val("NewPrivate");

            checkSubmitButton();
            break;
        default:
            disablePayerValidations(true);
            newPrivatePayer.hide();

            enableField(valuePerK, true);
            fillValuePerK('private');
            payerType.val("Private");

            checkSubmitButton();
            break;
    }
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
            response(subProceduresList2.filter(function (e) {
                return new RegExp('^' + request.term).test(e.label);
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
