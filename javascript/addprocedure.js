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

    $("select#entityType").change(function () {
        updatePayerVisibility();
    });

    $("#subProcedures").on('change', '.subProcedure', function () {
        calculateTotalK();
    });

    $("select#function").change(function () {
        updateFunctionVisibility();
    });

    $('[name=valuePerK]').bind("paste drop input change cut", function () {
        calculateTotalK();
    });

    $('[name=firstAssistantName]').bind("paste drop input change cut", function () {
        thereIsAFirstAssistant();
    });

    $('[name=secondAssistantName]').bind("paste drop input change cut", function () {
        thereIsASecondAssistant();
    });

    $('[name=instrumentistName]').bind("paste drop input change cut", function () {
        thereIsAnInstrumentist();
    });

    $('[name=anesthetistName]').bind("paste drop input change cut", function () {
        thereIsAnAnesthetist();
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
    calculateTotalK();
};

var removeSubProcedure = function () {
    if (subProcedures > 1) {
        $('#subProcedures br:last').remove();
        $('#subProcedures select:last').remove();
        subProcedures--;
    }
    calculateTotalK();
};

var calculateTotalK = function () {
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
    total *= $('[name=valuePerK]').val();
    $('input[name=totalRemun]').val(total);

};

var updatePayerVisibility = function () {
    switch ($("select#entityType").val()) {
        case 'Privado':
            $("span#privatePayer").show();
            $("span#entityPayer").hide();
            break;
        case 'Entidade':
            $("span#privatePayer").hide();
            $("span#entityPayer").show();
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

