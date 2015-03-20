# -*- coding: utf-8 -*-

class Zone
  attr_accessor :neighbors, :data
  attr_reader :zaddress, :area, :zlevel

  def initialize(zaddress, area, zlevel)
    @zaddress = zaddress
    @area = area
    @neighbors = {:left => nil, :right => nil}
    @zlevel = zlevel
    @data = Array.new
  end

  #ZAddressと次元からZAddressが指すZoneのエリアを求め，
  #そのエリアでZoneを初期化して返す
  def Zone.zaddress_to_zone(z, dimension)
    ll = Array.new(dimension){0.0}
    hr = Array.new(dimension){NETWORKSIZE}
    center = Array.new(dimension) {|i| (ll[i]+hr[i])*0.5}
    zlevel=z.length/dimension
    zlevel.times do |l|
      dimension.times do |i|
        ll[i] = z[(l*dimension)+i,1]=="0" ? ll[i] : center[i]
        hr[i] = z[(l*dimension)+i,1]=="0" ? center[i] : hr[i]
        center = Array.new(dimension) {|i| (ll[i]+hr[i])*0.5}
      end
    end
    Zone.new(z, {:ll => ll, :hr => hr}, zlevel)
  end

  #ゾーンが検索範囲かどうか
  def isOverlap?(range)
    dimension = @area[:ll].length
    ll = range[:ll]
    hr = range[:hr]
    dimension.times do |i|
      if hr[i] < @area[:ll][i] or @area[:hr][i] <= ll[i]
        return false unless ll[i] == NETWORKSIZE and @area[:hr][i] == NETWORKSIZE
      end
    end
    true
  end

  def divideZone()
    dimension = @area[:ll].length
    center = Array.new(dimension) {|i| (@area[:ll][i]+@area[:hr][i])*0.5}
    k = @zaddress.length
    zones = Array.new
    (2**dimension).times do |i|
      zaddress = sprintf("%s%0#{dimension}b",@zaddress, i)
      ll = Array.new(dimension) {|i| zaddress[i+k,1]=="0" ? @area[:ll][i] : center[i]}
      hr = Array.new(dimension) {|i| zaddress[i+k,1]=="0" ? center[i] : @area[:hr][i]}
      zone = Zone.new(zaddress, {:ll => ll, :hr => hr}, @zlevel+1)
      @data -= data = @data.select {|data| data.in?(zone)}
      zone.data = data
      zones << zone
    end
    raise "zone分割時のデータの受け渡しがうまくいってない" if @data.length > 0
    zones
  end

end
