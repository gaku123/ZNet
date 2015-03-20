# -*- coding: utf-8 -*-
require 'zone.rb'
require 'data.rb'
require 'sender.rb'
require 'receiver.rb'
require 'query.rb'

NETWORKSIZE = 1.0

class Node
  attr_accessor :id, :data, :neighbors, :zones, :mvector
  attr_reader :dimension

  include Sender, Receiver

##初期化処理##

  def initialize()
    @id = String.new
    @data = Array.new
    @neighbors = [{:left => nil, :right => nil}]
    @zones = Array.new
    @mvector = Array.new
  end

##外部の機能(UI)##

  def startNetwork(dimension)
    raise "引数がおかしい" unless dimension > 0 and dimension.kind_of?(Integer)
    @dimension = dimension
    zone = Zone.new(String.new, {:ll => Array.new(dimension){0.0}, :hr => Array.new(dimension){NETWORKSIZE}}, 0)
    @zones << zone
  end

  def put(data)
    if responsible_node?(data)
      @data << data
    else
      z = getZaddress(data.key)
      next_node = findCloserNode(z)
      send(PutQuery.new(next_node,self,data))
    end
  end

  def join(introducer)
    bjquery = BeforJoinQuery.new(introducer,self)
    bjquery = send(bjquery)
    query = JoinQuery.new(bjquery.responsible_node,self)
    query = send(query)
    @zones = query.join_info[:zones]
    @dimension = @zones.first.area[:ll].length
    @data = query.join_info[:data]
    @neighbors[0][:left] = query.join_info[:left]
    @neighbors[0][:right] = bjquery.responsible_node
    send(LinkQuery.new(@neighbors[0][:left],self,0,:right,self)) if @neighbors[0][:left] != nil
    makeSkipGraph()
  end

  def route(p) #引数は座標
    z = getZaddress(p)
    next_node = findCloserNode(z)
    query = send(RoutingQuery.new(next_node, self, p))
  end

  def liner(range)
    raise "範囲がおかしい" unless range[:ll].length == @dimension and range[:hr].length == @dimension
    zL = getZaddress(range[:ll])
    next_node = findCloserNode(zL)
    liner_query = send(LinerQuery.new(next_node, self, range))
  end

  def adapted(range)
    raise "範囲がおかしい" unless range[:ll].length == @dimension and range[:hr].length == @dimension
    zL = getZaddress(range[:ll])
    next_node = findCloserNode(zL)
    adapted_query = send(AdaptedQuery.new(next_node, self, range, 0))
  end

