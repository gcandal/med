const nif = $('#nifEntity, #nifPrivate');
const nifRegex = new RegExp('\\d{9}');
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

    if(entityType.val()=='NewPrivate') {
        errorMessageName = $('#errorMessageNamePrivate');
        errorMessageNif = $('#errorMessageNifPrivate');
    }
    else {
        errorMessageName = $('#errorMessageNameEntity');
        errorMessageNif = $('#errorMessageNifEntity');
    }

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
        isInvalid(nif, "NIF inválido", errorMessageNifEntity);
        isInvalid(nif, "NIF inválido", errorMessageNifPrivate);
        isInvalid(namePayer, "Nome obrigatório", errorMessageNamePrivate);
        isInvalid(namePayer, "Nome obrigatório", errorMessageNameEntity);
    } else {
        if (entityType.val() === 'Private') {
            isValid(nif, errorMessageNifPrivate);
            isValid(namePayer, errorMessageNamePrivate);
        } else {
            isValid(contracts, errorMessageDate);
            isValid(nif, errorMessageNifEntity);
            isValid(namePayer, errorMessageNameEntity);
        }
    }
});

var checkValidNIF = function (field) {
    var text = field.val();

    if (!isEdit && (isNaN(text) || !nifRegex.test(text)))
        return isInvalid(field, "NIF inválido", errorMessageNif);
    else if (text.length > 0 && (isNaN(text) || !nifRegex.test(text))) {
        return isInvalid(field, "NIF inválido", errorMessageNif);
    }
    else {
        return isValid(field, errorMessageNif);
    }
};

var checkValidName = function (field) {
    var text = field.val();

    if (!isEdit && text.length == 0) {
        return isInvalid(field, "Nome obrigatório", errorMessageName);
    } else {
        return isValid(field, errorMessageName);
    }
};

var checkValidDate = function () {
    var contractstart = $("#contractstart").val();
    var contractend = $("#contractend").val();

    if (contractstart.length != 0 && contractend.length != 0 && contractend < contractstart)
        return isInvalid(contracts, "Datas incoerentes", errorMessageDate);

    return isValid(contracts, errorMessageDate);
};

var isInvalid = function (field, errorText, errorField) {
    field.css('border', '1px solid red');
    errorField.text(errorText);

    if (entityType.val() === 'NewPrivate')
        submitButtonPrivate.attr("disabled", true);
    else
        submitButtonEntity.attr("disabled", true);

    return false;
};

var isValid = function (field, errorField) {
    if(field !== null && errorField !== null) {
        field.css('border', '1px solid green');
        errorField.text("");
    }


    if (entityType.val() === 'NewPrivate') {
        if(errorMessageName.text().length == 0 && errorMessageNif.text().length == 0) {
            submitButtonPrivate.attr("disabled", false);

            return true;
        }
        else {
            submitButtonPrivate.attr("disabled", true);

            return false;
        }
    }
    else {
        if(errorMessageName.text().length == 0 && errorMessageNif.text().length == 0
            && errorMessageDate.text().length == 0) {
            submitButtonEntity.attr("disabled", false);

            return true;
        }
        else {
            submitButtonPrivate.attr("disabled", true);

            return false;
        }
    }
};