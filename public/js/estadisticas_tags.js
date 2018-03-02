actualizar_botones_tags=function() {

    $('.borrar_tag').click(function() {
        var tag_id=$(this).attr("tag-pk");
        var rs_id=$(this).attr("rs-pk");

        $.post("/tag/delete_rs",{tag_id:tag_id, rs_id:rs_id},function(data) {
            $("#tag-fila-"+tag_id).addClass("hidden");

        }).fail(function(){
            alert("Tag can't be deleted");
        })
    });
};


$(document).ready(function() {
    actualizar_botones_tags();
});