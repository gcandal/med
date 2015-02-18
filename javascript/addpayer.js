var formEntidade = $("#formentidade");
var formPrivado = $("#formprivado");
var entityTypeInput = $("#entityTypeInput");
var entityType = $('#entityType');
var isEdit = false;
var errorMessageNifPrivate = $('#errorMessageNifPrivate');
var errorMessageNamePrivate = $('#errorMessageNamePrivate');
var errorMessageNifEntity = $('#errorMessageNifEntity');
var errorMessageNameEntity = $('#errorMessageNameEntity');
var errorMessageDate = $('#errorMessageDate');
var errorMessageName;
var errorMessageNif;

$(document).ready(function () {
    updateFormVisibility();

    entityType.change(function () {
        updateFormVisibility();
    });
});

var updateFormVisibility = function () {
    switch (entityType.val()) {
        case 'NewPrivate':
            errorMessageName = errorMessageNamePrivate;
            errorMessageNif = errorMessageNifPrivate;
            checkSubmitButton();
            formEntidade.hide();

            errorMessageNifEntity.parent().hide();
            errorMessageNameEntity.parent().hide();
            errorMessageDate.parent().hide();
            showIfHasText(errorMessageNifPrivate);
            showIfHasText(errorMessageNamePrivate);
            formPrivado.show();
            break;
        case 'NewEntity':
            errorMessageName = errorMessageNameEntity;
            errorMessageNif = errorMessageNifEntity;
            checkSubmitButton();
            formPrivado.hide();
            formEntidade.show();

            errorMessageNamePrivate.parent().hide();
            errorMessageNifPrivate.parent().hide();
            showIfHasText(errorMessageNifEntity);
            showIfHasText(errorMessageNameEntity);
            showIfHasText(errorMessageDate);

            if ($("#entityType option:selected").text() === 'Hospital')
                entityTypeInput.val("Hospital");
            else
                entityTypeInput.val("Insurance");
            break;
        default:
            errorMessageNifEntity.parent().hide();
            errorMessageNameEntity.parent().hide();
            errorMessageDate.parent().hide();
            errorMessageNifPrivate.parent().hide();
            errorMessageNamePrivate.parent().hide();
            break;
    }
};

var showIfHasText = function (field) {
    if (field.text() !== "")
        field.parent().show();
};