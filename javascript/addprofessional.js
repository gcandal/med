const specialityLabel = $("#specialityLabel");

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
            break;

        case 'Anesthetist':
            specialityLabel.hide();
            break;
    }
}