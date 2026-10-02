import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/connected_user.dart';
import '../../../../providers/repository_provider.dart';
import '../../../connect/application/partner_label_provider.dart';
import '../../../proof/data/proof_photo_cache.dart';

/// The 연결 끊기 confirmation, shared by the Us tab and the proof photo
/// viewer. Returns true when the couple was disconnected.
///
/// On success it also drops every cached proof photo right away (the cache
/// binder clears it too once the relation stream reports the change).
Future<bool> confirmAndDisconnectPartner(
  BuildContext context,
  WidgetRef ref,
  ConnectedUser person,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final name =
      ref
          .read(partnerLabelProvider)
          .preferredFor(
            person.user.uid,
            displayName: person.user.displayName,
          ) ??
      l10n.usUnknownUser;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.usDisconnectDialogTitle),
      content: Text(l10n.usDisconnectDialogContent(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            l10n.usDisconnectConfirm,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  try {
    await ref
        .read(disconnectConnectionUseCaseProvider)
        .execute(person.user.uid);
    // connectedProfilesProvider is a FutureProvider: refresh it by hand.
    ref.invalidate(connectedProfilesProvider);
    unawaited(ref.read(proofPhotoCacheProvider).clear());
    messenger?.showSnackBar(SnackBar(content: Text(l10n.usDisconnectSuccess)));
    return true;
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.usDisconnectError)));
    return false;
  }
}
