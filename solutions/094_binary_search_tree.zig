const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const Node = struct {
    data: i32,
    left: ?*Node,
    right: ?*Node,

    pub fn recDeinit(self: *Node, allocator: mem.Allocator) void {
        if (self.left) |l| l.recDeinit(allocator);
        if (self.right) |r| r.recDeinit(allocator);
        allocator.destroy(self);
    }
};

pub const Tree = struct {
    root: ?*Node,
    allocator: mem.Allocator,

    pub fn init(allocator: mem.Allocator) Tree {
        return .{ .root = null, .allocator = allocator };
    }

    pub fn deinit(self: *Tree) void {
        if (self.root) |root| root.recDeinit(self.allocator);

        self.root = null;
    }

    pub fn insert(self: *Tree, data: i32) mem.Allocator.Error!void {
        const new_node = try self.allocator.create(Node);
        new_node.* = .{ .data = data, .left = null, .right = null };

        if (self.root == null) {
            self.root = new_node;
        } else {
            var cur_node = self.root.?;
            loop: while (true) {
                const cur_data = cur_node.data;
                // std.debug.print("  > cur_data={d}\n", .{cur_data});
                if (cur_data >= data) { // left
                    if (cur_node.left) |l| {
                        cur_node = l;
                        continue :loop;
                    } else {
                        cur_node.left = new_node;
                        break :loop;
                    }
                } else { // right
                    if (cur_node.right) |r| {
                        cur_node = r;
                        continue :loop;
                    } else {
                        cur_node.right = new_node;
                        break :loop;
                    }
                }
            }
        }
    }

    pub fn sortedData(self: *const Tree, allocator: mem.Allocator) mem.Allocator.Error![]i32 {
        var list: std.ArrayList(i32) = .empty;
        errdefer list.deinit(allocator);
        if (self.root) |root| try recSortedData(root, allocator, &list);
        return list.toOwnedSlice(allocator);
    }
};

fn recSortedData(node: *Node, allocator: mem.Allocator, list: *std.ArrayList(i32)) mem.Allocator.Error!void {
    if (node.left) |l| try recSortedData(l, allocator, list);
    try list.append(allocator, node.data);
    if (node.right) |r| try recSortedData(r, allocator, list);
}

fn sortedDataTest(allocator: std.mem.Allocator, tree_data: []const i32, expected: []const i32) anyerror!void {
    var tree = Tree.init(allocator);
    defer tree.deinit();
    for (tree_data) |data| {
        try tree.insert(data);
    }
    const actual = try tree.sortedData(allocator);
    defer allocator.free(actual);
    try testing.expectEqualSlices(i32, expected, actual);
}

test "data is retained" {
    var tree = Tree.init(testing.allocator);
    defer tree.deinit();
    try tree.insert(4);
    if (tree.root) |o| {
        try testing.expectEqual(4, o.data);
        try testing.expectEqual(null, o.left);
        try testing.expectEqual(null, o.right);
    } else {
        try testing.expectEqual(false, true); // tree.root should not be null
    }
}

test "insert data at proper node-smaller number at left node" {
    var tree = Tree.init(testing.allocator);
    defer tree.deinit();
    try tree.insert(4);
    try tree.insert(2);
    if (tree.root) |o| {
        try testing.expectEqual(4, o.data);
        if (o.left) |l| {
            try testing.expectEqual(2, l.data);
            try testing.expectEqual(null, l.left);
            try testing.expectEqual(null, l.right);
        } else {
            try testing.expectEqual(false, true); // o.left should not be null
        }
        try testing.expectEqual(null, o.right);
    } else {
        try testing.expectEqual(false, true); // tree.root should not be null
    }
}

test "insert data at proper node-same number at left node" {
    var tree = Tree.init(testing.allocator);
    defer tree.deinit();
    try tree.insert(4);
    try tree.insert(4);
    if (tree.root) |o| {
        try testing.expectEqual(4, o.data);
        if (o.left) |l| {
            try testing.expectEqual(4, l.data);
            try testing.expectEqual(null, l.left);
            try testing.expectEqual(null, l.right);
        } else {
            try testing.expectEqual(false, true); // o.left should not be null
        }
        try testing.expectEqual(null, o.right);
    } else {
        try testing.expectEqual(false, true); // tree.root should not be null
    }
}

