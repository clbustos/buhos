
function buscar_similares_canonico() {

    $(".buscar_similares_canonico").click(function() {
        var partes=$(this).attr("id").split("-")
        var id=partes[1]
        var boton=$(this)
        var contenedor="#buscar_similar-"+id+"-campo"
        boton.prop("disabled",true);
        $(contenedor).html("<em>Espere, por favor...</em>");
        $.get("/canonico_documento/"+id+"/buscar_similar",{"ajax":1}, function(html_div) {

            //autor_id=resultado[0]
            //html_div=resultado[1]
            $(contenedor).html(html_div);
            $(contenedor).addClass('well');
            //$("#autor-"+autor_id).addClass("verde_suave");
            boton.prop("enabled",true);
            //$("#BRA-"+autor_id).removeClass("hidden");

            //boton.prop("disabled",false)
        }).fail(function() {
            alert("Se produjo un error");
        });

    });
}

function actualizar_decision(etapa,div_id) {
    div_id = typeof div_id !== 'undefined' ? div_id : false;
    var selector_action=div_id ? div_id+" .dc_decision" : '.dc_decision';

    $(selector_action).unbind("click");
    $(selector_action).click(function () {
        var pk_id = $(this).attr("data-pk");
        var decision = $(this).attr("data-decision");
        var user_id = $(this).attr("data-user");
        var only_buttons= $(this).attr("data-onlybuttons");
        var url = $(this).attr("data-url");
        //var comentario=$("#comentario-"+pk_id).val()
        var boton = $(this);
        boton.prop("disabled", true);
        var div_replace="#decision-cd-" + pk_id;
        $.post(url, {pk_id: pk_id, decision: decision, user_id: user_id, only_buttons:only_buttons}, function (data) {
            $(div_replace).html(data);
            actualizar_decision(etapa,div_replace);
            actualizar_textarea_editable(div_replace);

            // Tengo que considerar los tags...
            actualizar_tags_cd_rs(div_replace);
            actualizar_typeahead(div_replace);
            actualizar_mostrar_pred(div_replace);

        }).fail(function () {
            alert("No se pudo cargar la decisión")
        })
    })

}


function actualizar_resolucion(etapa) {

    $(".dc_resolucion").click(function () {
        var pk_id = $(this).attr("data-pk");
        var resolucion = $(this).attr("data-resolucion");
        var user_id = $(this).attr("data-user");
        var url = $(this).attr("data-url");
        var etapa = $(this).attr("data-etapa");

        //var comentario=$("#comentario-"+pk_id).val()
        var boton = $(this);
        boton.prop("disabled", true)
        $.post(url, {pk_id: pk_id, resolucion: resolucion, user_id: user_id}, function (data) {
            $("#botones_resolucion_"+etapa+"_"+ pk_id).html(data)
            //actualizar_textarea_editable();
            //setTimeout(function() {
            //},2000);

        }).fail(function () {
            alert("No se pudo cargar la resolucion")
        })
    })

}

function actualizar_nombre_editable() {
    $('.nombre_editable').editable({
        type: 'text',
        emptytext: '--Vacio--',
        title: 'Ingrese',
        ajaxOptions: {
            type: 'put'
        }
    });

}

function actualizar_textarea_editable(div_id) {
    div_id = typeof div_id !== 'undefined' ? div_id : false;
    var selector_action=div_id ? div_id+" .textarea_editable" : '.textarea_editable';
    $(selector_action).unbind("editable");
    $(selector_action).editable({
        type: 'textarea',
        emptytext: '--Vacio--',
        title: 'Ingrese',
        rows: 10,
        mode: "inline",
        ajaxOptions: {
            type: 'put'
        }
    });

}

$(document).ready(function () {
    actualizar_textarea_editable();
    actualizar_nombre_editable();

    $('.tipo_editable').editable({
        type: 'text',
        title: 'Ingrese nuevo tipo',
        ajaxOptions: {
            type: 'put'
        }
    });


    $('.select_editable').change(function() {
        pais_id=$(this).val();
        url=$(this).attr('data-url');
        pk=$(this).attr('data-pk');
        td_parent=$(this).parents("td");
        obj=jQuery.param({pk:pk, value:pais_id});
        $.post(url, obj,function () {
            td_parent.addClass("verde")
        }).fail(function() {
            td_parent.addClass("rojo")
        })


    })


    $(".tablesorter").tablesorter();



})