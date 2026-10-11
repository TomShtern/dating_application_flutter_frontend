import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/app_route_header.dart';
import '../../shared/widgets/developer_only_callout_card.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../theme/app_theme.dart';
import '../updates/app_update_provider.dart';

const _infoSky = Color(0xFF188DC8);
const _infoViolet = Color(0xFF8E6DE8);
const _infoMint = Color(0xFF16A871);
const _infoSlate = Color(0xFF667085);

enum InfoPage { help, terms, privacy, about }

/// Static in-app information pages opened from Settings.
class InfoPageScreen extends ConsumerWidget {
  const InfoPageScreen({super.key, required this.page});

  final InfoPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = _contentFor(page);
    final sections = [
      ...content.sections,
      if (page == InfoPage.about)
        _InfoSection(
          title: 'Installed update',
          body: switch (ref.watch(appUpdateControllerProvider).currentPatch) {
            null => 'Running the original release.',
            final patch => 'Update $patch is installed.',
          },
        ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            8,
            AppTheme.pagePadding,
            AppTheme.pagePadding,
          ),
          children: [
            AppRouteHeader(title: content.title),
            const SizedBox(height: 8),
            SectionIntroCard(
              icon: content.icon,
              title: content.introTitle,
              description: content.introDescription,
              iconColor: content.accentColor,
              iconBackgroundColor: content.accentColor.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.18
                    : 0.10,
              ),
            ),
            if (content.isPlaceholder) ...[
              SizedBox(height: AppTheme.listSpacing()),
              const DeveloperOnlyCalloutCard(
                title: 'Placeholder text',
                description:
                    'This is not the final legal text. Replace it with the '
                    'reviewed version before a store release.',
              ),
            ],
            for (final section in sections) ...[
              SizedBox(height: AppTheme.listSpacing()),
              _InfoSectionCard(
                section: section,
                accentColor: content.accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({required this.section, required this.accentColor});

  final _InfoSection section;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          accentColor.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.12 : 0.04,
          ),
          theme.colorScheme.surface,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection {
  const _InfoSection({required this.title, required this.body});

  final String title;
  final String body;
}

class _InfoPageContent {
  const _InfoPageContent({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.introTitle,
    required this.introDescription,
    required this.sections,
    this.isPlaceholder = false,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final String introTitle;
  final String introDescription;
  final List<_InfoSection> sections;
  final bool isPlaceholder;
}

_InfoPageContent _contentFor(InfoPage page) {
  return switch (page) {
    InfoPage.help => _helpContent,
    InfoPage.terms => _termsContent,
    InfoPage.privacy => _privacyContent,
    InfoPage.about => _aboutContent,
  };
}

const _helpContent = _InfoPageContent(
  title: 'Help',
  icon: Icons.help_outline_rounded,
  accentColor: _infoSky,
  introTitle: 'How things work',
  introDescription: 'Short answers to the questions that come up most.',
  sections: [
    _InfoSection(
      title: 'Liking and passing',
      body:
          'On Discover, swipe a card right to like or left to pass, or use '
          'the buttons under the card. The star sends a Super Like. Undo '
          'brings back your last swipe. Likes are limited per day — the line '
          'above the buttons shows how many you have left.',
    ),
    _InfoSection(
      title: 'Matches and messages',
      body:
          'When two people like each other it is a match, and you can chat. '
          'An open chat checks for new messages about every 20 seconds rather '
          'than instantly, so a reply can take a moment to show up. Hold one of '
          'your own messages to copy or unsend it. The menu in a chat can '
          'archive it, which moves it to the Archived group, or delete it '
          'from your list — a deleted chat comes back if either of you '
          'writes again.',
    ),
    _InfoSection(
      title: 'Your profile',
      body:
          'Edit your details and photos from the Profile tab. Hold and drag a '
          'photo to reorder — the first one is your primary photo. Use the '
          'eye icon to see your profile the way other people see it.',
    ),
    _InfoSection(
      title: 'Staying safe',
      body:
          'Open the menu on a profile or chat to unmatch, block or report '
          'someone. Blocking stops contact and hides both profiles '
          'immediately. You can review and undo blocks under Settings › '
          'Blocked users.',
    ),
    _InfoSection(
      title: 'Your account',
      body:
          'Confirm your email or phone number under Settings › Verification. '
          'Settings › Account lets you pause your profile, which hides you '
          'from new people while your matches and chats stay, or delete your '
          'account. Deletion is permanent.',
    ),
    _InfoSection(
      title: 'Contact',
      body: 'A support contact has not been set up yet.',
    ),
  ],
);

const _termsContent = _InfoPageContent(
  title: 'Terms of use',
  icon: Icons.description_outlined,
  accentColor: _infoViolet,
  introTitle: 'Terms of use',
  introDescription: 'The rules for using the app.',
  isPlaceholder: true,
  sections: [
    _InfoSection(
      title: 'Using the app',
      body:
          'You must be an adult to use the app, and the profile you create '
          'must be your own.',
    ),
    _InfoSection(
      title: 'How to treat others',
      body:
          'No harassment, threats, spam, scams or impersonation. Accounts '
          'that are reported can be reviewed and banned.',
    ),
    _InfoSection(
      title: 'Your content',
      body:
          'You are responsible for the photos and text you add, and you must '
          'have the right to share them.',
    ),
    _InfoSection(
      title: 'Leaving',
      body: 'You can delete your account at any time from Settings.',
    ),
  ],
);

const _privacyContent = _InfoPageContent(
  title: 'Privacy policy',
  icon: Icons.lock_outline_rounded,
  accentColor: _infoMint,
  introTitle: 'Privacy policy',
  introDescription: 'What the app holds about you and why.',
  isPlaceholder: true,
  sections: [
    _InfoSection(
      title: 'What you give us',
      body:
          'Your sign-in details, the profile details and photos you add, '
          'the location you choose, and the messages you send.',
    ),
    _InfoSection(
      title: 'How it is used',
      body:
          'To show your profile to other people, suggest profiles to you, '
          'and run matches and chats.',
    ),
    _InfoSection(
      title: 'Your choices',
      body:
          'You can change your profile at any time, and delete your account '
          'from Settings.',
    ),
  ],
);

const _aboutContent = _InfoPageContent(
  title: 'About',
  icon: Icons.info_outline_rounded,
  accentColor: _infoSlate,
  introTitle: 'Dating App',
  introDescription: 'Meet people nearby, match, and start a conversation.',
  sections: [],
);
