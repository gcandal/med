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
const principal = $("#principal");
const ajudante = $("#ajudante");
const namePrivate = $("#namePrivate");
const nifPrivate = $("#nifPrivate");
const nameEntity = $("#nameEntity");
const nifEntity = $("#nifEntity");
const personalRemun = $("#personalRemun");
const firstAssistantRemun = $('#firstAssistantRemun');
const firstAssistantName = $('#firstAssistantName');
const secondAssistantRemun = $('#secondAssistantRemun');
const secondAssistantName = $('#secondAssistantName');
const instrumentistRemun = $('#instrumentistRemun');
const instrumentistName = $('#instrumentistName');
const anesthetistName = $('#anesthetistName');
const anesthetistK = $('#anesthetistK');
const nSubProcedures = $('#nSubProcedures');
const submitButton = $("#submitButton");
const subProcedureTemplate = Handlebars.compile($('#subProcedure-template').html());

var enableField = function (field, disable) {
    field.prop('readonly', disable);
    if (disable)
        field.css('background-color', "lightgrey");
    else
        field.css('background-color', "");
    //field.prop('disabled', disable);
};

$(document).ready(function () {
    updatePayerVisibility();
    updateFunctionVisibility();

    $('#addSubProcedure').click(function () {
        addSubProcedure();
    });

    totalType.change(function () {
        if (totalType.val() == 'auto') {
            enableField(totalRemun, true);

            getTotalRemuneration();
            fillFirstAssistantRemuneration();
            fillSecondAssistantRemuneration();
            fillInstrumentistRemuneration();
            fillAnesthetistRemuneration();
            adjustPersonalRemuneration();
        } else {
            enableField(totalRemun, false);
        }
    });

    totalRemun.bind("paste drop input change cut", function () {
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    entityType.change(function () {
        updatePayerVisibility();
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    $("#entityName").change(function () {
        updatePayerVisibility();
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    $("#privateName").change(function () {
        updatePayerVisibility();
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    const subProcedures = $("#subProcedures");
    subProcedures.on('change', '.subProcedure', function () {
        getTotalRemuneration();
        adjustPersonalRemuneration();
    });

    subProcedures.on('click', '.removeSubProcedureButton', function (e) {
        e.preventDefault();
        removeSubProcedure($(this).parent().attr("id").split("subProcedure")[1]);
    });

    $("select#function").change(function () {
        updateFunctionVisibility();
    });

    valuePerK.bind("paste drop input change cut", function () {
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    firstAssistantName.bind("paste drop input change cut", function () {
        fillFirstAssistantRemuneration();
        adjustPersonalRemuneration();
    });

    secondAssistantName.bind("paste drop input change cut", function () {
        fillSecondAssistantRemuneration();
        adjustPersonalRemuneration();
    });

    instrumentistName.bind("paste drop input change cut", function () {
        fillInstrumentistRemuneration();
        adjustPersonalRemuneration();
    });

    anesthetistName.bind("paste drop input change cut", function () {
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    anesthetistK.change(function () {
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });


    $('.professionalName').autocomplete({
        source: function (request, response) {
            $.ajax({
                url: baseUrl + "actions/professionals/getrecentprofessionals.php",
                dataType: "json",
                data: {speciality: 'any', name: request.term},
                type: 'GET',
                success: function (data) {
                    response($.map(data, function (item) {
                        return {
                            label: item.name,
                            nif: item['nif'],
                            licenseid: item['licenseid'],
                            idspeciality: item['idspeciality'],
                            id: item['idprofessional']
                        };
                    }));
                },
                error: function (a, b, c) {
                    console.log(a);
                    console.log(b);
                    console.log(c);
                }
            });
        },
        minLength: 3,
        select: function (event, ui) {
            if (ui.item) {
                $(this).parent().siblings().first().next().next().next().children().first().val(ui.item.idspeciality);
                $(this).parent().siblings().first().next().children().first().val(ui.item.licenseid);
                $(this).parent().siblings().first().next().next().children().first().val(ui.item.nif);
            }
        }
    });
});

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

    getTotalRemuneration();
    fillFirstAssistantRemuneration();
    fillSecondAssistantRemuneration();
    fillInstrumentistRemuneration();
    fillAnesthetistRemuneration();
    adjustPersonalRemuneration();
};

var fillValuePerK = function (type) {
    var valueperk;
    switch (type) {
        case 'private':
            valuePerK.val(getPrivateValuePerK());
            break;
        case 'entity':
            valuePerK.val(getEntityValuePerK());
            break;
        case 'none':
            valueperk = 0;
            valuePerK.val(0);
            break;
        default:
            break;
    }

    if(isNaN(valueperk))
        return 0;
    else
        return valueperk;
};

var getPrivateValuePerK = function () {
    for (var i = 0; i < privatePayers.length; i++) {
        if (privatePayers[i].idprivatepayer == $('[name=privateName]').val()) {
            if (isNumeric(privatePayers[i].valueperk)) {
                submitButton.attr('disabled', false);
                return privatePayers[i].valueperk;
            }

        }
    }

    submitButton.attr('disabled', true);

    return 'Valor Indefinido. Edite Privado.';
};

var getEntityValuePerK = function () {
    for (var i = 0; i < entityPayers.length; i++) {
        if (entityPayers[i].identitypayer == $('[name=entityName]').val()) {
            if (isNumeric(entityPayers[i].valueperk)) {
                submitButton.attr('disabled', false);
                return entityPayers[i].valueperk;
            }
        }
    }

    submitButton.attr('disabled', true);

    return 'Valor Indefinido. Edite Entidade.';
};

var adjustPersonalRemuneration = function () {
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

    personalRemun.val(total);
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
    subProcedures--;
    nSubProcedures.val(subProcedures);
    getTotalRemuneration();
    adjustPersonalRemuneration();
};

var getTotalRemuneration = function () {
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

            submitButton.attr('disabled', false);

            fillValuePerK('private');
            payerType.val("Private");
            break;
        case 'Entity':
            privatePayer.hide();
            entityPayer.show();
            newEntityPayer.hide();
            newPrivatePayer.hide();

            enableField(valuePerK, true);
            submitButton.attr('disabled', false);

            fillValuePerK('entity');
            payerType.val("Entity");
            break;
        case 'NewPrivate':
            privatePayer.hide();
            entityPayer.hide();
            newEntityPayer.hide();
            newPrivatePayer.show();

            enableField(valuePerK, false);
            checkSubmitButton();

            fillValuePerK('none');
            payerType.val("NewPrivate");
            break;
        case 'NewEntity':
            privatePayer.hide();
            entityPayer.hide();
            newEntityPayer.show();
            newPrivatePayer.hide();

            enableField(valuePerK, false);
            checkSubmitButton();

            fillValuePerK('none');
            payerType.val("NewEntity");
            break;
        default:
            break;
    }
};

var updateFunctionVisibility = function () {
    switch ($("select#function").val()) {
        case 'Principal':
            principal.show();
            ajudante.hide();
            enableField(personalRemun, true);
            break;
        case 'Ajudante':
        case 'Anestesista':
            principal.hide();
            ajudante.show();
            enableField(personalRemun, false);
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

var noErrorMessages = function() {
    return $('.errorMessage, .errorMessage'+payerType.val().slice(3)).text() === '';
};

var checkSubmitButton = function() {
    submitButton.attr('disabled', !noErrorMessages());
};