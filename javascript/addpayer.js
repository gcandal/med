$(document).ready(function() {
    updateFormVisibility();

    $("select#entitytype").change(function () {
        updateFormVisibility();
    })
});

var updateFormVisibility = function() {
    switch($("select#entitytype").val()) {
        case 'Private':
            $("form#formentidade").hide();
            $("form#formprivado").show();
            break;
        case 'Insurance':
            $("form#formprivado").hide();
            $("form#formentidade").show();
            $("form#formentidade input[name=type]").val("Insurance");
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