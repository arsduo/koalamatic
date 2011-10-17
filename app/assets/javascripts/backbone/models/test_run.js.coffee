class Koalamatic.Models.TestRun extends Backbone.Model
  # we don't need defaults or other attributes, since these are read-only
  passed: () -> this.get("verified_failure_count") == 0

class Koalamatic.Collections.TestRunCollection extends Backbone.Collection
  model: Koalamatic.Models.TestRun