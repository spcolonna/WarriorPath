import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:warrior_path/l10n/app_localizations.dart';

class SubscriptionLapsedScreen extends StatelessWidget {
  const SubscriptionLapsedScreen({Key? key}) : super(key: key);

  Future<void> _contactSupport(BuildContext context, AppLocalizations l10n) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'tu-email-de-contacto@ejemplo.com',
      query: 'subject=${Uri.encodeComponent(l10n.renewalSubject)}',
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.mailError))
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.mailLaunchError(e.toString())))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.credit_card_off,
              size: 80,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.subscriptionExpired,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.subscriptionExpiredMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: Text(l10n.contactAdmin),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              onPressed: () => _contactSupport(context, l10n),
            ),
          ],
        ),
      ),
    );
  }
}
