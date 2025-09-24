import 'dart:js_interop';
import 'package:web/web.dart';
import 'dart:convert';

extension on JSObject {
  external JSAny? operator [](JSAny? key);
}

// The URL of the backend server. This will be replaced with the actual URL during deployment.
const backendUrl = 'https://your-cloud-run-service-url';

void main() {
  final form = document.querySelector('#claim-form') as HTMLFormElement;
  final emailInput = document.querySelector('#email-input') as HTMLInputElement;
  final eventNameElement =
      document.querySelector('#event-name') as HTMLHeadingElement;
  final status = document.querySelector('#status') as HTMLDivElement;
  final submitButton =
      document.querySelector('#submit-button') as HTMLButtonElement;
  final eventSelectorPlaceholder =
      document.querySelector('#event-selector-placeholder') as HTMLDivElement;
  final eventSelector =
      document.querySelector('#event-selector') as HTMLSelectElement;

  final url = URL(window.location.href);
  final eventSlug = url.searchParams.get('event');

  if (eventSlug == null || eventSlug.isEmpty) {
    _showEventSelector(eventSelector, eventSelectorPlaceholder, eventNameElement);
  } else {
    eventNameElement.innerText = _formatEventName(eventSlug);
    eventNameElement.style.display = 'block';
  }

  form.addEventListener('submit', (Event e) {
    e.preventDefault();
    status.innerText = 'Generando badge...';
    submitButton.disabled = true;

    final selectedEventSlug = eventSlug ?? eventSelector.value;

    _handleFormSubmit(
        emailInput.value, selectedEventSlug, status, submitButton);
  }.toJS);
}

Future<void> _showEventSelector(
    HTMLSelectElement eventSelector,
    HTMLDivElement eventSelectorPlaceholder,
    HTMLHeadingElement eventNameElement) async {
  try {
    final response = await window.fetch('$backendUrl/events'.toJS).toDart;
    if (response.ok) {
      final events = await response.json().toDart as JSArray<JSObject>;
      if (events.toDart.isNotEmpty) {
        for (var i = 0; i < events.length; i++) {
          final event = events[i];
          final option = document.createElement('option') as HTMLOptionElement;
          option.value = (event['slug'.toJS] as JSString).toDart;
          option.text = (event['name'.toJS] as JSString).toDart;
          eventSelector.add(option);
        }
        eventSelectorPlaceholder.style.display = 'block';
      } else {
        eventNameElement.innerText = 'No events found.';
        eventNameElement.style.display = 'block';
      }
    } else {
      eventNameElement.innerText = 'Error fetching events.';
      eventNameElement.style.display = 'block';
    }
  } catch (e) {
    eventNameElement.innerText = 'Error de conexión con el servidor.';
    eventNameElement.style.display = 'block';
  }
}

String _formatEventName(String slug) {
  return slug
      .split('-')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

Future<void> _handleFormSubmit(String email, String eventSlug, HTMLDivElement status, HTMLButtonElement submitButton) async {
  try {
    final headers = Headers();
    headers.append('Content-Type', 'application/json');

    final response = await window.fetch(
      '$backendUrl/claim'.toJS,
      RequestInit(
        method: 'POST',
        headers: headers,
        body: jsonEncode({
          'email': email,
          'event_slug': eventSlug,
        }).toJS,
      ),
    ).toDart;

    if (response.ok) {
      final data = await response.json().toDart as JSObject;
      final certificateUrl = (data['certificate_url'.toJS] as JSString).toDart;
      status.innerHTML = '¡Badge generado! Puedes verlo <a href="$certificateUrl" target="_blank">aquí</a>.'.toJS;
    } else {
      final responseBody = await response.text().toDart;
      status.innerText = 'Error: $responseBody';
    }
  } catch (e) {
    status.innerText = 'Error de conexión con el servidor.';
  } finally {
    submitButton.disabled = false;
  }
}
