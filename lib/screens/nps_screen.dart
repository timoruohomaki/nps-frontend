import 'package:flutter/material.dart' hide Feedback;

import '../api/feedback_client.dart';
import '../config.dart';
import '../device_context.dart';
import '../models/feedback.dart';

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

class _NpsScreenState extends State<NpsScreen> {
  int? _rating;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rating = _rating;
    if (rating == null) return;

    setState(() => _submitting = true);
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
      _showSnack('Thanks for your feedback!', isError: false);
      setState(() {
        _rating = null;
        _commentCtrl.clear();
      });
    } on FeedbackApiException catch (e) {
      if (!mounted) return;
      _showSnack('Submission failed (${e.statusCode}): ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('How likely are you to recommend us?')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'On a scale from 1 (not likely) to 10 (very likely):',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              _RatingPicker(
                selected: _rating,
                onSelect: _submitting ? null : (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 12),
              const _ScaleLegend(),
              const SizedBox(height: 28),
              TextField(
                controller: _commentCtrl,
                enabled: !_submitting,
                maxLength: 2000,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Anything you want to add? (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: (_rating == null || _submitting) ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingPicker extends StatelessWidget {
  const _RatingPicker({required this.selected, required this.onSelect});

  final int? selected;
  final void Function(int)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(10, (i) {
        final value = i + 1;
        final isSelected = value == selected;
        return ChoiceChip(
          label: Text('$value', style: const TextStyle(fontSize: 16)),
          selected: isSelected,
          onSelected: onSelect == null ? null : (_) => onSelect!(value),
        );
      }),
    );
  }
}

class _ScaleLegend extends StatelessWidget {
  const _ScaleLegend();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Not at all likely', style: style),
        Text('Extremely likely', style: style),
      ],
    );
  }
}
