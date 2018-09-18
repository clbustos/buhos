var CriteriaManager={};

(function(context)  {
    var counter=1;
    context.update=function(div_id) {
        update_action_buttons(div_id);
    };
    context.create_criterion=function(sr_id, type, text) {
        $("#criteria-"+sr_id+"-"+type+"-list").append(create_li(text, sr_id, type));
    };
    context.create_new=function(sr_id, type, placeholder) {
        $("#criteria-"+sr_id+"-"+type+"-list").append(create_new(sr_id, type, placeholder));
    };

    var create_new=function(sr_id, type, placeholder) {
        suffix=sr_id+"-"+type;
        html="<li class='list-group-item'>\n"+
        "<input type='text' id='criteria-"+suffix+"-new' placeholder='"+placeholder+"' >\n"+
        "<button class='btn btn-default add_criterion' id='criteria-"+suffix+"-add'>\n"+
        "<span class='glyphicon glyphicon-plus'>\n"
        return(html);
    };
    var create_li=function(text, sr_id, type) {
      suffix=sr_id+"-"+type+"-"+counter;
      html="<li class='list-group-item' id='criteria-"+suffix+"-li'>   \n" +
          text +
          "<input type='hidden' id='criteria-"+suffix+"-value'  name='criteria["+type+"][]' value='"+text+"' />"+
          "<div class='btn-group btn-sm'>\n" +
          //"<button class='btn btn-default edit_criterion' id='criteria-edit-"+suffix+"'>\n" +
          //"<span class='glyphicon glyphicon-edit'></span>\n" +
          "</button>\n" +
          "<button class='btn btn-default remove_criterion' id='criteria-"+suffix+"-remove'>\n" +
          "<span class='glyphicon glyphicon-minus'></span>\n" +
          "</button>\n" +
          "</div>\n" +
          "</li>";
        counter+=1;
        return(html);
    };

    var get_parts=function(id) {
        parts=id.split("-");
        if(parts.length==4) {
            return({sr_id:parts[1], type:parts[2], action:parts[3]});
        } else if(parts.length==5) {
            return({sr_id:parts[1], type:parts[2], counter:parts[3], action:parts[4]});
        }
    };

    var get_element_by_parts=function(parts, suffix) {
        return($("#criteria-"+parts.sr_id+"-"+parts.type+"-"+suffix));
    };

    var get_selector=function(div_id, div_class) {
        result=div_id ? div_id+ " "+ div_class: div_class;
        return(result);
    };
    var update_action_buttons=function(div_id) {
        div_id = typeof div_id !== 'undefined' ? div_id : false;

        var add_action= get_selector(div_id, ".criteria-list .add_criterion");
        var del_action= get_selector(div_id, ".criteria-list .remove_criterion");
        var edit_action= get_selector(div_id, ".criteria-list .edit_criterion");

        console.log(del_action);
        $(add_action).unbind("click");

        $(add_action).click(function(e) {
            e.preventDefault();
            var parts=get_parts($(this).attr("id"));
            //console.log(parts);
            var text_value=get_element_by_parts(parts,'new').val();
            var list=get_element_by_parts(parts,'list');
            if(text_value.chomp!="") {
                list.prepend(create_li(text_value, parts.sr_id, parts.type));
                get_element_by_parts(parts,'new').val("");
                update_action_buttons();
            }
        });

        $(del_action).unbind("click");

        $(del_action).click(function(e) {
            e.preventDefault();
            var parts=get_parts($(this).attr("id"));
            console.log(parts);
            $("#criteria-"+parts.sr_id+"-"+parts.type+"-"+parts.counter+"-li").remove();
        });


        $(edit_action).unbind("click");
        $(edit_action).click(function(e) {
            e.preventDefault();
        });

    };


})(CriteriaManager);

$(document).ready(function() {
    CriteriaManager.update();
});