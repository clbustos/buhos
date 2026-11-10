(function () {
  var list = document.getElementById('dashboard-reviews');
  if (!list) return;
  var dragged, saving = false;
  var error = document.getElementById('dashboard-order-error');
  var indicator = document.createElement('div');
  indicator.style.cssText = 'position:absolute;height:1px;background:#000;pointer-events:none;z-index:1000;';
  indicator.hidden = true;
  indicator.setAttribute('aria-hidden', 'true');
  document.body.appendChild(indicator);

  function destination(event) {
    var target = event.target.closest('.dashboard-review');
    if (!target || target === dragged) return null;
    var bounds = target.getBoundingClientRect();
    return { target: target, before: event.clientY < bounds.top + bounds.height / 2, bounds: bounds };
  }

  list.addEventListener('dragstart', function (event) {
    if (saving || !event.target.matches('.dashboard-drag-handle')) {
      event.preventDefault();
      return;
    }
    dragged = event.target.closest('.dashboard-review');
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', dragged.dataset.reviewId);
  });
  list.addEventListener('dragend', function () {
    dragged = null;
    indicator.hidden = true;
  });
  list.addEventListener('dragleave', function (event) {
    if (!list.contains(event.relatedTarget)) indicator.hidden = true;
  });
  list.addEventListener('dragover', function (event) {
    if (dragged && !saving) {
      event.preventDefault();
      event.dataTransfer.dropEffect = 'move';
      var place = destination(event);
      indicator.hidden = !place;
      if (place) {
        indicator.style.left = (place.bounds.left + window.scrollX) + 'px';
        indicator.style.top = ((place.before ? place.bounds.top : place.bounds.bottom) + window.scrollY) + 'px';
        indicator.style.width = place.bounds.width + 'px';
      }
    }
  });
  list.addEventListener('drop', function (event) {
    indicator.hidden = true;
    if (!dragged || saving) return;
    event.preventDefault();
    var place = destination(event);
    if (!place) return;
    var previous = Array.from(list.children);
    list.insertBefore(dragged, place.before ? place.target : place.target.nextSibling);
    dragged = null;
    var current = Array.from(list.children);
    if (current.every(function (item, index) { return item === previous[index]; })) return;
    var body = new URLSearchParams();
    current.forEach(function (item) { body.append('review_ids[]', item.dataset.reviewId); });
    saving = true;
    error.hidden = true;
    fetch(list.dataset.orderUrl, { method: 'POST', body: body, credentials: 'same-origin' })
      .then(function (response) {
        if (!response.ok || response.redirected) throw new Error('Order not saved');
      })
      .catch(function () {
        previous.forEach(function (item) { list.appendChild(item); });
        error.hidden = false;
      })
      .then(function () { saving = false; });
  });
})();
