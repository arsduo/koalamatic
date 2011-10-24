class Koalamatic.Views.TestRunList extends Backbone.View
  el: "ul"

  addToList: (testRun, index) ->
    view = new Koalamatic.Views.TestRunListItem({model: testRun, index: index});
    $(this.el).append(view.render());

  render: ->
    this.collection.each(_(this.addToList).bind(this));
    return this