import BT "../src/BTree";
import T "mo:matchers/Testable";
import Nat "mo:base/Nat";

module {
  public func testableBTree<K, V>(
    t: BT.BTree<K, V>,
    keyEquals: (K, K) -> Bool,
    valueEquals: (V, V) -> Bool,
    keyToText: K -> Text,
    valueToText: V -> Text,
  ): T.TestableItem<BT.BTree<K, V>> = {
    display = func(t: BT.BTree<K, V>): Text = BT.toText<K, V>(t, keyToText, valueToText);
    equals = func(t1: BT.BTree<K, V>, t2: BT.BTree<K, V>): Bool {
      BT.equals(t1, t2, keyEquals, valueEquals);
    }; 
    item = t;
  };
}