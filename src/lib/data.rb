
class MyData
  attr_accessor :key, :value

  def initialize(key, value)
    @key = key
    @value = value
  end

  def in?(zone)
    @key.length.times do |i|
      if @key[i] < zone.area[:ll][i] or @key[i] >= zone.area[:hr][i]
        return false unless @key[i] == NETWORKSIZE and zone.area[:hr][i] == NETWORKSIZE
      end
    end
    true
  end

end
