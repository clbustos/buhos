
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

$(document).ready(function () {

    $('.nombre_editable').editable({
        type: 'text',
        title: 'Ingrese nuevo nombre',
        ajaxOptions: {
            type: 'put'
        }
    });




    $('.tipo_editable').editable({
        type: 'text',
        title: 'Ingrese nuevo tipo',
        ajaxOptions: {
            type: 'put'
        }
    });


    $('.select_editable').change(function() {
        pais_id=$(this).val()
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


    $(".tablesorter").tablesorter();;



})