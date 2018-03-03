// Copyright (c) 2016-2018, Claudio Bustos Navarrete
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

asignacion_general=function(e,accion,f_divs) {
    var rs_id=e.data("rsid");
    var cd_id=e.data("cdid");
    var user_id=e.data("uid");
    var stage  =e.data("stage");
    console.log([cd_id,user_id,stage]);
    $.post("/canonical_document/user_assignation/"+accion, {rs_id:rs_id, cd_id:cd_id, user_id:user_id, stage:stage}, function (data) {
        var div_asignar="usuario-asignar-"+rs_id+"-"+cd_id+"-"+user_id+"-"+stage;
        var div_desasignar="usuario-desasignar-"+rs_id+"-"+cd_id+"-"+user_id+"-"+stage;
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