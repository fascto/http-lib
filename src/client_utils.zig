const std = @import("std");

pub const HTTPMethod = enum {
    GET,
    POST,
    PUT,
    DELETE,
    HEAD,
    OPTIONS,

    pub fn to_string(self: HTTPMethod) ![]const u8 {
        return switch (self) {
            .GET => "GET",
            .POST => "POST",
            .PUT => "PUT",
            .DELETE => "DELETE",
            .HEAD => "HEAD",
            .OPTIONS => "OPTIONS",
        };
    }
};

pub const HTTPStatusCode = enum {
    OK,
    CREATED,
    NOT_FOUND,
};

// PARA QUE FUNCIONE COMO UN JSON
pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub const Request = struct {
    method: HTTPMethod,
    path: []const u8,
    version: []const u8,
    headers: []const Header,
    body: ?[]const u8 = null,

    const Self = @This();

    pub fn init(
        method: HTTPMethod,
        path: []const u8,
        version: []const u8,
        headers: []const Header,
        body: ?[]const u8,
    ) Request {
        return .{ .method = method, .path = path, .version = version, .headers = headers, .body = body };
    }

    // HAY QUE SERIALIZAR Y PROBAR ESTA MIERDA !
    pub fn serialize(self: *Self, allocator: std.mem.Allocator) ![]const u8 {
        var http_request_message = try std.ArrayList(u8).initCapacity(allocator, 0);
        defer http_request_message.deinit(allocator);

        // request linee
        try http_request_message.writer(allocator).print("{!s} {s} HTTP/{s}\n", .{ self.method.to_string(), self.path, self.version });
        // Headers

        for (self.headers) |header| {
            try http_request_message.writer(allocator).print("{s}: {s}\r\n", .{ header.name, header.value });
        }

        // Body
        // Si hay body hay que tener en cuenta que es un POST, PUT O PATCH.
        // Esto quiere decir que tendria que ir el tipo y el content length del body.
        if (self.body) |b| {
            try http_request_message.writer(allocator).print("Content-Type: text/plain\r\n", .{});
            try http_request_message.writer(allocator).print("Content-Length: {any}\r\n", .{b.len});

            // linea separadora entre body y header
            try http_request_message.appendSlice(allocator, "\r\n");

            try http_request_message.appendSlice(allocator, b);
        }

        // Primera linea de cualquier paquete es el metodo, el path y la version protocolo <- Payaso por hacer esta mierda de approach...

        // http_request_message = try std.fmt.allocPrint(
        //     allocator,
        //     "{!s} {s} HTTP/{s}\n",
        //     .{ self.method.to_string(), self.path, self.version, self.headers },
        // );

        return try http_request_message.toOwnedSlice(allocator);
    }
};

// Supongo que esto no lo tengo que implementar pero lol.
pub const Response = struct {
    status_code: u16,
    reason_phrase: []const u8,
    version: []const u8,
    headers: []Header,
    body: ?[]const u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        _ = allocator;
        return Self{
            .status_code = 0,
            .reason_phrase = "",
            .version = "1.1",
            .headers = &[_]Header{},
            .body = null,
        };
    }
};

pub fn main() !void {
    std.debug.print("Esto es el main para probar las cosas del Response...\n", .{});

    const allocator = std.heap.page_allocator;

    // Headers
    const host: Header = Header{
        .name = "Host",
        .value = "developer.mozilla.org",
    };

    const user_agent = Header{
        .name = "User-Agent",
        .value = "ZigHTTPClient/1.0",
    };

    const accept = Header{
        .name = "Accept",
        .value = "*/*",
    };

    const connection = Header{
        .name = "Connection",
        .value = "keep-alive",
    };

    const language: Header = Header{
        .name = "Accept-Language",
        .value = "en",
    };

    const accept_encoding: Header = Header{
        .name = "Accept-Encoding",
        .value = "gzip, deflate",
    };

    var headers = [_]Header{ host, user_agent, accept, connection, accept_encoding, language };

    const body: []const u8 =
        \\ {
        \\  "user": "elpepe",
        \\  "pass": "elpepe123",
        \\  "token": "2disozz4io32324.adaoi3fsjdomao4322"
        \\ }
    ;

    var req: Request = Request.init(.POST, "/api/v1/elpepe{12}", "1.1", headers[0..], body);

    const req_serialized = req.serialize(allocator);

    std.debug.print("Paquete Serializado: \n\n{!s}\n", .{req_serialized});
}
