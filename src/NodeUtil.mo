import AU "./ArrayUtil";
import BS "./BinarySearch";
import Types "./Types";

import Option "mo:base/Option";
import Order "mo:base/Order";

module {

  /// Inserts element at the given index into a non-full leaf node
  public func insertAtIndexOfNonFullNodeData<K, V>(data: Types.Data<K, V>, kvPair: (K, V), insertIndex: Nat): () {
    let currentLastElementIndex: Nat = if (data.count == 0) { 0 } else { data.count - 1 };
    AU.insertAtPosition<(K, V)>(data.kvs, ?kvPair, insertIndex, currentLastElementIndex);

    // increment the count of data in this node since just inserted an element
    data.count += 1;
  };

  /// Inserts two rebalanced (split) child halves into a non-full array of children. 
  public func insertRebalancedChild<K, V>(children: [var ?Types.Node<K, V>], rebalancedChildIndex: Nat, leftChildInsert: Types.Node<K, V>, rightChildInsert: Types.Node<K, V>): () {
    // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
    var j: Nat = children.size() - 2;

    // This is just a sanity check to ensure the children aren't already full (should split promote otherwise)
    // TODO: Remove this check once confident
    if (Option.isSome(children[j+1])) { assert false }; 

    // Iterate backwards over the array and shift each element over to the right by one until the rebalancedChildIndex is hit
    while (j > rebalancedChildIndex) {
      children[j + 1] := children[j];
      j -= 1;
    };

    // Insert both the left and right rebalanced children (replacing the pre-split child)
    children[j] := ?leftChildInsert;
    children[j+1] := ?rightChildInsert;
  };

  /// Used when splitting the children of an internal node
  ///
  /// Takes in the rebalanced child index, as well as both halves of the rebalanced child and splits the children, inserting the left and right child halves appropriately
  ///
  /// For more context, see the documentation for the splitArrayAndInsertTwo method in ArrayUtils.mo
  public func splitChildrenInTwoWithRebalances<K, V>(
    children: [var ?Types.Node<K, V>],
    rebalancedChildIndex: Nat,
    leftChildInsert: Types.Node<K, V>,
    rightChildInsert: Types.Node<K, V>
  ): ([var ?Types.Node<K, V>], [var ?Types.Node<K, V>]) {
    AU.splitArrayAndInsertTwo<Types.Node<K, V>>(children, rebalancedChildIndex, leftChildInsert, rightChildInsert);
  };

  /// Helper used to get the key index of of a key within a node
  ///
  /// for more, see the BinarySearch.binarySearchNode() documentation
  public func getKeyIndex<K, V>(data: Types.Data<K, V>, compare: (K, K) -> Order.Order, key: K): BS.SearchResult {
    BS.binarySearchNode<K, V>(data.kvs, compare, key, data.count);
  };
}