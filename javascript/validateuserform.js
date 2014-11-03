const password1 = $('#password');
const password2 = $('#passwordconfirm');
const passwords = $('#password, #passwordconfirm');
const userName = $('#userName');
const email = $('#email');
const licenseId = $('#licenseId');
const submitButton = $("#submitButton");
const errorMessageUserName = $('#userNameError');
const errorMessageEmail = $('#emailError');
const errorMessagePassword = $('#passwordError');
const errorMessageLicenseId = $('#licenseIdError');

$(document).ready(function () {
    checkEqualPasswords();
    checkValidName();
    checkValidEmail();
    checkValidLicenseId();

    if (isEdit) {
        isValid(passwords, errorMessagePassword);
        isValid(userName, errorMessageUserName);
        isValid(email, errorMessageEmail);
        isValid(licenseId, errorMessageLicenseId);
    }
    else {
        isInvalid(passwords, "Passwords são obrigatórias", errorMessagePassword);
        isInvalid(userName, "Username é obrigatório", errorMessageUserName);
        isInvalid(email, "Email é obrigatório", errorMessageEmail);
        isInvalid(licenseId, "Cédula é obrigatório", errorMessageLicenseId);
    }
});

var checkEqualPasswords = function () {
    passwords.bind("paste drop input change cut", function () {
        var textpassword1 = password1.val();
        var textpassword2 = password2.val();

        if (textpassword1 !== textpassword2)
            return isInvalid(passwords, "Passwords não coincidem", errorMessagePassword);

        if (!isEdit && textpassword1.length == 0 && textpassword2.length == 0)
            return isInvalid(passwords, "Passwords são obrigatórias", errorMessagePassword);

        return isValid(passwords, errorMessagePassword);
    });
};

var checkValidName = function () {
    userName.bind("paste drop input change cut", function () {
        var textUserName = userName.val();

        if (!isEdit && textUserName.length == 0)
            return isInvalid($(this), "Username é obrigatório", errorMessageUserName);

        return isValid($(this), errorMessageUserName);
    });
};

var checkValidEmail = function () {
    email.bind("paste drop input change cut", function () {
        var textEmail = email.val();

        if (!isEdit && textEmail.length == 0)
            return isInvalid($(this), "Email é obrigatório", errorMessageEmail);

        return isValid($(this), errorMessageEmail);
    });
};

var checkValidLicenseId = function () {
    licenseId.bind("paste drop input change cut", function () {
        var textLicenseId = licenseId.val();

        if (!isEdit && textLicenseId.length == 0)
            return isInvalid($(this), "Cédula é obrigatório", errorMessageLicenseId);
        else if (isNaN(textLicenseId))
            return isInvalid($(this), "Cédula inválida", errorMessageLicenseId);

        isValid($(this), errorMessageLicenseId);
    });
};

var isInvalid = function (field, errorText, errorField) {
    field.css('border', '1px solid red');
    errorField.text(errorText);

    submitButton.attr("disabled", true);

    return false;
};

var isValid = function (field, errorField) {
    field.css('border', '1px solid green');
    errorField.text("");

    submitButton.attr("disabled", false);

    return true;
};