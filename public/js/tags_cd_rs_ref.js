var tagsRefQuery=new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    prefetch: '/tags/basic_ref_10.json',
    remote: {
        url: '/tags/refs/query_json/%QUERY',
        wildcard: '%QUERY'
    }
});

crear_tag_ref=function(url,val,cd_start_pk,cd_end_pk, rs_pk) {
    if(val.trim()=="") {
        alert("El tag no tiene texto")
    } else {
        $.post(url, {value: val}, function (data) {
            var div_id="#tags-cd_start-"+cd_start_pk+"-cd_end-"+cd_end_pk+"-rs-"+rs_pk;
            $(div_id).replaceWith(data);
            actualizar_tags_cd_rs_ref(div_id);
            actualizar_typeahead_ref(div_id);
            actualizar_mostrar_pred_ref(div_id);
        }).fail(function () {
            alert("No se pudo crear el tag")
        })
    }
};
actualizar_tags_cd_rs_ref=function(div_id) {

    div_id = typeof div_id !== 'undefined' ? div_id : false;

    var selector_accion = div_id ? div_id+" .boton_accion_tag_cd_rs_ref" : ".boton_accion_tag_cd_rs_ref";
    var selector_nuevo  = div_id ? div_id+" .boton_nuevo_tag_cd_rs_ref" : ".boton_nuevo_tag_cd_rs_ref";
    var keypres_nuevo   = div_id ? div_id+" .nuevo_tag_cd_rs_ref" : ".nuevo_tag_cd_rs_ref";
    $(selector_accion).unbind("click");
    $(selector_accion).click(function(){
        var url=$(this).attr("data-url");
        var cd_start_pk=$(this).attr("cd_start-pk");
        var cd_end_pk=$(this).attr("cd_end-pk");

        var rs_pk=$(this).attr("rs-pk");
        var tag_id=$(this).attr("tag-pk");
        $.post(url, {tag_id:tag_id}, function (data) {
            var div_id="#tags-cd_start-"+cd_start_pk+"-cd_end-"+cd_end_pk+"-rs-"+rs_pk;
            $(div_id).replaceWith(data);
            actualizar_tags_cd_rs_ref(div_id);
            actualizar_typeahead_ref(div_id);
            actualizar_mostrar_pred_ref(div_id);
        }).fail(function () {
            alert("No se pudo realizar la acción en el tag")
        })

    });
    $(selector_nuevo).unbind("click");
    $(selector_nuevo).click(function() {
        var url=$(this).attr("data-url");
        var cd_start_pk=$(this).attr("cd_start-pk");
        var cd_end_pk=$(this).attr("cd_end-pk");
        var rs_pk=$(this).attr("rs-pk");
        var val=$("#tag-cd_start-"+cd_start_pk+"-cd_end-"+cd_end_pk+"-rs-"+rs_pk+"-nuevotag").val().trim();

        crear_tag_ref(url,val, cd_start_pk,cd_end_pk, rs_pk);
        return(false);
    });
    $(keypres_nuevo).unbind("keypress");
    $(keypres_nuevo).on('keypress', function(e) {
        if(13==e.which && $(this).val().trim()!="") {
            var url=$(this).attr("data-url");
            var cd_start_pk=$(this).attr("cd_start-pk");
            var cd_end_pk=$(this).attr("cd_end-pk");
            var rs_pk=$(this).attr("rs-pk");
            var val=$(this).val().trim();
            crear_tag_ref(url,val,cd_start_pk,cd_end_pk, rs_pk);
            return(false);
        }
    });
};

actualizar_mostrar_pred_ref=function(div_id) {
    div_id = typeof div_id !== 'undefined' ? div_id : false;
    var selector_action=div_id ? div_id+" .mostrar_pred_ref" : '.mostrar_pred_ref';
    //console.log(selector_action);
    $(selector_action).unbind("click");
    $(selector_action).click(function() {
        var id=$(this).attr("id");
        var partes=id.split("__");
        var base=partes[0];

        $("#"+base+" .tag-predeterminado").removeClass("hidden");
        $("#"+base+"__mostrar_pred").hide();
    });
}
actualizar_typeahead_ref=function(div_id) {
    div_id = typeof div_id !== 'undefined' ? div_id : false;
    var selector=div_id ? div_id+" .nuevo_tag_cd_rs_ref" : '.nuevo_tag_cd_rs_ref';
    //console.log(selector);
    $(selector).unbind("typeahead");
    $(selector).typeahead({

            hint: true,
            highlight: true,
            minLength: 3
        },
        {
            name: 'tags',
            display:'value',
            source: tagsRefQuery
        });
};



$(document).ready(function() {
    // Typeahead section


    actualizar_tags_cd_rs_ref();
    actualizar_typeahead_ref();
    actualizar_mostrar_pred_ref();

});