/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function($) {
  var rows_per_subtable = 250;

  function beat(def,sleeplen) {
    return def.then(function(data) {
      var d = $.Deferred();
      setTimeout(function() { d.resolve(data); },sleeplen);
      return d;
    });
  }

  function loop(def,fn,group,sleeplen) {
    return def.then(function(raw_input) {
      var input = [];
      $.each(raw_input,function(a,b) { input.push([a,b]); });
      d = $.Deferred().resolve(input);
      var output = [];
      for(var ii=0;ii<input.length;ii+=group) {
        (function(i) {
          d = beat(d.then(function(j) {
            for(j=0;j<group && i+j<input.length;j++) {
              var c = fn(input[i+j][0],input[i+j][1]);
              if(c !== undefined) {
                output.push(c);
              }
            }
            return $.Deferred().resolve(output);
          }),sleeplen);
        })(ii);
      }
      return d;
    });
  }

  function new_th(key,cc) {
    var text = cc.label || cc.title || key;
    var attrs = {};
    var classes = [];
    attrs['data-key'] = key || '';
    if(cc.sort)  { classes.push('sorting'); }
    if(cc.help) {
      var help = $('<div/>').text(cc.help).html();
      text =
        '<span class="ht _ht" title="'+help+'">'+text+'</span>';
    }
    var attr_str = "";
    $.each(attrs,function(k,v) {
      attr_str += ' '+k+'="'+v+'"';
    });
    if(classes.length) {
      attr_str += ' class="'+classes.join(' ')+'"';
    };
    return "<th "+attr_str+">"+text+"</th>";
  }

  // TODO fix widths on load
  // TODO initial orient
  function fix_widths($table,config,orient) {
    var totals = { u: 0, px: 0 };
    var widths = [];
    $.each(config.columns,function(i,key) {
      var cc = config.colconf[key];
      var m = cc.width.match(/^(\d+)(.*)$/)
      if(cc.type && cc.type.screen && cc.type.screen.unshowable) { return; }
      if(orient.off_columns && orient.off_columns[key]) { return; }
      widths.push([m[1],m[2]]);
      if(m[2] == 'u' || m[2] == 'px') {
        totals[m[2]] += parseInt(m[1]);
      }
    });
    var table_width = $table.width();
    totals['px'] *= 100/table_width;
    if(totals['px'] > 100) { totals['px'] = 100; }
    totals['u'] = (100-totals['px']) / (totals['u']||1);
    var $head = $('table:first th',$table);
    var j = 0;
    $.each(config.columns,function(i,key) {
      var cc = config.colconf[key];
      if(cc.type && cc.type.screen && cc.type.screen.unshowable) { return; }
      if(orient.off_columns && orient.off_columns[key]) { return; }
      var $th = $head.eq(j);
      $th.css('width',(widths[j][0]*totals[widths[j][1]])+"%");
      j++;
    });
  }

  function new_header($table,config) {
    var columns = [];

    $.each(config.columns,function(i,key) {
      var cc = config.colconf[key];
      // TODO to plugin
      if(cc.type && cc.type.screen && cc.type.screen.unshowable) {
        return;
      }
      columns.push(new_th(key,cc));
    });
    return '<thead><tr>'+columns.join('')+"</tr></thead>";
  }
 
  function header_fix($table,orient) {
    var off = orient.off_columns || {};
    $('th',$table).each(function() {
      var $th = $(this);
      if(off[$th.data('key')]) { $th.hide(); } else { $th.show(); }
    });
  }

  function sort_for_col(config,col) {
    // TODO pluginise this
    var out = col;
    $.each(config.colconf,function(key,cc) {
      if(cc.type && cc.type.sort_for && cc.type.sort_for.col == col) {
        out = key;
      }
    });
    return out;
  }
 
  function add_sort($table,config,key,clear) {
    // Update data
    var view = $table.data('view');
    var sort = [];
    if(view && view.sort) { sort = view.sort; }
    var new_sort = [];
    var dir = 0;
    var sort_col = sort_for_col(config,key);
    $.each(sort,function(i,val) {
      if(val.key == sort_col) {
        dir = -val.dir;
      } else if(!clear) {
        new_sort.push(val);
      }
    });
    if(!dir) { dir = 1; }
    new_sort.push({ key: sort_col, dir: dir });
    view.sort = new_sort;
    $table.data('view',view);
    $table.trigger('view-updated');
    // Reflect data in display
    $('th',$table).removeClass('sorting_asc').removeClass('sorting_desc');
    $.each(new_sort,function(i,val) {
      var dir = val.dir>0?'asc':'desc';
      $('th[data-key="'+key+'"]').addClass('sorting_'+dir);
    }); 
  }

  function new_subtable($table) {
    var $out = $('<div class="subtable"><table><tbody></tbody></table></div>');
    $out.on('awaken',function() { wakeup($table,$out); });
    $out.on('sleepen',function() { sleep($out); });
    guess_subtable_sizes($table);
    return $out;
  }

  function guess_subtable_sizes($table) {
    var h_n = 0;
    var h_d = 0;
    $('.subtable',$table).each(function() {
      var $this = $(this);
      var h = $this.data('known-height');
      if(h) { h_n += h; h_d++; }
    });
    var h = rows_per_subtable * 50;
    //if(h_d) { h = h_n/h_d; }
    $('.subtable',$table).each(function() {
      var $this = $(this);
      if(!$this.data('known-height')) {
        $this.css('height',h+'px');
      }
    });
  }

  function extend_rows($table,target) {
    var $subtables = $('.subtable',$table);
    target -= $subtables.length*rows_per_subtable;
    while(target > 0) {
      var $subtable = new_subtable($table).appendTo($('.newtable_tabular',$table));
      $subtable.lazy();
      var to_add = target;
      if(to_add > rows_per_subtable)
        to_add = rows_per_subtable;
      target -= to_add;
    }
    $.lazy('refresh');
  }

  function retreat_rows($table,config,orient,grid,rev_series) {
    var last_table = Math.floor(grid.length/rows_per_subtable);
    $('.subtable',$table).each(function(i) {
      if(i>last_table) {
        $(this).remove();
      } else if(i==last_table) {
        remarkup($table,config,grid,rev_series,i,rows_per_subtable,orient);
      }
    });
    $.lazy('refresh');
  }
  
  function build_markup($table,config,grid,rev_series,table_num,orient) {
    var markup = [];
    var shown = [];
    for(var i=0;i<config.columns.length;i++) {
      var cc = config.colconf[config.columns[i]];
      if(cc.type && cc.type.screen && cc.type.screen.unshowable) {
        continue;
      }
      shown.push(rev_series[config.columns[i]]);
    }
    var start = table_num*rows_per_subtable;
    for(var i=start;i<start+rows_per_subtable && i<grid.length;i++) {
      var row = [];
      for(var j=0;j<shown.length;j++) {
        row[j] = grid[i][shown[j]]||'';
      }
      markup.push(row);
    }
    return markup;
  }

  function remarkup_sub($table,$subtable,config,grid,rev_series,table_num,orient) {
    var markup = build_markup($table,config,grid,rev_series,table_num,orient);
    $subtable.data('markup-orient',orient);
    var html = convert_markup($table,markup);
    $subtable.data('backing',html);
    $subtable.data('xxx',table_num);
  }

  function remarkup($table,config,grid,rev_series,start,rows,orient) {
    var subtabs = [];
    for(var j=start/rows_per_subtable;j<(start+rows)/rows_per_subtable;j++) {
      var $subtable = $('.subtable',$table).eq(j);
      remarkup_sub($table,$subtable,config,grid,rev_series,j,orient);
      subtabs.push(j);
    }
    return subtabs;
  }
  
  function convert_markup($table,markup) {
    var $th = $('table:first th',$table);
    var html = "";
    var keys = [];
    for(var j=0;j<$th.length;j++) {
      keys[j] = $th.eq(j).data('key');
    }
    for(var i=0;i<markup.length;i++) {
      html += "<tr>";
      for(var j=0;j<$th.length;j++) {
        var key = keys[j];
        var start = "<td>";
        if(i==0) {
          start = "<td style=\"width: "+$th.eq(j).width()+"px\">";
        }
        if(markup[i][j]) {
          html += start+markup[i][j]+"</td>";
        } else {
          html += start+"</td>";
        }
      }
      html += "</tr>";
    }
    return html;
  }

  function apply_html($table,table_num) {
    var $subtable = $($('.subtable',$table).eq(table_num));
    $subtable.data('redraw',1);
    $subtable.lazy(); // data has changed so not awake
    $.lazy('refresh');
    return $subtable;
  }

  function wakeup($table,$subtable) {
    if(!$subtable.data('redraw')) { return; }
    console.log("redrawing "+$subtable.data('xxx'));
    var html = $subtable.data('backing');
    $subtable.data('redraw',0);
    var $body = $('tbody',$subtable);
    if(!$body.length) {
      var $newtable = $('<table><tbody></tbody></table>');
      $subtable.empty().append($newtable);
    }
    $('tbody',$subtable)[0].innerHTML = html;
    $table.trigger('markup-activate',[$subtable]);
    $subtable.css('height','');
    $subtable.data('known-height',$subtable.height());
    guess_subtable_sizes($table);
    // The line below is probably more portable than the line above,
    //   but a third of the speed.
    //   Maybe browser checks if there are compat issues raised in testing?
    // $('tbody',$subtable).html(html);
    $.lazy('refresh');
  }

  function sleep($subtable) {
    $subtable.data('redraw',1);
    console.log("undrawing "+$subtable.data('xxx'));
    $subtable.css('height',$subtable.height()+'px');
    $subtable[0].innerHTML = '';
    $subtable.lazy();
  }

  function set_active_orient($subtable,active_orient) {
    var our_orient = $subtable.data('markup-orient');

    if(!$.orient_compares_equal(active_orient,our_orient)) {
      sleep($subtable);
    }
  }

  function replace_header($table,header) {
    $('thead',$table).replaceWith(header);
  }

  function eager() {
    $.lazy('eager');
    setTimeout(function() { eager(); },3000);
  }

  $.fn.new_table_tabular = function(config,data) {
    return {
      layout: function($table) {
        var header = new_header($table,config);
        return '<div class="new_table"><table>'+header+'<tbody></tbody></table><div class="no_results">Empty Table</div><div class="newtable_tabular"></div><div class="new_table_loading"><div>more rows loading</div></div>';
      },
      go: function($table,$el) {
        $('th',$table).click(function(e) {
          add_sort($table,config,$(this).data('key'),!e.shiftKey);
        });
        $.lazy('periodic',5000);
      },
      add_data: function($table,grid,series,start,num,orient) {
        var $subtables = $('.subtable',$table);
        fix_widths($table,config,orient);
        header_fix($table,orient);
        extend_rows($table,start+num);
        var rev_series = {};
        for(var i=0;i<series.length;i++) { rev_series[series[i]] = i; }
        var subtabs = remarkup($table,config,grid,rev_series,start,num,orient);
        d = $.Deferred().resolve(subtabs);
        var has_reset = false;
        var e = loop(d,function(tabnum,v) {
          var $subtable = apply_html($table,tabnum);
          if(!has_reset) {
            $subtables.each(function() {
              set_active_orient($(this),orient);
            });
            has_reset = true;
          }
        },1,10);
      },
      truncate_to: function($table,grid,series,orient) {
        if(length) {
          $('.no_results').hide();
        } else {
          $('.no_results').show();
        }
        var rev_series = {};
        for(var i=0;i<series.length;i++) { rev_series[series[i]] = i; }
        retreat_rows($table,config,orient,grid,rev_series);
      }
    };
  }; 
  eager();
})(jQuery);