##クエリ受信時の処理##

  def put0(query)
    data = query.data
    if responsible_node?(data)
      @data << data
    else
      z = getZaddress(data.key)
      next_node = findCloserNode(z)
      query.target = next_node
    end
  end

  def join0(query)
    @zones = @zones.shift.divideZone() if @zones.length == 1
    join_info={:zones => Array.new, :data => Array.new, :left => @neighbors[0][:left]}
    @neighbors[0][:left]=query.source #代入の順番注意
    num=rand(1..@zones.length-1) #新規ノードにあげるzoneの数（考察余地あり）
    num.times do #zoneとそのzoneに存在するデータを新規ノードへ渡す
      zone = @zones.shift
      join_info[:data] += zone.data
      join_info[:zones] << zone
    end
    @data -= join_info[:data]
    query.join_info = join_info
  end

  def link0(query)
    @neighbors[query.level][query.direction] = query.node
  end

  def route0(query)
    z = getZaddress(query.point)
    query.target=findCloserNode(z)
  end

  #検索の取り残しがないか心配
  def liner0(query)
    zL = getZaddress(query.ll)
    zH = getZaddress(query.hr)
    unless @zones.collect{|zone|zone.zaddress}.include?(zL) #まずはllの担当ノードをルーティング
      query.target = findCloserNode(zL)
    else
      if isOverlap?(query.range)
        query.range_nodes << self
      end
      if getZrange[:right] < zH
        zL2 = getLowestOverlapZ(query.range)
        ll2 = Zone.zaddress_to_zone(zL2, @dimension).area[:ll]
        query.target=findCloserNode(zL2)
        query.ll = ll2
      end
    end
  end

  def adapted0(query)
    zL = getZaddress(query.range[:ll])
    unless @zones.collect{|zone|zone.zaddress}.include?(zL) #まずはllの担当ノードをルーティング
      query.target = findCloserNode(zL)
    else
      if query.depth < getZlevel
        ranges = devideRange(query.range, query.depth)
        ranges.each do |range|
          next_node = findCloserNode(getZaddress(range[:ll]))
          devided_query = AdaptedQuery.new(next_node, self, range, query.depth+1)
          devided_query.range_nodes = query.range_nodes
          query.route << Array.new
          devided_query.route = query.route.last
          send(devided_query)
        end
      else
        query.range_nodes << self
      end
    end
  end

  #内部の機能

  #経路表から一番近いノードをかえす，自分の範囲なら自分
  #比較するZAddressのZoneが包含関係にあればtrueを返す条件式になっている
  def findCloserNode(z)
    @neighbors.length.times do |i|
      l = @neighbors[-(i+1)][:left]
      if l != nil
        lz = l.getZrange[:right]
        return l if z < lz
        return l if z[0,z.length] == lz[0,z.length]
        return l if z[0,lz.length] == lz[0,lz.length]
      end
      r = @neighbors[-(i+1)][:right]
      if r != nil
        rz = r.getZrange[:left]
        return r if rz < z
        return r if z[0,z.length] == rz[0,z.length]
        return r if z[0,rz.length] == rz[0,rz.length]
      end
    end
    self
  end

  #検索範囲を分割する
  #再帰呼び出しを使った多重ループ構造
  def devideRange(range, depth, dim = 0,
                  ll = Array.new, hr = Array.new, ranges = Array.new)
    if dim == @dimension
      devided_range = {:ll => ll.clone, :hr => hr.clone}
      ranges << devided_range
      return
    end
    #まず分割点を求める
    l = 0.0
    r = NETWORKSIZE
    c = (l+r)*0.5
    depth.times do |i|
      range[:hr][dim] <= c ? r=c : l=c
      c = (l+r)*0.5
    end
    #次に分割される分割点を求める
    temp = Array.new
    temp << range[:ll][dim]
    temp << c if range[:ll][dim] < c and c <= range[:hr][dim]
    temp << range[:hr][dim]
    #最後に分割する
    (temp.length-1).times do |i|
      ll[dim] = temp[i]
      hr[dim] = temp[i+1]
      devideRange(range, depth, dim+1, ll, hr, ranges)
    end
    ranges
  end

  #次に検索範囲と交差する自分のZRangeより大きいZAddressを返す
  def getLowestOverlapZ(range)
    zL = getZrange[:right]
    zH = getZaddress(range[:hr])
    while (zL <= zH)
      zL = sprintf("%0#{zL.length}b", zL.to_i(2)+1)
      return zL if Zone.zaddress_to_zone(zL, @dimension).isOverlap?(range)
    end
    nil
  end

  #自分のZoneが検索範囲と交差するかどうか
  def isOverlap?(range)
    @zones.each do |zone|
      return true if zone.isOverlap?(range)
    end
    false
  end

  #自分が引数のデータの担当ノードかどうか
  def responsible_node?(data)
    @zones.each do |zone|
      return true if data.in?(zone)
    end
    false
  end

  def makeSkipGraph()
    #mevectorの決定と~桁同じならリンクをはるクエリの送信のループはや
    #skipgraphは理想的なSkipGraphを作るのでここでは作らない．
    #これはstabiraiseでやることかも
  end

  #ネットワーク全体を自ノードのZlevel回分割して、座標があるZoneのZaddressを返す
  def getZaddress(p)
    dimension = @dimension
    zlevel = getZlevel
    z = String.new
    ll = Array.new(dimension) {0.0}
    hr = Array.new(dimension) {NETWORKSIZE}
    c = Array.new(dimension)
    zlevel.times do |i|
      dimension.times do |j|
        c[j] = (ll[j]+hr[j])*0.5
        if(p[j] < c[j])
          z << "0"
          hr[j] = c[j]
        else
          z << "1"
          ll[j] = c[j]
        end
      end
    end
    z
  end

  def getZlevel()
    raise "管理するZoneがない" if @zones.length == 0
    @zones[0].zlevel
  end

  def getZrange
    #sortの動作に注意
    @zones.sort!{|z1,z2| z1.zaddress <=> z2.zaddress}
    {:left => @zones.first.zaddress, :right => @zones.last.zaddress}
  end

end
