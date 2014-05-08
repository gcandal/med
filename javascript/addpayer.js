$(document).ready(function() {
    updateFormVisibility();

    $("select#entitytype").change(function () {
        updateFormVisibility();
    })
});

var updateFormVisibility = function() {
    switch($("select#entitytype").val()) {
        case 'Privado':
            $("form#formentidade").hide();
            $("form#formprivado").show();
            break;
        case 'Seguro':
            $("form#formprivado").hide();
            $("form#formentidade").show();
            $("form#formentidade input[name=type]").val("Seguro");
            break;
        case 'Hospital':
            $("form#formprivado").hide();
            $("form#formentidade").show();
            $("form#formentidade input[name=type]").val("Hospital");
            break;
        default:
            break;
    }
}

var setSelectedValue = function(value) {

}