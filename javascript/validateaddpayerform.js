const nif = $('#nifEntity, #nifPrivate');
const contracts = $("#contractstart, #contractend");
const submitButton = $("#submitButtonPrivate, #submitButtonEntity");
const errorMessageNif = $("#errorMessageNif");
const errorMessageDate = $("#errorMessageDate");

$(document).ready(function () {
    checkValidNIF();
    checkValidDate();

    isInvalid(nif, "NIF inválido", errorMessageNif);
    isValid(contracts, errorMessageDate);
});

var checkValidNIF = function () {
    var nifRegex = new RegExp('\\d{9}');

    nif.bind("paste drop input change cut", function () {
        var text = $(this).val();

        if (text.length != 9 || isNaN(text) || !nifRegex.test(text)) {
            return isInvalid($(this), "NIF inválido", errorMessageNif);
        } else {
            return isValid($(this), errorMessageNif);
        }
    });
};

var checkValidDate = function () {
    contracts.change(function () {
        var contractstart = $("#contractstart").val();
        var contractend = $("#contractend").val();

        if (contractstart.length == 0 || contractend.length == 0 || contractend >= contractstart)
            isValid(contracts, errorMessageDate);
        else
            isInvalid(contracts, "Datas incoerentes", errorMessageDate);
    });
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