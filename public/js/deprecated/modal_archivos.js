var ModalArchivo ={
    pagina:1,
    maximo_pages:null,
    archivo_mostrado:null,
    iniciar:function(pagina,maximo_pages,archivo_mostrado) {

        this.pagina=pagina;
        this.maximo_pages=maximo_pages;
        this.archivo_mostrado=archivo_mostrado;
        if(String(maximo_pages)==="") {
            this.maximo_pages=null;
        } else {
            this.maximo_pages=parseInt(maximo_pages);
        }
        $('#modalArchivos').find('.modal-title').text('Contenido archivo ' + ModalIFile.archivo_mostrado);

        this.actualizar_datos_modal();


    },
    actualizar_datos_modal:function() {

        if(this.pagina<=1) {
            this.pagina=1;
            $("#boton_pagina_menos").prop("disabled",true);
        } else if(this.pagina>1) {
            $("#boton_pagina_menos").prop("disabled",false);
        }

        if (this.maximo_pages) {
            if(this.pagina>=this.maximo_pages) {
                this.pagina=this.maximo_pages;
                $("#boton_pagina_mas").prop("disabled",true);
            }
        }

        $('#modal_count_pages').html("Página "+this.pagina+ " de "+this.maximo_pages);

        $('#modalArchivos').find('.modal-body').html("<img  class='archivo' src='/file/"+this.archivo_mostrado+"/page/"+this.pagina+"/image'>");



    }
};

$(document).ready(function() {
    $('#modalArchivos').on('shown.bs.modal', function (event) {
        var button = $(event.relatedTarget); // Button that triggered the modal
        var recipient = button.data('pk'); // Extract info from data-* attributes
        ModalIFile.start_modal(1,button.data("pages"),recipient);
        // If necessary, you could initiate an AJAX request here (and then do the updating in a callback).
        // Update the modal's content. We'll use jQuery here, but you could use a data binding library or other methods instead.

    });

    $("#boton_pagina_mas").click(function(){
        ModalIFile.pagina=ModalIFile.pagina+1;
        ModalIFile.update_data_modal();
    });
    $("#boton_pagina_menos").click(function(){
        ModalIFile.pagina=ModalIFile.pagina-1;
        ModalIFile.update_data_modal();
    });

    $(".archivo_ocultar_cd").click(function() {
        var arc_id=$(this).data("aid");
        var cd_id=$(this).data("cdid");
        $.post("/file/hide_cd", {file_id:arc_id, cd_id:cd_id} ,function () {
            $("#botones_archivo_"+arc_id).html("<span class='glyphicon glyphicon-eye-close'>Ocultado</span>")
        }).fail(function() {
            alert("No pude ocultar el canonico");
        })


    });


    $(".archivo_eliminar").click(function () {
        var arc_id = $(this).data("aid");

        $.post("/file/delete", {file_id: arc_id}, function () {
            $("#botones_archivo_" + arc_id).html("<span class='glyphicon glyphicon-remove'>Eliminado</span>")
        }).fail(function () {
            alert("No pude eliminar el archivo");
        })


    });

    $(".archivo_desasignar_cd").click(function() {
        var arc_id=$(this).data("aid");
        var cd_id=$(this).data("cdid");
        $.post("/file/unassign_cd", {file_id:arc_id, cd_id:cd_id} ,function () {
            $("#botones_archivo_"+arc_id).html("<span class='glyphicon glyphicon-remove'>Desasignado a CD</span>")
        }).fail(function() {
            alert("No pude ocultar el canonico");
        })


    });

    $(".archivo_desasignar_rs").click(function() {
        var arc_id=$(this).data("aid");
        var rs_id=$(this).data("rsid");
        $.post("/file/unassign_sr", {file_id:arc_id, rs_id:rs_id} ,function () {
            $("#botones_archivo_"+arc_id).html("<span class='glyphicon glyphicon-remove'>Desasignado a RS</span>")
        }).fail(function() {
            alert("No pude remover de RS");
        })


    });


    $(".asignar_canonico").click(function() {
        var arc_id=$(this).attr("archivo-pk");
        var cd_id=$("#select_canonico_"+arc_id).val();

        $.post("/file/assign_to_canonical", {file_id:arc_id, cd_id:cd_id} ,function (data) {
            $("#name_canonico-"+arc_id).html(data)
        }).fail(function() {
            alert("No pude actualizar el canonico");
        })

    });
});