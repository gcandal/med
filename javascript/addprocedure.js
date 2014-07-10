$(document).ready(function () {
    updatePayerVisibility();
    updateFunctionVisibility();

    $("select#entityType").change(function () {
        updatePayerVisibility();
    });

    $("select#function").change(function () {
        updateFunctionVisibility();
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
    if ($('[name=firstAssistantName]').val() != "") {
        console.log("1a inserted");
        return true;
    } else {
        console.log("1a removed");
        return false;
    }
};

var thereIsASecondAssistant = function () {
    if ($('[name=secondAssistantName]').val() != "") {
        console.log("2a inserted");
        return true;
    } else {
        console.log("2a removed");
        return false;
    }
};

var thereIsAnInstrumentist = function () {
    if ($('[name=instrumentistName]').val() != "") {
        console.log("ins inserted");
        return true;
    } else {
        console.log("ins removed");
        return false;
    }
};

var thereIsAnAnesthetist = function () {
    if ($('[name=anesthetistName]').val() != "") {
        console.log("ins inserted");
        return true;
    } else {
        console.log("ins removed");
        return false;
    }
};
