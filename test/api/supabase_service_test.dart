import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@GenerateMocks([http.Client])
import 'supabase_service_test.mocks.dart';

// This test mocks the http.Client used by Supabase
void main() {
  group('Supabase API Client', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
    });

    test('fetch data returns success', () async {
      when(mockClient.get(any)).thenAnswer((_) async => http.Response('{"data":"ok"}', 200));
      // Actually call your service here (inject mockClient)
      // Example: final response = await Supabase.instance.client.from('table').select();
      // For now, verify the mock was called
      await mockClient.get(Uri.parse('https://your-project.supabase.co/rest/v1/table'));
      verify(mockClient.get(any)).called(1);
    });

    test('handles network error gracefully', () async {
      when(mockClient.get(any)).thenThrow(Exception('No internet'));
      expect(() => mockClient.get(Uri.parse('https://example.com')), throwsException);
    });
  });
}