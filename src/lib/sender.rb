# -*- coding: utf-8 -*-
module Sender

  #クエリの転送方法は反復(iterative)
  #ノードはクエリを渡されたら次の転送先を設定して，要求元へ返す．
  def send(query)
    begin
      next_node = query.target
      query.route << next_node
      query = next_node.receive(query)
    end until next_node == query.target
    query
  end

end
