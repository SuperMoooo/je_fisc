import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './app_input_style.dart';
import './input_title.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// One attachment held by an [AppFilePickerField].
///
/// Deliberately not a `file_picker` or `image_picker` type — nothing here
/// imports a picker package, so the widget adds no dependency.
class AppPickedFile {
  const AppPickedFile({required this.name, this.path, this.sizeBytes});

  final String name;

  /// Where the bytes are, when they are on disk. A file chosen on the web has
  /// no path, and the field simply shows no preview for it.
  final String? path;

  final int? sizeBytes;

  /// Lower-case extension without the dot, or empty when the name has none.
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  /// Whether this can be drawn as a thumbnail.
  bool get isImage => const {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
  }.contains(extension);

  /// Size as a person reads it — "480 KB", "1.2 MB".
  String? get readableSize {
    final bytes = sizeBytes;
    if (bytes == null) return null;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// The icon that stands in for a file with no thumbnail.
  IconData get icon => switch (extension) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' || 'docx' || 'txt' || 'rtf' => Icons.description_outlined,
    'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
    'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
    'mp3' || 'wav' || 'm4a' => Icons.audiotrack_outlined,
    'mp4' || 'mov' || 'avi' => Icons.movie_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

/// A field whose value is a list of attachments: an area that opens the app's
/// own picker, and a row per file with a thumbnail and a remove button.
///
/// The picking belongs to the caller — this is the field, not the plugin.
///
/// ```dart
/// AppFilePickerField(
///   label: 'Documents',
///   files: _files,
///   maxFiles: 3,
///   required: true,
///   onPick: () async {
///     final picked = await getIt<MediaService>().pickFiles();
///     return [for (final f in picked) AppPickedFile(name: f.name, path: f.path)];
///   },
///   onChanged: (files) => setState(() => _files = files),
/// )
/// ```
class AppFilePickerField extends StatelessWidget {
  const AppFilePickerField({
    super.key,
    required this.label,
    required this.files,
    this.onPick,
    this.onChanged,
    this.hint = 'Add a file',
    this.maxFiles,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.validator,
    this.autovalidateMode,
    this.labelMode,
    this.variant,
    this.type,
    this.shape,
    this.size,
  });

  final String label;

  /// The attachments held right now. The caller owns them, as with every other
  /// field in the family.
  final List<AppPickedFile> files;

  /// Opens whatever picker the app uses and resolves to what was chosen.
  /// Returning null or an empty list leaves the field alone, so a cancelled
  /// picker costs nothing. Only a [readOnly] field may leave it out — it draws
  /// no add area to open one from.
  final Future<List<AppPickedFile>?> Function()? onPick;

  /// Called with the complete new list, added or removed. Only a [readOnly]
  /// field may leave it out — nothing can be added to or removed from one.
  final ValueChanged<List<AppPickedFile>>? onChanged;

  /// Copy on the add area.
  final String hint;

  /// Ceiling on how many may be held. At the limit the add area disappears
  /// rather than offering a pick the field would have to throw away.
  final int? maxFiles;

  final bool enabled;

  /// Shows the attachments without letting them be changed.
  ///
  /// Unlike the rest of the kit this is not a [ReadOnlyGate]: an add area that
  /// still looks tappable and does nothing is worse than no add area, so a
  /// read-only field drops it along with the remove buttons. The files
  /// themselves keep every colour they had — the point is to read them.
  final bool readOnly;

  /// Marks the label, and — unless [validator] replaces the rule — rejects an
  /// empty field when the form validates.
  final bool required;

  /// Replaces the built-in rule entirely. Receives the current files.
  final String? Function(List<AppPickedFile> files)? validator;

  final AutovalidateMode? autovalidateMode;

  /// Null follows [AppInputConfig.defaults].
  final AppInputLabelMode? labelMode;
  final AppInputVariant? variant;
  final AppInputType? type;
  final AppInputShape? shape;
  final AppInputSize? size;

  /// The rule applied when no [validator] is given: a required field holds at
  /// least one file, and no more than [max] are held.
  static String? validate(
    List<AppPickedFile> files, {
    bool required = false,
    int? max,
  }) {
    if (required && files.isEmpty) {
      return AppInputStyle.config.requiredMessage;
    }
    if (max != null && files.length > max) {
      return 'Attach no more than $max file${max == 1 ? '' : 's'}';
    }
    return null;
  }

  bool get _atLimit => maxFiles != null && files.length >= maxFiles!;

  String? _validate() {
    final rule = validator;
    return rule != null
        ? rule(files)
        : validate(files, required: required, max: maxFiles);
  }

  Future<void> _add(FormFieldState<List<AppPickedFile>> state) async {
    final pick = onPick;
    // Unreachable while there is no add area to tap, which is the only state
    // that leaves this null — but read as a local it stays non-null below.
    if (pick == null) return;
    HapticFeedback.selectionClick();
    final picked = await pick();
    if (picked == null || picked.isEmpty) return;

    // Trims at the ceiling rather than refusing the whole pick: someone who
    // selected five images for three slots meant to attach three.
    final next = [...files, ...picked];
    final limited = maxFiles == null ? next : next.take(maxFiles!).toList();
    state.didChange(limited);
    onChanged?.call(limited);
  }

  void _remove(int index, FormFieldState<List<AppPickedFile>> state) {
    HapticFeedback.selectionClick();
    final next = [...files]..removeAt(index);
    state.didChange(next);
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      (onPick != null && onChanged != null) || readOnly,
      'AppFilePickerField: a field that can be added to needs onPick and '
      'onChanged. Pass readOnly: true for one that only lists what is there.',
    );

    return InputFieldLayout(
      label: label,
      required: required,
      labelMode: labelMode,
      variant: variant,
      size: size,
      field: FormField<List<AppPickedFile>>(
        initialValue: files,
        enabled: enabled,
        autovalidateMode:
            autovalidateMode ?? AppInputStyle.config.autovalidateMode,
        validator: (_) => _validate(),
        builder: (state) {
          final error = state.errorText;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < files.length; i++)
                _FileRow(
                  file: files[i],
                  variant: variant,
                  onRemove: enabled && !readOnly
                      ? () => _remove(i, state)
                      : null,
                ),
              if (enabled && !readOnly && !_atLimit)
                _addArea(context, state, error != null),
              // Flush with the rows it explains, the way the fields built on
              // [InputDecoration] draw theirs.
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppConstants.space4),
                  child: Text(error, style: AppInputStyle.errorStyle(context)),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The tappable area that opens the picker. Dashed-looking rather than a
  /// filled field: it is an action, and it should not read as a value.
  Widget _addArea(
    BuildContext context,
    FormFieldState<List<AppPickedFile>> state,
    bool hasError,
  ) {
    final config = AppInputStyle.config;
    final accent = AppInputStyle.accentOrNull(context, variant);
    final theme = context.theme;
    // With no variant the area wears the theme's own outline over the same
    // fill a filled AppInput takes, so it sits in a form as one of the fields.
    final edge = accent ?? theme.colorScheme.outline;
    final borderColor = hasError
        ? theme.colorScheme.error
        : edge.withValues(alpha: config.idleBorderOpacity);
    final baseFill =
        theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;

    return Semantics(
      button: true,
      label: hint,
      child: InkWell(
        onTap: () => _add(state),
        borderRadius: AppConstants.borderRadius12,
        child: Container(
          width: double.infinity,
          padding: AppConstants.padding16,
          decoration: BoxDecoration(
            borderRadius: AppConstants.borderRadius12,
            border: Border.all(
              color: borderColor,
              width: config.idleBorderWidth,
            ),
            color: accent == null
                ? baseFill
                : Color.alphaBlend(
                    accent.withValues(alpha: config.fillOpacity),
                    baseFill,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppConstants.space8,
            children: [
              Icon(
                Icons.attach_file,
                size: AppInputStyle.configOf(size).iconSize,
                // Null leaves the glyph to the theme's icon color.
                color: accent,
              ),
              Text(
                hint,
                style: AppInputStyle.valueStyle(
                  context,
                  size: size,
                  variant: variant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One attachment: thumbnail or type icon, name, size, and a remove button.
class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove, this.variant});

  final AppPickedFile file;
  final VoidCallback? onRemove;
  final AppInputVariant? variant;

  @override
  Widget build(BuildContext context) {
    final accent = AppInputStyle.accentOf(context, variant);
    final size = file.readableSize;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.space8),
      child: Row(
        spacing: AppConstants.space12,
        children: [
          ClipRRect(
            borderRadius: AppConstants.borderRadius8,
            child: SizedBox.square(
              dimension: AppConstants.touchTarget,
              child: _thumbnail(context, accent),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium,
                ),
                if (size != null)
                  Text(
                    size,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove',
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget _thumbnail(BuildContext context, Color accent) {
    final path = file.path;
    if (file.isImage && path != null) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        // A file that has been moved or deleted since it was picked is not a
        // reason to break the row.
        errorBuilder: (context, error, stackTrace) => _icon(context, accent),
      );
    }
    return _icon(context, accent);
  }

  Widget _icon(BuildContext context, Color accent) => ColoredBox(
    color: accent.withValues(alpha: AppInputStyle.config.fillOpacity * 2),
    child: Icon(file.icon, color: accent, size: AppConstants.iconMedium),
  );
}
