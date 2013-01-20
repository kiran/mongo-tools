#! /usr/bin/ruby
require 'evaluator'

QUERIES = [
    {"B"=>{"$in"=>[24.0, 25.0, 28.0, 29.0]}, "A"=>{"$gt"=>27.3}},

    { "$or"=> [
            { "A"=> { "$gt"=> 25.0 } },
            { "b"=> { "$in"=> [ 1.0, 2.0, 3.0, 4.0 ] } }
        ]
    },

    {"B"=>{"$not" => {"$in"=>[24.0, 25.0, 28.0, 29.0]} } },

    { "$nor"=> [
            { "A"=> { "$gt"=> 25.0 } },
            { "b"=> { "$in"=> [ 1.0, 2.0, 3.0, 4.0 ] } }
        ]
    },

    {"A" => 23.0},

    {"A" => {"$in" => [1,2,3,4], "$lt" => 30.0} },

    {"A"=> { "$regex"=> "acme.*corp.*$", "$options"=> 'i' } },

    {"A"=> { "$size"=> 20 } },
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
