import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:ps_test/api_error.dart';
import 'package:ps_test/base_network_response.dart';

const DEBUG_PRINT_NETWORK = true;

const int HTTP_OK = 200;
const int HTTP_MAX_OK = 299;

const CONTENT_TYPE_KEY = 'Content-Type';
const CONTENT_TYPE_VALUE = 'application/json';
const TOKEN_KEY = 'Authorization';
const TOKEN_BASE = 'Bearer ';

class NetworkService {

  NetworkService._privateConstructor();

  static NetworkService _instance = NetworkService._privateConstructor();

  static NetworkService get instance {
    return _instance;
  }

  static refreshInstance() {
    _instance = NetworkService._privateConstructor();
  }

  int handshakeExceptionCount = 0;

  ///
  ///
  /// GET
  ///
  Future<BaseNetworkResponse> get(String route, {Map<String, String> headers, bool withToken = false, Map<String, String> params}) async {
    debugPrint(' GET: ' + route);

    return await request(route, method: 'GET', headers: headers, params: params, withToken: withToken);
  }

  ///
  ///
  /// POST
  ///
  Future<BaseNetworkResponse> post(String route,
      {Map<String, String> headers, Map<String, dynamic> body, bool withToken = false, Map<String, String> params}) async {
    debugPrint(' POST: ' + route + ', ' + body.toString());

    return await request(route, method: 'POST', body: body, headers: headers, params: params, withToken: withToken);
  }

  ///
  ///
  /// PATCH
  ///
  Future<BaseNetworkResponse> patch(String route,
      {Map<String, String> headers, Map<String, dynamic> body, bool withToken = false, Map<String, String> params}) async {
    debugPrint(' PATCH: ' + route + ', ' + body.toString());

    return await request(route, method: 'PATCH', body: body, headers: headers, params: params, withToken: withToken);
  }

  ///
  ///
  /// PUT
  ///
  Future<BaseNetworkResponse> put(String route,
      {Map<String, String> headers, Map<String, dynamic> body, bool withToken = false, Map<String, String> params}) async {
    debugPrint(' PUT: ' + route + ', ' + body.toString());

    return await request(route, method: 'PUT', body: body, headers: headers, params: params, withToken: withToken);
  }

  ///
  ///
  /// DELETE
  ///
  Future<BaseNetworkResponse> delete(String route, {Map<String, String> headers, bool withToken = false, Map<String, String> params}) async {
    debugPrint(' DELETE: ' + route);
    return await request(route, method: 'DELETE', headers: headers, params: params, withToken: withToken);
  }

  ///
  ///
  /// Get FIle
  ///
  Future<BaseNetworkResponse> getFile(String route, {Map<String, String> headers, bool withToken = false, Map<String, String> params}) async {
    debugPrint(' getFile: ' + route);

    return await request(route, method: 'GET', headers: headers, params: params, withToken: withToken, isFile: true);
  }

  List<String> retryTimes = [];

