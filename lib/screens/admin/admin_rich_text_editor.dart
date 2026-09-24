import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../../core/theme.dart';

/// Editor rich-text (WYSIWYG) yang seragam untuk panel admin.
///
/// Nilai HTML bisa dibaca lewat state-nya melalui [GlobalKey]:
/// ```dart
/// final key = GlobalKey<AdminRichTextEditorState>();
/// ...
/// key.currentState?.html
/// ```
class AdminRichTextEditor extends StatefulWidget {
  final String initialHtml;
  final String placeholder;
  final double minHeight;

  const AdminRichTextEditor({
    super.key,
    this.initialHtml = '',
    this.placeholder = 'Tulis…',
    this.minHeight = 200,
  });

  @override
  State<AdminRichTextEditor> createState() => AdminRichTextEditorState();
}

class AdminRichTextEditorState extends State<AdminRichTextEditor> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController(
      document: _documentFrom(widget.initialHtml),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  quill.Document _documentFrom(String html) {
    if (html.trim().isEmpty) return quill.Document();
    try {
      return quill.Document.fromDelta(HtmlToDelta().convert(html));
    } catch (_) {
      return quill.Document();
    }
  }

  /// Isi editor sebagai HTML.
  String get html {
    final ops = _controller.document.toDelta().toJson();
    if (ops.isEmpty) return '';
    return QuillDeltaToHtmlConverter(ops.cast<Map<String, dynamic>>()).convert();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(border: Border.all(color: AppTheme.line)),
        child: quill.QuillSimpleToolbar(
          controller: _controller,
          config: quill.QuillSimpleToolbarConfig(
            multiRowsDisplay: false,
            toolbarSize: 22,
            showDividers: true,
            sectionDividerSpace: 2,
            sectionDividerColor: AppTheme.line,
            buttonOptions: quill.QuillSimpleToolbarButtonOptions(
              base: quill.QuillToolbarBaseButtonOptions(
                iconSize: 15,
                iconButtonFactor: 1.5,
              ),
            ),
            iconTheme: quill.QuillIconTheme(
              iconButtonSelectedData: quill.IconButtonData(
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppTheme.brand,
                  shape: const RoundedRectangleBorder(),
                  padding: EdgeInsets.zero,
                ),
              ),
              iconButtonUnselectedData: quill.IconButtonData(
                color: AppTheme.ink600,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  shape: const RoundedRectangleBorder(),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            showFontFamily: false,
            showFontSize: false,
            showSearchButton: false,
            showSubscript: false,
            showSuperscript: false,
            showCodeBlock: false,
            showInlineCode: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            showAlignmentButtons: false,
            showHeaderStyle: false,
            showListCheck: false,
            showIndent: false,
            showClearFormat: true,
            showUndo: true,
            showRedo: true,
          ),
        ),
      ),
      Container(
        constraints: BoxConstraints(minHeight: widget.minHeight),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppTheme.line),
            right: BorderSide(color: AppTheme.line),
            bottom: BorderSide(color: AppTheme.line),
          ),
        ),
        child: quill.QuillEditor.basic(
          controller: _controller,
          config: quill.QuillEditorConfig(
            placeholder: widget.placeholder,
            padding: const EdgeInsets.all(12),
            expands: false,
          ),
        ),
      ),
    ]);
  }
}
