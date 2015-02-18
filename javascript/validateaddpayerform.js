const nif = $('#nifEntity, #nifPrivate');
const contracts = $("#contractstart, #contractend");
const submitButton = $("#submitButtonPrivate, #submitButtonEntity");
const errorMessageNif = $("#errorMessageNif");
const errorMessageDate = $("#errorMessageDate");

$(document).ready(function () {
    nif.bind("paste drop input change cut", function () {
        checkValidNIF($(this));
    });
    checkValidNIF();
    contracts.change(function () {
        checkValidDate();
    });
    checkValidDate();
});

var checkValidNIF = function (field) {
    var nifRegex = new RegExp('^\\d{9}$');

    var text = field.val();

    if (text.length != 9 || isNaN(text) || !nifRegex.test(text)) {
        return isInvalid(field, "NIF inválido", errorMessageNif);
    } else {
        return isValid(field, errorMessageNif);
    }
};

var checkValidDate = function () {
    var contractstart = $("#contractstart").val();
    var contractend = $("#contractend").val();

    if (contractstart.length == 0 || contractend.length == 0 || contractend >= contractstart)
        isValid(contracts, errorMessageDate);
    else
        isInvalid(contracts, "Datas incoerentes", errorMessageDate);
};

var isInvalid = function (field, errorText, errorFieldText) {
    submitButton.attr("disabled", true);
    field.css('border', '1px solid red');
    errorFieldText.text(errorText);

    return false;
};

var isValid = function (field, errorFieldText) {
    submitButton.attr("disabled", false);
    field.css('border', '1px solid green');
    errorFieldText.text("");

    return true;
};