  ///
  ///
  /// Base Request Function
  ///
  Future<BaseNetworkResponse> request(
    String route, {
    method = 'GET',
    Map<String, String> headers,
    Map<String, dynamic> body,
    bool withToken = false,
    Map<String, String> params,
    int retry = 0,
    bool isFile = false,
    int timeout = 30,
  }) async {
    debugPrint('request(): $method, uri: $route');
    debugPrint('request(): retry: $retry');

//    if (retry > 0) {
//      retryTimes.add(DateTime.now().toString());
//      debugPrint('RETRY TIMES: ' + retryTimes.join('\n'));
//    }

    if (retry > 10) {
      return BaseNetworkResponse(error: APIError.getOtherError('HandshakeException error 10 retries, stopping...'));
    }

    if (headers == null) {
      headers = {};
    }

    if (withToken) {
      headers = await _addTokenToHeaders(headers);
    }

    String bodyString = '';
    if (body != null) {
      bodyString = json.encode(body);

      debugPrint('bodyString: $bodyString');

      headers.addEntries([MapEntry(CONTENT_TYPE_KEY, CONTENT_TYPE_VALUE)]);
    }

    http.Response response;
    Future<http.Response> client;

    try {
        switch (method) {
          case 'GET':
            client = http.get(_attachParams(route, params), headers: headers);
            break;
          case 'POST':
            client = http.post(_attachParams(route, params), headers: headers, body: bodyString);
            break;
          case 'PATCH':
            client = http.patch(_attachParams(route, params), headers: headers, body: bodyString);
            break;
          case 'PUT':
            client = http.put(_attachParams(route, params), headers: headers, body: bodyString);
            break;
          case 'DELETE':
            client = http.delete(_attachParams(route, params), headers: headers);
            break;
          default:
        }
        response = await client.timeout(Duration(seconds: timeout));
//      _debugResponse(response);

      var isJson = false;

      if (!isFile) {
        _debugResponseBody(response);
      }

      if (response.body != null && response.body != '' && !isFile) {
        ///
        /// Content-Type JSON ?
        ///
        isJson = response.headers.entries
            .firstWhere((entry) {
              return entry.key == 'content-type';
            }, orElse: () => MapEntry('', ''))
            .value
            .contains('application/json');
      }

      ///
      ///
      /// HTTP ERROR
      ///
      if (_checkIfHttpError(response.statusCode)) {
        ///
        /// Unauthorized
        if (response.body != null && response.body != '') {
          debugPrint('HTTP ERROR body: ${response.body}');

          if (isJson) {
            Map<String, dynamic> responseDecoded = json.decode(response.body);
            if (responseDecoded != null && responseDecoded.containsKey('errorCode') && responseDecoded.containsKey('message')) {
              return BaseNetworkResponse(
                error: APIError.getHttpError(
                  responseDecoded['errorCode'],
                  responseDecoded['message'],
                ),
                response: responseDecoded,
              );
            }
          }
        }

        return BaseNetworkResponse(error: APIError.getHttpError(response.statusCode, response.reasonPhrase));
      }

      ///
      ///
      /// Return Response
      ///
      if (response.body != null && response.body != '') {
        if (isJson) {
          return BaseNetworkResponse(response: json.decode(response.body));
        }
        if (isFile) {
          return BaseNetworkResponse(response: response.bodyBytes);
        }
        return BaseNetworkResponse(response: response.body);
      }
      return BaseNetworkResponse(response: '');
    } on TimeoutException catch (error) {
      debugPrint('TimeoutException catch (error) $error');

      return BaseNetworkResponse(error: APIError.getConnectionError(APIErrorCodes.TIMEOUT, error.toString()));
    } on SocketException catch (error) {
      debugPrint(' SocketExceptioncatch (error) $error');

      return BaseNetworkResponse(error: APIError.getConnectionError(APIErrorCodes.CONNECTION_ERROR, error.toString()));
    } catch (error, trace) {
      debugPrint('request() catch (error) $error');
      debugPrint('request() catch (error) trace: $trace');

      if (error is HandshakeException) {
        debugPrint(' HandshakeException error: ${error.message}, ${error.osError}, response.statusCode: ${response?.statusCode}');
//        debugPrint('request() catch (error) trace: $trace');

        handshakeExceptionCount++;

        return await request(route, method: method, headers: headers, body: body, withToken: withToken, params: params, retry: retry + 1);
      }

      return BaseNetworkResponse(error: APIError.getParsingError(error.toString() /*'Failed to decode response body'*/));
    }
  }



  ///
  ///
  /// Helper Functions
  ///
  Future<Map<String, String>> _addTokenToHeaders(Map<String, String> headers) async {
    if (headers == null) {
      headers = Map();
    }
        headers.addEntries([MapEntry(TOKEN_KEY, TOKEN_BASE + ('asfknaslnfklaksnflkasnflasfknlasfsa'))]);

    // if (_tokenGetter != null) {
    //   try {
    //     headers.addEntries([MapEntry(TOKEN_KEY, TOKEN_BASE + (await _tokenGetter()))]);
    //   } catch (error) {
    //     if (error is PlatformException && error.code == 'USER_REQUIRED') {
    //       this._unauthorisedAction();
    //       throw error;
    //     }
    //   }
    // }

    return headers;
  }