test "insert data at proper node-greater number at right node" {
    var tree = Tree.init(testing.allocator);
    defer tree.deinit();
    try tree.insert(4);
    try tree.insert(5);
    if (tree.root) |o| {
        try testing.expectEqual(4, o.data);
        try testing.expectEqual(null, o.left);
        if (o.right) |r| {
            try testing.expectEqual(5, r.data);
            try testing.expectEqual(null, r.left);
            try testing.expectEqual(null, r.right);
        } else {
            try testing.expectEqual(false, true); // o.right should not be null
        }
    } else {
        try testing.expectEqual(false, true); // tree.root should not be null
    }
}

test "can create complex tree" {
    var tree = Tree.init(testing.allocator);
    defer tree.deinit();
    try tree.insert(4);
    try tree.insert(2);
    try tree.insert(6);
    try tree.insert(1);
    try tree.insert(3);
    try tree.insert(5);
    try tree.insert(7);
    if (tree.root) |o| {
        try testing.expectEqual(4, o.data);
        if (o.left) |l| {
            try testing.expectEqual(2, l.data);
            if (l.left) |ll| {
                try testing.expectEqual(1, ll.data);
                try testing.expectEqual(null, ll.left);
                try testing.expectEqual(null, ll.right);
            } else {
                try testing.expectEqual(false, true); // l.left should not be null
            }
            if (l.right) |lr| {
                try testing.expectEqual(3, lr.data);
                try testing.expectEqual(null, lr.left);
                try testing.expectEqual(null, lr.right);
            } else {
                try testing.expectEqual(false, true); // l.right should not be null
            }
        } else {
            try testing.expectEqual(false, true); // o.left should not be null
        }
        if (o.right) |r| {
            try testing.expectEqual(6, r.data);
            if (r.left) |rl| {
                try testing.expectEqual(5, rl.data);
                try testing.expectEqual(null, rl.left);
                try testing.expectEqual(null, rl.right);
            } else {
                try testing.expectEqual(false, true); // r.left should not be null
            }
            if (r.right) |rr| {
                try testing.expectEqual(7, rr.data);
                try testing.expectEqual(null, rr.left);
                try testing.expectEqual(null, rr.right);
            } else {
                try testing.expectEqual(false, true); // r.right should not be null
            }
        } else {
            try testing.expectEqual(false, true); // o.right should not be null
        }
    } else {
        try testing.expectEqual(false, true); // tree.root should not be null
    }
}

test "can sort data-can sort single number" {
    const tree_data = [_]i32{2};
    const expected = [_]i32{2};
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        sortedDataTest,
        .{ &tree_data, &expected },
    );
}

test "can sort data-can sort if second number is smaller than first" {
    const tree_data = [_]i32{ 2, 1 };
    const expected = [_]i32{ 1, 2 };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        sortedDataTest,
        .{ &tree_data, &expected },
    );
}

test "can sort data-can sort if second number is same as first" {
    const tree_data = [_]i32{ 2, 2 };
    const expected = [_]i32{ 2, 2 };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        sortedDataTest,
        .{ &tree_data, &expected },
    );
}

test "can sort data-can sort if second number is greater than first" {
    const tree_data = [_]i32{ 2, 3 };
    const expected = [_]i32{ 2, 3 };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        sortedDataTest,
        .{ &tree_data, &expected },
    );
}

test "can sort data-can sort complex tree" {
    const tree_data = [_]i32{ 2, 1, 3, 6, 7, 5 };
    const expected = [_]i32{ 1, 2, 3, 5, 6, 7 };
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        sortedDataTest,
        .{ &tree_data, &expected },
    );
}

test "empty tree has null root" {
    var tree = Tree.init(testing.allocator);
    defer tree.deinit();
    try testing.expectEqual(null, tree.root);
}

test "can sort data-can sort empty tree" {
    const tree_data = [_]i32{};
    const expected = [_]i32{};
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        sortedDataTest,
        .{ &tree_data, &expected },
    );
}
