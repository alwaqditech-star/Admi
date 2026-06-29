import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

class CreateInvoiceCall {
  static Future<ApiCallResponse> call({
    String? name = '',
    int? number,
    String? amountFormat = '',
    String? osf = '',
    String? yarsCARD = '',
    String? monthCard = '',
    String? ccv = '',
  }) async {
    final ffApiRequestBody = '''
{
  "identityNumber": "7006309764",
  "commercialRecordNumber": "4031224235",
  "commercialRecordIssueDateHijri": "1440-07-07",
  "phoneNumber": "+966506279585",
  "extensionNumber": "1",
  "emailAddress": "ahmdrr777@gmail.com",
  "managerName": "محمد احمد امين عدنان جوير",
  "managerPhoneNumber": "+966506279585",
  "managerMobileNumber": "+966506279585",
  "activity": "SPECIALITY_TRANSPORT"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Create Invoice',
      apiUrl: 'https://wasl.tga.gov.sa/api/tracking/v1/operating-companies',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': '460303a1-49bd-446b-b3ac-2f2f0e37ea23',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? sum(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.amount_format''',
      ));
}

class ApiWasalCall {
  static Future<ApiCallResponse> call() async {
    final ffApiRequestBody = '''
{
  "sequenceNumber": "609281120",
  "driverId": "1098876947",
  "tripId": "4",
  "distanceInMeters": 5100,
  "durationInSeconds": 3600,
  "customerRating": 1,
  "customerWaitingTimeInSeconds": 5,
  "originCityNameInArabic": "حائل",
  "destinationCityNameInArabic": "حائل",
  "originLatitude": 27.499814978014555,
  "originLongitude": 41.71623955619158,
  "destinationLatitude": 27.49288666817404,
  "destinationLongitude": 41.72284851910663,
  "pickupTimestamp": "2024-11-21T12:35:00.000",
  "dropoffTimestamp": "2024-11-21T13:35:00.000",  
  "tripCost": 300,
  "startedWhen": "2024-11-20T12:35:05.000"
}
''';
    return ApiManager.instance.makeApiCall(
      callName: 'api wasal',
      apiUrl: 'https://wasl.api.elm.sa/api/dispatching/v2/trips',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'client-id': 'fd504148-a9c4-407d-9397-1b6577307517',
        'app-id': 'aa9bbe27',
        'app-key': '08de13da121531a8c259f60f10748e03',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
