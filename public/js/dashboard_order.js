(function () {
  var list = document.getElementById('dashboard-reviews');
  if (!list) return;
  var dragged, saving = false;
  var error = document.getElementById('dashboard-order-error');

  list.addEventListener('dragstart', function (event) {
    if (saving || !event.target.matches('.dashboard-drag-handle')) {
      event.preventDefault();
      return;
    }
    dragged = event.target.closest('.dashboard-review');
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', dragged.dataset.reviewId);
  });
  list.addEventListener('dragend', function () { dragged = null; });
  list.addEventListener('dragover', function (event) {
    if (dragged && !saving) {
      event.preventDefault();
      event.dataTransfer.dropEffect = 'move';
    }
  });
  list.addEventListener('drop', function (event) {
    if (!dragged || saving) return;
    event.preventDefault();
    var target = event.target.closest('.dashboard-review');
    if (!target || target === dragged) return;
    var previous = Array.from(list.children);
    var bounds = target.getBoundingClientRect();
    list.insertBefore(dragged, event.clientY < bounds.top + bounds.height / 2 ? target : target.nextSibling);
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
