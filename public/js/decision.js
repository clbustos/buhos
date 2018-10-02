function actualizar_decision(stage,div_id) {
    div_id = typeof div_id !== 'undefined' ? div_id : false;
    var selector_action=div_id ? div_id+" .dc_decision" : '.dc_decision';
    var checked_action=div_id ? div_id+" .criteria_cd_user": ".criteria_cd_user";


    $(selector_action).unbind("click");
    $(checked_action).unbind("click");

    $(checked_action).click(function() {
        var cd_id= $(this).attr("data-cd-id");
        var sr_id= $(this).attr("data-sr-id");
        var user_id= $(this).attr("data-user-id");
        var criterion_id= $(this).attr("data-criterion-id");
        var url= $(this).attr("data-url");
        var presence=$(this).attr("data-presence");
        var div_replace="#criteria-user-" + sr_id+"-"+cd_id+"-"+user_id;
        var div_decision="#decision-cd-" + cd_id;

        $.post(url, {cd_id: cd_id, sr_id:sr_id, user_id:user_id, presence:presence, criterion_id:criterion_id}, function (data) {
            $(div_replace).html(data);
            actualizar_decision(stage,div_decision);
            actualizar_textarea_editable(div_decision);
            TagManager.update(div_decision);
        }).fail(function (data) {
            console.log(data);
            alert("Can't update criteria.");
        });


    });

    $(selector_action).click(function () {
        var pk_id = $(this).attr("data-pk");
        var decision = $(this).attr("data-decision");
        var user_id = $(this).attr("data-user");
        var only_buttons= $(this).attr("data-onlybuttons");
        var url = $(this).attr("data-url");
        //var commentary=$("#commentary-"+pk_id).val()
        var boton = $(this);
        boton.prop("disabled", true);
        var div_replace="#decision-cd-" + pk_id;
        $.post(url, {pk_id: pk_id, decision: decision, user_id: user_id, only_buttons:only_buttons}, function (data) {
            $(div_replace).html(data);
            actualizar_decision(stage,div_replace);
            actualizar_textarea_editable(div_replace);


            TagManager.update(div_replace);
            // Tengo que considerar los tags...
            // actualizar_tags_cd_rs(div_replace);
            // actualizar_typeahead(div_replace);
            // actualizar_mostrar_pred(div_replace);

        }).fail(function () {
            alert("Can't load decision")
        });
    })

}
