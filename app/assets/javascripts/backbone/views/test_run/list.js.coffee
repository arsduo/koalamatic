class Koalamatic.Views.TestListView extends Backbone.View
  el: "li"
  
  initialize: () ->
    this.collection.each(this.addToList.bind(this))
  
  addToList: (testRun, index) ->
    view = new Koalamatic.Views.TestRunView({model: testRun, index: index});
    $(this.el).append(view.render());
