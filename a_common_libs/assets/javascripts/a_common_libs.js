// Namespace declaration
$(document).ready(function(){
  $('select.select2, input[type="hidden"], input.ui-autocomplete-input').each(function(){
    if (this.getAttribute('data-combobox') === 'true'){
      RMPlus.Utils.makeSelect2Combobox(this);
    }
    else {
      if (this.tagName.toLowerCase() === 'select') {
        var select2_width = this.getAttribute('data-select2-width');
        var placeholder = this.getAttribute('placeholder') || ' ';
        if (select2_width != undefined){
          $(this).select2({ width: select2_width, allowClear: true, placeholder: placeholder });
        }
        else {
          $(this).select2({ width: '400px', allowClear: true, placeholder: placeholder });
        }
      }
    }
  });

  $(document.body).on('click', 'div.period_picker_input, .period_picker_max_min', function(){
    $('div.period_picker_box .period_picker_cell[data-date="' + moment().format('YYYY-MM-DD') + '"]').addClass('acl_picker_today');
    // $('div.period_picker_box.xdsoft_noselect.visible.active .period_picker_cell[data-date="' + moment().format('YYYY-MM-DD') + '"]').addClass('acl_picker_today');
  });
  var original_buildFilterRow = buildFilterRow;

  buildFilterRow = function(field, operator, values){
    original_buildFilterRow.apply(this, arguments);
    var fieldId = field.replace('.', '_');
    var filterOptions = availableFilters[field];

    if(filterOptions['type'] == 'acl_date_time'){
      var td_value = $('#tr_' + field).find('td.values');
      td_value.html('');
      td_value.append('<span><input type="text" name="v['+ field +'][]" id="values_'+ fieldId +'_1" size="10" class="value" /></span>'+
                      '<span style="display: none;"> — <input type="text" name="v['+ field +'][]" id="values_'+ fieldId +'_2" size="10" class="value"/></span>');

      if($().periodpicker){
        $('#values_'+fieldId+'_1').val(values[0]).periodpicker(datetimepickerOptions);
        $('#values_'+fieldId+'_2').val(values[1]).periodpicker(datetimepickerOptions);
      }

    }
  };

  var original_enableValues = enableValues;

  enableValues = function(field, indexes){
    original_enableValues.apply(this, arguments);
    $('#values_' + field + '_1' + ' + .period_picker_input').prev().hide();
    $('#values_' + field + '_2' + ' + .period_picker_input').prev().hide();
  };

  $(document.body).on('click', '.acl_ajax_edit', function () {
    var target = $(this).attr('data-target') || (this.id ? ('modal-' + this.id) : 'form_ajax');
    var form_div = $('#' + target);
    if (form_div.length == 0) {
      form_div = $('<div id="' + target + '" class="modal I fade" role="dialog" aria-hidden="true" data-height="90%" style="z-index: 1060;"></div>');
      $(document.body).prepend(form_div);
    }
    var width = $(this).attr('data-width');
    if (width) {
      form_div.attr('data-width', width);
    } else if (!form_div.attr('data-width')) {
      form_div.attr('data-width', '1050px');
    }

    form_div.html('<div class="loader form_loader"></div>');
    form_div.modal('show');
    var url = this.tagName == 'A' ? this.href : this.getAttribute('data-url');
    form_div.load(url, function () {
      $('.tabs-buttons').hide();
      RMPlus.LIB.resize_bs_modal(form_div);
    });
    return false;
  });

});


