const nameProfessional = $('.professionalName');
const nifProfessional = $('.professionalNif');
const licenseIdProfessional = $('.professionalLicenseId');
if (typeof submitButton === 'undefined')
    var submitButton = $("#submitButton");
var professionalNifRegex = new RegExp('\\d{9}');
const errorMessageNameProfessional = $('#errorMessageNameProfessional');
const errorMessageNifProfessional = $('#errorMessageNifProfessional');
const errorMessageLicenseIdProfessional = $('#errorMessageLicenseIdProfessional');


if (typeof checkSubmitButton === 'undefined') {
    var noErrorMessages = function() {
        return $(".errorMessage").text().length == 0;
    };

    var checkSubmitButton = function() {
        submitButton.attr('disabled', !noErrorMessages());
    };
}

$(document).ready(function () {
    checkValidNameProfessional();
    checkValidNIFProfessional();
    checkValidLicenseIdProfessional();
    isValid(nifProfessional, errorMessageNifProfessional);
    isValid(licenseIdProfessional, errorMessageLicenseIdProfessional);

    if (method !== "addProfessional" && method !== "editProfessional") {
        isValid(nameProfessional, errorMessageNameProfessional);
    }
    else {
        isInvalid(nameProfessional, "Nome é obrigatório", errorMessageNameProfessional);
    }
});

var checkValidNameProfessional = function () {
    nameProfessional.bind("paste drop input change cut", function () {
        var textName = $(this).val();

        if ( (method === "addProfessional" || method === "editProfessional" ) && textName.length == 0)
            return isInvalid($(this), "Nome é obrigatório", errorMessageNameProfessional);

        return isValid($(this), errorMessageNameProfessional);
    });
};

var checkValidNIFProfessional = function () {
    nifProfessional.bind("paste drop input change cut", function () {
        var text = $(this).val();

        if (text.length > 0 && (isNaN(text) || !professionalNifRegex.test(text))) {
            return isInvalid($(this), "NIF inválido", errorMessageNifProfessional);
        }
        else {
            return isValid($(this), errorMessageNifProfessional);
        }
    });
};

var checkValidLicenseIdProfessional = function () {
    licenseIdProfessional.bind("paste drop input change cut", function () {
        var textLicenseId = $(this).val();

        if (isNaN(textLicenseId))
            return isInvalid($(this), "Cédula inválida", errorMessageLicenseIdProfessional);

        isValid($(this), errorMessageLicenseIdProfessional);
    });
};

var isInvalid = function (field, errorText, errorField) {
    field.css('border', '1px solid red');
    errorField.text(errorText);

    checkSubmitButton();

    return false;
};

var isValid = function (field, errorField) {
    field.css('border', '1px solid green');
    errorField.text("");

    checkSubmitButton();

    return true;
};
