# -*- coding: utf-8 -*-
require 'node.rb'

class Simulator
  attr_accessor :nodes, :dimension, :results, :dataset

  def Simulator.main

    s = start

    begin

      print ">"
      input = gets.chomp.split(' ')

      case input[0]
      when "start"
        s = start
      when "route"
        s.route(input[1].to_i)
      when "print"
        s.printResults(input[1])
      when "liner"
        s.liner(input[1].to_i, input[2].to_f)
      when "adapted"
        s.adapted(input[1].to_i, input[2].to_f)
      when "savedata"
        s.saveData(input[1])
      when "changenetworksize"
        s.changeNetworkSize(input[1].to_i)
      when "changedimension"
        s.changeDimension(input[1].to_i)
      when "work"
        s.work(input[1].to_i)
      when "work2"
        s.work2(input[1].to_i)
      when "work3"
        s.work3(input[1].to_i)
      end

    end until input[0] == "exit"

  end

  def Simulator.start

    puts "initial settings"

    print "ネットワークの次元数 : "
    dimension = gets.to_i

    print "ノード数 : "
    network_size = gets.to_i

    print "データ数 : "
    data_num = gets.to_i

    print "データタイプ(\"random\",\"gauss\") : "
    data_type = gets.chomp

    puts "making network.."
    s = Simulator.new(dimension, network_size, data_num, data_type)
    s.makePerfectSkipGraph()
    puts "start znet simulator"
    s
  end

## ZNet構築 ##

  def initialize(dimension, node_num, data_num, data_type)
    @dimension = dimension
    @node_num = node_num
    @data_num = data_num
    @data_type = data_type
    @results = Array.new
    @id = 0
    node = Node.new
    node.startNetwork(dimension)
    node.id=@id.to_s
    @dataset = node.data = node.zones[0].data = dataset(data_num, data_type)
    @id += 1
    @nodes = [node]
    addNode(node_num-1)
  end

  def addNode(num)
    num.times do
      node = Node.new
      node.id = @id.to_s
      @id += 1
      node.join(@nodes[0])
      @nodes << node
    end
  end

  def makePerfectSkipGraph()
    node = @nodes[0]
    node = node.neighbors[0][:left] until node.neighbors[0][:left] == nil
    right_most_node = node
    Math::log(@nodes.length,2).to_i.times do |i|
      until node == nil do
        node.neighbors[i+1] = {:left => nil, :right => nil}
        l = node.neighbors[i][:left]
        node.neighbors[i+1][:left] = l.neighbors[i][:left] unless l == nil
        r = node.neighbors[i][:right]
        node.neighbors[i+1][:right]=r.neighbors[i][:right] unless r == nil
        node = node.neighbors[0][:right]
      end
      node = right_most_node
    end
  end

  def dataset(num, type)
    points = Array.new

    case type
    when "random"
      num.times do
        point = Array.new
        @dimension.times {point << rand(0..NETWORKSIZE)}
        points << MyData.new(point,"")
      end
    when "gauss"
      center = Array.new(dimension){rand((0.2)..(NETWORKSIZE-0.2))}
      num.times do
        point = Array.new
        @dimension.times do |i|
          begin 
            r = 0.15 * Math.sqrt( -2 * Math.log(rand()) ) * Math.cos(2 * Math::PI * rand()) + center[i]
          end while (r < 0 or NETWORKSIZE < r)
          point << r
        end
        points << MyData.new(point,"")
      end
    when "read"
    end

    points
  end

## Znet上での操作 ##

  def route(num)
    num = 1 if num < 1

    @results.clear
    num.times do
      point = Array.new(@dimension){rand(0..NETWORKSIZE)}
      node = @nodes.sample
      @results << node.route(point)
    end

  end

  def liner(num, length)
    until length != 0 and (0..NETWORKSIZE).include?(length)
      length = rand(0..NETWORKSIZE)
    end
    num = 1 if num < 1

    @results.clear
    num.times do
      ll = Array.new(@dimension){rand(0..(NETWORKSIZE-length))}
      hr = Array.new(@dimension){|i|ll[i]+length}
      node = @nodes.sample
      @results << node.liner({:ll => ll, :hr => hr})
    end

  end

  def adapted(num, length)
    until length != 0 and (0..NETWORKSIZE).include?(length)
      length = rand(0..NETWORKSIZE)
    end
    num = 1 if num < 1

    @results.clear
    num.times do
      ll = Array.new(@dimension){rand(0..(NETWORKSIZE-length))}
      hr = Array.new(@dimension){|i|ll[i]+length}
      node = @nodes.sample
      @results << node.adapted({:ll => ll, :hr => hr})
    end

  end

