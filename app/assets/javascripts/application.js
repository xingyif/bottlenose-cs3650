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

$(function() {
  $('[data-toggle="tooltip"]').tooltip()
  
  $('.local-time').each(function(_) {
    var dd = moment(Date.parse($(this).text()));
    if (!dd.isValid()) { dd = moment($(this).text()); }
    
    if (dd.isValid()) {
      var today = moment().startOf('day');
      if (today.isBefore(dd))
        $(this).text("Today, " + dd.format("h:mm:ssa"));
      else
        $(this).text(dd.format("MMM D YYYY, h:mm:ssa"));
    }
  });
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
  var precision = parseInt(options.precision || spinner.data("precision") || "0");
  if (max !== undefined && val >= max)
    upArrow.addClass("disabled");
  if (min !== undefined && val <= min)
    downArrow.addClass("disabled");
  function validate() {
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
    var newVal = parseFloat(input.val(), 10) + delta;
    if (max !== undefined) {
      newVal = Math.min(max, newVal);
    }
    input.val(newVal.toFixed(precision)).change();
  }
  function decrement() {
    var newVal = parseFloat(input.val(), 10) - delta;
    if (min !== undefined) {
      newVal = Math.max(min, newVal);
    }
    input.val(newVal.toFixed(precision)).change();
  }
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
}

function makeSpinner(options) {
  var input = $("<input>").addClass("form-control").val(options.val || 0);
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
  $("#lateness-configuration .equal-height-group")
    .matchHeight({byRow: false, property: 'height'});
  $('.spinner').each(function() { activateSpinner(this) });
});
$(function() {
  function fixSizes() {
    var $affixElement = $('[data-spy="affix"]');
    $affixElement.width($affixElement.parent().width());
  }
  $(window).resize(fixSizes);
  fixSizes();
});
