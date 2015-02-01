const idorganization = $("#idorganization").val();
const errorMessage = $('#licenseIdError');
const submitButton = $('#submitButton');
const licenseid = $('#licenseid');

$(document).ready(function () {
    checkIfInviteUnsent();

    isInvalid("Cédula obrigatória");
});

var checkIfInviteUnsent = function () {
    licenseid.bind("paste drop input change cut", function () {
        var text = licenseid.val();

        if (isNaN(text))
            return isInvalid("Cédula inválida");
        else if (text.length == 0)
            return isInvalid("Cédula obrigatória");
        else
            isValid();


        $.get(baseUrl + 'actions/organizations/checkinvitationsent.php?licenseid=' + text + '&idorganization=' + idorganization, function (data) {
            if (data['exists'])
                isInvalid('Já enviou um convite para essa cédula');
            else
                isValid();
        });
    });
};

var isInvalid = function (errorText) {
    submitButton.attr("disabled", true);
    licenseid.css('border', '1px solid red');
    errorMessage.text(errorText);
    errorMessage.parent().show();

    return false;
};

var isValid = function () {
    submitButton.attr("disabled", false);
    licenseid.css('border', '1px solid green');
    errorMessage.text("");
    errorMessage.parent().hide();

    return true;
};