##  表示  ##
  def printResults(arg)
    if @results.empty?
      return
    end

    if arg =~ /zn|nz/ then printNodeAndZone end
    if arg == "n" then printNode end
    if arg == "z" then printZone end

    @results.each do |res|
      case res
      when RoutingQuery
        puts "point : #{res.point}"
      when RangeQuery
        puts "length : #{(res.range[:hr][0]-res.range[:ll][0]).inspect}"
        puts "range : #{res.range.inspect}"
        res.range_nodes.each {|n| puts "range id#{n.id}"}
      end
      puts "source : id#{res.source.id}"
      puts "target : id#{res.target.id}"
      puts "hop : #{res.route.length}"
      res.route.each {|n| puts "hop id#{n.id}" if n.class == Node}
    end

  end

  def printNode()
    node = @nodes[0]
    node = node.neighbors[0][:left] until node.neighbors[0][:left] == nil
    until node == nil do
      node.neighbors.length.times do |j|
        print node.neighbors[-(j+1)][:left].id unless node.neighbors[-(j+1)][:left] == nil
        print "-"
        print node.id
        print "-"
        print node.neighbors[-(j+1)][:right].id unless node.neighbors[-(j+1)][:right] == nil
        puts
      end
      puts
      node = node.neighbors[0][:right]
    end
  end

  def printNodeAndZone()
    node = @nodes[0]
    node = node.neighbors[0][:left] until node.neighbors[0][:left] == nil
    until node == nil do
      node.neighbors.length.times do |j|
        print node.neighbors[-(j+1)][:left].id unless node.neighbors[-(j+1)][:left] == nil
        print "-"
        print node.id
        print "-"
        print node.neighbors[-(j+1)][:right].id unless node.neighbors[-(j+1)][:right] == nil
        puts
      end
      p node.zones
      node = node.neighbors[0][:right]
    end
  end

  ## シミュレーター情報保存，変更 ##
  def saveData(name)
    if name == nil
      print "file name : "
      name = gets.chomp
    end
    io = open(name, "w")
    @dataset.each do |data|
      data.key.each {|e| io.print "#{e.to_s} "}
      io.puts
    end
    io.close
  end

  def changeNetworkSize(node_num)
    @node_num = node_num
    @results = Array.new
    @id = 0
    node = Node.new
    node.startNetwork(@dimension)
    node.id=@id.to_s
    node.data = node.zones[0].data = @dataset
    @id += 1
    @nodes = [node]
    addNode(node_num-1)
    makePerfectSkipGraph()
  end

  def changeDimension(dimension)
    @dimension = dimension
    @results = Array.new
    @id = 0
    node = Node.new
    node.startNetwork(dimension)
    node.id=@id.to_s
    @dataset = node.data = node.zones[0].data = dataset(@data_num, @data_type)
    @id += 1
    @nodes = [node]
    addNode(@node_num-1)
    makePerfectSkipGraph()
  end

  ## 実験用 ##
  def work(lookup_num)
    io = open("work1-"+@data_type+"-"+@dimension.to_s+"dimension", "w")
    io.puts "length liner_hop liner_msg adapted_hop adapted_msg"
    5.times do |i|
      lhop, lmsg = 0, 0
      ahop, amsg = 0, 0
      length = ((i+1)*0.05).round(2)
      lookup_num.times do
        node = @nodes.sample
        ll = Array.new(@dimension){rand(0..(NETWORKSIZE-length).round(2))}
        hr = Array.new(@dimension){|i|ll[i]+length}
        lquery = node.liner({:ll => ll, :hr => hr})
        aquery = node.adapted({:ll => ll, :hr => hr})
        lhop += lquery.route.length
        lmsg += lquery.route.length
        ahop += countHop(aquery.route)
        amsg += aquery.route.flatten.length
      end
      lhop,lmsg,ahop,amsg = [lhop, lmsg, ahop, amsg].map{|e|e/lookup_num} unless lookup_num == 0
      io.printf("%0.2f %d %d %d %d\n", length, lhop, lmsg, ahop, amsg)
    end
    io.close
  end

  def work2(lookup_num)
    io = open("work2-"+@data_type+"-"+@dimension.to_s+"dimension", "w")
    io.puts "network-size liner_hop liner_msg adapted_hop adapted_msg"
    length = 0.2
    5.times do |i|
      networksize = (i+1)*2000
      changeNetworkSize(networksize)
      lhop, lmsg = 0, 0
      ahop, amsg = 0, 0
      lookup_num.times do
        node = @nodes.sample
        ll = Array.new(@dimension){rand(0..(NETWORKSIZE-length).round(2))}
        hr = Array.new(@dimension){|i|ll[i]+length}
        lquery = node.liner({:ll => ll, :hr => hr})
        aquery = node.adapted({:ll => ll, :hr => hr})
        lhop += lquery.route.length
        lmsg += lquery.route.length
        ahop += countHop(aquery.route)
        amsg += aquery.route.flatten.length
      end
      lhop,lmsg,ahop,amsg = [lhop, lmsg, ahop, amsg].map{|e|e/lookup_num} unless lookup_num == 0
      io.printf("%d %d %d %d %d\n", networksize, lhop, lmsg, ahop, amsg)
    end
    io.close
  end

  def work3(lookup_num)
    io = open("work3-"+@data_type, "w")
    io.puts "dimension liner_hop liner_msg adapted_hop adapted_msg"
    length = 0.2
    4.times do |i|
      dimension = i*4
      dimension = 2 if i == 0
      changeDimension(dimension)
      lhop, lmsg = 0, 0
      ahop, amsg = 0, 0
      lookup_num.times do
        node = @nodes.sample
        ll = Array.new(@dimension){rand(0..(NETWORKSIZE-length).round(2))}
        hr = Array.new(@dimension){|i|ll[i]+length}
        lquery = node.liner({:ll => ll, :hr => hr})
        aquery = node.adapted({:ll => ll, :hr => hr})
        lhop += lquery.route.length
        lmsg += lquery.route.length
        ahop += countHop(aquery.route)
        amsg += aquery.route.flatten.length
      end
      lhop,lmsg,ahop,amsg = [lhop, lmsg, ahop, amsg].map{|e|e/lookup_num} unless lookup_num == 0
      io.printf("%d %d %d %d %d\n", dimension, lhop, lmsg, ahop, amsg)
    end
    io.close
  end

  #並列に行われた検索ではrouteが入れ子構造になるが，以下略
  def countHop(route)
    max = nlen = route.select{|e| e.class == Node}.length
    route.select{|e| e.class == Array}.each do |array|
      alen = countHop(array)
      max = nlen+alen if max < nlen+alen
    end
    max
  end

end
