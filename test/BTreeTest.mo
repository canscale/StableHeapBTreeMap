import M "mo:matchers/Matchers";
import S "mo:matchers/Suite";
import T "mo:matchers/Testable";

import Array "mo:base/Array";
import Nat "mo:base/Nat";

import BT "../src/BTree";
import BTM "./BTreeMatchers";


func testableNatBTree(t: BT.BTree<Nat, Nat>): T.TestableItem<BT.BTree<Nat, Nat>> {
  BTM.testableBTree(t, Nat.equal, Nat.equal, Nat.toText, Nat.toText)
};  

// Concise helper for setting up a BTree of type BTree<Nat, Nat> with multiple elements
func quickCreateBTreeWithKVPairs(order: Nat, keyValueDup: [Nat]): BT.BTree<Nat, Nat> {
  let kvPairs = Array.map<Nat, (Nat, Nat)>(keyValueDup, func(k) { (k, k) });

  BT.createBTreeWithKVPairs<Nat, Nat>(order, Nat.compare, kvPairs);
};


let initSuite = S.suite("init", [
  S.test("initializes an empty BTree with order 4 to have the correct number of keys (order - 1)",
    BT.init<Nat, Nat>(?4),
    M.equals(testableNatBTree({
      var root = #leaf({
        data = {
          kvs = [var null, null, null];
          var count = 0;
        }
      });
      order = 4;
    }))
  ),
  S.test("if null order is provided, initializes an empty BTree with order 8 to have the correct number of keys (order - 1)",
    BT.init<Nat, Nat>(null),
    M.equals(testableNatBTree({
      var root = #leaf({
        data = {
          kvs = [var null, null, null, null, null, null, null];
          var count = 0;
        }
      });
      order = 8;
    }))
  )
]);

let getSuite = S.suite("get", [
  S.test("returns null on an empty BTree",
    BT.get<Nat, Nat>(BT.init<Nat, Nat>(?4), Nat.compare, 5),
    M.equals(T.optional<Nat>(T.natTestable, null))
  ),
  S.test("returns null on a BTree leaf node that does not contain the key",
    BT.get<Nat, Nat>(quickCreateBTreeWithKVPairs(4, [3, 7]), Nat.compare, 5),
    M.equals(T.optional<Nat>(T.natTestable, null))
  ),
  S.test("returns null on a multi-level BTree that does not contain the key",
    BT.get<Nat, Nat>(
      quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160]),
      Nat.compare,
      21
    ),
    M.equals(T.optional<Nat>(T.natTestable, null))
  ),
  S.test("returns null on a multi-level BTree that does not contain the key, if the key is greater than all elements in the tree",
    BT.get<Nat, Nat>(
      quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160]),
      Nat.compare,
      200
    ),
    M.equals(T.optional<Nat>(T.natTestable, null))
  ),
  S.test("returns the value if a BTree leaf node contains the key",
    BT.get<Nat, Nat>(quickCreateBTreeWithKVPairs(4, [3, 7, 10]), Nat.compare, 10),
    M.equals(T.optional<Nat>(T.natTestable, ?10))
  ),
  S.test("returns the value if a BTree internal node contains the key",
    BT.get<Nat, Nat>(
      quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160]),
      Nat.compare,
      120
    ),
    M.equals(T.optional<Nat>(T.natTestable, ?120))
  ),
]);


