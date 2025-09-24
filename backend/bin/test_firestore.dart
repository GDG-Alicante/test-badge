
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

  try {
    await firestore.collection('test_collection').document('test_doc').set({
      'message': 'Hello from firedart!',
      'timestamp': DateTime.now().toIso8601String(),
    });
    print('Successfully wrote to test_collection/test_doc');
  } catch (e) {
    print('Error writing to Firestore: $e');
  }
  exit(0);
}
