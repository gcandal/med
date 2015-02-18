const nameProfessional = $('.professionalName');
const nifProfessional = $('.professionalNif');
const licenseIdProfessional = $('.professionalLicenseId');
if (typeof submitButton === 'undefined')
    var submitButton = $("#submitButton");
var professionalNifRegex = new RegExp('^\\d{9}$');
const errorMessageNameProfessional = $('#errorMessageNameProfessional');
const errorMessageNifProfessional = $('#errorMessageNifProfessional');
const errorMessageLicenseIdProfessional = $('#errorMessageLicenseIdProfessional');


if (typeof checkSubmitButton === 'undefined') {
    var noErrorMessages = function () {
        return $(".errorMessage").text().length == 0;
    };

    var checkSubmitButton = function () {
        submitButton.attr('disabled', !noErrorMessages());
    };
}

$(document).ready(function () {
    nameProfessional.bind("paste drop input change cut", function () {
        checkValidNameProfessional($(this));
    });
    checkValidNameProfessional(nameProfessional);
    nifProfessional.bind("paste drop input change cut", function () {
        checkValidNIFProfessional($(this));
    });
    checkValidNIFProfessional(nifProfessional);
    licenseIdProfessional.bind("paste drop input change cut", function () {
        checkValidLicenseIdProfessional($(this));
    });
    checkValidLicenseIdProfessional(licenseIdProfessional);
});

var checkValidNameProfessional = function (field) {
    var textName = field.val();

    if ((method === "addProfessional" || method === "editProfessional" ) && textName.length == 0)
        return isInvalid(field, "Nome é obrigatório", errorMessageNameProfessional);

    return isValid(field, errorMessageNameProfessional);
};

var checkValidNIFProfessional = function (field) {
    var text = field.val();

    if (text.length > 0 && (isNaN(text) || !professionalNifRegex.test(text))) {
        return isInvalid(field, "NIF inválido", errorMessageNifProfessional);
    }
    else {
        return isValid(field, errorMessageNifProfessional);
    }
};

var checkValidLicenseIdProfessional = function (field) {
    var textLicenseId = field.val();

    if (isNaN(textLicenseId))
        return isInvalid(field, "Cédula inválida", errorMessageLicenseIdProfessional);

    isValid(field, errorMessageLicenseIdProfessional);
};

var isInvalid = function (field, errorText, errorField) {
    field.css('border', '1px solid red');
    errorField.text(errorText);
    errorField.parent().show();

    checkSubmitButton();

    return false;
};

var isValid = function (field, errorField) {
    field.css('border', '1px solid green');
    errorField.text("");
    errorField.parent().hide();

    checkSubmitButton();

    return true;
};
