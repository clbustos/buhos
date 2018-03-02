var FileHandler ={
    archivo_mostrado:null,
    start_modal:function(archivo_mostrado, name) {

        this.archivo_mostrado=archivo_mostrado;
        this.name=name;
        $('#modalArchivos').find('.modal-title').text('Contenido archivo ' + FileHandler.name);
        this.update_data_modal();
    },
    update_data_modal:function() {

        $('#modalArchivos').find('.modal-body').html("<iframe src = '/ViewerJS/#../file/"+this.archivo_mostrado+"/download' width='800' height='600' allowfullscreen webkitallowfullscreen></iframe>")



    },
    action_on_cd:function(e, url, glyphicon_class, name) {
        var arc_id=e.data("aid");
        var cd_id=e.data("cdid");
        $.post(url, {file_id: arc_id, cd_id: cd_id} ,function () {
            $("#botones_archivo_"+arc_id).html("<span class='glyphicon glyphicon-"+glyphicon_class+"'>"+name+"</span>")
        }).fail(function() {
            alert("can't perform action");
        })
    }
};

$(document).ready(function() {
    $('#modalArchivos').on('shown.bs.modal', function (event) {
        var button = $(event.relatedTarget); // Button that triggered the modal
        var recipient = button.data('pk'); // Extract info from data-* attributes
        var name    = button.data('name');
        FileHandler.start_modal(recipient,name);
        // If necessary, you could initiate an AJAX request here (and then do the updating in a callback).
        // Update the modal's content. We'll use jQuery here, but you could use a data binding library or other methods instead.

    });

    $(".archivo_ocultar_cd").click(function() {
        FileHandler.action_on_cd($(this), '/file/hide_cd', 'eye-close', 'Hidden');
    });
    $(".archivo_mostrar_cd").click(function() {
        FileHandler.action_on_cd($(this), '/file/show_cd', 'eye-open', 'Show');
    });

    $(".archivo_desasignar_cd").click(function() {
        FileHandler.action_on_cd($(this), '/file/unassign_cd', 'remove', 'Not assigned to CD');

    });

    $(".archivo_eliminar").click(function () {
        var arc_id = $(this).data("aid");

        $.post("/file/delete", {file_id: arc_id}, function () {
            $("#botones_archivo_" + arc_id).html("<span class='glyphicon glyphicon-remove'>Eliminado</span>")
        }).fail(function () {
            alert("No pude eliminar el archivo");
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

        $.post("/file/assign_to_canonical", {file_id:arc_id,  cd_id:cd_id} ,function (data) {
            $("#name_canonico-"+arc_id).html(data)
        }).fail(function() {
            alert("No pude actualizar el canonico");
        })

    });
});