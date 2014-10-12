$(document).ready(function () {
    checkValidNIF();
    checkValidDate();

    $("#entitytype").change(function () {
        $.each(nif, function (i, v) {
            $(this).val("");
            $(this).removeAttr('style');
        });
        $.each(niferror, function (i, v) {
            $(this).text("")
        });
    });
});

var checkValidNIF = function () {
    var nifRegex = new RegExp('\\d{9}');
    var nif = $('#nifEntity, #nifPrivate');
    var niferror = $("#niferrorEntity, #niferrorPrivate");

    nif.bind("paste drop input change cut", function () {
        var text = $(this).val();

        if (text.length != 9 || isNaN(text) || !nifRegex.test(text)) {
            $(this).css('border', '1px solid red');
            disableSubmission();

            $.each(niferror, function (i, v) {
                $(this).text("Formato inválido")
            });

            if (text.length == 0) {
                enableSubmission();
                $(this).removeAttr('style');
                $.each(niferror, function (i, v) {
                    $(this).text("")
                });
            }
        } else {
            $.each(niferror, function (i, v) {
                $(this).text("")
            });
            $(this).css('border', '1px solid green');
            enableSubmission();
        }
    });
};

var checkValidDate = function () {
    $("#contractstart, #contractend").change(function () {
        var contractstart = $("#contractstart").val();
        var contractend = $("#contractend").val();
        var contracts = $("#contractstart, #contractend");

        if (contractend <= contractstart) {
            disableSubmission();
            $("#dateerror").text("Data incoerentes");
            $.each(contracts, function (e) {
                $(this).css('border', '1px solid red');
            })

            if (contractstart.length == 0 || contractend.length == 0) {
                $("#dateerror").text("");
                $.each(contracts, function (e) {
                    $(this).removeAttr('style');
                })
            }
        }
        else {
            $("#dateerror").text("");
            enableSubmission();

            if (contractstart.length > 0 && contractend.length > 0) {
                $.each(contracts, function (e) {
                    $(this).css('border', '1px solid green');
                })
            }
        }
    });
};

var disableSubmission = function() {
    $("#submitButton").attr("disabled", true);
}

var enableSubmission = function() {
    $("#submitButton").attr("disabled", false);
}