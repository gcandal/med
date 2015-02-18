var specialityLabel = $("#specialityLabel");
var specialityId = $('#specialityId');

$(document).ready(function() {
   $("#professionalType").change(function() {
       updateSpecialityVisibility($(this).val());
   });
});

var updateSpecialityVisibility = function(professionalType) {
    switch(professionalType) {
        case 'Assistant':
            specialityLabel.show();
            specialityId.children().show();
            break;

        case 'Instrumentist':
            specialityLabel.hide();
            specialityId.val(2);
            specialityId.find(":not(:selected)").hide();
            break;

        case 'Anesthetist':
            specialityLabel.hide();
            specialityId.val(1);
            specialityId.find(":not(:selected)").hide();
            break;
    }
};