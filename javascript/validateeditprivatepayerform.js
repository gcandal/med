$(document).ready(function () {
    checkValidNIF();
});

var checkValidNIF = function () {
    var nifRegex = new RegExp('\\d{9}');
    var niferror = $("#niferrorPrivate");
    var nif = $('#nifPrivate');

    nif.bind("paste drop input change cut", function () {
        var text = nif.val();
        if (text.length != 9 || isNaN(text) || !nifRegex.test(text)) {
            $(this).css('border', '1px solid red');
            niferror.text("Formato inválido");

            if (text.length == 0) {
                $(this).removeAttr('style');
                niferror.text("");
            }
        } else {
            niferror.text("");
            $(this).css('border', '1px solid green');
        }
    });
};