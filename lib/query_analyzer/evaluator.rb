require 'rubygems'
require 'mongo'

require 'pp' #debug purposes
def debug (*xs)
  xs.each do |x|
    PP::pp(x, $>, 65)
  end
end


class EvaluationResult
  LV1 = 1
  LV2 = 2
  def initialize(msg, level)
    @msg = msg
    @level = level
  end
  attr_accessor :msg, :level
  def level_info
    case level
    when LV1
      "Level 1"
    when LV2
      "Level 2"
    else raise "Unknown level: #{level}. "
    end
  end
end


class EfficencyResult < EvaluationResult
  #severity levels:
  WARNING = 1
  BAD = 2
  CRITICAL = 3
  def initialize(msg, severity)
    super(msg,severity)
  end

  def level_info
    case level
    when WARNING
      "Waring"
    when BAD
      "Bad"
    when CRITICAL
      "Critial"
    else raise "Unknown severity: #{level}. "
    end
  end
end


class IndexResult < EvaluationResult

  #recommendation level
  # May ignore some fields or contain too many fields
  # User should consider whether create this index is worth it.
  OPTIONAL = 1

  # Most of time it improves performance
  GOOD = 2

  def initialize(msg, level)
    super(msg,level)
  end

  def level_info
    case level
    when OPTIONAL
      "Optional"
    when GOOD
      "Recommendation"
    else raise "Unknown Recommendation level: #{level}. "
    end
  end
end


