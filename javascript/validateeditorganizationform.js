$(document).ready(function () {
    checkIfNameIsFree();
});

var checkIfNameIsFree = function () {
    var name = $('#name');

    name.bind("paste drop input change cut", function () {
        var text = name.val();
        if (text.length > 0)
            $.get(baseUrl + 'actions/organizations/checkorganizationname.php?name=' + name.val(), function (data) {
                if (data['exists'])
                    name.css('border', '1px solid red');
                else
                    name.css('border', '1px solid green');
            });
        else
            name.removeAttr('style');
    });
};