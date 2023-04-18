// Copyright (c) 2016-2023, Claudio Bustos Navarrete
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// * Neither the name of the copyright holder nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


$.ajaxSetup({async:true});

function buscar_similares_canonico() {

    $(".buscar_similares_canonico").click(function() {
        var partes=$(this).attr("id").split("-");
        var id=partes[1];
        var boton=$(this);
        var contenedor="#buscar_similar-"+id+"-campo";
        boton.prop("disabled",true);
        $(contenedor).html("<em>Espere, por favor...</em>");
        $.get("/canonical_document/"+id+"/search_similar",{"ajax":1}, function(html_div) {

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


function actualizar_resolution(stage, div_id) {

    div_id = typeof div_id !== 'undefined' ? div_id : false;
    var selector_action=div_id ? div_id+" .dc_resolution" : '.dc_resolution';



    $(selector_action).unbind("click");

    $(selector_action).click(function () {
        var pk_id = $(this).attr("data-pk");
        var resolution = $(this).attr("data-resolution");
        var user_id = $(this).attr("data-user");
        var url = $(this).attr("data-url");
        var stage = $(this).attr("data-stage");

        //var commentary=$("#commentary-"+pk_id).val()
        var boton = $(this);
        boton.prop("disabled", true);
        $.post(url, {pk_id: pk_id, resolution: resolution, user_id: user_id}, function (data) {
            $("#botones_resolution_"+stage+"_"+ pk_id).html(data);
            var to_update="#botones_resolution_"+stage+"_"+pk_id;
            actualizar_resolution(stage,to_update);
            actualizar_textarea_editable(to_update);


        }).fail(function () {
            alert("No se pudo cargar la resolution")
        })
    })

}

function actualizar_name_editable() {
    $('.name_editable').editable({
        type: 'text',
        mode:'inline',
        onblur:'submit',
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
        rows: 10,
        mode: "inline",
        showbuttons:'bottom',
        onblur:'submit',
        ajaxOptions: {
            type: 'put'
        }
    });

}

$(document).ready(function () {
    actualizar_textarea_editable();
    actualizar_name_editable();

    $(".toggle_buttons button").click(function(e) {
        var class_to="."+$(this).attr('data-class-toggle');
        $(class_to).toggle();
        $(this).toggleClass('btn-primary');
    });



    $('.type_editable').editable({
        type: 'text',
        title: 'Add new type',
        ajaxOptions: {
            type: 'put'
        }
    });


    $('.select_editable').change(function() {
        var pais_id=$(this).val();
        var url=$(this).attr('data-url');
        var pk=$(this).attr('data-pk');
        var td_parent=$(this).parents("td");
        var obj=jQuery.param({pk:pk, value:pais_id});
        $.post(url, obj,function () {
            td_parent.addClass("verde")
        }).fail(function() {
            td_parent.addClass("rojo")
        })


    });

    $('.btn-action').click(function() {
       var form=$(this.form);
       form.find("input[name='action']").val($(this).data('action'));

    });

    $(".tablesorter").tablesorter();

});
