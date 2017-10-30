asignacion_general=function(e,accion,f_divs) {
    var rs_id=e.data("rsid");
    var cd_id=e.data("cdid");
    var user_id=e.data("uid");
    console.log([cd_id,user_id]);
    $.post("/canonico_documento/asignacion_usuario/"+accion, {rs_id:rs_id, cd_id:cd_id, user_id:user_id}, function (data) {
        var div_asignar="usuario-asignar-"+rs_id+"-"+cd_id+"-"+user_id;
        var div_desasignar="usuario-desasignar-"+rs_id+"-"+cd_id+"-"+user_id;
        f_divs(div_asignar,div_desasignar);
    }).fail(function () {
        alert("No se pudo "+accion+" el documento al usuario")
    })
};
$(document).ready(function() {


    $(".usuario_asignar").click(function() {
        asignacion_general($(this),"asignar",function(div_asignar,div_desasignar) {
            $("#"+div_asignar).addClass("hidden");
            $("#"+div_desasignar).removeClass("hidden");
        });
    });

        $(".usuario_desasignar").click(function() {
            asignacion_general($(this),"desasignar",function(div_asignar,div_desasignar) {
                $("#"+div_asignar).removeClass("hidden");
                $("#"+div_desasignar).addClass("hidden");
            });
        });


});