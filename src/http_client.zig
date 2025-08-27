const std = @import("std");
const posix = std.posix;
const http_utils = @import("./client_utils.zig");

const Request = http_utils.Request;
const Response = http_utils.Response;
const HTTPMethod = http_utils.HTTPMethod;

const Header = http_utils.Header;

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

pub fn getDefaultHeaders() ?[]const Header {
    return &[_]Header{
        .{
            .name = "Host",
            .value = "example.com",
        },
        .{
            .name = "User-Agent",
            .value = "ZigHTTPClient/1.0",
        },
        .{
            .name = "Accept",
            .value = "*/*",
        },
        .{
            .name = "Connection",
            .value = "close",
        },
    };
}

pub const RequestOptions = struct {
    allocator: std.mem.Allocator,
    method: HTTPMethod = .GET,
    version: []const u8 = "1.1",
    body: ?[]const u8 = null,
    headers: ?[]const Header = null,
    user_agent: []const u8 = "ZigHTTPClient/1.0",
    content_type: ?[]const u8 = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .method = .GET,
            .version = "1.1",
            .body = null,
            .headers = getDefaultHeaders(),
            .content_type = null,
        };
    }
};

pub const HttpClient = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .allocator = allocator };
    }

    pub fn fetch(self: *Self, url: []const u8, Options: RequestOptions) !void {

        // Crear el request.
        // TODO: Tengo qe ver la forma de parsear la parte dle path del url...

        // TODO: Parsear URL properly
        // Por ahora, separar host y path manualmente

        var request: Request = Request.init(
            Options.method,
            url,
            Options.version,
            Options.headers.?,
            Options.body,
        );

        const request_serialized = try request.serialize(self.allocator);

        // crear el socket.
        const socket = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
        defer posix.close(socket);

        // Resolver hostname a IP (simplificado)
        // var server_addr = try self.resolveHost(parsed_url.host, parsed_url.port);
        var server_addr = try std.net.Address.parseIp("23.192.228.80", 80);
        // aca deberia de hacer que el url se convierta en la IP para poder pegarla a dicho endpoint.
        // No se si parseIp me deja pasar el url.

        // Conectar
        try posix.connect(socket, &server_addr.any, server_addr.getOsSockLen());

        _ = try posix.send(socket, request_serialized, 0);

        var buf: [1024]u8 = undefined;
        const n = try posix.recv(socket, &buf, 0);
        std.debug.print("Response:\n{s}\n", .{buf[0..n]});
    }

    // pub fn send() !Response {}

    pub fn get(self: Self, url: []const u8) !Response {
        var options = RequestOptions.init(self.allocator);
        options.method = .GET;
        return self.fetch(url, options);
    }

    pub fn post(self: *Self, url: []const u8) !Response {
        var options = RequestOptions.init(self.allocator);
        options.method = .POST;
        return self.fetch(url, options);
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
    // pub fn parse_response_to_json() !Response {}

    pub fn deinit() void {}
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Crear primero el objeto HttpClient

    var http_client: HttpClient = HttpClient.init(allocator);

    // const host: Header = Header{
    //     .name = "Host",
    //     .value = "example.com",
    // };

    // const user_agent = Header{
    //     .name = "User-Agent",
    //     .value = "ZigHTTPClient/1.0",
    // };

    // const accept = Header{
    //     .name = "Accept",
    //     .value = "*/*",
    // };

    // const connection = Header{
    //     .name = "Connection",
    //     .value = "close",
    // };

    // const language: Header = Header{
    //     .name = "Accept-Language",
    //     .value = "en",
    // };

    // const accept_encoding: Header = Header{
    //     .name = "Accept-Encoding",
    //     .value = "identity",
    // };

    var options = RequestOptions.init(allocator);
    options.body = "";

    try http_client.fetch("/", options);

    //// Prueba de los sockets posix y algunos handlers de std.net: ////

    // const allocator = std.heap.page_allocator;

    // const sock = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    // defer posix.close(sock);

    // var my_addr = try std.net.Address.parseIp("0.0.0.0", 0);
    // try posix.bind(sock, &my_addr.any, my_addr.getOsSockLen());

    // var server_addr = try std.net.Address.parseIp("23.220.75.245", 80);
    // try posix.connect(sock, &server_addr.any, server_addr.getOsSockLen());

    // // Como reverenda mierda hago para configurar esto como en C sin std.net?

    // // Ideas?

    // const request = "GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n";

    // _ = try posix.send(sock, request, 0);

    // var buf: [1024]u8 = undefined;
    // const n = try posix.recv(sock, &buf, 0);
    // std.debug.print("Response:\n{s}\n", .{buf[0..n]});

    ////////////////////////////////////////////////////////////////////////////////////////
}
