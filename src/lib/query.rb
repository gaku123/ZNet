class Query
  attr_accessor :target, :source, :route

  def initialize(target, source)
    @target = target
    @source = source
    @route = Array.new
  end
end

class RoutingQuery < Query

  attr_accessor :point

  def initialize(target, source, point)
    super(target, source)
    @point = point
  end
end

class PutQuery < Query
  attr_accessor :data

  def initialize(target, source, data)
    super(target, source)
    @data = data
  end
end

class LinkQuery < Query
  attr_accessor :level, :direction, :node

  def initialize(target, source, level, direction, node)
    super(target, source)
    @level = level
    @direction = direction
    @node = node
  end
end

class BeforJoinQuery < Query
  attr_accessor :responsible_node

  def initialize(target, source)
    super(target, source)
    @responsible_node = nil
  end
end

class JoinQuery < Query
  attr_accessor :join_info

  def initialize(target, source)
    super(target, source)
    @join_info = nil
  end
end

class RangeQuery < Query
  attr_accessor :range, :range_nodes

  def initialize(target, source, range)
    super(target, source)
    @range = range
    @range_nodes = Array.new
  end
end

class LinerQuery < RangeQuery
  attr_accessor :ll, :hr

  def initialize(target, source, range, ll = range[:ll], hr = range[:hr])
    super(target, source, range)
    @ll = ll
    @hr = hr
  end
end

class AdaptedQuery < RangeQuery
  attr_accessor :depth

  def initialize(target, source, range, depth)
    super(target, source, range)
    @depth = depth
  end
end
