
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import O "mo:base/Order";
import Nat "mo:base/Nat";


module {
  
  public type Node<K, V> = {
    #leaf: Leaf<K, V>;
    #internal: Internal<K, V>;
  };

  public type Data<K, V> = {
    kvs: [var ?(K, V)];
    var count: Nat;
  };

  public type Internal<K, V> = {
    data: Data<K, V>;
    children: [var ?Node<K, V>]
  };

  public type Leaf<K, V> = {
    data: Data<K, V>;
  };

  public type BTree<K, V> = {
    var root: Node<K, V>;
    order: Nat;
  };

  // TODO - enforce BTrees to have order of at least 4
  public func init<K, V>(order: Nat): BTree<K, V> = {
    var root = #leaf({
      data = {
        kvs = Array.tabulateVar<?(K, V)>(order - 1, func(i) { null });
        var count = 0;
      };
    }); 
    order;
  };

  /// Opinionated version of generating a textual representation of a BTree. Primarily to be used
  /// for testing and debugging
  public func toText<K, V>(t: BTree<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var textOutput = "BTree={";
    textOutput #= "root=" # rootToText<K, V>(t.root, keyToText, valueToText) # "; ";
    textOutput #= "order=" # Nat.toText(t.order) # "; ";
    textOutput # "}";
  };


  /// Determines if two BTrees are equivalent
  public func equals<K, V>(
    t1: BTree<K, V>,
    t2: BTree<K, V>,
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool
  ): Bool {
    if (t1.order != t2.order) return false;

    nodeEquals(t1.root, t2.root, keyEquals, valueEquals);
  };


  func rootToText<K, V>(node: Node<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var rootText = "{";
    switch(node) {
      case (#leaf(leafNode)) { rootText #= "#leaf=" # leafToText(leafNode, keyToText, valueToText) };
      case (#internal(internalNode)) {
        rootText #= "#internal=" # internalToText(internalNode, keyToText, valueToText) 
      };
    }; 

    rootText;
  };

  func leafToText<K, V>(leaf: Leaf<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var leafText = "{data=";
    leafText #= dataToText(leaf.data, keyToText, valueToText); 
    leafText # "}";
  };

  func internalToText<K, V>(internal: Internal<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var internalText = "{";
    internalText #= "data=" # dataToText(internal.data, keyToText, valueToText) # "; ";
    internalText #= "children=[";

    var i = 0;
    while (i < internal.children.size()) {
      switch(internal.children[i]) {
        case null { internalText #= "null" };
        case (?(#leaf(leafNode))) { internalText #= "#leaf=" # leafToText(leafNode, keyToText, valueToText) };
        case (?(#internal(internalNode))) {
          internalText #= "#internal=" # internalToText(internalNode, keyToText, valueToText)
        };
      };
      internalText #= ", ";
      i += 1;
    };

    internalText # "]}";
  };

  func dataToText<K, V>(data: Data<K, V>, keyToText: K -> Text, valueToText: V -> Text): Text {
    var dataText = "{kvs=[";
    var i = 0;
    while (i < data.kvs.size()) {
      switch(data.kvs[i]) {
        case null { dataText #= "null, " };
        case (?(k, v)) {
          dataText #= "(key={" # keyToText(k) # "}, value={" # valueToText(v) # "}), "
        }
      };

      i += 1;
    };

    dataText #= "]; count=" # Nat.toText(data.count) # ";}";
    dataText;
  };

  
  func nodeEquals<K, V>(
    n1: Node<K, V>,
    n2: Node<K, V>,
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool
  ): Bool {
    switch(n1, n2) {
      case (#leaf(l1), #leaf(l2)) { 
        dataEquals(l1.data, l2.data, keyEquals, valueEquals);
      };
      case (#internal(i1), #internal(i2)) {
        dataEquals(i1.data, i2.data, keyEquals, valueEquals)
        and
        childrenEquals(i1.children, i2.children, keyEquals, valueEquals)
      };
      case _ { false };
    };
  };

  func childrenEquals<K, V>(
    c1: [var ?Node<K, V>],
    c2: [var ?Node<K, V>],
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool
  ): Bool {
    if (c1.size() != c2.size()) { return false };

    var i = 0;
    while (i < c1.size()) {
      switch(c1[i], c2[i]) {
        case (null, null) {};
        case (?n1, ?n2) { 
          if (not nodeEquals(n1, n2, keyEquals, valueEquals)) {
            return false;
          }
        };
        case _ { return false }
      };

      i += 1;
    };

    true
  };

  func dataEquals<K, V>(
    d1: Data<K, V>,
    d2: Data<K, V>,
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool
  ): Bool {
    if (d1.count != d2.count) { return false };
    if (d1.kvs.size() != d2.kvs.size()) { return false };

    var i = 0;
    while(i < d1.kvs.size()) {
      switch(d1.kvs[i], d2.kvs[i]) {
        case (null, null) {};
        case (?(k1, v1), ?(k2, v2)) {
          if (
            (not keyEquals(k1, k2))
            or
            (not valueEquals(v1, v2))
          ) { return false };
        };
        case _ { return false };
      };

      i += 1;
    };

    true;
  };

}
