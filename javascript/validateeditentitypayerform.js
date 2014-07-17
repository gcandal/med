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
    var niferror = $("#niferrorEntity");
    var nif = $('#nifEntity');

    nif.bind("paste drop input change cut", function () {
        var text = nif.val();
        if (text.length != 9 || isNaN(text) || !nifRegex.test(text)) {
            $(this).css('border', '1px solid red');
            $.each(niferror, function (i, v) {
                $(this).text("Formato inválido")
            });

            if (text.length == 0) {
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
        }
    });
};

var checkValidDate = function () {
    $("#contractstart, #contractend").change(function () {
        var contractstart = $("#contractstart").val();
        var contractend = $("#contractend").val();
        var contracts = $("#contractstart, #contractend");

        if (contractend <= contractstart) {
            $("#dateerror").text("Data incoerentes");
            $.each(contracts, function (e) {
                $(this).css('border', '1px solid red');
            })

            if (contractstart.length == 0 || contractend.length == 0) {
                $("#daterror").text("");
                $.each(contracts, function (e) {
                    $(this).removeAttr('style');
                })
            }
        }
        else {
            $("#daterror").text("");

            if (contractstart.length > 0 && contractend.length > 0) {
                $.each(contracts, function (e) {
                    $(this).css('border', '1px solid green');
                })
            }
        }
    });
};