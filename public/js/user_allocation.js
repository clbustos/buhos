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



var UserAllocationManager={};

(function(context)  {

    context.update=function() {
        create_class_handler('allocate', false, true);
        create_class_handler('unallocate', true, false);
    };

    var create_class_handler=function(name, allocate_show, unallocate_show) {
        $(".user_"+name).click(function() {
            general_allocation($(this),name, function(div_allocate,div_unallocate) {
                allocate_show   ? $("#"+div_allocate).removeClass('hidden') : $("#"+div_allocate).addClass('hidden')
                unallocate_show ? $("#"+div_unallocate).removeClass('hidden') : $("#"+div_unallocate).addClass('hidden')
            });
        });
    };

    var general_allocation=function(e,accion,f_divs) {
        var rs_id=e.data("rsid");
        var cd_id=e.data("cdid");
        var user_id=e.data("uid");
        var stage  =e.data("stage");
        console.log([cd_id,user_id,stage]);
        $.post("/canonical_document/user_allocation/"+accion, {rs_id:rs_id, cd_id:cd_id, user_id:user_id, stage:stage}, function (data) {
            var div_allocate="user-allocate-"+rs_id+"-"+cd_id+"-"+user_id+"-"+stage;
            var div_unallocate="user-unallocate-"+rs_id+"-"+cd_id+"-"+user_id+"-"+stage;
            f_divs(div_allocate,div_unallocate);
        }).fail(function () {
            alert("Can't "+accion+" the document to user")
        })
    };
})(UserAllocationManager);


$(document).ready(function() {
    UserAllocationManager.update();
});
