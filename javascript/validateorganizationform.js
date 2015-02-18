var submitButton = $("#submitButton");
var errorMessage = $("#errorMessage");
var organizationName = $('#name');

$(document).ready(function () {
    organizationName.bind("paste drop input change cut", function () {
        checkIfNameIsFreeListener();
    });
    checkIfNameIsFreeListener();
});

var checkIfNameIsFreeListener = function () {
    var text = organizationName.val();

    if (text.length > 0)
        $.get(baseUrl + 'actions/organizations/checkorganizationname.php?name=' + text, function (data) {
            if (data['exists'])
                return isInvalid("Este nome já está a ser usado");
            else
                return isValid();
        });
    else if (!isEdit)
        isInvalid("Nome é obrigatório");
    else
        isValid();
};

var isInvalid = function (errorText) {
    submitButton.attr("disabled", true);
    organizationName.css('border', '1px solid red');
    errorMessage.text(errorText);
    errorMessage.parent().show();

    return false;
};

var isValid = function () {
    submitButton.attr("disabled", false);
    organizationName.css('border', '1px solid green');
    errorMessage.text("");
    errorMessage.parent().hide();

    return true;
};