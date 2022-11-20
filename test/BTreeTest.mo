import M "mo:matchers/Matchers";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";

import Nat "mo:base/Nat";

import BT "../src/BTree";


func testableNatBTree(t: BT.BTree<Nat, Nat>): T.TestableItem<BT.BTree<Nat, Nat>> {
  testableBTree(t, Nat.equal, Nat.equal, Nat.toText, Nat.toText)
};  


func testableBTree<K, V>(
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

let initSuite = S.suite("init", [
  S.test("initializes an empty BTree with order 4 to have the correct number of keys (order - 1)",
    BT.init<Nat, Nat>(4),
    M.equals(testableNatBTree({
      var root = #leaf({
        data = {
          kvs = [var null, null, null];
          var count = 0;
        }
      });
      order = 4;
    }))
  )
]);

S.run(S.suite("BTree",
  [
    initSuite,
  ]
));