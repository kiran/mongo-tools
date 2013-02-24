require 'spec_helper'

describe Evaluator do
  let(:evaluator) {
    Evaluator.new 'localhost', 27017
  }

  def perform_query(query, expected_outcome)
    result = evaluator.evaluate_query(query, :suggest_indexes => false)
    result.map! {|er| [er.code, er.level]}
    expect(result.sort).to eq(expected_outcome.sort)
  end

  context "Given a query to evaluate:" do

    it "Parses basic equality queries." do
      perform_query(
        {
          'field1' => {
            'sub1' => 3,
            'sub2' => 'string_val',
          },
          'field2' => 99,
        },
        []
      )
    end

    it "Reports usage of $in with a large array." do
      perform_query(
        {
          'field1' => {'$gt' => 20 },
          'field2' => {'$in' => [1]*10000},
        },
        [[EfficiencyResult::IN, EfficiencyResult::CRITICAL]]
      )
    end

    it "Reports usage of $nin." do
      perform_query(
        {
          'field1' => {'$nin' => [1,2,3]},
        },
        [[EfficiencyResult::NEGATION, EfficiencyResult::CRITICAL]]
      )
    end

    it "Reports usage of $ne." do
      perform_query(
        {
          'field1' => {'$ne' => 'orange' }
        },
        [[EfficiencyResult::NEGATION, EfficiencyResult::CRITICAL]]
      )
    end

    it "Parses comparison operators." do
      perform_query(
        {
          'field1' => {'$lt' => 1},
          'field2' => {'$lte' => 2},
          'field3' => {'$gt' => {'sub1' => 2, 'sub2' => 'string' } },
          'field4' => {'$gte' => 4},
        },
        []
      )
    end

    it "Reports usage of $all." do
      perform_query(
        {
          'field1' => {'$all' => [1,2,3,4]},
        },
        [[EfficiencyResult::ALL, EfficiencyResult::CRITICAL]]
      )
    end

    it "Parses compound queries ($or, $and)." do
      for op in ['$or', '$and'] do
        perform_query(
          {
            op => [
              'field1' => 2.15,
              'field2' => 'red',
              'field3' => { '$ne' => 15 },
              'field4' => { 'sub1' => 1, 'sub2' => 2 },
            ]
          },
          [[EfficiencyResult::NEGATION, EfficiencyResult::CRITICAL]]
        )
      end
    end

    it "Reports usage of $not." do
      perform_query(
        {
          'field1' => { '$not' => { '$in' => [1,2,3]*10000 } }
        },
        [[EfficiencyResult::NOT, EfficiencyResult::CRITICAL],
        [EfficiencyResult::IN, EfficiencyResult::CRITICAL]]
      )
    end

    it "Reports usage of $nor and recurses into subqueries." do
      perform_query(
        {
          '$nor' => [
            'field1' => 2.15,
            'field2' => 'red',
            'field3' => { '$ne' => 15 },
            'field4' => { 'sub1' => 1, 'sub2' => 2 },
          ]
        },
        [[EfficiencyResult::NOR, EfficiencyResult::CRITICAL],
        [EfficiencyResult::NEGATION, EfficiencyResult::CRITICAL]]
      )
    end

    it "Reports inefficient regexes." do
      perform_query(
        {
          "A" => { "$regex" => "^acme.*corp", "$options" => 'i'},
        },
        [[EfficiencyResult::REGEX_CASE, EfficiencyResult::BAD]]
      )

      perform_query(
        {
          "A" => { "$regex" => "acme.*corp" },
        },
        [[EfficiencyResult::REGEX_ANCHOR, EfficiencyResult::BAD]]
      )

      perform_query(
        {
          "A" => { "$regex" => "^acme.*corp.*$" },
        },
        [[EfficiencyResult::REGEX_BAD_END, EfficiencyResult::BAD]]
      )

      perform_query(
        {
          "A" => { "$regex" => "acme.*corp.*", "$options" => 'i'},
        },
        [[EfficiencyResult::REGEX_CASE, EfficiencyResult::BAD],
        [EfficiencyResult::REGEX_BAD_END, EfficiencyResult::BAD],
        [EfficiencyResult::REGEX_ANCHOR, EfficiencyResult::BAD]]
      )
    end

    it "Reports usage of $size." do
      perform_query(
        { "field" => { "$size" => 1 } },
        [[EfficiencyResult::SIZE, EfficiencyResult::WARNING]]
      )
    end

    it "Reports usage of $where." do
      perform_query(
        {
          '$where' => 'this.credits == this.debits'
        },
        [[EfficiencyResult::WHERE, EfficiencyResult::CRITICAL]]
      )
    end

    it "Raises RuntimeError when an unknown operator is encountered." do
      query = {
        'A' => {'$brighter_than'=> '#AAFFCC'}
      }
      expect {
        evaluator.evaluate_query(query, :suggest_indexes => false)
      }.to raise_error(RuntimeError)
    end

    it "Parses geospatial queries." do
      queries = [
        { "loc" => { "$within" => { "$box" => [ [0,0], [100,100] ] } } },
        { "loc" => { "$near"=> [100,100] } },
        { "loc" => { "$nearSphere" => [0,0] } },
        { "loc" => { "$within" => { "$centerSphere" => [ [88,30], 10 / 3959 ] } } },
        { "loc" => { "$within" => { "$center" => [ [0,0], 10 ] } } },
        { "loc" => { "$near" => [100,100], "$maxDistance" => 10 } },
        { "loc" => { "$within" => { "$polygon" => [ [0,0], [3,6], [6,0]  ] } } },
        { "address.loc" => { "$within" => { "$box" => [ [0,0], [100,100] ], "$uniqueDocs" => true } } },
      ]
      queries.each do |query|
        perform_query(query, [])
      end
    end

  end # context


  context "When asked to suggest an index:" do

    it "Suggests indexes with optimal order of fields." do
      query = {
        "B" => { "$in" => [24.0, 25.0, 28.0, 29.0]},
        "A" => { "$gt" => 27.3}
      }
      sort_hash = { "C" => 1.0 }
      result =  evaluator.evaluate_query(query, :sort_hash => sort_hash)

      expect(result[0].raw_index).to \
        eq("{ 'C': 1, 'B': 1, 'A': 1 }")
      expect(result[0].level).to eq(IndexResult::GOOD)


      # example given by
      # http://java.dzone.com/articles/optimizing-mongodb-compound?mz=36885-nosql
      query = {
        "timestamp" => { "$gte" => 2, "$lte" => 4 },
        "anonymous" => false
      }
      sort_hash = { "rating" => -1.0 }
      result =  evaluator.evaluate_query(query, :sort_hash => sort_hash)

      expect(result[0].raw_index).to \
        eq ("{ 'anonymous': 1, 'rating': 1, 'timestamp': 1 }")
      expect(result[0].level).to eq(IndexResult::GOOD)


      query = {
        '$nor' => [
          'field1' => 2.15,
          'field2' => 'red',
          'field3' => { '$ne' => 15 },
          'field4' => { 'sub1' => 1, 'sub2' => 2 },
        ]
      }
      result = evaluator.evaluate_query(query)

      expect(result[0].raw_index).to \
        eq("{ 'field1': 1, 'field2': 1, 'field4': 1, 'field3': 1 }")
      expect(result[0].level).to eq(IndexResult::OPTIONAL)
    end

    it "Does not suggest indexes for fields with unsupported operators." do
      query = { "B" => { "$regex" => "^acme.*corp.*$" }, "A" => { "$gt" => 27.3}}
      sort_hash = { "C" => 1.0 }
      result = evaluator.evaluate_query(query, :sort_hash => sort_hash)

      expect(result[0].raw_index).to eq("{ 'C': 1, 'A': 1 }")
      expect(result[0].level).to eq(IndexResult::OPTIONAL)
    end

    it "Handles equal, range and sort operators." do
      query = { "B" => 9,"A" => { "$gt" => 27.3, "$lt" => 97.3}}
      sort_hash = { "C" => -1.0 }
      result =  evaluator.evaluate_query(query, :sort_hash => sort_hash)

      expect(result[0].raw_index).to eq("{ 'B': 1, 'C': 1, 'A': 1 }")
      expect(result[0].level).to eq(IndexResult::GOOD)
    end

    it "Suggests a proper index for sorting purposes." do
      query = {}
      sort_hash = { "C" => 1.0 }
      result = evaluator.evaluate_query(query, :sort_hash => sort_hash)

      expect(result[0].raw_index).to eq("{ 'C': 1 }")
      expect(result[0].level).to eq(IndexResult::GOOD)
    end

    it "Recommends no index for queries that do not need one." do
      query = {}
      result =  evaluator.evaluate_query(query)
      expect(result).to eq([])

      query = {"location" => { "$near" => [100,100] }}
      result =  evaluator.evaluate_query(query)
      expect(result).to eq([])
    end

  end # context

end
