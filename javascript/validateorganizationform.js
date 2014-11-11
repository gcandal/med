const submitButton = $("#submitButton");
const errorMessage = $("#errorMessage");
const organizationName = $('#name');

$(document).ready(function () {
    checkIfNameIsFreeListener();

    if(!isEdit)
        isInvalid("Nome é obrigatório");
    else
        isValid();
});

var checkIfNameIsFreeListener = function () {
    organizationName.bind("paste drop input change cut", function () {
        var text = organizationName.val();

        if (text.length > 0)
            $.get(baseUrl + 'actions/organizations/checkorganizationname.php?name=' + text, function (data) {
                if (data['exists'])
                    return isInvalid("Este nome já está a ser usado");
                else
                    return isValid();
            });
        else if(!isEdit)
            isInvalid("Nome é obrigatório");
        else
            isValid();
    });
};

var isInvalid = function(errorText) {
    submitButton.attr("disabled", true);
    organizationName.css('border', '1px solid red');
    errorMessage.text(errorText);

    return false;
};

var isValid = function() {
    submitButton.attr("disabled", false);
    organizationName.css('border', '1px solid green');
    errorMessage.text("");

    return true;
};