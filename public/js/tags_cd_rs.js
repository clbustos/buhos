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




var TagManager={};

(function(context)  {
    context.create_bloodhound=function(prefetch_url, remote_url) {
        var tags_query=new Bloodhound({
            datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
            queryTokenizer: Bloodhound.tokenizers.whitespace,
            prefetch: prefetch_url,
            remote: {
                url: remote_url,
                wildcard: '%QUERY'
            }
        });
        return(tags_query);
    };

    // update all selectors related to CD Tags
    var update_tag_cd=function(div_id) {
        update_tags_cd_rs(div_id);
        update_typeahead_cd(div_id);
        update_show_pred_cd(div_id);
    };
    // update all selectors related to Between CD Tags

    var update_tag_ref=function(div_id) {
        update_tags_cd_rs_ref(div_id);
        update_typeahead_ref(div_id);
        update_show_pred_ref(div_id);
    };

    // update all selectors.
    // Public functions
    context.update=function(div_id) {
        update_tag_cd(div_id);
        update_tag_ref(div_id);
    };

    var get_selector=function(div_id, div_class) {
        result=div_id ? div_id+ " "+ div_class: div_class;
        return(result);
    };

    // Send POST to create a tag
    var send_post_create_tag=function(info_tag,val) {
        if(val.trim()=="") {
            alert("TAG: No text")
        } else {
            $.post(info_tag.url, {value: val}, function (data) {
                var div_id=info_tag.getDivId();
                $(div_id).replaceWith(data);
                info_tag.updateDiv();
            }).fail(function () {
                alert("TAG: Can't create (server error)")
            })
        }
    };


    var unbind_actions=function(sa,sn,kn) {
        $(sa).unbind("click");
        $(sn).unbind("click");
        $(kn).unbind("keypress");
    };

    // retrieve information from Cd tag
    var TagInCdInfo=function(e) {
        this.url    =e.attr("data-url");
        this.cd_pk  =e.attr("cd-pk");
        this.rs_pk  =e.attr("rs-pk");
        this.tag_id =e.attr("tag-pk");

    };

    TagInCdInfo.prototype.getDivId = function() {
        return "#tags-cd-"+this.cd_pk+"-rs-"+this.rs_pk;
    };

    TagInCdInfo.prototype.updateDiv = function() {
        update_tag_cd(this.getDivId());
    };

    TagInCdInfo.prototype.replaceWith=function(data) {
        $(this.getDivId()).replaceWith(data);
    };

    var TagBwCdInfo=function(e) {
        this.url            = e.attr("data-url");
        this.cd_start_pk    = e.attr("cd_start-pk");
        this.cd_end_pk      = e.attr("cd_end-pk");
        this.rs_pk          = e.attr("rs-pk");
        this.tag_id         = e.attr("tag-pk")
    };

    TagBwCdInfo.prototype.getDivId = function() {
        return "#tags-cd_start-"+this.cd_start_pk+"-cd_end-"+this.cd_end_pk+"-rs-"+this.rs_pk
    };

    TagBwCdInfo.prototype.updateDiv = function() {
        update_tag_ref(this.getDivId());
    };

    var create_tag_cd=function(e, FUNC) {
        var info_tag=new TagInCdInfo(e);
        val=FUNC(info_tag.cd_pk, info_tag.rs_pk);
        send_post_create_tag(info_tag, val);
        return(false);
    };

    // retrieve information from Bw CD tag


    var create_tag_ref=function(e, FUNC) {
        var info_tag=new TagBwCdInfo(e);
        val=FUNC(info_tag.cd_start_pk, info_tag.cd_end_pk, info_tag.rs_pk);
        send_post_create_tag(info_tag,val);
        return(false);
    };


    var action_click=async function(sel_action, type) {
        $(sel_action).click(function(){
            switch(type) {
                case 'tag_in_cd':
                    var info_tag=new TagInCdInfo($(this));
                    break;
                case 'tag_bw_cd':
                    var info_tag=new TagBwCdInfo($(this));
                    break;
            }
            $.post(info_tag.url, {tag_id:info_tag.tag_id}, function (data) {
                info_tag.replaceWith(data);
                info_tag.updateDiv();
            }).fail(function () {
                alert("TAG: Can't run the action")
            })

        });
    };

    var update_tags_cd_rs=function(div_id) {

        div_id = typeof div_id !== 'undefined' ? div_id : false;

        var selector_action = get_selector(div_id, ".boton_accion_tag_cd_rs");
        var selector_nuevo  = get_selector(div_id, ".boton_nuevo_tag_cd_rs");
        var keypres_nuevo   = get_selector(div_id, ".nuevo_tag_cd_rs");

        unbind_actions(selector_action,selector_nuevo,keypres_nuevo);

        action_click(selector_action, 'tag_in_cd');
        $(selector_nuevo).click(function() {
            return(create_tag_cd($(this), function(cd_pk, rs_pk) {return $("#tag-cd-"+cd_pk+"-rs-"+rs_pk+"-nuevotag").val().trim()}));
        });

        $(keypres_nuevo).on('keypress', function(e) {
            if(13==e.which && $(this).val().trim()!="") {
                var val=$(this).val().trim();
                return(create_tag_cd($(this), function(cd_pk,rs_pk) {  return val }));
            }
        });
    };

    var update_tags_cd_rs_ref=function(div_id) {

        div_id = typeof div_id !== 'undefined' ? div_id : false;

        var sel_act        = get_selector(div_id, " .boton_accion_tag_cd_rs_ref");
        var selector_nuevo = get_selector(div_id, ".boton_nuevo_tag_cd_rs_ref");
        var keypres_nuevo  = get_selector(div_id, ".nuevo_tag_cd_rs_ref");

        unbind_actions(sel_act,selector_nuevo,keypres_nuevo);
        action_click(sel_act, 'tag_bw_cd');
        $(selector_nuevo).click(function() {
            return(create_tag_ref($(this), function(cd_start_pk, cd_end_pk, rs_pk) {
                return $("#tag-cd_start-"+cd_start_pk+"-cd_end-"+cd_end_pk+"-rs-"+rs_pk+"-nuevotag").val().trim();
            }));
        });

        $(keypres_nuevo).on('keypress', function(e) {
            if(13==e.which && $(this).val().trim()!="") {
                var val=$(this).val().trim();
                return(create_tag_ref($(this), function() {  return val }));
            }
        });
    };



   var update_show_pred_generic=function(div_id, selector_class, split_string) {
        div_id = typeof div_id !== 'undefined' ? div_id : false;
        var selector_action=get_selector(div_id , selector_class );
        //console.log(selector_action);
        $(selector_action).unbind("click");
        $(selector_action).click(function() {
            var id=$(this).attr("id");
            var partes=id.split(split_string);
            var base=partes[0];
            //console.log("#"+base+ split_string+"_mostrar_pred");
            $("#"+base+" .tag-predeterminado").removeClass("hidden");
            $("#"+base+ split_string+"mostrar_pred").hide();
        });
    };


    var update_show_pred_cd=function(div_id) {
        update_show_pred_generic(div_id, ".mostrar_pred","_");
    };

    var update_show_pred_ref=function(div_id) {
        update_show_pred_generic(div_id, ".mostrar_pred_ref","__");
    };

    var update_typeahead_generic=function(div_id, selector_class, source) {
        div_id = typeof div_id !== 'undefined' ? div_id : false;
        var selector=get_selector(div_id, selector_class);
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
                source: source
            });
    };

    var update_typeahead_cd=function(div_id) {
        update_typeahead_generic(div_id, ".nuevo_tag_cd_rs",tagsQuery);
    };

    var update_typeahead_ref=function(div_id) {
        update_typeahead_generic(div_id, ".nuevo_tag_cd_rs_ref",tagsRefQuery);
    };

})(TagManager);

var tagsQuery=TagManager.create_bloodhound('/tags/basic_10.json','/tags/query_json/%QUERY');
var tagsRefQuery=TagManager.create_bloodhound('/tags/basic_ref_10.json','/tags/refs/query_json/%QUERY');




$(document).ready(function() {
    TagManager.update();
});