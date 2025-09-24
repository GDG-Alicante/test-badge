import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:github/github.dart';
import 'package:mustache_template/mustache_template.dart';

// A custom UUID v4 generator.
class Uuid {
  final _random = Random();

  String v4() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (match) {
        final r = (_random.nextInt(16));
        final v = match.group(0) == 'x' ? r : (r & 0x3 | 0x8);
        return v.toRadixString(16);
      },
    );
  }
}

String generateHtmlBadge(Map<String, dynamic> badgeData) {
  // Load the HTML template
  // Assuming the template is relative to the project root or a known path
  // For now, let's assume it's at backend/lib/templates/badge.html relative to where the server is run
  final templateFile = File('backend/lib/templates/badge.html');
  if (!templateFile.existsSync()) {
    print('Error: Template file not found at ${templateFile.path}');
    return '<h1>Error: Template not found</h1>';
  }
  final templateContent = templateFile.readAsStringSync();
  final template = Template(templateContent, htmlEscapeValues: false);
  return template.renderString(badgeData);
}

String generateOpenBadgeJson(
    Map<String, dynamic> badgeData, String githubOwner, String githubRepo) {
  // This will be replaced with actual Open Badge JSON generation
  return jsonEncode({
    '@context': 'https://w3id.org/openbadges/v2',
    'type': 'Assertion',
    'id': 'urn:uuid:${badgeData['certificateId']}',
    'recipient': {
      'type': 'email',
      'hashed': false,
      'identity': badgeData['email'], // Assuming email is in badgeData
    },
    'badge':
        'https://$githubOwner.github.io/$githubRepo/badges/${badgeData['eventName']?.toString().toLowerCase().replaceAll(' ', '-')}/badge.json', // Link to badge class
    'verification': {
      'type': 'HostedBadge',
      'url':
          'https://$githubOwner.github.io/$githubRepo/badges/${badgeData['eventName']?.toString().toLowerCase().replaceAll(' ', '-')}/${badgeData['certificateId']}.html',
    },
    'issuedOn': '${badgeData['issueDate']}T00:00:00Z',
    'issuer':
        'https://gdg.community.dev/events/details/google-gdg-alicante-presents-devfest-2025-alicante/', // Placeholder
  });
}

Future<void> commitFileToGitHub(
  GitHub github,
  String owner,
  String repo,
  String branch,
  String path,
  String content,
  String message,
) async {
  final slug = RepositorySlug(owner, repo);
  print(
      'Attempting to commit to GitHub: $owner/$repo on branch $branch, path $path');

  try {
    await github.repositories.createFile(
      slug,
      CreateFile(
        path: path,
        content: base64Encode(
            utf8.encode(content)), // Content must be base64 encoded
        message: message,
        branch: branch,
      ),
    );
    // print('Successfully committed $path to GitHub. Response: ${response.toJson()}');
  } catch (e, stacktrace) {
    print('Error in commitFileToGitHub: $e\nStacktrace: $stacktrace');
    rethrow; // Re-throw the exception so it's caught by the caller
  }
}