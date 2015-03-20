# -*- coding: utf-8 -*-
module Receiver

  def receive(query)
    case query #これはスーパークラスもtrueになるらしい
      when PutQuery then put0(query)
      when BeforJoinQuery then beforjoin0(query)
      when JoinQuery then join0(query)
      when LinkQuery then link0(query)
      when RoutingQuery then route0(query)
      when LinerQuery then liner0(query)
      when AdaptedQuery then adapted0(query)
      else raise "no matching Query #{query.class}"
    end
    query #send(送信元)
  end

  def put0(query)
  end

  #論文ではintroducerが適当な座標を検索して、
  #クエリが転送されたノードの中で一番データが多いノードが選ばれる。
  #ここではノード間通信で、クエリの送受信をしてないから処理をここに書いた。
  #やっていることは全てのノードの中でデータを一番多くもつノードを選んでいる。
  def beforjoin0(query)
    max = p = query.target
    p = p.neighbors[0][:left] until p.neighbors[0][:left] == nil
    until(p == nil) do
      max = p if max.data.length < p.data.length
      p = p.neighbors[0][:right]
    end
    query.responsible_node = max
  end

  def join0(query)
  end

  def route0(query)
  end

  def range0(query)
  end

end