let insertSuite = S.suite("insert", [
  S.suite("root as leaf tests", [
    S.test("inserts into an empty BTree",
      do {
        let t = BT.init<Nat, Nat>(?4);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 4, 4);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(4, 4), null, null];
            var count = 1;
          }
        });
        order = 4;
      }))
    ),
    S.test("inserting an element into a BTree that does not exist returns null",
      do {
        let t = BT.init<Nat, Nat>(?4);
        BT.insert<Nat, Nat>(t, Nat.compare, 4, 4);
      },
      M.equals(T.optional<Nat>(T.natTestable, null))
    ),
    S.test("replaces already existing element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 2, 22);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 22), ?(4, 4), ?(6, 6), null, null];
            var count = 3;
          }
        });
        order = 6;
      }))
    ),
    S.test("returns the previous value of when replacing an already existing element in the BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        BT.insert<Nat, Nat>(t, Nat.compare, 2, 22);
      },
      M.equals(T.optional<Nat>(T.natTestable, ?2))
    ),
    S.test("inserts new smallest element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 1, 1);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(1, 1), ?(2, 2), ?(4, 4), ?(6, 6), null];
            var count = 4;
          }
        });
        order = 6;
      }))
    ),
    S.test("inserts middle element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 5, 5);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), ?(5,5), ?(6, 6), null];
            var count = 4;
          }
        });
        order = 6;
      }))
    ),
    S.test("inserts last element correctly into a BTree",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 8);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), ?(6, 6), ?(8, 8), null];
            var count = 4;
          }
        });
        order = 6;
      }))
    ),
    S.test("orders multiple inserts into a BTree correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [8, 2, 10, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 8);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), ?(6, 6), ?(8, 8), ?(10, 10)];
            var count = 5;
          }
        });
        order = 6;
      }))
    ),
    S.test("inserting greatest element into full leaf splits an even ordererd BTree correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 8);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
            }),
            null,
            null
          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting greatest element into full leaf splits an odd ordererd BTree correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(5, [2, 4, 6, 7]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 8);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null, null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 7), ?(8, 8), null, null];
                var count = 2;
              };
            }),
            null,
            null,
            null
          ]
        });
        order = 5;
      }))
    ),
  ]),
  S.suite("root as internal tests", [
    S.test("inserting an element that already exists replaces it",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 8, 88);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 88), null, null];
                var count = 1;
              };
            }),
            null,
            null,
          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into the right child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 7, 7);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(4, 4), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 7), ?(8, 8), null];
                var count = 2;
              };
            }),
            null,
            null,
          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into the left child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 3, 3);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), null, null];
            var count = 1;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(2, 2), ?(3, 3), ?(4, 4)];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
            }),
            null,
            null,
          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into a full left most child promotes to the root correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 1, 1);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(6, 6), null];
            var count = 2;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
            }),
            null,
          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into a full right most child promotes it to the root correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3, 1, 10, 15]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 12, 12);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(6, 6), ?(12, 12)];
            var count = 3;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), ?(10, 10), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(15, 15), null, null];
                var count = 1;
              };
            }),
          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting an element that does not yet exist into a full right most child promotes it to the root correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3, 1, 10, 15, 12]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 7, 7);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(6, 6), ?(12, 12)];
            var count = 3;
          };
          children = [var 
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 7), ?(8, 8), ?(10, 10)];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(15, 15), null, null];
                var count = 1;
              };
            }),
          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting an element that does not exist into a tree with a full root that where the inserted element is promoted to become the new root, also hitting case 2 of splitChildrenInTwoWithRebalances",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 4, 6, 8, 3, 1, 10, 15, 12, 7]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 9, 9);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(9, 9), null, null];
            var count = 1;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(3, 3), ?(6, 6), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(1, 1), ?(2, 2), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(4, 4), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(7, 7), ?(8, 8), null];
                    var count = 2;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(12, 12), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(15, 15), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ]
            }),
            null,
            null

          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting an element that does not exist into a tree with a full root that where the inserted element is promoted to be in the left internal child of the new root",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 10, 20, 8, 5, 7, 15, 25, 40, 3]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 4, 4);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(10, 10), null, null];
            var count = 1;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(4, 4), ?(7, 7), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(2, 2), ?(3, 3), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(5, 5), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(8, 8), null, null];
                    var count = 1;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(25, 25), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(15, 15), ?(20, 20), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(40, 40), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ]
            }),
            null,
            null

          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting an element that does not exist into that promotes and element from a full internal into a root internal with space, hitting case 2 of splitChildrenInTwoWithRebalances",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 10, 20, 8, 5, 7, 15, 25, 40, 3, 4, 50, 60, 70, 80, 90, 100, 110, 120]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 130, 130);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(10, 10), ?(90, 90), null];
            var count = 2;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(4, 4), ?(7, 7), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(2, 2), ?(3, 3), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(5, 5), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(8, 8), null, null];
                    var count = 1;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(25, 25), ?(60, 60), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(15, 15), ?(20, 20), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(40, 40), ?(50, 50), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(70, 70), ?(80, 80), null];
                    var count = 2;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(120, 120), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(100, 100), ?(110, 110), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(130, 130), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ];
            }),
            null

          ]
        });
        order = 4;
      }))
    ),
    S.test("inserting an element that does not exist into a tree with a full root, promoting an element to the root and hitting case 1 of splitChildrenInTwoWithRebalances",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [25, 100, 50, 75, 125, 150, 175, 200, 225, 250, 5]);
        let _ = BT.insert<Nat, Nat>(t, Nat.compare, 10, 10);
        t;
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(150, 150), null, null];
            var count = 1;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(25, 25), ?(75, 75), null];
                var count = 2;
              };
              children = [var 
                ?#leaf({
                  data = {
                    kvs = [var ?(5, 5), ?(10, 10), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(50, 50), null, null];
                    var count = 1;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(100, 100), ?(125, 125), null];
                    var count = 2;
                  };
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(225, 225), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(175, 175), ?(200, 200), null];
                    var count = 2;
                  };
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(250, 250), null, null];
                    var count = 1;
                  };
                }),
                null,
                null
              ]
            }),
            null,
            null

          ]
        });
        order = 4;
      }))
    ),
  ])
]);

