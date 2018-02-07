var ModalArchivo ={
    archivo_mostrado:null,
    iniciar:function(archivo_mostrado,name) {

        this.archivo_mostrado=archivo_mostrado;
        this.name=name;
        $('#modalArchivos').find('.modal-title').text('Contenido archivo ' + ModalArchivo.name);
        this.actualizar_datos_modal();
    },
    actualizar_datos_modal:function() {

        $('#modalArchivos').find('.modal-body').html("<iframe src = '/ViewerJS/#../archivo/"+this.archivo_mostrado+"/descargar' width='800' height='600' allowfullscreen webkitallowfullscreen></iframe>")



    }
};

$(document).ready(function() {
    $('#modalArchivos').on('shown.bs.modal', function (event) {
        var button = $(event.relatedTarget); // Button that triggered the modal
        var recipient = button.data('pk'); // Extract info from data-* attributes
        var name    = button.data('name');
        ModalArchivo.iniciar(recipient,name);
        // If necessary, you could initiate an AJAX request here (and then do the updating in a callback).
        // Update the modal's content. We'll use jQuery here, but you could use a data binding library or other methods instead.

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


    $(".archivo_eliminar").click(function () {
        var arc_id = $(this).data("aid");

        $.post("/archivo/eliminar", {archivo_id: arc_id}, function () {
            $("#botones_archivo_" + arc_id).html("<span class='glyphicon glyphicon-remove'>Eliminado</span>")
        }).fail(function () {
            alert("No pude eliminar el archivo");
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