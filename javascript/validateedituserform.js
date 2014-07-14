$(document).ready(function() {
    checkEqualPasswords();
});

var checkEqualPasswords = function() {
    var password1 = $('#password');
    var password2 = $('#passwordconfirm');
    var passwords = $('#password, #passwordconfirm');

    passwords.bind("paste drop input change cut", function () {
        var textpassword1 = password1.val();
        var textpassword2 = password2.val();

        if(textpassword1.length == 0 && textpassword2.length == 0) {
            passwords.removeAttr("style");

            return;
        }

        if(textpassword1 !== textpassword2) {
            passwords.css('border', '1px solid red');
        } else
            passwords.css('border', '1px solid green');
    });
};