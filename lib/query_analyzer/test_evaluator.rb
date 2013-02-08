#! /usr/bin/ruby
require_relative 'evaluator'

QUERIES = [
    {
        "query" => { "B" => { "$in" => [24.0, 25.0, 28.0, 29.0]}, "A" => { "$gt" => 27.3 } },
        "orderby" => { "C" => 1.0 }
    },

    { "query" => { "$or" => [
                        { "A" => { "$gt" => 25.0 } },
                        { "b" => { "$in" => [ 1.0, 2.0, 3.0, 4.0 ] } }
                        ]}
    },

    { "query" => {"B" => {"$not" => {"$in" =>[ 24.0, 25.0, 28.0, 29.0 ] } } } },

    { "query" => { "$nor" => [
                        { "A" => { "$gt" => 25.0 } }, { "b" => { "$in" => [ 1.0, 2.0, 3.0, 4.0 ] } }
                        ] }
    },

    { "query" => { "A" => 23.0 } },

    { "query" => { "A" => {"$in" => [ 1, 2, 3, 4 ], "$lt" => 30.0} } },

    { "query" => { "A" => { "$regex" => "acme.*corp.*$", "$options" => 'i' } } },

    { "query" => { "A" => { "$size" => 20 } } },

    { "query" => { "A" => { "$exists" => true, "$nin" => [ 5, 15 ] } } },
]

e = Evaluator.new 'localhost', 27017

QUERIES.each do |query|
  evaluation_results = e.evaluate_query(query, 'dbname.collname')
  print 'QUERY: '
  debug query
  puts 'evaluation result:'
  evaluation_results.each do |res|
    puts "- #{res.msg} (severity #{res.severity})"
  end
  puts
end