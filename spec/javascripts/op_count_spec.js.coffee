describe 'Opcount Graph', ->
  ocv = op_count_viz
  paper.setup('graph_canvas')
  paper.install(window)

  it 'has basic constants defined', ->
    expect(op_count_viz.num_ops).toEqual(6)
    expect(op_count_viz.op_labels).toBeDefined()
    expect(op_count_viz.y_scale).toBeDefined()

  it 'draws static objects like axes and axis labels on the canvas', ->
    # Most data structures start off empty.
    expect(ocv.y_label_text.length).toEqual(0)
    expect(ocv.y_label_guides.length).toEqual(0)
    ocv.draw_static()
    expect(ocv.y_label_text.length).toEqual(ocv.num_y_labels)
    expect(ocv.y_label_guides.length).toEqual(ocv.num_y_labels)

  it 'prepares to receive data by initializing Paper.JS PointText objects', ->
    expect(ocv.paper_op_counts.length).toEqual(0)
    ocv.init_graph()
    expect(ocv.paper_op_counts.length).toEqual(6)
    expect(text_op_count.content.length).toEqual(0) for text_op_count in ocv.paper_op_counts

  it 'calls jQuery\'s ajax method', ->
    spyOn($, 'ajax')
    ocv.get_op_counts(op_count_viz.callback)
    expect($.ajax).toHaveBeenCalled()

  it 'makes a real AJAX request with a fake callback', ->
    my_callback = jasmine.createSpy()
    ocv.get_op_counts(my_callback)
    waitsFor ->
      return my_callback.callCount > 0
    runs ->
      expect(my_callback).toHaveBeenCalled()

  # Tests that an actual AJAX call is working properly
  describe 'the get_op_counts method and its AJAX call', ->
    
    expect(ocv.old_op_counts.length).toEqual(1)
    expect(ocv.new_op_counts.length).toEqual(1)
    expect(ocv.paper_op_counts.length).toEqual(0)

    beforeEach ->
      ocv.get_op_counts(ocv.callback)
      waitsFor ->
        return ocv.new_op_counts.length == ocv.num_ops

    it 'populates the new_op_counts array with data', ->
      runs ->
        expect(ocv.new_op_counts.length).toEqual(ocv.num_ops)

    it 'copies the new data from new_op_counts to old_op_counts', ->
      runs ->
        ocv.update_text()
        expect(ocv.old_op_counts.length).toEqual(ocv.num_ops)

    it 'updates its Paper.JS objects\' content with new data', ->
      ocv.get_op_counts(ocv.callback)
      waits(10)  # Wait a bit for new data to come in
      runs ->
        ocv.update_text()
        expect(text_op_count.content.length).toBeGreaterThan(0)\
          for text_op_count in ocv.paper_op_counts
        
        # The very act of requesting op counts should make the command
        # count jump to at least 2.
        command_count = 5
        expect(ocv.paper_op_counts[command_count].content).toNotEqual('0')

    it 'updates the graph itself', ->
      expect(ocv.old_op_counts.length).toEqual(6)
      ocv.update_graph()
      console.log('array of op_point_lists:', ocv.op_data_points)
      expect(op_point_list.length).toBeGreaterThan(0)\
        for op_point_list in ocv.op_data_points

      expect(op_point).not.toBeGreaterThan(ocv.y_scale)\
        for op_point in op_point_list\
          for op_point_list in ocv.op_data_points

