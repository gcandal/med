$(document).ready(function () {
    updateFormVisibility();

    $("select#entityType").change(function () {
        updateFormVisibility();
    })

    /*
     console.log(subProcedureTypes[0].name);

     var subProcedures = 1;
     addSubProcedure();

     $('#addSubProcedure').click(function () {
     addSubProcedure();
     i++;
     });

     $('#removeSubProcedure').click(function () {
     removeSubProcedure();
     i--;
     })
     */
});

var updateFormVisibility = function () {
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

/*

 var addSubProcedure = function () {
 $('<select name="subProcedure"+i>' + getSubProcedureTypes() + '</select>').fadeIn('slow').appendTo('#subProcedures');
 }

 var removeSubProcedure = function () {
 if (i > 1) {
 $('#subProcedures:last').remove();
 }
 }

 var getSubProcedureTypes = function () {
 var result = "";
 for (var i = 0; i < subProcedureTypes.length; i++) {
 result += '<option value = "' + subProcedureTypes[i].idproceduretype + '">' + subProcedureTypes[i].name + '</select>';
 }
 return result;
 }

 */