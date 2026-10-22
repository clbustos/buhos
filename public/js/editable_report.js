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
    $(document).on('click', '.report-resolved-button', function () {
        var button = $(this);
        if (button.prop('disabled')) return;
        var resolved = button.attr('data-resolved') !== 'true';
        button.prop('disabled', true);
        $.ajax({url: button.data('url'), type: 'PUT', dataType: 'json', data: {resolved: String(resolved)}})
            .done(function (response) {
                button.attr('data-resolved', String(resolved));
                button.attr('aria-pressed', String(resolved));
                button.attr('title', button.attr(resolved ? 'data-reopen-label' : 'data-resolve-label'));
                button.toggleClass('btn-success', resolved).toggleClass('btn-default', !resolved);
                button.find('.report-state-icon').toggleClass('glyphicon-ok-circle', resolved).toggleClass('glyphicon-time', !resolved);
                button.find('.report-status').text(response.label);
            }).fail(function () {
                alert(button.attr('data-error-label'));
            }).always(function () {
                button.prop('disabled', false);
            });
    });
});
