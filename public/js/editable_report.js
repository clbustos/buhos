function actualizar_reportes(div_id) {
    div_id = typeof div_id !== 'undefined' ? div_id : false;
    var selector_action = div_id ? div_id + " .document-report-editable" : ".document-report-editable";

    $(selector_action).each(function () {
        var reportButton = $(this);
        var source = reportButton.data('source');
        var currentValue = reportButton.attr('data-value');
        var selectedReports = currentValue ? currentValue.split(',') : [];

        reportButton.editable({
            type: 'checklist',
            value: selectedReports,
            mode: 'popup',
            placement: 'bottom',
            showbuttons: true,
            display: false,
            highlight:false,
            ajaxOptions: {
                type: 'put',
                dataType: 'json'
            },
            source: source,
            success: function (response, newValue) {
                var selected = response && response.selected ? response.selected : newValue;
                var selectedCount = selected ? selected.length : 0;
                var countBadge = $(this).find('.document-report-count');

                $(this).toggleClass('btn-warning', selectedCount > 0);
                $(this).toggleClass('btn-default', selectedCount === 0);
                $(this).attr('data-value', selected ? selected.join(',') : '');
                countBadge.text(selectedCount);
                countBadge.toggleClass('hidden', selectedCount === 0);
            }
        });
    });
}

$(document).ready(function () {
    actualizar_reportes();
});
