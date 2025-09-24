import 'dart:convert';
import 'dart:io';

import 'package:firedart/firedart.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:gdg_alicante_badges_backend/certificate_generator.dart';

// Firestore instance.
late Firestore _firestore;

// GitHub configuration.
late String _githubOwner;
late String _githubPublicRepo; // This will be the public repo: test-badges
late String _githubToken;
late GitHub _github;

// The router that will handle our API endpoints.
final _router = Router()
  ..get('/', _rootHandler)
  ..post('/claim', _claimHandler)
  ..get('/events', _eventsHandler); // New endpoint to list events

// Handler for the root endpoint.
Response _rootHandler(Request req) {
  return Response.ok('Welcome to the GDG Alicante Badge Generator backend!\n');
}

// Handler for /events endpoint.
Future<Response> _eventsHandler(Request request) async {
  final events = await _firestore.collection('event_details').get();
  final eventList = events
      .map((doc) => {
            'slug': doc.id,
            'name': doc.map['name'],
          })
      .toList();
  return Response.ok(jsonEncode(eventList),
      headers: {'Content-Type': 'application/json'});
}

// Handler for the /claim endpoint.
Future<Response> _claimHandler(Request request) async {
  // 1. Read the request body (email, event_slug).
  final body = await request.readAsString();
  final params = jsonDecode(body);
  final email = params['email'];
  final eventSlug = params['event_slug'];

  if (email == null || eventSlug == null) {
    return Response.badRequest(body: 'Missing email or event_slug');
  }

  // 2. Validate against Firestore.
  print('Validating $email for event $eventSlug...');
  final attendees = _firestore
      .collection('events')
      .document(eventSlug)
      .collection('attendees');
  final query = await attendees.where('email', isEqualTo: email).get();

  if (query.isEmpty) {
    return Response.notFound(
        'Attendee with that email not found for this event.');
  }

  final attendee = query.first;
  final attendeeName = attendee['name'];

  if (attendee['claimed_certificate'] == true) {
    return Response(409,
        body:
            'Certificate already claimed. URL: ${attendee['certificate_url']}');
  }

  // Fetch event details
  final eventDetailsDoc =
      await _firestore.collection('event_details').document(eventSlug).get();
  if (eventDetailsDoc.map.isEmpty) {
    return Response.notFound('Event details not found for $eventSlug.');
  }
  final eventDetails = eventDetailsDoc.map;
  final gdgCommunityLink = eventDetails['gdgCommunityLink'];
  final eventName = eventDetails['name']; // Use event name from details

  // 3. Generate badge data.
  final certificateId = Uuid().v4();
  final issueDate = DateTime.now().toIso8601String().substring(0, 10);

  final badgeData = {
    'attendeeName': attendeeName,
    'eventName': eventName,
    'certificateId': certificateId,
    'issueDate': issueDate,
    'gdgCommunityLink': gdgCommunityLink,
    'email': email, // Add email for Open Badge
  };

  // Generate HTML badge
  final htmlContent = generateHtmlBadge(badgeData);
  final htmlPath = 'badges/$eventSlug/$certificateId.html';

  // Generate Open Badge JSON
  final openBadgeJson = generateOpenBadgeJson(badgeData, _githubOwner, _githubPublicRepo);
  final openBadgePath = 'badges/$eventSlug/$certificateId.json';

  // 4. Commit HTML and Open Badge JSON to GitHub Pages.
  print(
      'Committing badge HTML and Open Badge JSON for $certificateId to GitHub Pages...');

  try {
    await commitFileToGitHub(
      _github,
      _githubOwner,
      _githubPublicRepo, // Commit to the public repo
      'gh-pages', // On the gh-pages branch
      htmlPath,
      htmlContent,
      'feat: Generate HTML badge for $attendeeName',
    );
    await commitFileToGitHub(
      _github,
      _githubOwner,
      _githubPublicRepo, // Commit to the public repo
      'gh-pages', // On the gh-pages branch
      openBadgePath,
      openBadgeJson,
      'feat: Generate Open Badge JSON for $attendeeName',
    );
  } catch (e) {
    print('Error committing to GitHub: $e');
    return Response.internalServerError(body: 'Error committing to GitHub.');
  }

  // The URL will point to the public GitHub Pages URL.
  final certificateUrl =
      'https://$_githubOwner.github.io/$_githubPublicRepo/$htmlPath';

  // 5. Update Firestore.
  print('Updating Firestore record for $email...');
  await attendee.reference
      .update({'claimed_certificate': true, 'certificate_url': certificateUrl});

  // 6. Return the certificate URL.
  return Response.ok(
    jsonEncode({'certificate_url': certificateUrl}),
    headers: {'Content-Type': 'application/json'},
  );
}



void main(List<String> args) async {
  // Get GCP Project ID from environment variable.
  final projectId = Platform.environment['GCP_PROJECT_ID'];
  if (projectId == null) {
    print('GCP_PROJECT_ID environment variable not set.');
    exit(1);
  }
  _firestore = Firestore(projectId);

  // Get GitHub configuration from environment variables.
  _githubOwner = Platform.environment['GITHUB_REPO_OWNER']!;
  _githubPublicRepo = Platform.environment['GITHUB_REPO_NAME']!;
  _githubToken = Platform.environment['GH_PAGES_DEPLOY_TOKEN']!;
  _github = GitHub(auth: Authentication.withToken(_githubToken));

  // Use the PORT environment variable if available, otherwise default to 8080.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // The handler that combines the router with logging and error handling.
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(_router);

  // Start the server.
  final server = await io.serve(handler, InternetAddress.anyIPv6, port);
  print('Server listening on port ${server.port}');
}