let deleteSuite = S.suite("delete", [
  S.suite("deletion from a BTree with root as leaf (tree height = 1)", [
    S.test("if tree is empty returns null",
      BT.delete<Nat, Nat>(BT.init<Nat, Nat>(?4), Nat.compare, 5),
      M.equals(T.optional<Nat>(T.natTestable, null))
    ),
    S.test("if the key exists in the BTree returns that key",
      BT.delete<Nat, Nat>(quickCreateBTreeWithKVPairs(4, [2, 7]), Nat.compare, 2),
      M.equals(T.optional<Nat>(T.natTestable, ?2))
    ),
    S.test("if the key exists in the BTree removes the kv from the leaf correctly",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [2, 7, 10]);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 2);
        t;
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(7, 7), ?(10, 10), null];
            var count = 2;
          }
        });
        order = 4;
      }))
    ),
  ]),
  S.suite("deletion from leaf node", [
    S.test("if the key does not exist returns null",
      BT.delete<Nat, Nat>(quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40]), Nat.compare, 5),
      M.equals(T.optional<Nat>(T.natTestable, null))
    ),
    S.suite("if the key exists", [
      S.test("if the leaf has more than the minimum # of keys, deletes the key correctly",
        do {
          let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40]);
          ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
          t
        },
        M.equals(testableNatBTree({
          var root = #internal({
            data = {
              kvs = [var ?(30, 30), null, null];
              var count = 1;
            };
            children = [var
              ?#leaf({
                data = { 
                  kvs = [var ?(20, 20), null, null];
                  var count = 1;
                }
              }),
              ?#leaf({
                data = { 
                  kvs = [var ?(40, 40), null, null];
                  var count = 1;
                }
              }),
              null,
              null
            ]
          });
          order = 4;
        }))
      ),
      S.suite("if the leaf has the minimum # of keys", [
        /*
        */
        S.test("if the leaf is rightmost and can borrow from its left sibling, deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(20, 20), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(30, 30), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is leftmost and can borrow from its left sibling, deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(40, 40), ?(60, 60), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(30, 30), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(50, 50), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(70, 70), null, null];
                    var count = 1;
                  }
                }),
                null
              ]
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can borrow from its left sibling, deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(20, 20), ?(60, 60), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(30, 30), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(70, 70), null, null];
                    var count = 1;
                  }
                }),
                null
              ]
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can't borrow from its left sibling but can borrow from its right sibling, deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(30, 30), ?(70, 70), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(60, 60), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(80, 80), null, null];
                    var count = 1;
                  }
                }),
                null
              ]
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is on the left and can't borrow from its left sibling or its right sibling, but can merge with the parent and internal has > minKeys deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(70, 70), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(30, 30), ?(60, 60), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(80, 80), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is the left most and can't borrow from its right sibling, but can merge with the parent and internal has > minKeys returns the deleted value",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            BT.delete<Nat, Nat>(t, Nat.compare, 10);
          },
          M.equals(T.optional<Nat>(T.natTestable, ?10))
        ),
        S.test("if the leaf is left most and can't borrow from its left sibling, but can merge with the parent and internal has <= minKeys merges the leaf with its right sibling and parent key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 72, 75]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(90, 90), null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(60, 60), ?(75, 75), null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(30, 30), ?(50, 50), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(70, 70), ?(72, 72), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(80, 80), null, null];
                        var count = 1;
                      };
                    }),
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(120, 120), null, null];
                    var count = 1;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(100, 100), ?(110, 110), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(130, 130), null, null];
                        var count = 1;
                      };
                    }),
                    null,
                    null
                  ]
                }),
                null,
                null
              ]
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is right most and can't borrow from its left sibling, but can merge with the parent and internal has > minKeys deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 80);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(30, 30), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), null, null];
                    var count = 1;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(60, 60), ?(70, 70), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is right most and can't borrow from its left sibling, but can merge with the parent and internal has <= minKeys merges the leaf with its left sibling and parent key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 72, 75]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 72);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 80);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(90, 90), null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(30, 30), ?(60, 60), null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(10, 10), ?(20, 20), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(40, 40), ?(50, 50), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(70, 70), ?(75, 75), null];
                        var count = 2;
                      };
                    }),
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(120, 120), null, null];
                    var count = 1;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(100, 100), ?(110, 110), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(130, 130), null, null];
                        var count = 1;
                      };
                    }),
                    null,
                    null
                  ]
                }),
                null,
                null
              ]
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can't borrow from its left sibling or its right sibling, but can merge with the parent and internal has > minKeys deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 60);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(70, 70), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = { 
                    kvs = [var ?(10, 10), ?(30, 30), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = { 
                    kvs = [var ?(80, 80), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can't borrow from its left sibling or its right sibling, and root is the parent internal and parent has <= minKeys flattens the tree and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 20);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 40);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 60);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 30);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 80);
            t
          },
          M.equals(testableNatBTree({
            var root = #leaf({
              data = {
                kvs = [var ?(10, 10), ?(70, 70), null];
                var count = 2;
              };
            });
            order = 4;
          }))
        ),
        S.test("if the leaf is in the middle and can't borrow from its left sibling or its right sibling, and the parent internal has <= minKeys merges the leaf with its left sibling and the parent key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(4, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 72, 75]);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 72);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 50);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 70);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(90, 90), null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(30, 30), ?(75, 75), null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(10, 10), ?(20, 20), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(40, 40), ?(60, 60), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(80, 80), null, null];
                        var count = 1;
                      };
                    }),
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(120, 120), null, null];
                    var count = 1;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(100, 100), ?(110, 110), null];
                        var count = 2;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(130, 130), null, null];
                        var count = 1;
                      };
                    }),
                    null,
                    null
                  ]
                }),
                null,
                null
              ]
            });
            order = 4;
          }))
        ),
        /*
        */
        S.test("BTree with order=6 test of if the leaf is in the middle and can't borrow from its left sibling or its right sibling, and the parent internal has > minKeys merges the leaf with its left sibling and the parent key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(6, Array.tabulate<Nat>(26, func(i) { i+1 }));
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 14);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 11);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(16, 16), null, null, null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(4, 4), ?(12, 12), null, null, null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(1, 1), ?(2, 2), ?(3, 3), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(5, 5), ?(6, 6), ?(7, 7), ?(8, 8), null];
                        var count = 4;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(13, 13), ?(15, 15), null, null, null];
                        var count = 2;
                      };
                    }),
                    null,
                    null,
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(20, 20), ?(24, 24), null, null, null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(17, 17), ?(18, 18), ?(19, 19), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(21, 21), ?(22, 22), ?(23, 23), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(25, 25), ?(26, 26), null, null, null];
                        var count = 2;
                      };
                    }),
                    null,
                    null,
                    null
                  ]
                }),
                null,
                null,
                null,
                null
              ]
            });
            order = 6;
          }))
        ),
        S.test("BTree with order=6 test of if the leaf is in the middle and can't borrow from its left sibling or its right sibling, and the parent internal has <= minKeys so pulls from its left sibling through the parent (root) key and deletes the key correctly",
          do {
            let t = quickCreateBTreeWithKVPairs(6, Array.tabulate<Nat>(26, func(i) { i+1 }));
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 23);
            ignore BT.delete<Nat, Nat>(t, Nat.compare, 26);
            t
          },
          M.equals(testableNatBTree({
            var root = #internal({
              data = {
                kvs = [var ?(12, 12), null, null, null, null];
                var count = 1;
              };
              children = [var
                ?#internal({
                  data = {
                    kvs = [var ?(4, 4), ?(8, 8), null, null, null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(1, 1), ?(2, 2), ?(3, 3), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(5, 5), ?(6, 6), ?(7, 7), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(9, 9), ?(10, 10), ?(11, 11), null, null];
                        var count = 3;
                      };
                    }),
                    null,
                    null,
                    null
                  ]
                }),
                ?#internal({
                  data = {
                    kvs = [var ?(16, 16), ?(20, 20), null, null, null];
                    var count = 2;
                  };
                  children = [var
                    ?#leaf({
                      data = {
                        kvs = [var ?(13, 13), ?(14, 14), ?(15, 15), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(17, 17), ?(18, 18), ?(19, 19), null, null];
                        var count = 3;
                      };
                    }),
                    ?#leaf({
                      data = {
                        kvs = [var ?(21, 21), ?(22, 22), ?(24, 24), ?(25, 25), null];
                        var count = 4;
                      };
                    }),
                    null,
                    null,
                    null
                  ]
                }),
                null,
                null,
                null,
                null
              ]
            });
            order = 6;
          }))
        ),
        /*
        */
      ]),
    ])
  ]),
  S.suite("deletion from internal node", [
    S.test("Simple case deleting root borrows predecessor from left child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, [1,2,3,4]);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 3);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(2, 2), null, null];
            var count = 1;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              }
            }),
            null,
            null
          ]
        });
        order = 4;
      }))
    ),
    S.test("Simple case deleting root borrows inorder predecessor but then needs to rebalance via left child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(8, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 5);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(2, 2), ?(4, 4), null];
            var count = 2;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(3, 3), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(7, 7), ?(8, 8), null];
                var count = 2;
              }
            }),
            null
          ]
        });
        order = 4;
      }))
    ),
    S.test("Simple case deleting root borrows inorder predecessor but then needs to rebalance via right child",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(8, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 5);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 2);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(3, 3), ?(7, 7), null];
            var count = 2;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(4, 4), null, null];
                var count = 1;
              }
            }),
            ?#leaf({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              }
            }),
            null
          ]
        });
        order = 4;
      }))
    ),
    S.test("Order 6, simple case deleting root with minimum number of keys condenses the BTree into a leaf",
      do {
        let t = quickCreateBTreeWithKVPairs(6, [1,2,3,4,5,6]);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 4);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 3);
        t
      },
      M.equals(testableNatBTree({
        var root = #leaf({
          data = {
            kvs = [var ?(1, 1), ?(2, 2), ?(5, 5), ?(6, 6), null];
            var count = 4;
          };
        });
        order = 6;
      }))
    ),
    S.test("BTree with height 3 root borrows inorder predecessor and no need to rebalance",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(8, 8), ?(18, 18), null];
            var count = 2;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(3, 3), ?(6, 6), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(1, 1), ?(2, 2), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(4, 4), ?(5, 5), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(7, 7), null, null];
                    var count = 1;
                  }
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(12, 12), ?(15, 15), null];
                var count = 2;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(10, 10), ?(11, 11), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(13, 13), ?(14, 14), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(16, 16), ?(17, 17), null];
                    var count = 2;
                  }
                }),
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(21, 21), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(19, 19), ?(20, 20), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(22, 22), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            }),
            null
          ]
        });
        order = 4;
      }))
    ),
    S.test("BTree with height 3 root replaces with inorder predecessor and borrows from left child to rotate left",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 11);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 12);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 13);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 14);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 16);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 18);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(6, 6), ?(17, 17), null];
            var count = 2;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(3, 3), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(1, 1), ?(2, 2), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(4, 4), ?(5, 5), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(9, 9), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(7, 7), ?(8, 8), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(10, 10), ?(15, 15), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(21, 21), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(19, 19), ?(20, 20), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(22, 22), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            }),
            null
          ]
        });
        order = 4;
      }))
    ),
    S.test("BTree with height 3 root replaces with inorder predecessor and cannot borrow from left so borrows from right child to rotate right",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(22, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 1);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 4);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 5);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 7);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(12, 12), ?(18, 18), null];
            var count = 2;
          };
          children = [var
            ?#internal({
              data = {
                kvs = [var ?(8, 8), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(2, 2), ?(3, 3), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(10, 10), ?(11, 11), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(15, 15), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(13, 13), ?(14, 14), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(16, 16), ?(17, 17), null];
                    var count = 2;
                  }
                }),
                null,
                null
              ]
            }),
            ?#internal({
              data = {
                kvs = [var ?(21, 21), null, null];
                var count = 1;
              };
              children = [var
                ?#leaf({
                  data = {
                    kvs = [var ?(19, 19), ?(20, 20), null];
                    var count = 2;
                  }
                }),
                ?#leaf({
                  data = {
                    kvs = [var ?(22, 22), null, null];
                    var count = 1;
                  }
                }),
                null,
                null
              ]
            }),
            null
          ]
        });
        order = 4;
      }))
    ),
    S.test("BTree with height 3 root replaces with inorder predecessor and cannot borrow from left or right so shrinks the tree size",
      do {
        let t = quickCreateBTreeWithKVPairs(4, Array.tabulate<Nat>(13, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 2);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 4);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 5);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 7);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 11);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(8, 8), ?(12, 12), null];
            var count = 2;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(3, 3), null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(10, 10), null, null];
                var count = 1;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(13, 13), null, null];
                var count = 1;
              };
            }),
            null
          ]
        });
        order = 4;
      }))
    ),
    S.test("BTree with order=6 and height 3 root replaces with inorder predecessor and cannot borrow from left or right so shrinks the tree size",
      do {
        let t = quickCreateBTreeWithKVPairs(6, Array.tabulate<Nat>(26, func(i) { i+1 }));
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 3);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 6);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 7);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 8);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 9);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 10);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 13);
        ignore BT.delete<Nat, Nat>(t, Nat.compare, 16);
        t
      },
      M.equals(testableNatBTree({
        var root = #internal({
          data = {
            kvs = [var ?(4, 4), ?(15, 15), ?(20, 20), ?(24, 24), null];
            var count = 4;
          };
          children = [var
            ?#leaf({
              data = {
                kvs = [var ?(1, 1), ?(2, 2), null, null, null];
                var count = 2;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(5, 5), ?(11, 11), ?(12, 12), ?(14, 14), null];
                var count = 4;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(17, 17), ?(18, 18), ?(19, 19), null, null];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(21, 21), ?(22, 22), ?(23, 23), null, null];
                var count = 3;
              };
            }),
            ?#leaf({
              data = {
                kvs = [var ?(25, 25), ?(26, 26), null, null, null];
                var count = 2;
              };
            }),
            null,
          ]
        });
        order = 6;
      }))
    ),
  ]),
]);


S.run(S.suite("BTree",
  [
    initSuite,
    getSuite,
    insertSuite,
    deleteSuite
  ]
));