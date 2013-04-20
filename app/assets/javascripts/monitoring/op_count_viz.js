if (!op_count_viz) {
  var op_count_viz = {
    canvas_w: 600,
    canvas_h: 330,

    num_ops: 6,
    op_colors: ['#669966', '#587498', '#efd13b',
                '#e86850', '#79bedb', '#ff9933'],
    op_labels: ['INSERTS', 'QUERIES', 'UPDATES',
                'DELETES', 'GETMORES', 'COMMANDS'],

    // Will contain six Paper.JS PointText objects. Their text is ops/time.
    paper_op_counts: [],

    // Each will be an array of six aggregate op counts, not ops/time.
    old_op_counts: [null],
    new_op_counts: [null],

    // Contains six arrays of absolute y coordinates.
    op_data_points: [[], [], [], [], [], []],

    // Contains six Paper.JS Paths, each the shape of the data points
    // plus two base points at the bottom edge of the graph.
    op_graph_paths: [],

    top_bar_h: 30,
    side_bar_w: 100,
    side_swatch_w: 10,

    // The maximum number of operations per second the graph
    // can display: ((#inserts + #queries + ... + #commands) / sec)
    y_scale: 5000,

    // The number of seconds that display on the graph at one time.
    x_scale: 90,

    text_x: 20,
    op_y_offset: 21,
    label_y_offset: 34,
    
    // Graph axes and labels
    scale_layer: null,  // Paper.JS layer object so the scale is always on top
    y_scale_max: 2000,  // Ops per second
    y_label_text: [],   // Paper.JS PointText objects
    y_label_guides: [], // Paper.JS Line Paths
    num_y_labels: 4,
    y_scale_top_pad: 12,
    y_scale_text_offset: 7,
    
    x_point_width: 20,

    normal_text_style: {
      fontSize: 13,
      fillColor: 'white',
      font: 'Courier'
    },

    scale_text_style: {
      fontSize: 10,
      fillColor: 'gray',
      font: 'Helvetica'
    },

    title_text_style: {
      fontSize: 18,
      fillColor: 'white',
      font: 'Courier'
    },

  };
}


// The callback is broken out for testing purposes.
op_count_viz.callback = function(json) {
  op_count_viz.new_op_counts = json;
}


// This will change when the stats API is finished.
op_count_viz.get_op_counts = function(callback) {
  $.ajax({
    url: "/monitoring/opcounts",
    type: "GET",
    dataType: "json",

    success: callback,

    error: function( xhr, status ) {
      console.log("op_count_viz.get_op_counts: ajax op count request failed");
    },

    complete: function( xhr, status ) {}
  });
};


// Use the namespace from app/assets/javascripts/monitoring/op_count_viz.js
op_count_viz.draw_static = function() {
  var ocv = op_count_viz;

  //window.graph_canvas.width = ocv.canvas_w;
  //window.graph_canvas.height = ocv.canvas_h;

  // Top bar
  var top_bar = new Path.Rectangle(0, 0, ocv.canvas_w, ocv.top_bar_h);
  top_bar.fillColor = 'black';
  var top_bar_title = new PointText(10, 20);
  top_bar_title.characterStyle = ocv.title_text_style;
  top_bar_title.content = 'OPCOUNTERS';
  var top_bar_subtitle = new PointText(130, 18);
  top_bar_subtitle.characterStyle = ocv.scale_text_style;
  top_bar_subtitle.content = '[ops/sec]';

  // Side bar
  var side_bar_h = (ocv.canvas_h - ocv.top_bar_h) / ocv.num_ops;
  for (var i = 0; i < ocv.num_ops; ++i) {
    var y = ocv.top_bar_h + i * side_bar_h;
    
    var swatch = new Path.Rectangle(0, y, ocv.side_swatch_w, side_bar_h);
    swatch.fillColor = ocv.op_colors[i];
    
    var op_label = new PointText(ocv.text_x, y + ocv.label_y_offset);
    op_label.content = ocv.op_labels[i];
    op_label.characterStyle = ocv.normal_text_style;
  }

  // Guide line
  var gpath = new Path.Line([ocv.side_bar_w, ocv.top_bar_h], [ocv.side_bar_w, ocv.canvas_h]);
  gpath.strokeColor = 'white';
  gpath.strokeWidth = 0.25;

  // Y-axis: prelim scale = 2000 ops/sec total
  var y_label_spacing = (ocv.canvas_h - ocv.top_bar_h) / ocv.num_y_labels;
  ocv.scale_layer = new Layer();
  for (var i = 0; i < ocv.num_y_labels; ++i) {
    var y = ocv.canvas_h - (y_label_spacing * (i + 1));

    ocv.scale_layer.activate();          // A top layer ensuring scale text is on top.
    ocv.y_label_text[i] = new PointText(ocv.canvas_w, y + ocv.y_scale_text_offset);
    ocv.y_label_text[i].characterStyle = ocv.scale_text_style;
    ocv.y_label_text[i].paragraphStyle.justification = 'right';
    ocv.y_label_text[i].content = (ocv.y_scale_max / ocv.num_y_labels) * (i + 1);

    paper.project.layers[0].activate();  // The default project layer (everything else).
    ocv.y_label_guides[i] = new Path.Line([ocv.side_bar_w, y], [ocv.canvas_w, y]);
    ocv.y_label_guides[i].strokeColor = 'gray';
    ocv.y_label_guides[i].strokeWidth = 0.25;
  }
};


