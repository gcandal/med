const specialityLabel = $("#specialityLabel");
const specialityId = $('#specialityId');

$(document).ready(function() {
   $("#professionalType").change(function() {
       updateSpecialityVisibility($(this).val());
   });
});

var updateSpecialityVisibility = function(professionalType) {
    switch(professionalType) {
        case 'Assistant':
            specialityLabel.show();
            break;

        case 'Instrumentist':
            specialityLabel.hide();
            specialityId.val(2);
            break;

        case 'Anesthetist':
            specialityLabel.hide();
            specialityId.val(1);
            break;
    }
}