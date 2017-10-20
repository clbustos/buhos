var ModalArchivo ={
    pagina:1,
    maximo_paginas:null,
    archivo_mostrado:null,
    iniciar:function(pagina,maximo_paginas,archivo_mostrado) {

        this.pagina=pagina;
        this.maximo_paginas=maximo_paginas;
        this.archivo_mostrado=archivo_mostrado;
        if(maximo_paginas=="") {
            this.maximo_paginas=null;
        } else {
            this.maximo_paginas=parseInt(maximo_paginas);
        }
        $('#modalArchivos').find('.modal-title').text('Contenido archivo ' + ModalArchivo.archivo_mostrado);

        this.actualizar_datos_modal();


    },
    actualizar_datos_modal:function() {

        if(this.pagina<=1) {
            this.pagina=1;
            $("#boton_pagina_menos").prop("disabled",true);
        } else if(this.pagina>1) {
            $("#boton_pagina_menos").prop("disabled",false);
        }

        if (this.maximo_paginas) {
            if(this.pagina>=this.maximo_paginas) {
                this.pagina=this.maximo_paginas;
                $("#boton_pagina_mas").prop("disabled",true);
            }
        }

        $('#modal_cuenta_paginas').html("Página "+this.pagina+ " de "+this.maximo_paginas);

        $('#modalArchivos').find('.modal-body').html("<img  class='archivo' src='/archivo/"+this.archivo_mostrado+"/pagina/"+this.pagina+"/image'>");



    }
};

$(document).ready(function() {
    $('#modalArchivos').on('shown.bs.modal', function (event) {
        var button = $(event.relatedTarget); // Button that triggered the modal
        var recipient = button.data('pk'); // Extract info from data-* attributes
        ModalArchivo.iniciar(1,button.data("paginas"),recipient);
        // If necessary, you could initiate an AJAX request here (and then do the updating in a callback).
        // Update the modal's content. We'll use jQuery here, but you could use a data binding library or other methods instead.

    });

    $("#boton_pagina_mas").click(function(){
        ModalArchivo.pagina=ModalArchivo.pagina+1;
        ModalArchivo.actualizar_datos_modal();
    });
    $("#boton_pagina_menos").click(function(){
        ModalArchivo.pagina=ModalArchivo.pagina-1;
        ModalArchivo.actualizar_datos_modal();
    });

    $(".archivo_ocultar_cd").click(function() {
        var arc_id=$(this).data("aid");
        var cd_id=$(this).data("cdid");
        $.post("/archivo/ocultar_cd", {archivo_id:arc_id, cd_id:cd_id} ,function () {
            $("#botones_archivo_"+arc_id).html("<span class='glyphicon glyphicon-eye-close'>Ocultado</span>")
        }).fail(function() {
            alert("No pude ocultar el canonico");
        })


    });

    $(".archivo_desasignar_cd").click(function() {
        var arc_id=$(this).data("aid");
        var cd_id=$(this).data("cdid");
        $.post("/archivo/desasignar_cd", {archivo_id:arc_id, cd_id:cd_id} ,function () {
            $("#botones_archivo_"+arc_id).html("<span class='glyphicon glyphicon-remove'>Desasignado a CD</span>")
        }).fail(function() {
            alert("No pude ocultar el canonico");
        })


    });

    $(".archivo_desasignar_rs").click(function() {
        var arc_id=$(this).data("aid");
        var rs_id=$(this).data("rsid");
        $.post("/archivo/desasignar_rs", {archivo_id:arc_id, rs_id:rs_id} ,function () {
            $("#botones_archivo_"+arc_id).html("<span class='glyphicon glyphicon-remove'>Desasignado a RS</span>")
        }).fail(function() {
            alert("No pude remover de RS");
        })


    });


    $(".asignar_canonico").click(function() {
        var arc_id=$(this).attr("archivo-pk");
        var cd_id=$("#select_canonico_"+arc_id).val();

        $.post("/archivo/asignar_canonico", {archivo_id:arc_id, cd_id:cd_id} ,function (data) {
            $("#nombre_canonico-"+arc_id).html(data)
        }).fail(function() {
            alert("No pude actualizar el canonico");
        })

    });
});