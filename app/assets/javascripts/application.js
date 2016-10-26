// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery.matchHeight
//= require jquery-tablesorter
//= require jquery.keyDecoder
//= require nicEdit
//= require moment
//= require bootstrap-sprockets
//= require bootstrap-datetimepicker
//= require bootstrap.treeview
//= require bootstrap-toggle
//= require codemirror
//= require codemirror/addons/runmode/runmode
//= require codemirror/addons/selection/active-line
//= require codemirror/modes/clike
//= require codemirror/modes/javascript
//= require codemirror/modes/scheme
//= require_tree .



// Based on https://stackoverflow.com/questions/14324919/status-of-rails-link-to-function-deprecation
function enableReflectiveCalls() {
  $('[data-on][data-call][data-args]').each(function(d){
    if ($(this).data("already-enabled-reflective-call")) return;
    var event = $(this).data('on');
    $(this).on(event, function(e) {
      var toCall = $(this).data('call');
      var args = $(this).data('args')
      if (typeof(window[toCall]) !== 'function')
        throw new Error("No such function to call: " + toCall);
      if (!(args instanceof Array))
        throw new Error("Arguments are not an array: " + args);
      args = args.slice();
      args.push(e);
      window[toCall].apply(this, args);
    });
    $(this).data("already-enabled-reflective-call", true);
  });
}


var validKeys = {
  "ArrowLeft": true,
  "ArrowRight": true,
  "Backspace": true,
  "Delete": true,
  "End": true,
  "Home": true,
  "Tab": true,
};
var validKeyCodes = {
  9: true
};

function validateNumericInput(e) {
  if (validKeys[e.key] || validKeyCodes[e.keyCode]) return;
  if (e.key.match(/^F\d+$/)) return;
  if (!Number.isNaN(Number(e.key)) && (Number(e.key) == Number.parseInt(e.key))) return;
  if (e.key === "." && e.currentTarget.value.indexOf(".") < 0) return;
  if (e.key === "-" && e.currentTarget.value.indexOf("-") < 0 && e.currentTarget.selectionStart === 0) return;
  if (e.ctrlKey || e.altKey || e.metaKey) return;
  e.preventDefault();
};

function ensureValidNumericInputOnSubmit(e) {
  var problems = false;
  $("input.numeric").each(function(elt) {
    if (Number.isNaN(Number($(this).val()))) {
      problems = true;
      $(this)
        .addClass("badAnswer")
        .one("focus", function() { $(this).removeClass("badAnswer"); });
    }
  });
  if (problems) {
    e.preventDefault();
    alert("There are invalid values for some of the fields; please correct them before submitting.");
  }
}

$(function() {
  $('[data-toggle="tooltip"]').tooltip()
  
  $('.local-time').each(function(_) {
    var dd = moment(Date.parse($(this).text()));
    if (!dd.isValid()) { dd = moment($(this).text()); }
    
    if (dd.isValid()) {
      var today = moment().startOf('day');
      var tomorrow = moment(today).add(1, 'days');
      var twodays = moment(tomorrow).add(1, 'days');
      if (today.isSameOrBefore(dd) && dd.isBefore(tomorrow))
        $(this).text("Today, " + dd.format("h:mm:ssa"));
      else if (tomorrow.isSameOrBefore(dd) && dd.isBefore(twodays))
        $(this).text("Tomorrow, " + dd.format("h:mm:ssa"));
      else
        $(this).text(dd.format("MMM D YYYY, h:mm:ssa"));
    }
  });
  
  $("input.numeric").on("keydown", validateNumericInput);
})


function activateSpinner(obj, options) {
  var spinner = $(obj || this);
  var input = spinner.find('input');
  var upArrow = spinner.find('.btn:first-of-type');
  var downArrow = spinner.find('.btn:last-of-type');
  var upInterval, downInterval;
  var delta = input.data("delta") || 1;
  var max = input.data("max");
  var min = input.data("min");
  var val = parseFloat(input.val(), 10);
  var precision = parseInt((options && options.precision) || spinner.data("precision") || "0");
  if (max !== undefined && val >= max)
    upArrow.addClass("disabled");
  if (min !== undefined && val <= min)
    downArrow.addClass("disabled");
  function validate() {
    max = input.data("max");
    min = input.data("min");
    var val = parseFloat(input.val(), 10);
    if (max !== undefined && val >= max) {
      upArrow.addClass("disabled");
      clearInterval(upInterval);
      upInterval = undefined;
    }
    if (min === undefined || val > min)
      downArrow.removeClass("disabled");
    if (min !== undefined && val <= min) {
      downArrow.addClass("disabled");
      clearInterval(downInterval);
      downInterval = undefined;
    }
    if (max === undefined || val < max)
      upArrow.removeClass("disabled");
  }
  input.on("change", validate);
  function increment() {
    var newVal = (parseFloat(input.val(), 10) || 0) + delta;
    if (max !== undefined) {
      newVal = Math.min(max, newVal);
    }
    input.val(newVal.toFixed(precision)).change();
  }
  function decrement() {
    var newVal = (parseFloat(input.val(), 10) || 0) - delta;
    if (min !== undefined) {
      newVal = Math.max(min, newVal);
    }
    input.val(newVal.toFixed(precision)).change();
  }
  input.on("keydown", function(e) {
    validateNumericInput(e);
    if (e.key === "ArrowUp") { increment(); return; }
    if (e.key === "ArrowDown") { decrement(); return; }
    if (e.key === "ArrowLeft" || e.key === "ArrowRight") { return; }
    var curVal = $(this).val();
    var newVal = curVal.slice(0, this.selectionStart) + e.key + curVal.slice(this.selectionEnd, curVal.length);
    newVal = parseFloat(newVal, 10);
    if (max !== undefined && newVal > max) { e.preventDefault(); }
    if (min !== undefined && newVal < min) { e.preventDefault(); }
  });
  
  $(upArrow).on('mousedown', function() {
    upInterval = setInterval(increment, 200);
    increment();
  });
  $(downArrow).on('mousedown', function() {
    downInterval = setInterval(decrement, 200);
    decrement();
  });
  $(document).on('mouseup', function() {
    if (upInterval) clearInterval(upInterval);
    if (downInterval) clearInterval(downInterval);
    upInterval = undefined;
    downInterval = undefined;
    return false;
  });
  return input;
}

function makeSpinner(options) {
  var input = $("<input>")
      .addClass("form-control numeric")
      .val(options.val || 0)
      .bind("paste", function(e) { e.preventDefault(); });
  if (options.klass !== undefined)
    input.addClass(options.klass);
  if (options.max !== undefined)   input.data("max", options.max);
  if (options.min !== undefined)   input.data("min", options.min);
  if (options.delta !== undefined) input.data("delta", options.delta);
  var div = $("<div>").addClass("input-group spinner")
      .append(input)
      .append($("<div>").addClass("input-group-btn-vertical")
              .append($("<button>").addClass("btn btn-default")
                      .append($("<i>").addClass("fa fa-caret-up")))
              .append($("<button>").addClass("btn btn-default")
                      .append($("<i>").addClass("fa fa-caret-down"))));
  activateSpinner(div, options);
  return div;
}

$(function() {
  function fixSizes() {
    var $affixElement = $('[data-spy="affix"]');
    $affixElement.width($affixElement.parent().width());
  }
  $(window).resize(fixSizes);
  fixSizes();
});
