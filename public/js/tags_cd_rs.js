var tagsQuery=new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    prefetch: '/tags/basic_10.json',
    remote: {
        url: '/tags/query_json/%QUERY',
        wildcard: '%QUERY'
    }
});



var TagManager={};

(function(context)  {
    context.update=function(div_id) {
        update_tags_cd_rs(div_id);
        update_typeahead(div_id);
        update_show_pred(div_id);
    };
    var send_post_create_tag=function(url,val,cd_pk,rs_pk) {
        if(val.trim()=="") {
            alert("TAG: No text")
        } else {
            $.post(url, {value: val}, function (data) {
                var div_id="#tags-cd-"+cd_pk+"-rs-"+rs_pk;
                $(div_id).replaceWith(data);
                context.update();
            }).fail(function () {
                alert("TAG: Can't create (server error)")
            })
        }
    };

    var get_selector=function(div_id, div_class) {
        result=div_id ? div_id+ " "+ div_class: div_class;
        return(result);
    };
    var create_tag=function(e, FUNC) {
        var url=e.attr("data-url");
        var cd_pk=e.attr("cd-pk");
        var rs_pk=e.attr("rs-pk");
        val=FUNC(cd_pk, rs_pk);

        send_post_create_tag(url,val, cd_pk,rs_pk);
        return(false);
    };

    var update_tags_cd_rs=function(div_id) {

        div_id = typeof div_id !== 'undefined' ? div_id : false;

        var selector_accion= get_selector(div_id, " .boton_accion_tag_cd_rs");
        var selector_nuevo = get_selector(div_id, ".boton_nuevo_tag_cd_rs");
        var keypres_nuevo= get_selector( div_id, ".nuevo_tag_cd_rs");

        $(selector_accion).unbind("click");
        $(selector_nuevo).unbind("click");
        $(keypres_nuevo).unbind("keypress");

        $(selector_accion).click(function(){
            var url=$(this).attr("data-url");
            var cd_pk=$(this).attr("cd-pk");
            var rs_pk=$(this).attr("rs-pk");
            var tag_id=$(this).attr("tag-pk");
            $.post(url, {tag_id:tag_id}, function (data) {
                var div_id="#tags-cd-"+cd_pk+"-rs-"+rs_pk;
                $(div_id).replaceWith(data);
                context.update(div_id);
            }).fail(function () {
                alert("TAG: Can't run the action")
            })

        });

        $(selector_nuevo).click(function() {
            return(create_tag ($(this), function(cd_pk, rs_pk) {return $("#tag-cd-"+cd_pk+"-rs-"+rs_pk+"-nuevotag").val().trim();}));
        });

        $(keypres_nuevo).on('keypress', function(e) {
            if(13==e.which && $(this).val().trim()!="") {
                var ee=$(this);
                return(create_tag($(this), function(cd_pk,rs_pk) {  return ee.val().trim(); }));
            }
        });
    };
    var update_show_pred=function(div_id) {
        div_id = typeof div_id !== 'undefined' ? div_id : false;
        var selector_action=div_id ? div_id+" .mostrar_pred" : '.mostrar_pred';
        //console.log(selector_action);
        $(selector_action).unbind("click");
        $(selector_action).click(function() {
            var id=$(this).attr("id");
            var partes=id.split("_");
            var base=partes[0];
            $("#"+base+" .tag-predeterminado").removeClass("hidden");
            $("#"+base+"_mostrar_pred").hide();
        });
    };

    var update_typeahead=function(div_id) {
        div_id = typeof div_id !== 'undefined' ? div_id : false;
        var selector=div_id ? div_id+" .nuevo_tag_cd_rs" : '.nuevo_tag_cd_rs';
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
                source: tagsQuery
            });
    };
})(TagManager);





$(document).ready(function() {

    TagManager.update();
});