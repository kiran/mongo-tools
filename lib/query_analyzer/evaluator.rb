require 'rubygems'
require 'mongo'

class EvaluationResult
  def initialize(msg, level)
    @msg = msg
    @level = level
  end
  attr_accessor :msg, :level
end


class EfficiencyResult < EvaluationResult
  # Severity levels:
  # :warning
  # :bad
  # :critical

  # Inefficiency codes:
  # :all
  # :in
  # :negation
  # :where
  # :not
  # :nor
  # :regex_anchor
  # :regex_case
  # :regex_bad_end
  # :size

  def initialize(msg, level, code)
    super(msg, level)
    @code = code
  end

  attr_accessor :code
end


class IndexResult < EvaluationResult
  # levels:
  # :optional - May ignore some fields or contain too many fields.
  # User should consider whether creating this index is worth it.
  # :good - Most of time it improves performance

  # returns the index serialized as string, e.g.:
  # "{ 'price': 1, 'rating': 1, 'duration': 1 }"
  def raw_index
    elems = @index.map do |field, type|
      type_str = case type
                 when Mongo::ASCENDING then "1"
                 when Mongo::DESCENDING then "-1"
                 when Mongo::GEO2DSPHERE then "'2dsphere'"
                 when Mongo::GEO2D then "'2d'"
                 else "?"
                 end
      "'#{field}': #{type_str}"
    end

    "{ #{elems.join(", ")} }"
  end

  def initialize(index, level)
    @index = index
    super("Index recommendation: #{raw_index()}", level)
  end

  attr_accessor :index
end


