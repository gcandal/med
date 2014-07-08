$(document).ready(function () {
    updatePayerVisibility();
    updateFunctionVisibility();

    $("select#entityType").change(function () {
        updatePayerVisibility();
    })

    $("select#function").change(function () {
        updateFunctionVisibility();
    })

});

var updatePayerVisibility = function () {
    switch ($("select#entityType").val()) {
        case 'Privado':
            $("span#privatePayer").show();
            $("span#entityPayer").hide();
            break;
        case 'Entidade':
            $("span#privatePayer").hide();
            $("span#entityPayer").show();
            break;
        default:
            break;
    }
}

var updateFunctionVisibility = function () {
    switch ($("select#function").val()) {
        case 'Chefe':
            $("span#chefe").show();
            $("span#assistente").hide();
            break;
        case 'Assistente':
        case 'Anestesista':
            $("span#chefe").hide();
            $("span#assistente").show();
            break;
        default:
            break;
    }
}
