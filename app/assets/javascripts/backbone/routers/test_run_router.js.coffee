class Koalamatic.Routers.TestRunsRouter extends Backbone.Router
  initialize: (options) ->
    @testRuns = new Koalamatic.Collections.TestRunCollection()
    @testRuns.reset options.testRuns

  routes:
    "/list?page=:page" : "list"
    "/index"    : "index"

  list: ->
    @view = new Koalamatic.Views.TestRunList(collection: @testRuns, el: "#runs")
    # is it bad form for the view to render directly into a DOM element?
    # should it render into a fragment that the router then manipulates (per the generated examples below?)
    @view.render()
    
  index: ->
    @view = new Koalamatic.Views.testRuns.IndexView(testRuns: @testRuns)
    $("#testRuns").html(@view.render().el)

  show: (id) ->
    foo = @testRuns.get(id)
    
    @view = new Koalamatic.Views.testRuns.ShowView(model: foo)
    $("#testRuns").html(@view.render().el)
    
  edit: (id) ->
    foo = @testRuns.get(id)

    @view = new Koalamatic.Views.testRuns.EditView(model: foo)
    $("#testRuns").html(@view.render().el)
