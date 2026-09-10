const std = @import("std");
const testing = std.testing;

// pub fn showList(list: List, tag: []const u8) void {
//     var head = list.first;
//     std.debug.print("INFO: {s} => ", .{tag});
//     while (head != null) {
//         std.debug.print("{d} ", .{head.?.data});
//         head = head.?.next;
//     }
//     std.debug.print("\n", .{});
// }

/// Doubly-linked list.
/// Not handling all edge cases for list.len == 0 as the exercise does not require it
pub fn LinkedList(comptime T: type) type {
    return struct {
        pub const Node = struct {
            prev: ?*Node = null,
            next: ?*Node = null,
            data: T = 0,
        };

        first: ?*Node = null,
        last: ?*Node = null,
        len: T = 0,

        pub fn push(self: *LinkedList(T), new_node: *Node) void {
            if (self.len == 0) {
                self.first = new_node;
                self.len += 1;
            } else if (self.len == 1) {
                self.first.?.next = new_node;
                self.last = new_node;
                self.last.?.prev = self.first;
                self.len += 1;
            } else {
                const old_last = self.last;
                self.last.?.next = new_node;
                self.last = new_node;
                self.last.?.prev = old_last;
                self.len += 1;
            }
        }

        pub fn pop(self: *LinkedList(T)) ?*Node {
            if (self.len == 1) {
                self.len -= 1;
                const node = self.first;
                self.first = null;
                return node;
            } else if (self.len == 2) {
                const node = self.last;
                self.first.?.next = null;
                self.last = null;
                self.len -= 1;
                return node;
            } else {
                const node = self.last;
                const new_last = self.last.?.prev;
                self.last = new_last;
                self.len -= 1;
                return node;
            }
        }

        pub fn shift(self: *LinkedList(T)) ?*Node {
            if (self.len == 1) {
                self.len -= 1;
                const node = self.first;
                self.first = null;
                return node;
            } else if (self.len == 2) {
                const node = self.first;
                const last = self.last;
                self.first = last;
                self.last = null;
                self.first.?.next = null;
                self.len -= 1;
                return node;
            } else {
                const node = self.first;
                self.first = self.first.?.next;
                self.len -= 1;
                return node;
            }
        }

        pub fn unshift(self: *LinkedList(T), new_node: *Node) void {
            if (self.len == 0) {
                self.first = new_node;
                self.len += 1;
            } else if (self.len == 1) {
                const first = self.first;
                self.first = new_node;
                self.first.?.next = first;
                self.last = first;
                self.last.?.prev = self.first;
                self.len += 1;
            } else {
                const first = self.first;
                self.first = new_node;
                self.first.?.next = first;
                self.first.?.next.?.prev = self.first;
                self.len += 1;
            }
        }

        pub fn delete(self: *LinkedList(T), node_to_delete: *Node) void {
            if (self.len == 1 and self.first.?.data == node_to_delete.data) {
                self.first = null;
                self.len -= 1;
            } else if (self.len == 2) {
                if (self.first.?.data == node_to_delete.data) {
                    const last = self.last;
                    self.first = last;
                    self.first.?.next = null;
                    self.last = null;
                    self.len -= 1;
                } else if (self.last.?.data == node_to_delete.data) {
                    self.last = null;
                    self.first.?.next = null;
                    self.len -= 1;
                } else {
                    // nothing to delete
                    return;
                }
            } else {
                const value_to_delete = node_to_delete.data;
                if (self.first.?.data == value_to_delete) {
                    const new_first = self.first.?.next;
                    self.first = new_first;
                    self.first.?.prev = null;
                    self.len -= 1;
                }

                var head: ?*Node = self.first.?.next;
                while (head != null) {
                    const value = head.?.data;
                    if (value == value_to_delete) {
                        head.?.prev.?.next = head.?.next;
                        head = null;
                        self.len -= 1;
                    } else {
                        head = head.?.next;
                    }
                }
            }
        }
    };
}

const List = LinkedList(usize);

test "pop gets element from the list" {
    var list = List{};
    var a = List.Node{ .data = 7 };
    list.push(&a);
    try testing.expectEqual(@as(usize, 7), list.pop().?.data);
}

test "push/pop respectively add/remove at the end of the list" {
    var list = List{};
    var a = List.Node{ .data = 11 };
    var b = List.Node{ .data = 13 };
    list.push(&a);
    list.push(&b);
    try testing.expectEqual(@as(usize, 13), list.pop().?.data);
    try testing.expectEqual(@as(usize, 11), list.pop().?.data);
}

test "shift gets an element from the list" {
    var list = List{};
    var a = List.Node{ .data = 17 };
    list.push(&a);
    try testing.expectEqual(@as(usize, 17), list.shift().?.data);
}

test "shift gets first element from the list" {
    var list = List{};
    var a = List.Node{ .data = 23 };
    var b = List.Node{ .data = 5 };
    list.push(&a);
    list.push(&b);
    try testing.expectEqual(@as(usize, 23), list.shift().?.data);
    try testing.expectEqual(@as(usize, 5), list.shift().?.data);
}

test "unshift adds element at start of the list" {
    var list = List{};
    var a = List.Node{ .data = 23 };
    var b = List.Node{ .data = 5 };
    list.unshift(&a);
    list.unshift(&b);
    try testing.expectEqual(@as(usize, 5), list.shift().?.data);
    try testing.expectEqual(@as(usize, 23), list.shift().?.data);
}

