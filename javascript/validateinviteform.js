$(document).ready(function () {
    checkIfInviteUnsent();
});

var checkIfInviteUnsent = function () {
    var licenseid = $('#licenseid');
    var licenseiderror = $('#licenseiderror');

    licenseid.bind("paste drop input change cut", function () {
        var text = licenseid.val();
        var idorganization = $("#idorganization").val();

        if (text.length < 1 || isNaN(text)) {
            licenseid.removeAttr('style');
            licenseiderror.text("Formato inválido");

            if (text.length == 0)
                licenseiderror.text("");

            return;
        } else
            licenseiderror.text("");


        $.get(baseUrl + 'actions/organizations/checkinvitationsent.php?licenseid=' + text + '&idorganization=' + idorganization, function (data) {
            if (data['exists'])
                licenseid.css('border', '1px solid red');
            else
                licenseid.css('border', '1px solid green');
        });
    });
};