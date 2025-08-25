const std = @import("std");
const posix = std.posix;
const http_utils = @import("./client_utils.zig");

const Request = http_utils.Request;
const Response = http_utils.Response;
const HTTPMethod = http_utils.HTTPMethod;

// Primero que nada... Que mierda quiere hacer un cliente HTTP.

// 1- Mandar una peticion

// 2- Que la peticion que mande pueda elegir tanto el metodo (HTTP) que quiera hacer.

// 3- Si el metodo es un POST, PUT o DELETE pueda mandar un body.

// 4- Elegir la url hacia donde la quiere mandar.

// 5- Quizas elegir la version de HTTP de su preferencia (1.1, 2.0, 3.0, ...)

// 6- Que se le devuelva un codigo de respuesta dependiendo de si salio bien o mal la request.

// 7- (Quizas medio anticipado) Que tenga un buen set de exceptiones para manejar todo bien.

// 8- Esperar respuesta del server al cual le hizo la peticion.

// 9- Una forma de poder parsear la respuesta en un formato JSON, XML o el que fuere.

// Ahora viene lo bueno..
// Funcion para que me devuelva un struct de tipo HttpClient

pub const RequestOptions = struct {
    method: HTTPMethod = .GET,
    version: []const u8 = "1.1",
    body: ?[]const u8 = null,
    header: ?[]const u8 = null,
    user_agent: []const u8 = "ZigHTTPClient/1.0",
    content_type: ?[]const u8 = null,
};

pub const HttpClient = struct {
    allocator: *std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .allocator = allocator };
    }

    pub fn fetch(self: *Self, url: []const u8, method: HTTPMethod, Options: HttpOptions) !Response {
        _ = self;

        // Crear el request.
        // TODO: Tengo qe ver la forma de parsear la parte dle path del url...
        var request: Request = Request.init(method, url, "1.1", headers.items, "");

        // crear el socket.
        const socket = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
        defer posix.close(socket);

        // Resolver hostname a IP (simplificado)
        var server_addr = try self.resolveHost(parsed_url.host, parsed_url.port);
        // aca deberia de hacer que el url se convierta en la IP para poder pegarla a dicho endpoint.
        // No se si parseIp me deja pasar el url.

        // Conectar
        try posix.connect(socket, &server_addr.any, server_addr.getOsSockLen());

        _ = try posix.send(socket, request, 0);

        var buf: [1024]u8 = undefined;
        const n = try posix.recv(socket, &buf, 0);
        std.debug.print("Response:\n{s}\n", .{buf[0..n]});
    }

    // pub fn send() !Response {}

    pub fn get(self: *Self, url: []const u8) !Response {
        return self.fetch(url, .GET, null);
    }

    pub fn post(self: *Self, url: []const u8, body: []const u8) !Response {
        return self.fetch(url, .POST, body);
    }

    pub fn put(self: *Self, url: []const u8, body: []const u8) !Response {
        return self.fetch(url, .PUT, body);
    }

    pub fn delete(self: *Self, url: []const u8) !Response {
        return self.fetch(url, .DELETE, null);
    }

    pub fn resolveHost() !void {}

    pub fn get_headers() !void {}

    pub fn get_body() !void {}

    // Deberia ser parte del server. Pero lo hago aca por temas de prueba
    pub fn parse_response_to_json() !Response {
        return 
    }

    pub fn deinit() void {}
};

pub fn upperCase(string: []const u8) ![]const u8 {
    const upper_string: []const u8 = try std.mem.eql(u8, std.ascii.upperString(&string.len, string));
    return upper_string;
}

pub fn main() !void {

    //// Prueba de los sockets posix y algunos handlers de std.net: ////

    // const allocator = std.heap.page_allocator;

    const sock = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    defer posix.close(sock);

    var my_addr = try std.net.Address.parseIp("0.0.0.0", 0);
    try posix.bind(sock, &my_addr.any, my_addr.getOsSockLen());

    var server_addr = try std.net.Address.parseIp("23.220.75.245", 80);
    try posix.connect(sock, &server_addr.any, server_addr.getOsSockLen());

    // Como reverenda mierda hago para configurar esto como en C sin std.net?

    // Ideas?

    const request = "GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n";

    _ = try posix.send(sock, request, 0);

    var buf: [1024]u8 = undefined;
    const n = try posix.recv(sock, &buf, 0);
    std.debug.print("Response:\n{s}\n", .{buf[0..n]});

    ////////////////////////////////////////////////////////////////////////////////////////
}
