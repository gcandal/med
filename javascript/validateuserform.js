var password1 = $('#password');
var password2 = $('#passwordconfirm');
var passwords = $('#password, #passwordconfirm');
var userName = $('#userName');
var email = $('#email');
var licenseId = $('#licenseId');
var submitButton = $("#submitButton");
var errorMessageUserName = $('#userNameError');
var errorMessageEmail = $('#emailError');
var errorMessagePassword = $('#passwordError');
var errorMessageLicenseId = $('#licenseIdError');

$(document).ready(function () {
    userName.bind("paste drop input change cut", function () {
        checkValidName($(this));
    });
    checkValidName(userName);
    passwords.bind("paste drop input change cut", function () {
        checkEqualPasswords();
    });
    checkEqualPasswords();
    email.bind("paste drop input change cut", function () {
        checkValidEmail($(this));
    });
    checkValidEmail(email);
    licenseId.bind("paste drop input change cut", function () {
        checkValidLicenseId($(this));
    });
    checkValidLicenseId(licenseId);
});

var checkEqualPasswords = function () {
    var textpassword1 = password1.val();
    var textpassword2 = password2.val();

    if (textpassword1 !== textpassword2)
        return isInvalid(passwords, "Passwords não coincidem", errorMessagePassword);

    if (!isEdit && textpassword1.length == 0 && textpassword2.length == 0)
        return isInvalid(passwords, "Passwords são obrigatórias", errorMessagePassword);

    return isValid(passwords, errorMessagePassword);
};

var checkValidName = function (field) {
    var textUserName = userName.val();

    if (!isEdit && textUserName.length == 0)
        return isInvalid(field, "Username é obrigatório", errorMessageUserName);

    return isValid(field, errorMessageUserName);
};

var checkValidEmail = function (field) {
    var textEmail = email.val();

    if (!isEdit && textEmail.length == 0)
        return isInvalid(field, "Email é obrigatório", errorMessageEmail);

    return isValid(field, errorMessageEmail);
};

var checkValidLicenseId = function (field) {
    var textLicenseId = licenseId.val();

    if (!isEdit && textLicenseId.length == 0)
        return isInvalid(field, "Cédula é obrigatório", errorMessageLicenseId);
    else if (isNaN(textLicenseId))
        return isInvalid(field, "Cédula inválida", errorMessageLicenseId);

    isValid(field, errorMessageLicenseId);
};

var isInvalid = function (field, errorText, errorField) {
    field.css('border', '1px solid red');
    errorField.text(errorText);
    errorField.parent().show();
    submitButton.attr("disabled", true);

    return false;
};

var isValid = function (field, errorField) {
    field.css('border', '1px solid green');
    errorField.text("");
    errorField.parent().hide();
    submitButton.attr("disabled", false);

    return true;
};