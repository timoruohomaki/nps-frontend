import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter/services.dart' show rootBundle;

import '../api/feedback_client.dart';
import '../config.dart';
import '../device_context.dart';
import '../models/feedback.dart';
import '../theme.dart';

class NpsScreen extends StatefulWidget {
  const NpsScreen({
    super.key,
    required this.config,
    required this.device,
    required this.client,
  });

  final AppConfig config;
  final DeviceContext device;
  final FeedbackClient client;

  @override
  State<NpsScreen> createState() => _NpsScreenState();
}

enum _Phase { entering, submitting, success }

class _NpsScreenState extends State<NpsScreen> {
  int? _rating;
  final _commentCtrl = TextEditingController();
  _Phase _phase = _Phase.entering;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rating = _rating;
    if (rating == null) return;

    setState(() {
      _phase = _Phase.submitting;
      _error = null;
    });
    try {
      final fb = Feedback(
        app: widget.config.appId,
        appVersion: widget.device.appVersion,
        platform: widget.device.platform,
        timestamp: iso8601UtcNow(),
        npsRating: rating,
        timezone: widget.device.timezone,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      );
      await widget.client.submit(fb);
      if (!mounted) return;
      setState(() => _phase = _Phase.success);
    } on FeedbackApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.entering;
        _error = 'Submission failed (${e.statusCode}): ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.entering;
        _error = 'Network error: $e';
      });
    }
  }

  void _reset() {
    setState(() {
      _rating = null;
      _commentCtrl.clear();
      _phase = _Phase.entering;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _phase == _Phase.success
                  ? _SuccessView(rating: _rating!, onAnother: _reset)
                  : _FormView(
                      rating: _rating,
                      commentCtrl: _commentCtrl,
                      submitting: _phase == _Phase.submitting,
                      error: _error,
                      onSelect: (v) => setState(() => _rating = v),
                      onSubmit: _submit,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.rating,
    required this.commentCtrl,
    required this.submitting,
    required this.error,
    required this.onSelect,
    required this.onSubmit,
  });

  final int? rating;
  final TextEditingController commentCtrl;
  final bool submitting;
  final String? error;
  final void Function(int) onSelect;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LogoSlot(),
        const SizedBox(height: 24),
        Text(
          'How likely are you to recommend us?',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your answer helps us understand what is working and what is not.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceMuted),
        ),
        const SizedBox(height: 28),
        _RatingCard(
          selected: rating,
          enabled: !submitting,
          onSelect: onSelect,
        ),
        const SizedBox(height: 16),
        _CommentCard(controller: commentCtrl, enabled: !submitting),
        if (error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: error!),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: (rating == null || submitting) ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Send feedback'),
          ),
        ),
      ],
    );
  }
}

class _LogoSlot extends StatelessWidget {
  const _LogoSlot();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasLogo(),
      builder: (context, snap) {
        if (snap.data == true) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Image.asset('assets/images/logo.png', height: 48),
          );
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'N',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _hasLogo() async {
    try {
      await rootBundle.load('assets/images/logo.png');
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.selected,
    required this.enabled,
    required this.onSelect,
  });

  final int? selected;
  final bool enabled;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Not at all likely',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  'Extremely likely',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(10, (i) {
                final value = i + 1;
                return _RatingTile(
                  value: value,
                  selected: value == selected,
                  enabled: enabled,
                  onTap: () => onSelect(value),
                );
              }),
            ),
            if (selected != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: _BucketBadge(rating: selected!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorForRating(value);
    final bg = selected ? color : Colors.white;
    final fg = selected ? Colors.white : AppTheme.onSurface;
    final border = selected ? color : AppTheme.border;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 40,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: selected ? 0 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '$value',
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BucketBadge extends StatelessWidget {
  const _BucketBadge({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (rating) {
      <= 6 => ('Detractor', AppTheme.detractor),
      <= 8 => ('Passive', AppTheme.passive),
      _ => ('Promoter', AppTheme.promoter),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.controller, required this.enabled});
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: TextField(
          controller: controller,
          enabled: enabled,
          maxLength: 2000,
          maxLines: 4,
          minLines: 3,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: 'Tell us a bit more (optional)',
            filled: false,
            counterText: '',
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.detractor.withValues(alpha: 0.08),
        border: Border.all(color: AppTheme.detractor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.detractor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.detractor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.rating, required this.onAnother});
  final int rating;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorForRating(rating);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 40, color: color),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Thank you',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your feedback has been recorded.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceMuted),
        ),
        const SizedBox(height: 40),
        Center(
          child: TextButton(
            onPressed: onAnother,
            child: const Text('Send another response'),
          ),
        ),
      ],
    );
  }
}
