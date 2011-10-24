class Koalamatic.Views.TestRunListItem extends Backbone.View
  render: () ->
    JST["backbone/templates/test_run/list_item"]({run: this.model, index: this.options.index})