class Evaluator
  def initialize(client)
    @client = client
  end

  # Evaluates the whole query.
  # Returns an array of EvaluationResult objects.
  # query_hash is the decoded query json, e.g.
  # {
  #     "B" => {"$in" => [24.0, 25.0]},
  #     "A" => {"$gt" => 27.3, "$lt" => 1000.0},
  # }
  # additional arguments may be passed in the args hash:
  # :suggest_indexes => true | false
  # :sort_hash => a hash describing sorting order
  # :namespace => a collection namespace
  def evaluate_query(query_hash, args = {})
    sort_hash = args[:sort_hash] || {}
    suggest_indexes = args[:suggest_indexes]
    suggest_indexes = true if suggest_indexes.nil?
    namespace = args[:namespace]

    result = {
      :index => [],
      :query => []
    }

    if suggest_indexes
        result[:index] += check_for_indexes(query_hash, sort_hash, namespace)
    end

    result[:query] += analyze_query query_hash
    result
  end

  private

  def get_db(dbname)
    @client.db(dbname)
  end

  def get_coll(namespace)
    db_name, collection_name = namespace.split(".",2)
    db = get_db(db_name)
    coll = db[collection_name]
  end

  def get_index_information(namespace)
    if namespace.nil?
      return {}
    else
      return get_coll(namespace).index_information
    end
  end

  # The operator handlers follow.
  # Every handler returns an array of EfficiencyResult objects
  # depending on the following arguments:
  # field (self explanatory)
  # operator_arg - the query arguments, specific to different operators

  def handle_all (field, operator_arg)
    [
      EfficiencyResult.new(
        %{\
        In the current release queries that use the $all operator must \
        scan all the documents that match the first element in the query \
        array. As a result, even with an index to support the query, the \
        operation may be long running, particularly when the first element \
        in the array is not very selective.},
        :critical,
        :all)
    ]
  end

  MAX_IN_ARRAY = 2000
  def handle_in (field, operator_arg)
    result = []
    elems_no = operator_arg.count
    if elems_no > MAX_IN_ARRAY
      result << EfficiencyResult.new(
        "$in operator with a large array (#{elems_no}) is inefficient",
        :critical,
        :in)
    end
    result
  end

  def handle_negation (field, operator_arg)
    [
      EfficiencyResult.new(
        "Negation operators ($ne, $nin) are inefficient.",
        :critical,
        :negation)
    ]
  end

  def handle_where (field, operator_arg)
    [
      EfficiencyResult.new(
        "javascript is slow, you should consider redesigning your queries.",
        :critical,
        :where)
    ]
  end

  def handle_multiple(field, operator_arg)
    res = []
    operator_arg.each do |query|
      res += analyze_query(query)
    end
    res
  end

  def handle_not(field, operator_arg)
    res = [
      EfficiencyResult.new(
        "Negation operator ($not) is inefficient.",
        :critical,
        :not)
    ]
    res += handle_single_field(field, operator_arg)
    res
  end

  def handle_nor(field, operator_arg)
    res = [
      EfficiencyResult.new(
        "Negation operator ($nor) is inefficient.",
        :critical,
        :nor)
    ]
    res += handle_multiple(field, operator_arg)
    res
  end

  def handle_regex(field, operator_arg)
    res = []
    regex = eval operator_arg

    if !regex.source.start_with?("^")
      res << EfficiencyResult.new(
        %{\
        Try to change the regex so that it has an anchor for the beginning \
        (i.e. ^). Otherwise the engine cannot make use of indexes (if there are any).},
        :bad,
        :regex_anchor)
    end

    if regex.casefold?
      res << EfficiencyResult.new(
        %{\
        Case insensitive queries are inefficient. Consider keeping \
        a lowercase copy of field '#{field}' in your documents.},
        :bad,
        :regex_case)
    end

    [".*", ".*$"].each do |bad_end|
      if regex.source.end_with?(bad_end)
        res << EfficiencyResult.new(
          %{\
          Do you really need #{bad_end} at the end of your regex? \
          It slows down the queries.},
          :bad,
          :regex_bad_end)
      end
    end

    res
  end

  def handle_size(field, operator_arg)
    [
      EfficiencyResult.new(
        %{\
        Queries cannot use indexes for $size portion of a query. \
        Consider keeping a separate field holding the array size \
        and creating an index on it.},
        :warning,
        :size)
    ]
  end
  # Mentioned inhttp://oreillynet.com/pub/e/1772
  def handle_mod(field, operator_arg)
    [
      EfficiencyResult.new(
        "Queries caonnot use indexes for $mod portion of a query." ,
        :warning,
        :mod)
    ]
  end

  def empty_handle(field, operator_arg)
    []
  end

  # ====================Indexes suggestion======================

  RANGE_OPERATORS = %w{ $all $not $in $ne $nin $lt $lte $gt $gte }
  GEOSPATIAL_OPERATORS = %w{ $within $geoWithin $geoIntersects $near $nearSphere }
  AGGREGATION_OPERATORS = %w{ $or $nor $and }

  # Given the list of operators, recursively traverse the query
  # and find all occurences of the operators. Return an array of pairs
  # [ [operator, value], ... ]
  def extract_operators_(query_hash, operators)
    res = []
    traverse_query query_hash do |type, key, val|
      case type
      when :multiple_queries_operator
        res += [key, val] if operators.include? key
        val.each { |sub| res += extract_operators_(sub, operators) }
      when :field_query
        val.each { |op, op_val| res << [op, op_val] if operators.include? op }
      end
    end
    res
  end

  # Depending on the query operators and structure this function
  # returns what type of index would be suitable for the query.
  # Returns one of these values: :regular, :geo2d, :geo2dsphere
  def potential_index_type(query_hash)

    # $geoIntersects is only handled by 2dsphere index
    ops = extract_operators_(query_hash, ['$geoIntersects'])
    if !ops.empty?
      return :geo2dsphere
    end

    # Queries that have one of these operators are intended for 2dsphere indexes
    # if teere is '$geometry' field in the operator's options. Otherwise
    # they are suitable for 2d index.
    ops = extract_operators_(query_hash, ['$near', '$nearSphere'])
    ops.each do |operator, value|
      if (value.is_a? Hash) && (value.has_key? '$geometry')
        return :geo2dsphere
      else
        return :geo2d
      end
    end

    ops = extract_operators_(query_hash, ['$within', '$geoWithin'])
    ops.each do |operator, value|
      if (value.is_a? Hash) && (value.has_key?('$geometry') || value.has_key?('$centerSphere'))
        return :geo2dsphere
      else
        return :geo2d
      end
    end

    return :regular
  end

  def check_for_indexes(query_hash, sort_hash, namespace)
    method = case potential_index_type(query_hash)
             when :geo2dsphere then :check_for_2dsphere_indexes
             when :geo2d then :check_for_2d_indexes
             when :regular then :check_for_regular_indexes
             end
    send(method, query_hash, sort_hash, namespace)
  end

  # Classify fields into four types and return a mapping from type symbols
  # to arrays of fields. The types are:
  # :equal_type - e.g. "A" => "10"
  # :sort_type - fields that are present in the sort_hash
  # :range_type - fieds that are used with an operator from RANGE_OPERATORS
  # :geospatial_type - fields for which geospatial operators are used
  # :unsupported_type - e.g. {"A" => { "$regex" => "acme.*corp.*$" }
  def classify_fields(query_hash, sort_hash)
    classified_fields = {
      :equal_type => [],
      :sort_type => [],
      :range_type  => [],
      :geospatial_type => [],
      :unsupported_type => [],
    }
    _classify_field!(query_hash, classified_fields)
    classified_fields[:sort_type] = sort_hash.keys.clone()

    classified_fields
  end

  def _classify_field!(query_hash, classified_fields)
    traverse_query query_hash do |type, key, val|
      case type
      when :multiple_queries_operator
        # skip "$nor" for it cannot use indexes
        # "$or" will be handled in check_for_indexes
        val.each { |sub| _classify_field!(sub, classified_fields) } if (key =="$and")
      when :field_query
        #e.g. "A" => {"$gt" : 13, "$lt" : 27}
        if (val.keys - RANGE_OPERATORS).empty?
          classified_fields[:range_type] << key
        elsif (val.keys - GEOSPATIAL_OPERATORS).empty?
          classified_fields[:geospatial_type] << key
        else
          classified_fields[:unsupported_type] << key
        end
      when :field_equality
        #e.g. "A" => "10"
        classified_fields[:equal_type] << key
      end
    end
  end

  def check_for_2d_indexes(query_hash, sort_hash, namespace)
    classified_fields = classify_fields(query_hash, sort_hash)
    return [] if has_suitable_2d_index?(classified_fields, namespace)

    geo_fields = classified_fields[:geospatial_type].uniq
    return [] if geo_fields.empty?

    # suggest an index on arbitrarily chosen 'geospatial field'
    geo_field = geo_fields[0]
    index = {geo_field => Mongo::GEO2D}

    [IndexResult.new(index.to_a, :good)]
  end

  def has_suitable_2d_index?(classified_fields, namespace)
    indexes = get_index_information(namespace)
    indexes.each do |_, index|
      return true if is_2d_index_suitable?(classified_fields, index["key"])
    end
    false
  end

  def is_2d_index_suitable?(classified_fields, index)
    geo_fields = classified_fields[:geospatial_type].uniq

    # a suitable index should start with a '2d' field,
    # the field should be present in geo_fields
    prefix = index.take_while do |field, type|
      (geo_fields.include? field) && (type == Mongo::GEO2D)
    end

    !prefix.empty?
  end

  def check_for_2dsphere_indexes(query_hash, sort_hash, namespace)
    # 2dsphere indexes don't enhance queries that use aggregation operators
    if !(query_hash.keys & AGGREGATION_OPERATORS).empty?
      return []
    end

    classified_fields = classify_fields(query_hash, sort_hash)

    return [] if has_ideal_2dsphere_index?(classified_fields, namespace)

    # we are going to construct an 'ideal' index
    index = {}

    [:equal_type, :geospatial_type, :range_type].each do |f_type|
      classified_fields[f_type].each do |field|
        if !index.keys.include?(field)
          index[field] = case f_type
                         when :geospatial_type then Mongo::GEO2DSPHERE
                         else Mongo::ASCENDING
                         end
        end
      end
    end

    return [] if index.empty?

    quality = :good
    if (!classified_fields[:unsupported_type].empty?) || \
       (!classified_fields[:sort_type].empty?)
      quality = :optional
    end

    [IndexResult.new(index.to_a, quality)]
  end

  def has_ideal_2dsphere_index?(classified_fields, namespace)
    indexes = get_index_information(namespace)
    indexes.each do |_, index|
      return true if is_2dsphere_index_ideal?(classified_fields, index["key"])
    end
    false
  end

  def is_2dsphere_index_ideal?(classified_fields, index)
    return false if index.values.include?(Mongo::GEO2D)

    eq_fields = classified_fields[:equal_type].uniq
    range_fields = classified_fields[:range_type].uniq
    geo_fields = classified_fields[:geospatial_type].uniq
    all_fields = eq_fields | geo_fields | range_fields

    # we are interested in the maximal prefix of the index that
    # contains only fields from the query
    index = index.take_while{|k,v| all_fields.include? k}
    index = Hash[*index.flatten]

    # eq_fields should be contained in a contiguous prefix of the index
    prefix = index.keys.take_while{|k| eq_fields.include? k}
    remaining = index.keys.drop(prefix.length)
    if prefix.sort != eq_fields.sort
      return false
    end

    # all 'geospatial' fields should have '2dsphere' type within the index
    classified_fields[:geospatial_type].each do |field|
      return false if index[field] != '2dsphere'
    end

    # the set of remaining fields should be equal to the set of fields
    # contained in geo_fields and all_fields
    (geo_fields | range_fields).uniq.sort == remaining.uniq.sort
  end

  def check_for_regular_indexes(query_hash, sort_hash, namespace)
    # When using indexes with $or queries each clause of an $or query will execute in parallel
    # So find indexes for each clause rather than a compound indexes for whole query.
    # Note: when using the $or operator with the sort() method in a query,
    # the query will not use the indexes on the $or fields.
    # (http://docs.mongodb.org/manual/reference/operator/or/#_S_or)
    result = []
    if (query_hash.keys.include?("$or") && sort_hash.empty?)
      query_hash["$or"].each {|clause| result += check_for_indexes(clause, sort_hash, namespace)}
      return result
    end

    classified_fields = classify_fields(query_hash, sort_hash)

    if has_ideal_regular_index?(classified_fields, sort_hash, namespace)
      return []
    end

    # we are going to construct an 'ideal' index
    recommended_index = {}

    # index sequence : 1.equality tests 2.sort fields 3.range filters
    # http://java.dzone.com/articles/optimizing-mongodb-compound?mz=36885-nosql
    [:equal_type, :sort_type, :range_type].each do |field_type|
      classified_fields[field_type].each do |field|

        if recommended_index.keys.include?(field)
          # this field has already been handled
          next
        end

        order = Mongo::ASCENDING
        if sort_hash.include?(field)
          order = sort_hash[field] > 0 ? Mongo::ASCENDING : Mongo::DESCENDING
        end

        recommended_index[field] = order
      end
    end

    if recommended_index.size == 0
      return []
    end

    recommended_index = recommended_index.to_a
    if classified_fields[:unsupported_type].size == 0
      return [IndexResult.new(recommended_index, :good)]
    else
      return [IndexResult.new(recommended_index, :optional)]
    end
  end

  # Evaluate existing indexes against query. Similar to Dex(https://github.com/mongolab/dex).
  # The query is evaluated against each index according two criteria:
  # -Coverage (none, partial, full)
  #  a less granular description of fields covered.
  #  None corresponds to Fields Covered 0 and indicates the index is not used by the query.
  #  Full means the number of fields covered is equal to the number of fields in the query.
  #  Partial describes any value of fields covered value between None and Full.
  # -Order (ideal or not)
  #  describes whether the index is partially-ordered according to ideal index order: Equivalence > Sort > Range
  def generate_index_report(index, classified_fields, sort_hash)
    eq_fields = classified_fields[:equal_type].uniq
    sort_fields = classified_fields[:sort_type] # these are already unique
    range_fields = classified_fields[:range_type].uniq
    all_fields = eq_fields | sort_fields | range_fields

    # we are interested in the maximal prefix of the index that
    # contains only fields from the query
    index = index.take_while{|k,v| all_fields.include? k}
    index = Hash[*index.flatten]

    if index.values.include?("2d") || index.values.include?("2dsphere")
      return {:geospatial => true, :coverage => nil, :ideal_order => nil}
    end

    # evaluate the coverage quality
    covered_fields = (index.keys & all_fields).length
    if covered_fields == 0
      coverage = :none
    elsif covered_fields == all_fields.length
      coverage = :full
    else
      coverage = :partial
    end

    # evaluate the order quality
    ideal_order = true

    # eq_fields should be contained in a contiguous prefix of the index
    prefix = index.keys.take_while{|k| eq_fields.include? k}
    if prefix.sort != eq_fields.sort
      ideal_order = false
    end

    # when we discard eq_fields, the remaining sort_fields should be equal to
    # a contiguous prefix of the index
    remaining = sort_fields - eq_fields
    remaining_index = index.keys.reject{|field| eq_fields.include? field}
    if remaining_index.take(remaining.length) != remaining
      ideal_order = false
    end

    # index has to be sorted in the same manner as we require in sort_hash
    # (even if a field is included in eq_fields)
    sort_manner = index.find_all{|k,v| sort_hash.keys.include? k}
    if sort_manner != sort_hash.to_a
      ideal_order = false
    end
    {:coverage => coverage, :ideal_order => ideal_order, :geospatial=> false}
  end

  # This method returns true if it is able to detect that there is an ideal
  # index for the given query (full coverage, ideal order).
  def has_ideal_regular_index?(classified_fields, sort_hash, namespace)
    indexes = get_index_information(namespace)
    indexes.each do |_, index|
      report = generate_index_report(index["key"], classified_fields, sort_hash)

      if (report[:coverage] == :full) && (report[:ideal_order] == true)
        return true
      end
    end
    false
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
    "$mod" => :handle_mod,
    "$type" => :empty_handle, #TODO

    # javascript
    "$regex" =>  :handle_regex,
    "$where" => :handle_where,

    # geospatial
    "$geoWithin" => :empty_handle,
    "$within" => :empty_handle,
    "$nearSphere" => :empty_handle,
    "$near" => :empty_handle,
    "$maxDistance" => :empty_handle,
    "$centerSphere" => :empty_handle,
    "$geoIntersects" => :empty_handle,
    "$uniqueDocs" => :empty_handle,

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
    if hash.has_key?("$options")
      #assert that we have a "$regex" operator
      if !hash.has_key?("$regex")
        raise "$options operator provided, but $regex not present."
      end

      options = hash["$options"]
      hash.delete("$options")
    end

    if hash.has_key?("$regex")
      regex = "/#{hash["$regex"]}/#{options}"
      hash["$regex"] = regex
    end
  end

  # handles operators for a single field, eg
  # {"$in" => [1.0, 2.0, 3.0], "$lt" => 12}
  # @param field specifies the field in the collection
  def handle_single_field(field, operators_hash)
    res = []

    normalize_regexes operators_hash

    operators_hash.each do |operator_str, val|
      method_symbol = OPERATOR_HANDLERS_DISPATCH[operator_str]
      if method_symbol.nil?
        raise "Unknown operator: '#{operator_str}'."
      end
      res += method( method_symbol ).call field, val
    end
    res
  end

  # checks if a hash contains keys that start with a '$'
  def has_operators hash
    hash.any? { |key, _| key.start_with? "$" }
  end

  # This method iterates through all query elements and yields
  # each (key, val) pair along with a symbol designating the pair's meaning.
  # This method is NOT recursive.
  def traverse_query (query_hash)
    query_hash.each do |key, val|
      if key.start_with?("$")
        #e.g. $or => [query1, query2, ...]
        yield :multiple_queries_operator, key, val
      elsif (val.is_a? Hash) && (has_operators val)
        #e.g. "A" => {"$gt" : 13, "$lt" : 27}
        yield :field_query, key, val
      else
        #e.g. "A" => { "sub1" : 10, "sub2" : 30 }
        yield :field_equality, key, val
      end
    end
  end

  def analyze_query(query_hash)
    result = []
    traverse_query query_hash do |type, key, val|
      field = nil
      operator_hash = nil

      case type
      when :multiple_queries_operator
        operator_hash = { key => val }
      when :field_query
        field = key
        operator_hash = val
      when :field_equality
        field = key
        operator_hash = { "_equality_check" => nil }
      end
      result += handle_single_field field, operator_hash
    end
    result
  end

end #class Evaluator
