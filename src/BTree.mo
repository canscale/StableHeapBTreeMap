/// The BTree module collection of functions and types

import Types "./Types";
import AU "./ArrayUtil";
import NU "./NodeUtil";

import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import O "mo:base/Order";
import Nat "mo:base/Nat";




module {
  public type BTree<K, V> = Types.BTree<K, V>;
  public type Node<K, V> = Types.Node<K, V>;
  public type Internal<K, V> = Types.Internal<K, V>;
  public type Leaf<K, V> = Types.Leaf<K, V>;
  public type Data<K, V> = Types.Data<K, V>;

  // TODO - enforce BTrees to have order of at least 4
  public func init<K, V>(order: ?Nat): BTree<K, V> {
    let btreeOrder = switch(order) {
      case null { 8 };
      case (?providedOrder) { providedOrder };
    };

    {
      var root = #leaf({
        data = {
          kvs = Array.tabulateVar<?(K, V)>(btreeOrder - 1, func(i) { null });
          var count = 0;
        };
      }); 
      order = btreeOrder;
    }
  };

  
  /// Allows one to quickly create a BTree using an array of key value pairs
  public func createBTreeWithKVPairs<K, V>(order: Nat, compare: (K, K) -> O.Order, kvPairs: [(K, V)]): BTree<K, V> {
    let t = init<K, V>(?order);
    let _ = Array.map<(K, V), ?V>(kvPairs, func(pair) {
      insert<K, V>(t, compare, pair.0, pair.1)
    });
    t;
  };


  /// Retrieves the value corresponding to the key of BTree if it exists
  public func get<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, key: K): ?V {
    switch(tree.root) {
      case (#internal(internalNode)) { getFromInternal(internalNode, compare, key) };
      case (#leaf(leafNode)) { getFromLeaf(leafNode, compare, key) }
    }
  };


  /// Inserts an element into a BTree
  public func insert<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, key: K, value: V): ?V {
    let insertResult = switch(tree.root) {
      case (#leaf(leafNode)) { leafInsertHelper<K, V>(leafNode, tree.order, compare, key, value) };
      case (#internal(internalNode)) { internalInsertHelper<K, V>(internalNode, tree.order, compare, key, value) };
    };

    switch(insertResult) {
      case (#insert(ov)) { ov };
      case (#promote({ kv; leftChild; rightChild; })) {
        tree.root := #internal({
          data = {
            kvs = Array.tabulateVar<?(K, V)>(tree.order - 1, func(i) {
              if (i == 0) { ?kv }
              else { null }
            });
            var count = 1;
          };
          children = Array.tabulateVar<?(Node<K, V>)>(tree.order, func(i) {
            if (i == 0) { ?leftChild }
            else if (i == 1) { ?rightChild }
            else { null }
          });
        });

        null
      }
    };
  };


  /// Deletes an element from a BTree
  public func delete<K, V>(tree: BTree<K, V>, compare: (K, K) -> O.Order, key: K): ?V {
    switch(tree.root) {
      case (#leaf(leafNode)) {
        // TODO: think about how this can be optimized so don't have to do two steps (search and then insert)?
        switch(NU.getKeyIndex<K, V>(leafNode.data, compare, key)) {
          case (#keyFound(deleteIndex)) { 
            leafNode.data.count -= 1;
            let (_, deletedValue) = AU.deleteAndShiftValuesOver<(K, V)>(leafNode.data.kvs, deleteIndex);
            ?deletedValue
          };
          case _ { null }
        }

      };
      case (#internal(internalNode)) { 
        switch(internalDeleteHelper(internalNode, tree.order, compare, key, false)) {
          case (#delete(value)) { value };
          case (#mergeChild({ internalChild; deletedValue })) {
            if (internalChild.data.count > 0) {
              tree.root := #internal(internalChild);
            }
            // This case will be hit if the BTree has order == 4
            // In this case, the internalChild has no keys (last key was merged with new child), so need to promote that merged child (its only child)
            else {
              tree.root := switch(internalChild.children[0]) {
                case (?node) { node };
                case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In BTree.delete(), element deletion failed, due to a null replacement node error") };
              };
            };
            deletedValue
          }
        }
      }

    }
  };

  // This type is used to signal to the parent calling context what happened in the level below
  type IntermediateInternalDeleteResult<K, V> = {
    // element was deleted or not found, returning the old value (?value or null)
    #delete: ?V;
    // deleted an element, but was unable to successfully borrow and rebalance at the previous level without merging children
    // the internalChild is the merged child that needs to be rebalanced at the next level up in the BTree
    #mergeChild: {
      internalChild: Internal<K, V>;
      deletedValue: ?V
    }
  };

  func internalDeleteHelper<K, V>(internalNode: Internal<K, V>, order: Nat, compare: (K, K) -> O.Order, deleteKey: K, skipNode: Bool): IntermediateInternalDeleteResult<K, V> {
    let minKeys = NU.minKeysFromOrder(order);
    let keyIndex = NU.getKeyIndex<K, V>(internalNode.data, compare, deleteKey);

    // match on both the result of the node binary search, and if this node level should be skipped even if the key is found (internal kv replacement case)
    switch(keyIndex, skipNode) {
      // if key is found in the internal node
      case (#keyFound(deleteIndex), false) {
        let deletedValue = switch(internalNode.data.kvs[deleteIndex]) {
          case (?kv) { ?kv.1 };
          case null { assert false; null };
        };
        // TODO: (optimization) replace with deletion in one step without having to retrieve the maxKey first
        let replaceKV = NU.getMaxKeyValue(internalNode.children[deleteIndex]);
        internalNode.data.kvs[deleteIndex] := ?replaceKV;
        switch(internalDeleteHelper(internalNode, order, compare, replaceKV.0, true)) {
          case (#delete(_)) { #delete(deletedValue) };
          case (#mergeChild({ internalChild; })) { #mergeChild({ internalChild; deletedValue }) }
        };
      };
      // if key is not found in the internal node OR the key is found, but skipping this node (because deleting the in order precessor i.e. replacement kv)
      // in both cases need to descend and traverse to find the kv to delete
      case ((#keyFound(_), true) or (#notFound(_), _)) {
        let childIndex = switch(keyIndex) {
          case (#keyFound(replacedSkipKeyIndex)) { replacedSkipKeyIndex };
          case (#notFound(childIndex)) { childIndex };
        };
        let child = switch(internalNode.children[childIndex]) {
          case (?c) { c };
          case null { Debug.trap("UNREACHABLE_ERROR: file a bug report! In internalDeleteHelper, child index of #keyFound or #notfound is null") };
        };
        switch(child) {
          // if child is internal
          case (#internal(internalChild)) { 
            switch(internalDeleteHelper(internalChild, order, compare, deleteKey, false), childIndex == 0) {
              // if value was successfully deleted and no additional tree re-balancing is needed, return the deleted value
              case (#delete(v), _) { #delete(v) };
              // if internalChild needs rebalancing and pulling child is left most
              case (#mergeChild({ internalChild; deletedValue }), true) {
                // try to pull left-most key and child from right sibling
                switch(NU.borrowFromInternalSibling(internalNode.children, childIndex + 1, #successor)) {
                  // if can pull up sibling kv and child
                  case (#borrowed({ deletedSiblingKVPair; child; })) {
                    NU.rotateBorrowedKVsAndChildFromSibling(
                      internalNode,
                      childIndex,
                      deletedSiblingKVPair,
                      child,
                      internalChild,
                      #right
                    );
                    #delete(deletedValue);
                  };
                  // unable to pull from sibling, need to merge with right sibling and push down parent
                  case (#notEnoughKeys(sibling)) {
                    // get the parent kv that will be pushed down the the child
                    let kvPairToBePushedToChild = ?AU.deleteAndShiftValuesOver(internalNode.data.kvs, 0);
                    internalNode.data.count -= 1;
                    // merge the children and push down the parent
                    let newChild = NU.mergeChildrenAndPushDownParent<K, V>(internalChild, kvPairToBePushedToChild, sibling);
                    // update children of the parent
                    internalNode.children[0] := ?#internal(newChild);
                    ignore ?AU.deleteAndShiftValuesOver(internalNode.children, 1);
                    
                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue; })
                    } else {
                      #delete(deletedValue)
                    }
                  };
                }
              };
              // if internalChild needs rebalancing and pulling child is > 0, so a left sibling exists
              case (#mergeChild({ internalChild; deletedValue }), false) {
                // try to pull right-most key and its child directly from left sibling
                switch(NU.borrowFromInternalSibling(internalNode.children, childIndex - 1: Nat, #predecessor)) {
                  case (#borrowed({ deletedSiblingKVPair; child; })) {
                    NU.rotateBorrowedKVsAndChildFromSibling(
                      internalNode,
                      childIndex - 1: Nat,
                      deletedSiblingKVPair,
                      child,
                      internalChild,
                      #left
                    );
                    #delete(deletedValue);
                  };
                  // unable to pull from left sibling
                  case (#notEnoughKeys(leftSibling)) {
                    // if child is not last index, try to pull from the right child
                    if (childIndex < internalNode.data.count) {
                      switch(NU.borrowFromInternalSibling(internalNode.children, childIndex, #successor)) {
                        // if can pull up sibling kv and child
                        case (#borrowed({ deletedSiblingKVPair; child; })) {
                          NU.rotateBorrowedKVsAndChildFromSibling(
                            internalNode,
                            childIndex,
                            deletedSiblingKVPair,
                            child,
                            internalChild,
                            #right
                          );
                          return #delete(deletedValue);
                        };
                        // if cannot borrow, from left or right, merge (see below)
                        case _ {};
                      }
                    };

                    // get the parent kv that will be pushed down the the child
                    let kvPairToBePushedToChild = ?AU.deleteAndShiftValuesOver(internalNode.data.kvs, childIndex - 1: Nat);
                    internalNode.data.count -= 1;
                    // merge it the children and push down the parent 
                    let newChild = NU.mergeChildrenAndPushDownParent(leftSibling, kvPairToBePushedToChild, internalChild);

                    // update children of the parent
                    internalNode.children[childIndex - 1] := ?#internal(newChild);
                    ignore ?AU.deleteAndShiftValuesOver(internalNode.children, childIndex);
                    
                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue; })
                    } else {
                      #delete(deletedValue)
                    };
                  }
                }
              };
            }
          };
          // if child is leaf
          case (#leaf(leafChild)) { 
            switch(leafDeleteHelper(leafChild, order, compare, deleteKey), childIndex == 0) {
              case (#delete(value), _) { #delete(value)};
              // if delete child is left most, try to borrow from right child
              case (#mergeLeafData({ data; leafDeleteIndex }), true) { 
                switch(NU.borrowFromRightLeafChild(internalNode.children, childIndex)) {
                  case (?borrowedKVPair) {
                    let kvPairToBePushedToChild = internalNode.data.kvs[childIndex];
                    internalNode.data.kvs[childIndex] := ?borrowedKVPair;
                    
                    let deletedKV = AU.insertAtPostionAndDeleteAtPosition<(K, V)>(leafChild.data.kvs, kvPairToBePushedToChild, leafChild.data.count - 1, leafDeleteIndex);
                    #delete(?deletedKV.1);
                  };

                  case null { 
                    // can't borrow from right child, delete from leaf and merge with right child and parent kv, then push down into new leaf
                    let rightChild = switch(internalNode.children[childIndex + 1]) {
                      case (?#leaf(rc)) { rc};
                      case _ { Debug.trap("UNREACHABLE_ERROR: file a bug report! In internalDeleteHelper, if trying to borrow from right leaf child is null, rightChild index cannot be null or internal") };
                    };
                    let (mergedLeaf, deletedKV) = mergeParentWithLeftRightChildLeafNodesAndDelete(
                      internalNode.data.kvs[childIndex],
                      leafChild,
                      rightChild,
                      leafDeleteIndex,
                      #left
                    );
                    // delete the left most internal node kv, since was merging from a deletion in left most child (0) and the parent kv was pushed into the mergedLeaf
                    ignore AU.deleteAndShiftValuesOver<(K, V)>(internalNode.data.kvs, 0);
                    // update internal node children
                    AU.replaceTwoWithElementAndShift<Node<K, V>>(internalNode.children, #leaf(mergedLeaf), 0);
                    internalNode.data.count -= 1;

                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue = ?deletedKV.1 })
                    } else {
                      #delete(?deletedKV.1)
                    }

                  }
                }
              };
              // if delete child is middle or right most, try to borrow from left child
              case (#mergeLeafData({ data; leafDeleteIndex }), false) { 
                // if delete child is right most, try to borrow from left child
                switch(NU.borrowFromLeftLeafChild(internalNode.children, childIndex)) {
                  case (?borrowedKVPair) {
                    let kvPairToBePushedToChild = internalNode.data.kvs[childIndex - 1];
                    internalNode.data.kvs[childIndex - 1] := ?borrowedKVPair;
                    let kvDelete = AU.insertAtPostionAndDeleteAtPosition<(K, V)>(leafChild.data.kvs, kvPairToBePushedToChild, 0, leafDeleteIndex);
                    #delete(?kvDelete.1);
                  };
                  case null {
                    // if delete child is in the middle, try to borrow from right child
                    if (childIndex < internalNode.data.count) {
                      // try to borrow from right
                      switch(NU.borrowFromRightLeafChild(internalNode.children, childIndex)) {
                        case (?borrowedKVPair) {
                          let kvPairToBePushedToChild = internalNode.data.kvs[childIndex];
                          internalNode.data.kvs[childIndex] := ?borrowedKVPair;
                          // insert the successor at the very last element
                          let kvDelete = AU.insertAtPostionAndDeleteAtPosition<(K, V)>(leafChild.data.kvs, kvPairToBePushedToChild, leafChild.data.count-1, leafDeleteIndex);
                          return #delete(?kvDelete.1);
                        };
                        // if cannot borrow, from left or right, merge (see below)
                        case _ {}
                      }
                    };

                    // can't borrow from left child, delete from leaf and merge with left child and parent kv, then push down into new leaf
                    let leftChild = switch(internalNode.children[childIndex - 1]) {
                      case (?#leaf(lc)) { lc};
                      case _ { Debug.trap("UNREACHABLE_ERROR: file a bug report! In internalDeleteHelper, if trying to borrow from left leaf child is null, then left child index must not be null or internal") };
                    };
                    let (mergedLeaf, deletedKV) = mergeParentWithLeftRightChildLeafNodesAndDelete(
                      internalNode.data.kvs[childIndex-1],
                      leftChild,
                      leafChild,
                      leafDeleteIndex,
                      #right
                    );
                    // delete the right most internal node kv, since was merging from a deletion in the right most child and the parent kv was pushed into the mergedLeaf
                    ignore AU.deleteAndShiftValuesOver<(K, V)>(internalNode.data.kvs, childIndex - 1);
                    // update internal node children
                    AU.replaceTwoWithElementAndShift<Node<K, V>>(internalNode.children, #leaf(mergedLeaf), childIndex - 1);
                    internalNode.data.count -= 1;

                    if (internalNode.data.count < minKeys) {
                      #mergeChild({ internalChild = internalNode; deletedValue = ?deletedKV.1 })
                    } else {
                      #delete(?deletedKV.1)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  };


  // This type is used to signal to the parent calling context what happened in the level below
  type IntermediateLeafDeleteResult<K, V> = {
    // element was deleted or not found, returning the old value (?value or null)
    #delete: ?V;
    // leaf had the minimum number of keys when deleting, so returns the leaf node's data and the index of the key that will be deleted
    #mergeLeafData: {
      data: Data<K, V>;
      leafDeleteIndex: Nat;
    }
  };

  func leafDeleteHelper<K, V>(leafNode: Leaf<K, V>, order: Nat, compare: (K, K) -> O.Order, deleteKey: K): IntermediateLeafDeleteResult<K, V> {
    let minKeys = NU.minKeysFromOrder(order);

    switch(NU.getKeyIndex<K, V>(leafNode.data, compare, deleteKey)) {
      case (#keyFound(deleteIndex)) {
        if (leafNode.data.count > minKeys) {
          leafNode.data.count -= 1;
          #delete(?AU.deleteAndShiftValuesOver<(K, V)>(leafNode.data.kvs, deleteIndex).1)
        } else {
          #mergeLeafData({
            data = leafNode.data;
            leafDeleteIndex = deleteIndex;
          });
        }
      };
      case (#notFound(_)) {
        #delete(null)
      }
    }
  };


  // get helper if internal node
  func getFromInternal<K, V>(internalNode: Internal<K, V>, compare: (K, K) -> O.Order, key: K): ?V { 
    switch(NU.getKeyIndex<K, V>(internalNode.data, compare, key)) {
      case (#keyFound(index)) { getExistingValueFromIndex(internalNode.data, index) };
      case (#notFound(index)) {
        switch(internalNode.children[index]) {
          // expects the child to be there, otherwise there's a bug in binary search or the tree is invalid
          case null { assert false; null };
          case (?#leaf(leafNode)) { getFromLeaf(leafNode, compare, key)};
          case (?#internal(internalNode)) { getFromInternal(internalNode, compare, key)}
        }
      }
    }
  };

  // get function helper if leaf node
  func getFromLeaf<K, V>(leafNode: Leaf<K, V>, compare: (K, K) -> O.Order, key: K): ?V { 
    switch(NU.getKeyIndex<K, V>(leafNode.data, compare, key)) {
      case (#keyFound(index)) { getExistingValueFromIndex(leafNode.data, index) };
      case _ null;
    }
  };

  // get function helper that retrieves an existing value in the case that the key is found
  func getExistingValueFromIndex<K, V>(data: Data<K, V>, index: Nat): ?V {
    switch(data.kvs[index]) {
      case null { null };
      case (?ov) { ?ov.1 }
    }
  };


  // which child the deletionIndex is referring to
  type DeletionSide = { #left; #right; }; 
  
  func mergeParentWithLeftRightChildLeafNodesAndDelete<K, V>(
    parentKV: ?(K, V),
    leftChild: Leaf<K, V>,
    rightChild: Leaf<K, V>,
    deleteIndex: Nat,
    deletionSide: DeletionSide
  ): (Leaf<K, V>, (K, V)) {
    let count = leftChild.data.count * 2;
    let (kvs, deletedKV) = AU.mergeParentWithChildrenAndDelete<(K, V)>(
      parentKV,
      leftChild.data.count,
      leftChild.data.kvs,
      rightChild.data.kvs,
      deleteIndex,
      deletionSide
    );
    (
      {
        data = {
          kvs; 
          var count = count
        }
      },
      deletedKV
    )
  };


  // This type is used to signal to the parent calling context what happened in the level below
  type IntermediateInsertResult<K, V> = {
    // element was inserted or replaced, returning the old value (?value or null)
    #insert: ?V;
    // child was full when inserting, so returns the promoted kv pair and the split left and right child 
    #promote: {
      kv: (K, V);
      leftChild: Node<K, V>;
      rightChild: Node<K, V>;
    };
  };


  // Helper for inserting into a leaf node
  func leafInsertHelper<K, V>(leafNode: Leaf<K, V>, order: Nat, compare: (K, K) -> O.Order, key: K, value: V): (IntermediateInsertResult<K, V>) {
    // Perform binary search to see if the element exists in the node
    switch(NU.getKeyIndex<K, V>(leafNode.data, compare, key)) {
      case (#keyFound(insertIndex)) {
        let previous = leafNode.data.kvs[insertIndex];
        leafNode.data.kvs[insertIndex] := ?(key, value);
        switch(previous) {
          case (?ov) { #insert(?ov.1) };
          case null { assert false; #insert(null) }; // the binary search already found an element, so this case should never happen
        }
      };
      case (#notFound(insertIndex)) {
        // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
        let maxKeys: Nat = order - 1;
        // If the leaf is full, insert, split the node, and promote the middle element
        if (leafNode.data.count >= maxKeys) {
          let (leftKVs, promotedParentElement, rightKVs) = AU.insertOneAtIndexAndSplitArray(
            leafNode.data.kvs,
            (key, value),
            insertIndex
          );

          let leftCount = order / 2;
          let rightCount: Nat = if (order % 2 == 0) { leftCount - 1 } else { leftCount };

          (
            #promote({
              kv = promotedParentElement;
              leftChild = createLeaf<K, V>(leftKVs, leftCount);
              rightChild = createLeaf<K, V>(rightKVs, rightCount);
            })
          )
        } 
        // Otherwise, insert at the specified index (shifting elements over if necessary) 
        else {
          NU.insertAtIndexOfNonFullNodeData<K, V>(leafNode.data, ?(key, value), insertIndex);
          #insert(null);
        };
      }
    }
  };


  // Helper for inserting into an internal node
  func internalInsertHelper<K, V>(internalNode: Internal<K, V>, order: Nat, compare: (K, K) -> O.Order, key: K, value: V): IntermediateInsertResult<K, V> {
    switch(NU.getKeyIndex<K, V>(internalNode.data, compare, key)) {
      case (#keyFound(insertIndex)) {
        let previous = internalNode.data.kvs[insertIndex];
        internalNode.data.kvs[insertIndex] := ?(key, value);
        switch(previous) {
          case (?ov) { #insert(?ov.1) };
          case null { assert false; #insert(null) }; // the binary search already found an element, so this case should never happen
        }
      };
      case (#notFound(insertIndex)) {
        let insertResult = switch(internalNode.children[insertIndex]) {
          case null { assert false; #insert(null) };
          case (?#leaf(leafNode)) { leafInsertHelper(leafNode, order, compare, key, value) };
          case (?#internal(internalChildNode)) { internalInsertHelper(internalChildNode, order, compare, key, value) };
        };

        switch(insertResult) {
          case (#insert(ov)) { #insert(ov) };
          case (#promote({ kv; leftChild; rightChild; })) {
            // Note: BTree will always have an order >= 4, so this will never have negative Nat overflow
            let maxKeys: Nat = order - 1;
            // if current internal node is full, need to split the internal node
            if (internalNode.data.count >= maxKeys) {
              // insert and split internal kvs, determine new promotion target kv
              let (leftKVs, promotedParentElement, rightKVs) = AU.insertOneAtIndexAndSplitArray(
                internalNode.data.kvs,
                (kv),
                insertIndex
              );

              // calculate the element count in the left KVs and the element count in the right KVs
              let leftCount = order / 2;
              let rightCount: Nat = if (order % 2 == 0) { leftCount - 1 } else { leftCount };

              // split internal children
              let (leftChildren, rightChildren) = NU.splitChildrenInTwoWithRebalances<K, V>(
                internalNode.children,
                insertIndex,
                leftChild,
                rightChild
              );

              // send the kv to be promoted, as well as the internal children left and right split 
              #promote({
                kv = promotedParentElement;
                leftChild = #internal({
                  data = { kvs = leftKVs; var count = leftCount; };
                  children = leftChildren;
                });
                rightChild = #internal({
                  data = { kvs = rightKVs; var count = rightCount; };
                  children = rightChildren;
                })
              });
            }
            else {
              // insert the new kvs into the internal node
              NU.insertAtIndexOfNonFullNodeData(internalNode.data, ?kv, insertIndex);
              // split and re-insert the single child that needs rebalancing
              NU.insertRebalancedChild(internalNode.children, insertIndex, leftChild, rightChild);
              #insert(null);
            }
          }
        };
      }
    };
  };


  func createLeaf<K, V>(kvs: [var ?(K, V)], count: Nat): Node<K, V> {
    #leaf({
      data = {
        kvs;
        var count;
      }
    })
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