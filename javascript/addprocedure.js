$(document).ready(function() {
    updateFormVisibility();

    $("select#entityType").change(function () {
        updateFormVisibility();
    })

    var subprocedures = 1;

    addSubProcedure();

    $('#addSubProcedure').click(function() {
        addSubProcedure();
        i++;
    });

    $('#removeSubProcedure').click(function() {
        removeSubProcedure();
        i--;
    })

});

var updateFormVisibility = function() {
    switch($("select#entityType").val()) {
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

var addSubProcedure = function() {
    $('<div><input type="text" class="field" name="dynamic[]" value="' + i + '" /></div>').fadeIn('slow').appendTo('#subProcedures');
}

var removeSubProcedure =function() {
    if(i > 1) {
        $('#subProcedures:last').remove();
    }
}