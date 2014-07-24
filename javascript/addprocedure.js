$(document).ready(function () {
    updatePayerVisibility();
    updateFunctionVisibility();
    addSubProcedure();

    $('#addSubProcedure').click(function () {
        subProcedures++;
        addSubProcedure();
        $('#nSubProcedures').value = subProcedures;
    });

    $('#removeSubProcedure').click(function () {
        removeSubProcedure();
        $('#nSubProcedures').value = subProcedures;
    });

    $('[name=totalType]').change(function () {
        if ($('[name=totalType]').val() == 'auto') {
            $("[name=totalRemun]").prop('readonly', true);
        } else {
            $("[name=totalRemun]").prop('readonly', false);
        }
    });

    $('[name=totalRemun]').bind("paste drop input change cut", function () {
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    $("select#entityType").change(function () {
        updatePayerVisibility();
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    $("select[name=entityName]").change(function () {
        updatePayerVisibility();
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    $("select[name=privateName]").change(function () {
        updatePayerVisibility();
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    $("#subProcedures").on('change', '.subProcedure', function () {
        getTotalRemuneration();
        adjustPersonalRemuneration();
    });

    $("select#function").change(function () {
        updateFunctionVisibility();
    });

    $('[name=valuePerK]').bind("paste drop input change cut", function () {
        getTotalRemuneration();
        fillFirstAssistantRemuneration();
        fillSecondAssistantRemuneration();
        fillInstrumentistRemuneration();
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    $('[name=firstAssistantName]').bind("paste drop input change cut", function () {
        fillFirstAssistantRemuneration();
        adjustPersonalRemuneration();
    });

    $('[name=secondAssistantName]').bind("paste drop input change cut", function () {
        fillSecondAssistantRemuneration();
        adjustPersonalRemuneration();
    });

    $('[name=instrumentistName]').bind("paste drop input change cut", function () {
        fillInstrumentistRemuneration();
        adjustPersonalRemuneration();
    });

    $('[name=anesthetistName]').bind("paste drop input change cut", function () {
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });

    $('#anesthetistK').change(function () {
        fillAnesthetistRemuneration();
        adjustPersonalRemuneration();
    });


    $('#principal table tr:not(:first-child) td:first-child input').autocomplete({
        source: function( request, response ) {
            $.ajax({
                url: baseUrl + "actions/procedures/getrecentprofessionals.php",
                dataType: "json",
                data: {speciality: 'any', name: request.term},
                type: 'GET',
                success: function(data) {
                    response($.map(data, function(item) {
                        return {
                            label: item.name,
                            nif: item['nif'],
                            id: item['idprofessional']
                        };
                    }));
                },
                error: function(a, b, c) {
                    console.log(a);
                    console.log(b);
                    console.log(c);
                }
            });
        },
        minLength: 3,
        select: function(event, ui) {
            if(ui.item) {
                $(this).parent().siblings().first().next().children().first().val(ui.item.nif);
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
    $('<select name="subProcedure' + subProcedures + '" class="subProcedure">' + getSubProcedureTypes() +
        '</select><br>').fadeIn('slow').appendTo('#subProcedures');
    getTotalRemuneration();
    fillFirstAssistantRemuneration();
    fillSecondAssistantRemuneration();
    fillInstrumentistRemuneration();
    fillAnesthetistRemuneration();
    adjustPersonalRemuneration();

};

var fillValuePerK = function (type) {
    switch (type) {
        case 'private':
            $('[name=valuePerK]').val(getPrivateValuePerK());
            break;
        case 'entity':
            $('[name=valuePerK]').val(getEntityValuePerK());
            break;
        case 'none':
            $('[name=valuePerK]').val(0);
            break;
        default:
            break;
    }
};

var getPrivateValuePerK = function () {
    var oneChosen = false;
    for (var i = 0; i < privatePayers.length; i++) {
        if (privatePayers[i].idprivatepayer == $('[name=privateName]').val()) {
            if (isNumeric(privatePayers[i].valueperk))
                return privatePayers[i].valueperk;
        }
    }
    return 'Valor Indefinido. Edite Privado.';
};

var getEntityValuePerK = function () {
    var oneChosen = false;
    for (var i = 0; i < entityPayers.length; i++) {
        if (entityPayers[i].identitypayer == $('[name=entityName]').val()) {
            if (isNumeric(entityPayers[i].valueperk))
                return entityPayers[i].valueperk;
        }
    }
    return 'Valor Indefinido. Edite Entidade.';
};

var adjustPersonalRemuneration = function () {
    var total = $('[name=totalRemun]').val();

    if (thereIsAFirstAssistant()) {
        total -= $('[name=firstAssistantRemun]').val();

    }
    if (thereIsASecondAssistant()) {
        total -= $('[name=secondAssistantRemun]').val();

    }
    if (thereIsAnInstrumentist()) {
        total -= $('[name=instrumentistRemun]').val();

    }
    if (thereIsAnAnesthetist()) {
        total -= $('[name=anesthetistRemun]').val();
    }

    $('[name=personalRemun]').val(total);
};

var fillFirstAssistantRemuneration = function () {
    if (thereIsAFirstAssistant()) {
        var remun = $('[name=totalRemun]').val() * 0.2;
        $('[name=firstAssistantRemun]').val(remun);
    } else {
        $('[name=firstAssistantRemun]').val(0);
    }
};

var fillSecondAssistantRemuneration = function () {
    if (thereIsASecondAssistant()) {
        var remun = $('[name=totalRemun]').val() * 0.1;
        $('[name=secondAssistantRemun]').val(remun);
    } else {
        $('[name=secondAssistantRemun]').val(0);
        $('[name=secondAssistantRemun]').val(0);
    }
};

var fillInstrumentistRemuneration = function () {
    if (thereIsAnInstrumentist()) {
        var remun = $('[name=totalRemun]').val() * 0.1;
        $('[name=instrumentistRemun]').val(remun);
    } else {
        $('[name=instrumentistRemun]').val(0);
    }
};

var fillAnesthetistRemuneration = function () {
    if (thereIsAnAnesthetist()) {
        var percentage;
        switch ($('#anesthetistK').val()) {
            case "25":
                var remun = $('[name=totalRemun]').val() * 0.25;
                break;
            case "30":
                var remun = $('[name=totalRemun]').val() * 0.30;
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

                var remun = k * $('input[name=valuePerK]').val();
                break;
        }
        $('[name=anesthetistRemun]').val(remun);
    } else {
        $('[name=anesthetistRemun]').val(0);
    }
};

var removeSubProcedure = function () {
    if (subProcedures > 1) {
        $('#subProcedures br:last').remove();
        $('#subProcedures select:last').remove();
        subProcedures--;
    }
    getTotalRemuneration();
    adjustPersonalRemuneration();
};

var getTotalRemuneration = function () {
    if ($('[name=totalType]').val() == 'auto') {
        var total = 0.0;

        if (isNumeric($('input[name=valuePerK]').val())) {
            $('.subProcedure').each(function () {
                for (var i = 0; i < subProcedureTypes.length; i++) {
                    if ($(this).val() == subProcedureTypes[i].idproceduretype) {
                        total = total + parseInt(subProcedureTypes[i].k);
                        console.log("Tipo:" + subProcedureTypes[i].idproceduretype + "; K: " + subProcedureTypes[i].k);
                    }
                }
            });
        }
        console.log("Total de K: " + total);
        total *= $('[name=valuePerK]').val();
        console.log("Total Remun: " + total);
        $('input[name=totalRemun]').val(total);
    }
};


function getTotalK() {
    var total = 0;

    if (isNumeric($('input[name=valuePerK]').val())) {
        $('.subProcedure').each(function () {
            for (var i = 0; i < subProcedureTypes.length; i++) {
                if ($(this).val() == subProcedureTypes[i].idproceduretype) {
                    total += subProcedureTypes[i].k;
                }
            }
        });
    }
    return total;
}

var updatePayerVisibility = function () {
    var payerType = $("#payerType");

    switch ($("select#entityType").val()) {
        case 'Privado':
            $("span#privatePayer").show();
            $("span#entityPayer").hide();
            $("span#newEntityPayer").hide();
            $("span#newPrivatePayer").hide();
            $("[name=valuePerK]").prop('readonly', true);
            fillValuePerK('private');
            payerType.val("None");
            break;
        case 'Entidade':
            $("span#privatePayer").hide();
            $("span#entityPayer").show();
            $("span#newEntityPayer").hide();
            $("span#newPrivatePayer").hide();
            $("[name=valuePerK]").prop('readonly', true);
            fillValuePerK('entity');
            payerType.val("None");
            break;
        case 'Novo Privado':
            $("span#privatePayer").hide();
            $("span#entityPayer").hide();
            $("span#newEntityPayer").hide();
            $("span#newPrivatePayer").show();
            $("[name=valuePerK]").prop('readonly', false);
            fillValuePerK('none');
            payerType.val("Private");
            break;
        case 'Nova Entidade':
            $("span#privatePayer").hide();
            $("span#entityPayer").hide();
            $("span#newEntityPayer").show();
            $("span#newPrivatePayer").hide();
            $("[name=valuePerK]").prop('readonly', false);
            fillValuePerK('none');
            payerType.val("Insurance");
            break;
        default:
            break;
    }
};

var updateFunctionVisibility = function () {
    switch ($("select#function").val()) {
        case 'Principal':
            $("span#principal").show();
            $("span#ajudante").hide();
            break;
        case 'Ajudante':
        case 'Anestesista':
            $("span#principal").hide();
            $("span#ajudante").show();
            break;
        default:
            break;
    }
};

var thereIsAFirstAssistant = function () {
    return $('[name=firstAssistantName]').val() != "";
};

var thereIsASecondAssistant = function () {
    return $('[name=secondAssistantName]').val() != "";
};

var thereIsAnInstrumentist = function () {
    return $('[name=instrumentistName]').val() != "";
};

var thereIsAnAnesthetist = function () {
    return $('[name=anesthetistName]').val() != "";
};

var isNumeric = function (n) {
    return !isNaN(parseFloat(n)) && isFinite(n);
};

