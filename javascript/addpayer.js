const formEntidade = $("#formentidade");
const formPrivado = $("#formprivado");
const entityTypeInput = $("#entityTypeInput");
const entityType = $('#entityType');
const isEdit = false;
const errorMessageNifPrivate = $('#errorMessageNifPrivate');
const errorMessageNamePrivate = $('#errorMessageNamePrivate');
const errorMessageNifEntity = $('#errorMessageNifEntity');
const errorMessageNameEntity = $('#errorMessageNameEntity');
const errorMessageDate = $('#errorMessageDate');
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
            formEntidade.hide();
            errorMessageNifEntity.hide();
            errorMessageNameEntity.hide();
            errorMessageDate.hide();
            errorMessageNifPrivate.show();
            errorMessageNamePrivate.show();
            formPrivado.show();
            break;
        case 'NewEntity':
            errorMessageName = errorMessageNameEntity;
            errorMessageNif = errorMessageNifEntity;
            formPrivado.hide();
            formEntidade.show();
            errorMessageNifEntity.show();
            errorMessageNameEntity.show();
            errorMessageDate.show();
            errorMessageNifPrivate.hide();
            errorMessageNamePrivate.hide();

            if($("#entityType option:selected").text() === 'Hospital')
                entityTypeInput.val("Hospital");
            else
                entityTypeInput.val("Insurance");
            break;
        default:
            errorMessageNifEntity.hide();
            errorMessageNameEntity.hide();
            errorMessageDate.hide();
            errorMessageNifPrivate.hide();
            errorMessageNamePrivate.hide();
            break;
    }
};