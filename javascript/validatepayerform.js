var namePayer = $('#namePrivate');
var submitButton = $("#submitButton");
if (typeof errorMessageNamePrivate === 'undefined') {
    var errorMessageNamePrivate = $('#errorMessageNamePrivate');
}
if (typeof isEdit === 'undefined') {
    var isEdit = false;
}
if (typeof checkSubmitButton === 'undefined') {
    var noErrorMessages = function () {
        return $(".errorMessagePrivate").text().length == 0;
    };

    var checkSubmitButton = function () {
        submitButton.attr('disabled', !noErrorMessages());
    };
}

$(document).ready(function () {
    namePayer.bind("paste drop input change cut", function () {
        checkValidPayerName($(this));
    });

    if (typeof method === "undefined") {
        checkValidPayerName(namePayer);
    }
});

var checkValidPayerName = function (field) {
    var text = field.val();

    if (!isEdit && text.length == 0) {
        return isInvalidPayer(field, "Nome obrigatório", errorMessageNamePrivate);
    } else {
        return isValidPayer(field, errorMessageNamePrivate);
    }
};

var isInvalidPayer = function (field, errorText, errorField) {
    field.css('border', '1px solid red');
    errorField.text(errorText);

    checkSubmitButton();
};

var isValidPayer = function (field, errorField) {
    field.css('border', '1px solid green');
    errorField.text("");
    errorField.parent().hide();


    checkSubmitButton();
};