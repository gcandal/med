const cellphoneRegex = new RegExp('^((\\+|00)\\d{1,3})?\\d{9}$');
if (typeof nifRegex === 'undefined')
    var nifRegex = new RegExp('^\\d{9}$');
if (typeof nifPatient === 'undefined')
    var nifPatient = $('#nifPatient');
if (typeof namePatient === 'undefined')
    var namePatient = $('#namePatient');
if (typeof cellphonePatient === 'undefined')
    var cellphonePatient = $('#cellphonePatient');
if (typeof submitButton === 'undefined') {
    var submitButton = $("#submitButton");
    var errorMessageNifPatient = $("#errorMessageNifPatient");
    var errorMessageNamePatient = $("#errorMessageNamePatient");
    var errorMessageCellphonePatient = $("#errorMessageCellphonePatient");
}


if (typeof checkSubmitButton === 'undefined') {
    var noErrorMessages = function () {
        return $(".errorMessage").text().length == 0;
    };

    var checkSubmitButton = function () {
        submitButton.attr('disabled', !noErrorMessages());
    };
}

$(document).ready(function () {
    namePatient.bind("paste drop input change cut", function () {
        checkValidName($(this));
    });

    nifPatient.bind("paste drop input change cut", function () {
        checkValidNIF($(this));
    });

    cellphonePatient.bind("paste drop input change cut", function () {
        checkValidCellphone($(this));
    });

    if (typeof method === "undefined") {
        if (!isEdit) {
            isInvalidPatient(namePatient, "Nome obrigatório", errorMessageNamePatient);
        } else {
            isValidPatient(namePatient, errorMessageNamePatient);
        }

        isValidPatient(nifPatient, errorMessageNifPatient);
        isValidPatient(cellphonePatient, errorMessageCellphonePatient);
    }
});

var checkValidNIF = function (field) {
    var text = field.val();

    if (!isEdit && (isNaN(text) || !nifRegex.test(text)))
        return isInvalidPatient(field, "NIF inválido", errorMessageNifPatient);
    else if (text.length > 0 && (isNaN(text) || !nifRegex.test(text))) {
        return isInvalidPatient(field, "NIF inválido", errorMessageNifPatient);
    }
    else {
        return isValidPatient(field, errorMessageNifPatient);
    }
};

var checkValidName = function (field) {
    var text = field.val();

    if (!isEdit && text.length == 0) {
        return isInvalidPatient(field, "Nome obrigatório", errorMessageNamePatient);
    } else {
        return isValidPatient(field, errorMessageNamePatient);
    }
};

var checkValidCellphone = function (field) {
    var text = field.val();

    if (!isEdit && !cellphoneRegex.test(text))
        return isInvalidPatient(field, "Telefone inválido", errorMessageCellphonePatient);
    else if (text.length > 0 && !cellphoneRegex.test(text)) {
        return isInvalidPatient(field, "Telefone inválido", errorMessageCellphonePatient);
    }
    else {
        return isValidPatient(field, errorMessageCellphonePatient);
    }
};

var isInvalidPatient = function (field, errorText, errorField) {
    field.css('border', '1px solid red');
    errorField.text(errorText);
    errorField.parent().show();

    checkSubmitButton();
};

var isValidPatient = function (field, errorField) {
    field.css('border', '1px solid green');
    errorField.text("");
    errorField.parent().hide();

    checkSubmitButton();
};