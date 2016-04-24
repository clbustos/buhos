$(document).ready(function() {
        $('.edit').editable('/edicion', {
         indicator : 'Grabando...',
         tooltip   : 'haga click para editar...'                
        }
        )

        $( "#tabs" ).tabs();
        $( ".datepicker" ).datepicker();
        $(".chzn-select").chosen()
        $("ul.sf-menu").superfish(); 

        
 });
