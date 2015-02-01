const nif = $('#nifEntity, #nifPrivate');
const nifRegex = new RegExp('^\\d{9}$');
const namePayer = $('#nameEntity, #namePrivate');
const contracts = $("#contractstart, #contractend");
const submitButtonPrivate = $("#submitButtonPrivate, #submitButton");
const submitButtonEntity = $("#submitButtonEntity, #submitButton");

if (typeof errorMessageNifPrivate === 'undefined') {
    var errorMessageNifPrivate = $('#errorMessageNifPrivate');
}
if (typeof errorMessageNamePrivate === 'undefined') {
    var errorMessageNamePrivate = $('#errorMessageNamePrivate');
}
if (typeof errorMessageNifEntity === 'undefined') {
    var errorMessageNifEntity = $('#errorMessageNifEntity');
}
if (typeof errorMessageNameEntity === 'undefined') {
    var errorMessageNameEntity = $('#errorMessageNameEntity');
}
if (typeof errorMessageDate === 'undefined') {
    var errorMessageDate = $('#errorMessageDate');
}
if (typeof entityType === 'undefined') {
    var entityType = $('#entityType');

    if (entityType.val() == 'NewPrivate') {
        errorMessageName = errorMessageNamePrivate;
        errorMessageNif = errorMessageNifPrivate;
    }
    else {
        errorMessageName = errorMessageNameEntity;
        errorMessageNif = errorMessageNifEntity;
    }
}

if (typeof checkSubmitButton === 'undefined') {
    var noErrorMessages = function () {
        return $(".errorMessage" + entityType.val().slice(3)).text().length == 0;
    };

    var checkSubmitButton = function () {
        if (entityType.val() === 'NewPrivate')
            submitButtonPrivate.attr('disabled', !noErrorMessages());
        else
            submitButtonEntity.attr('disabled', !noErrorMessages());
    };
}

$(document).ready(function () {
    namePayer.bind("paste drop input change cut", function () {
        checkValidName($(this));
    });

    nif.bind("paste drop input change cut", function () {
        checkValidNIF($(this));
    });

    contracts.change(function () {
        checkValidDate();
    });

    if (!isEdit) {
        isValidPayer(nif, errorMessageNifPrivate);
        isValidPayer(nif, errorMessageNifEntity);
        isInvalidPayer(namePayer, "Nome obrigatório", errorMessageNamePrivate);
        isInvalidPayer(namePayer, "Nome obrigatório", errorMessageNameEntity);
    } else {
        isValidPayer(nif, errorMessageNifPrivate);
        isValidPayer(namePayer, errorMessageNamePrivate);
        isValidPayer(contracts, errorMessageDate);
        isValidPayer(nif, errorMessageNifEntity);
        isValidPayer(namePayer, errorMessageNameEntity);
    }
});

var checkValidNIF = function (field) {
    var text = field.val();

    if (!isEdit && (isNaN(text) || !nifRegex.test(text)))
        return isInvalidPayer(field, "NIF inválido", errorMessageNif);
    else if (text.length > 0 && (isNaN(text) || !nifRegex.test(text))) {
        return isInvalidPayer(field, "NIF inválido", errorMessageNif);
    }
    else {
        return isValidPayer(field, errorMessageNif);
    }
};

var checkValidName = function (field) {
    var text = field.val();

    if (!isEdit && text.length == 0) {
        return isInvalidPayer(field, "Nome obrigatório", errorMessageName);
    } else {
        return isValidPayer(field, errorMessageName);
    }
};

var checkValidDate = function () {
    var contractstart = $("#contractstart").val();
    var contractend = $("#contractend").val();

    if (contractstart.length != 0 && contractend.length != 0 && contractend < contractstart)
        return isInvalidPayer(contracts, "Datas incoerentes", errorMessageDate);

    return isValidPayer(contracts, errorMessageDate);
};

var isInvalidPayer = function (field, errorText, errorField) {
    field.css('border', '1px solid red');
    errorField.text(errorText);
    updateFormVisibility();

    checkSubmitButton();
};

var isValidPayer = function (field, errorField) {
    field.css('border', '1px solid green');
    errorField.text("");
    errorField.parent().hide();


    checkSubmitButton();
};