  bool _checkIfHttpError(int statusCode) {
    return statusCode < HTTP_OK || statusCode > HTTP_MAX_OK;
  }

  String _createParamString(String key, String value) {
    return key + '=' + value;
  }

  String _attachParams(String originalRoute, Map<String, String> params) {
    if (params != null) {
      List<String> paramStrings = params.map((key, value) => MapEntry(key, _createParamString(key, value))).values.toList();
      for (int i = 0; i < paramStrings.length; i++) {
        originalRoute += i == 0 ? '?' : '&';
        originalRoute += paramStrings[i];
      }
    }
    return originalRoute;
  }

  Future<String> readResponse(HttpClientResponse response) {
    var completer = Completer<String>();
    var contents = StringBuffer();

    response.transform(utf8.decoder).listen(
      (data) {
//        debugPrint('data: $data');
        contents.write(data);
      },
      onDone: () {
//        debugPrint('readResponse contents: $contents');
        completer.complete(contents.toString());
      },
    );
    return completer.future;
  }

  ///
  ///
  /// debug print
  ///

  // ignore: unused_element
  void _debugHttpClientResponse(HttpClientRequest request, HttpClientResponse response) {
    if (!DEBUG_PRINT_NETWORK) {
      return;
    }
    debugPrint('_debugHttpClientResponse  = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =');
    debugPrint('request ${request.method} ${request.uri}');
    debugPrint('response.statusCode ${response.statusCode}');
//    debugPrint('response.headers ${response.headers}');
    try {
      var contentType = response.headers.contentType.value;

      debugPrint('response.headers.contentType: $contentType');
      debugPrint('is json: ${contentType.contains('application/json')}');
    } catch (e) {}
  }

  // ignore: unused_element
  void _debugResponse(http.BaseResponse response) {
    if (!DEBUG_PRINT_NETWORK) {
      return;
    }
    debugPrint(' _debugResponse:');
    debugPrint('request ${response.request.method} ${response.request.url}');
    debugPrint('response.statusCode ${response.statusCode}');
//    debugPrint('response.headers ${response.headers}');
    try {
      var contentType = response.headers.entries.firstWhere((entry) {
        return entry.key == 'content-type';
      }, orElse: () => MapEntry('', '')).value;
      debugPrint('response.headers.contentType: $contentType');
      debugPrint('is json: ${contentType.contains('application/json')}');
    } catch (e) {}
  }

  void _debugResponseBody(http.Response response) {
    if (!DEBUG_PRINT_NETWORK) {
      return;
    }
    debugPrint('request ${response.request.method} ${response.request.url}');
    debugPrint('response.statusCode ${response.statusCode}');
    debugPrint('──────────────────────────────────────────────────────────────────────────────────────────────────── ');
    debugPrint('response.body: ${response.body}');
    debugPrint('──────────────────────────────────────────────────────────────────────────────────────────────────── ');
  }

  // ignore: unused_element
  void _debugHttpClientResponseBody(HttpClientRequest request, HttpClientResponse response, String responseBody) {
    if (!DEBUG_PRINT_NETWORK) {
      return;
    }
    debugPrint('request ${request.method} ${request.uri}');
    debugPrint('response.statusCode ${response.statusCode}');
    debugPrint('──────────────────────────────────────────────────────────────────────────────────────────────────── ');
    debugPrint('responseBody: $responseBody');
    debugPrint('──────────────────────────────────────────────────────────────────────────────────────────────────── ');
  }

  void debugPrint(String text) {
    if (DEBUG_PRINT_NETWORK) {
      print(text);
    }
  }
}
