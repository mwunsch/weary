# Weary

This is the **big rewrite** of Weary, currently ongoing.

Weary is a framework and DSL for building clients for RESTful web service APIs.

## Rack

Every `Weary::Request` object is a valid Rack application.

Every Class that includes `Weary::Adapter` is a valid Rack application.

Weary is just a whole lot of Rack under the covers.

Run `bundle` and then:
    bundle exec rspec --format documentation --color