var CriteriaManager={};

(function(context)  {
    context.update=function(div_id) {
        update_action_buttons(div_id);
    };

    var get_selector=function(div_id, div_class) {
        result=div_id ? div_id+ " "+ div_class: div_class;
        return(result);
    };
    var update_action_buttons=function(div_id) {
        div_id = typeof div_id !== 'undefined' ? div_id : false;

        var add_action= get_selector(div_id, ".criteria-list .add_criteria");
        var del_action= get_selector(div_id, ".criteria-list .del_criteria");


        $(add_action).unbind("click");

        $(add_action).click(function(e) {
          var url       =   $(this).attr("data-url");
          var parts     =   $(this).attr('id').split("-");
          var sr_id     =   parts[2];
          var cr_type   =   parts[3];
          var text=$("#criteria-"+cr_type+"-new").val();
          if(text==="") {
              return(false);
          }
            $.post(url, {sr_id:sr_id, cr_type:cr_type, text:text}, function (data) {
                $("#criteria-"+cr_type).html(data);
                update_action_buttons("#criteria-"+cr_type);
                return(false);
            }).fail(function () {
                alert("Criteria: Can't add the criterion");
                return(false);
            });
          return(false);
        });

        $(del_action).unbind("click");
        $(del_action).click(function(e) {
            var url       =   $(this).attr("data-url");
            var parts     =   $(this).attr('id').split("-");

            var sr_id     =   parts[2];
            var cr_type   =   parts[3];
            var cr_id   =     parts[4];
            $.post(url, {sr_id:sr_id, cr_type:cr_type, cr_id:cr_id}, function (data) {
                $("#criteria-"+cr_type).html(data);
                update_action_buttons("#criteria-"+cr_type);
                return(false);
            }).fail(function () {
                alert("Criteria: Can't remove the criterion");
                return(false);
            });
            return(false);
        });


    };


})(CriteriaManager);

$(document).ready(function() {
    CriteriaManager.update();
});