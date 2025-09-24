import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:firedart/firedart.dart';

void main(List<String> args) async {
  // Get GCP Project ID from environment variable.
  final projectId = Platform.environment['GCP_PROJECT_ID'];
  if (projectId == null) {
    print('GCP_PROJECT_ID environment variable not set.');
    exit(1);
  }
  final firestore = Firestore(projectId);
  print('Using GCP Project ID: $projectId');

  final eventSlug = 'test3';
  print('Seeding Firestore for event: $eventSlug');

  // Seed event details
  final eventDetailsRef = firestore.collection('event_details').document(eventSlug);
  await eventDetailsRef.set({
    'name': 'DevFest Alicante 2025', // From test.csv
    'gdgCommunityLink': 'https://gdg.community.dev/events/details/google-gdg-alicante-presents-devfest-2025-alicante/',
  });
  print('  - Added event details for $eventSlug');

  final input = File('backend/data/test.csv').openRead();
  final fields = await input
      .transform(utf8.decoder)
      .transform(const CsvToListConverter(shouldParseNumbers: false, eol: '\n'))
      .toList();

  // Remove header row
  fields.removeAt(0);

  final eventDocRef = firestore.collection('events').document(eventSlug);
  await eventDocRef.set(
      {'name': 'Event $eventSlug'}); // Create the event document explicitly

  final attendeesCollection = eventDocRef.collection('attendees');

  print('length: ${fields.length}');

  for (var field in fields) {
    final firstName = field[2];
    final lastName = field[3];
    final email = field[4];
    final name = '$firstName $lastName';
    print('name: $name');

    try {
      await attendeesCollection.document(email).set({
        'name': name,
        'email': email,
        'claimed_certificate': false,
        'certificate_url': null,
      });
      print('  - Added attendee $email for event $eventSlug');
    } catch (e) {
      print('  - Error adding attendee $email for event $eventSlug: $e');
    }
  }

  print('Seeding complete!');
  exit(0);
}