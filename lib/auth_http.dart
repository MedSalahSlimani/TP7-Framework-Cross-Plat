import 'package:http/http.dart' as h;
import 'session.dart';

Map<String, String> _merge(Map<String, String>? headers) =>
    {...?headers, ...Session.authHeader};

Future<h.Response> get(Uri url, {Map<String, String>? headers}) =>
    h.get(url, headers: _merge(headers));

Future<h.Response> post(Uri url, {Map<String, String>? headers, Object? body}) =>
    h.post(url, headers: _merge(headers), body: body);

Future<h.Response> put(Uri url, {Map<String, String>? headers, Object? body}) =>
    h.put(url, headers: _merge(headers), body: body);

Future<h.Response> delete(Uri url, {Map<String, String>? headers}) =>
    h.delete(url, headers: _merge(headers));