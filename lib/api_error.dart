class APIErrorCodes {
  static const CONNECTION_ERROR = 1000;
  static const TIMEOUT = 1001;

  static const CAMERA_WORKER_SERVICE_ERROR = 1042;

  static const PARSING_ERROR = 2000;

  static const FIREBASE_ERROR = 3000;
  static const FIREBASE_WRONG_PIN = 3001;

  static const OTHER = 9000;
}

enum APIErrorType {
  UnknownError,
  ConnectionError,
  httpError,
  parsingError,
  FireBaseError,
}

class APIError {
  final String readableError;
  final int errorCode;
  final APIErrorType type;

  APIError({
    this.readableError,
    this.errorCode,
    this.type,
  });

  static APIError getConnectionError(int code, String message) {
    return APIError(readableError: message, errorCode: code, type: APIErrorType.ConnectionError);
  }

  static APIError getHttpError(int code, String message) {
    return APIError(readableError: message, errorCode: code, type: APIErrorType.httpError);
  }

  static APIError getParsingError(String message) {
    return APIError(readableError: message, errorCode: APIErrorCodes.PARSING_ERROR, type: APIErrorType.parsingError);
  }

  static APIError getFireBaseError(String code, String message, [int errorCode]) {
    return APIError(readableError: message, errorCode: errorCode ?? APIErrorCodes.FIREBASE_ERROR, type: APIErrorType.FireBaseError);
  }

  static APIError getOtherError([String message]) {
    return APIError(readableError: message, errorCode: APIErrorCodes.OTHER, type: APIErrorType.UnknownError);
  }

  @override
  String toString() {
    return 'APIError: type: $type, errorCode: $errorCode, readableError: $readableError';
  }
}