op_count_viz.init_graph = function() {
  var ocv = op_count_viz;
  var side_bar_h = (ocv.canvas_h - ocv.top_bar_h) / ocv.num_ops;
  for (var i = 0; i < ocv.num_ops; ++i) {
    var y = ocv.top_bar_h + i * side_bar_h;
    ocv.paper_op_counts.push(new PointText(ocv.text_x, y + ocv.op_y_offset));
    ocv.paper_op_counts[i].characterStyle = ocv.normal_text_style;

    ocv.op_graph_paths.push(new Path());
  }
};


// (This does not yet) Poll the statistics database for new opcount data
// and update the text opcounts along the left side of the graph.
op_count_viz.update_text = function() {
  var ocv = op_count_viz;
  var side_bar_h = (ocv.canvas_h - ocv.top_bar_h) / ocv.num_ops;

  // Allows the graph to start exactly when it has its first "real"
  // data point. In other words, displays op counts only when there
  // are values to be displayed.
  if (ocv.old_op_counts[0] === null) {
    ocv.old_op_counts = ocv.new_op_counts.slice(0);
  } else {
    // Replace the old PointText objects from the previous second.
    for (var i = 0; i < ocv.num_ops; ++i) {
      var y = ocv.top_bar_h + i * side_bar_h;
      var diff = ocv.new_op_counts[i] - ocv.old_op_counts[i];
      var text = (typeof diff === 'number' && !isNaN(diff)) ? diff : 0;
      ocv.paper_op_counts[i].content = text;
    }
  }
  view.draw();
};


op_count_viz.update_graph = function() {
  var ocv = op_count_viz;
  if (ocv.old_op_counts[0] === null)
    return;  // We haven't received data points yet.

  var graph_w = ocv.canvas_w - ocv.side_bar_w;
  var graph_h = ocv.canvas_h - ocv.top_bar_h;

  var max_points = graph_w / ocv.x_point_width + 1;
  var height_so_far = 0;

  // Calculate newest y-coordinates and eliminate the oldest if needed.
  // Do it in reverse so inserts/sec go on top.
  for (var i = ocv.num_ops - 1; i >= 0; --i) {
    height_so_far += (ocv.new_op_counts[i] - ocv.old_op_counts[i]);
    ocv.op_data_points[i].push(height_so_far);
    if (ocv.op_data_points[i].length > max_points) {
      // Chop the first one off so the graph doesn't encroach onto the
      // lefthand text opcounts.
      ocv.op_data_points[i].shift();
    }
  }

  for (var i = 0; i < ocv.num_ops; ++i) {
    ocv.op_graph_paths[i].remove();

    // Assemble a path consisting of the data points plus two base points
    // to form a filled area for each operation.
    ocv.op_graph_paths[i] = new Path();
    var start_x = ocv.canvas_w - ((ocv.op_data_points[i].length - 1) * ocv.x_point_width);
    ocv.op_graph_paths[i].add(new Point(start_x, ocv.canvas_h));
    for (var j = 0; j < ocv.op_data_points[i].length; ++j) {
      var y = ocv.canvas_h - (ocv.op_data_points[i][j] / ocv.y_scale_max) * graph_h;
      ocv.op_graph_paths[i].add(new Point(start_x + j * ocv.x_point_width, y));
    }
    ocv.op_graph_paths[i].add(new Point(ocv.canvas_w, ocv.canvas_h));
    ocv.op_graph_paths[i].closePath();
    ocv.op_graph_paths[i].fillColor = ocv.op_colors[i];

    // smooth() is not ready for prime-time yet. Need to fix weird artifacts first.
    //ocv.op_graph_paths[i].smooth();   
  }
  view.draw();
};


op_count_viz.draw_dynamic = function() {
  var ocv = op_count_viz;
  ocv.update_text();
  ocv.update_graph();

  for (var i = 0; i < ocv.num_ops; ++i) {
    ocv.old_op_counts[i] = ocv.new_op_counts[i];
  }
  ocv.get_op_counts(ocv.callback);  // Will change with the stats API.
};


if (document.getElementById('graph_canvas') !== null) {
  paper.setup('graph_canvas');
  paper.install(window);
  op_count_viz.draw_static();
  op_count_viz.init_graph(); // Will change for stats API.
  window.setInterval(op_count_viz.draw_dynamic, 1000);
}


