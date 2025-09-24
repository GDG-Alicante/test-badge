import 'dart:io';
import 'package:firedart/firedart.dart';

void main(List<String> args) async {
  final projectId = Platform.environment['GCP_PROJECT_ID'];
  if (projectId == null) {
    print('GCP_PROJECT_ID environment variable not set.');
    exit(1);
  }
  final firestore = Firestore(projectId);
  print('Using GCP Project ID: $projectId');

  final eventSlug = 'devfest-2025-alicante';
  final email = 'aarcarpas@gmail.com';

  try {
    final attendeeRef = firestore.collection('events').document(eventSlug).collection('attendees').document(email);
    await attendeeRef.update({
      'claimed_certificate': false,
      'certificate_url': null,
    });
    print('Successfully cleared claim for $email in event $eventSlug');
  } catch (e) {
    print('Error clearing claim: $e');
  }
  exit(0);
}