test "pop, push, shift, and unshift can be used in any order" {
    var list = List{};
    var a = List.Node{ .data = 1 };
    var b = List.Node{ .data = 2 };
    var c = List.Node{ .data = 3 };
    var d = List.Node{ .data = 4 };
    var e = List.Node{ .data = 5 };
    list.push(&a);
    list.push(&b);
    try testing.expectEqual(@as(usize, 2), list.pop().?.data);
    list.push(&c);
    try testing.expectEqual(@as(usize, 1), list.shift().?.data);
    list.unshift(&d);
    list.push(&e);
    try testing.expectEqual(@as(usize, 4), list.shift().?.data);
    try testing.expectEqual(@as(usize, 5), list.pop().?.data);
    try testing.expectEqual(@as(usize, 3), list.shift().?.data);
}

test "count an empty list" {
    const list = List{};
    try testing.expectEqual(@as(usize, 0), list.len);
}

test "count a list with items" {
    var list = List{};
    var a = List.Node{ .data = 37 };
    var b = List.Node{ .data = 1 };
    list.push(&a);
    list.push(&b);
    try testing.expectEqual(@as(usize, 2), list.len);
}

test "count is correct after mutation" {
    var list = List{};
    var a = List.Node{ .data = 31 };
    var b = List.Node{ .data = 43 };
    list.push(&a);
    try testing.expectEqual(@as(usize, 1), list.len);
    list.unshift(&b);
    try testing.expectEqual(@as(usize, 2), list.len);
    _ = list.shift();
    try testing.expectEqual(@as(usize, 1), list.len);
    _ = list.pop();
    try testing.expectEqual(@as(usize, 0), list.len);
}

test "popping to empty doesn't break the list" {
    var list = List{};
    var a = List.Node{ .data = 41 };
    var b = List.Node{ .data = 59 };
    var c = List.Node{ .data = 47 };
    list.push(&a);
    list.push(&b);
    _ = list.pop();
    _ = list.pop();
    list.push(&c);
    try testing.expectEqual(@as(usize, 1), list.len);
    try testing.expectEqual(@as(usize, 47), list.pop().?.data);
}

test "shifting to empty doesn't break the list" {
    var list = List{};
    var a = List.Node{ .data = 41 };
    var b = List.Node{ .data = 59 };
    var c = List.Node{ .data = 47 };
    list.push(&a);
    list.push(&b);
    _ = list.shift();
    _ = list.shift();
    list.push(&c);
    try testing.expectEqual(@as(usize, 1), list.len);
    try testing.expectEqual(@as(usize, 47), list.shift().?.data);
}

test "deletes the only element" {
    var list = List{};
    var a = List.Node{ .data = 61 };
    list.push(&a);
    list.delete(&a);
    try testing.expectEqual(@as(usize, 0), list.len);
}

test "deletes the element with the specified value from the list" {
    var list = List{};
    var a = List.Node{ .data = 71 };
    var b = List.Node{ .data = 83 };
    var c = List.Node{ .data = 79 };
    list.push(&a);
    list.push(&b);
    list.push(&c);
    list.delete(&b);
    try testing.expectEqual(@as(usize, 2), list.len);
    try testing.expectEqual(@as(usize, 79), list.pop().?.data);
    try testing.expectEqual(@as(usize, 71), list.shift().?.data);
}

test "deletes the element with the specified value from the list, re-assigns tail" {
    var list = List{};
    var a = List.Node{ .data = 71 };
    var b = List.Node{ .data = 83 };
    var c = List.Node{ .data = 79 };
    list.push(&a);
    list.push(&b);
    list.push(&c);
    list.delete(&b);
    try testing.expectEqual(@as(usize, 2), list.len);
    try testing.expectEqual(@as(usize, 79), list.pop().?.data);
    try testing.expectEqual(@as(usize, 71), list.pop().?.data);
}

test "deletes the element with the specified value from the list, re-assigns head" {
    var list = List{};
    var a = List.Node{ .data = 71 };
    var b = List.Node{ .data = 83 };
    var c = List.Node{ .data = 79 };
    list.push(&a);
    list.push(&b);
    list.push(&c);
    list.delete(&b);
    try testing.expectEqual(@as(usize, 2), list.len);
    try testing.expectEqual(@as(usize, 71), list.shift().?.data);
    try testing.expectEqual(@as(usize, 79), list.shift().?.data);
}

test "deletes the first of two elements" {
    var list = List{};
    var a = List.Node{ .data = 97 };
    var b = List.Node{ .data = 101 };
    list.push(&a);
    list.push(&b);
    list.delete(&a);
    try testing.expectEqual(@as(usize, 1), list.len);
    try testing.expectEqual(@as(usize, 101), list.pop().?.data);
}

test "deletes the second of two elements" {
    var list = List{};
    var a = List.Node{ .data = 97 };
    var b = List.Node{ .data = 101 };
    list.push(&a);
    list.push(&b);
    list.delete(&b);
    try testing.expectEqual(@as(usize, 1), list.len);
    try testing.expectEqual(@as(usize, 97), list.pop().?.data);
}

test "delete does not modify the list if the element is not found" {
    var list = List{};
    var a = List.Node{ .data = 89 };
    var b = List.Node{ .data = 103 };
    list.push(&a);
    list.delete(&b);
    try testing.expectEqual(@as(usize, 1), list.len);
}

test "deletes only the first occurrence" {
    var list = List{};
    var a = List.Node{ .data = 73 };
    var b = List.Node{ .data = 9 };
    var c = List.Node{ .data = 9 };
    var d = List.Node{ .data = 107 };
    list.push(&a);
    list.push(&b);
    list.push(&c);
    list.push(&d);
    list.delete(&b);
    try testing.expectEqual(@as(usize, 3), list.len);
    try testing.expectEqual(@as(usize, 107), list.pop().?.data);
    try testing.expectEqual(@as(usize, 9), list.pop().?.data);
    try testing.expectEqual(@as(usize, 73), list.pop().?.data);
}
