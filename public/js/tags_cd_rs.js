crear_tag=function(url,val,cd_pk,rs_pk) {
    if(val.trim()=="") {
        alert("El tag no tiene texto")
    } else {
        $.post(url, {value: val}, function (data) {
            $("#tags-cd-"+cd_pk+"-rs-"+rs_pk).replaceWith(data);
            actualizar_tags_cd_rs();
        }).fail(function () {
            alert("No se pudo crear el tag")
        })
    }
};
actualizar_tags_cd_rs=function() {
    $(".boton_accion_tag_cd_rs").click(function(){
        var url=$(this).attr("data-url");
        var cd_pk=$(this).attr("cd-pk");
        var rs_pk=$(this).attr("rs-pk");
        var tag_id=$(this).attr("tag-pk");
        $.post(url, {tag_id:tag_id}, function (data) {

            $("#tags-cd-"+cd_pk+"-rs-"+rs_pk).replaceWith(data);
            actualizar_tags_cd_rs();
        }).fail(function () {
            alert("No se pudo realizar la acción en el tag")
        })

    })

    $(".boton_nuevo_tag_cd_rs").click(function() {
        var url=$(this).attr("data-url");
        var cd_pk=$(this).attr("cd-pk");
        var rs_pk=$(this).attr("rs-pk");
        var val=$("#tag-cd-"+cd_pk+"-rs-"+rs_pk+"-nuevotag").val().trim();
        crear_tag(url,val, cd_pk,rs_pk);
    });

    $(".nuevo_tag_cd_rs").on('keypress', function(e) {
        if(13==e.which && $(this).val().trim()!="") {
            var url=$(this).attr("data-url");
            var cd_pk=$(this).attr("cd-pk");
            var rs_pk=$(this).attr("rs-pk");
            var val=$(this).val().trim();
            crear_tag(url,val,cd_pk,rs_pk);
        }
    });
};

$(document).ready(function() {
    actualizar_tags_cd_rs();

});