class Evaluator
  def initialize(addr, port)
    @addr = addr
    @port = port
  end

  def getDb(dbname)
    cl = Mongo::MongoClient.new @addr, @port
    return cl.db(dbname)
  end

  def getColl(namespace)
    db_name, collection_name = namespace.split('.',2)
    db = getDb(db_name)
    coll = db[collection_name]
  end

  # TODO
  def getIndexInformation(namespace)
    coll = getColl(namespace)
    debug coll.index_information
  end

  # evaluates the whole query
  # @returns an array of EvaluationResult objects
  # query hash is the decoded query json, e.g.
  # {
  #   "query" => {
  #     "B" => {"$in" => [24.0, 25.0]},
  #     "A" => {"$gt" => 27.3, "$lt" => 1000.0},
  #   },
  #   "orderby" => {
  #     "A" : 1.0,
  #   },
  # }
  def evaluate_query(query_hash, namespace, check_index)
    out = []

    # TODO
    out += check_for_indexes query_hash if check_index

    query_hash.each do |key, val|
      out += analyze_query(val,namespace) if key == "query"
    end
    return out
  end

  private

  #
  # the operator handlers follow
  # every handler returns an array of EfficencyResult objects
  # depending on the following arguments
  # namespace - specifies the collection
  # field (self explanatory)
  # operator_arg - the query arguments, specific to different operators
  #

  def handle_all (namespace, field, operator_arg)
    return [
      EfficencyResult.new(
        %{\
In the current release queries that use the $all operator must \
scan all the documents that match the first element in the query \
array. As a result, even with an index to support the query, the \
operation may be long running, particularly when the first element \
in the array is not very selective.},
EfficencyResult::CRITICAL)
    ]
  end

  MAX_IN_ARRAY = 2000
  def handle_in (namespace, field, operator_arg)
    result = []
    elems_no = operator_arg.count
    if elems_no > MAX_IN_ARRAY then
      result << EfficencyResult.new(
        "$in operator with a large array (#{elems_no}) is inefficient",
        EfficencyResult::CRITICAL)
    end
    return result
  end

  def handle_negation (namespace, field, operator_arg)
    return [
      EfficencyResult.new(
        'Negation operators ($ne, $nin) are inefficient.',
        EfficencyResult::CRITICAL)
    ]
  end

  def handle_where (namespace, field, operator_arg)
    return [
      EfficencyResult.new(
        'javascript is slow, you should consider redesigning your queries.',
        EfficencyResult::CRITICAL)
    ]
  end

  def handle_multiple(namespace, field, operator_arg)
    res = []
    operator_arg.each do |query|
      res += analyze_query(query, namespace)
    end
    return res
  end

  def handle_not(namespace, field, operator_arg)
    res = [
      EfficencyResult.new(
        'Negation operator ($not) is inefficient',
        EfficencyResult::CRITICAL)
    ]
    res += handle_single_field(namespace, field, operator_arg)
    return res
  end

  def handle_nor(namespace, field, operator_arg)
    res = [
      EfficencyResult.new(
        'Negation operator ($nor) is inefficient',
        EfficencyResult::CRITICAL)
    ]
    res += handle_multiple(namespace, field, operator_arg)
    return res
  end

  def handle_regex(namespace, field, operator_arg)
    res = []
    regex = eval operator_arg

    if not regex.source.start_with? '^' then
      res << EfficencyResult.new(
        'Try to change the regex so that it has an anchor for the ' +
        'beginning (i.e. ^). Otherwise the engine cannot make use of ' +
        'indexes (if there are any).',
        EfficencyResult::BAD)
    end

    if regex.casefold? then
      res << EfficencyResult.new(
        'Case insensitive queries are inefficient. Consider keeping ' +
        "a lowercase copy of field '#{field}' in your documents.",
        EfficencyResult::BAD)
    end

    ['.*', '.*$'].each do |bad_end|
      if regex.source.end_with? bad_end then
        res << EfficencyResult.new(
          "Do you really need #{bad_end} at the end of your regex? "+
          'It slows down the queries.',
          EfficencyResult::BAD)
      end
    end

    return res
  end

  def handle_size(namespace, field, operator_arg)
    [
      EfficencyResult.new(
        'Queries cannot use indexes for $size portion of a query. ' +
        'Consider keeping a separate field holding the array size ' +
        'and creating an index on it.',
        EfficencyResult::WARNING)
    ]
  end

  def empty_handle(namespace, field, operator_arg)
    []
  end
  # ====================Indexes suggestion======================

  RANGE_OPERATORS = %w{ $all $not $in $ne $nin $lt $lte $gt $gte }


  EQUAL_TYPE = 0
  SORT_TYPE = 1
  RANGE_TYPE = 2
  UNSUPPORTED_TYPE = 3

  # classify fields into four types
  # EQUAL_TYPE: e.g. "A" => "10"
  # SORT_TYPE: e.g. "orderby" => { "C" => 1.0 }
  # RANGE_TYPE: #e.g. "A" => {"$gt" : 13, "$lt" : 27}
  # UNSUPPORTED_TYPE: e.g. {"A" => { "$regex" => "acme.*corp.*$", "$options" => 'i' } }
  def classify_field!(query_hash, classified_fields)
    query_hash.each do |key, val|
      if key.start_with? '$'
        # e.g "$or" => [{ "A" => { "$gt" => 25.0 } }, { "b" => { "$in" => [ 1.0, 2.0, 3.0, 4.0 ] } }]
        classified_fields[UNSUPPORTED_TYPE] << key
        val.each { |sub| classify_field!(sub, classified_fields) }
      elsif (val.is_a? Hash) and (has_operators val)
        #e.g. "A" => {"$gt" : 13, "$lt" : 27}
        support = true
        val.each do |op, _|
          support = false if RANGE_OPERATORS.index(op) == nil
        end
        if support
          classified_fields[RANGE_TYPE] << key
        else
          classified_fields[UNSUPPORTED_TYPE] << key
        end
      else
        #e.g. "A" => "10"
        classified_fields[EQUAL_TYPE] << key
      end
    end
  end

  def generate_index_suggestion recommendation
    str = "Index Recommendation: {"
    recommendation.each do |field|
      str += " '" + field + "': 1,"
    end
    str[str.size-1] = " "
    str[str.size] = "}"
    return str
  end

  def check_for_indexes query_hash
    #classified_fields[FieldType][FieldName]
    classified_fields = Array.new(4) {[]}
    recommendation = []
    query_hash.each do |key, val|
      if key == "query"
        classify_field!(val, classified_fields)
      elsif key == "orderby"
        val.each do |key, val|
          classified_fields[SORT_TYPE] << key
      end
      elsif
        raise "Unknown field \"#{key}\" in query."
      end
    end
    # index sequence : 1.equality tests 2.sort fields 3.range filters
    # http://java.dzone.com/articles/optimizing-mongodb-compound?mz=36885-nosql
    [EQUAL_TYPE, SORT_TYPE, RANGE_TYPE].each do |i|
      classified_fields[i].each do |field|
        recommendation << field if recommendation.index(field) == nil
      end
    end
    return [] if recommendation.size == 0
    return [IndexResult.new( generate_index_suggestion(recommendation),
      classified_fields[UNSUPPORTED_TYPE].size == 0 ? IndexResult::GOOD : IndexResult::OPTIONAL )]
  end
  # ============================================================

  OPERATOR_HANDLERS_DISPATCH = {
    "_equality_check" => :empty_handle,

    # http://docs.mongodb.org/manual/reference/operators/

    # comparison
    "$all" => :handle_all,
    "$in" => :handle_in,
    "$ne" => :handle_negation,
    "$nin" => :handle_negation,
    # we should not check for indexes here, the other method does that:
    "$lt" => :empty_handle,
    "$lte" => :empty_handle,
    "$gt" => :empty_handle,
    "$gte" => :empty_handle,

    # logical
    "$and" => :handle_multiple,
    "$or" => :handle_multiple,
    "$nor" => :handle_nor,
    "$not" => :handle_not,

    # element
    "$exists" => :empty_handle, #TODO
    "$mod" => :empty_handle, #TODO
    "$type" => :empty_handle, #TODO

    # javascript
    "$regex" =>  :handle_regex,
    "$where" => :handle_where,

    # geospatial
    "$box" => :empty_handle, #TODO
    "$near" => :empty_handle, #TODO
    "$within" => :empty_handle, #TODO

    # array
    "$elemMatch" => :empty_handle, #TODO
    "$size" => :handle_size,
  }

  # This method prepares the hash argument, so that it can be
  # handled by handle_regex method. Specifically, it changes
  # { "$regex" => "^acme.*corp", "$options" => 'i'}
  # to
  # { "$regex" => "/^acme.*corp/i" }
  #
  # if hash argument contains neither '$regex' nor '$options' field,
  # then hash remains unchanged
  def normalize_regexes hash
    options = nil
    if hash.has_key? '$options' then
      #assert that we have a 'regex' operator
      if not hash.has_key? '$regex' then
        raise '$options operator provided, but $regex not present.'
      end

      options = hash['$options']
      hash.delete('$options')
    end

    if hash.has_key? '$regex' then
      regex = "/#{hash['$regex']}/#{options}"
      hash['$regex'] = regex
    end
  end

  # handles operators for a single field, eg
  # {"$in" => [1.0, 2.0, 3.0], "$lt" => 12}
  # @param namespace specifies the collection
  # @param field specifies the field in the collection
  def handle_single_field(namespace, field, operators_hash)
    res = []

    normalize_regexes operators_hash

    operators_hash.each do |operator_str, val|
      method_symbol = OPERATOR_HANDLERS_DISPATCH[operator_str]
      if method_symbol.nil?
        raise "Unknown operator: '#{operator_str}'."
      end
      res += method( method_symbol ).call namespace, field, val
    end
    return res
  end

  # checks if a hash contains keys that start with a '$'
  def has_operators hash
    operators_count = 0

    hash.each do |key, val|
      if key.start_with? '$'
        operators_count += 1
      end
    end

    #XXX - what if operators_count is different than 0 and hash.size

    return operators_count > 0
  end

  def analyze_query(query_hash, namespace)
    out = []
    query_hash.each do |key, val|
      field = nil
      operator_hash = nil
      if key.start_with? '$' then
        #e.g. $or => [query1, query2, ...]
        operator_hash = { key => val }
      elsif (val.is_a? Hash) and (has_operators val)
        #e.g. "A" => {"$gt" : 13, "$lt" : 27}
        field = key
        operator_hash = val
      else
        #e.g. "A" => { "sub1" : 10, "sub2" : 30 }
        field = key
        operator_hash = { "_equality_check" => nil }
      end

      out += handle_single_field namespace, field, operator_hash
    end
    return out
  end

end #class Evaluator
