import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/presentation/visit_create/blocs/visit_create_bloc.dart';
import 'package:je_fisc/features/work/presentation/visit_create/blocs/visit_create_event.dart';
import 'package:je_fisc/features/work/presentation/visit_create/blocs/visit_create_state.dart';
import 'package:je_fisc/features/work/presentation/visit_create/widgets/picture_source_sheet.dart';
import 'package:je_fisc/shared/widgets/buttons/app_button.dart';
import 'package:je_fisc/shared/widgets/inputs/app_date_input.dart';
import 'package:je_fisc/features/category/domain/models/category_model.dart';
import 'package:je_fisc/shared/widgets/inputs/app_file_picker_field.dart';
import 'package:je_fisc/shared/widgets/inputs/app_multi_select_input.dart';
import 'package:je_fisc/shared/widgets/inputs/app_time_input.dart';
import 'package:je_fisc/shared/widgets/layouts/app_single_scroll_view.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/app_status_view.dart';
import '../../../../../shared/widgets/overlays/app_toast.dart';

/// The bloc is provided by `VisitCreatePage`, so this only reads it — which
/// is what lets a widget test pump it with a bloc of its own.
class VisitCreateView extends StatefulWidget {
  const VisitCreateView({
    super.key,
    required this.workId,
    required this.pickPictures,
  });

  final int workId;

  /// Opens the picker for [ImageSource] and resolves to the chosen files'
  /// paths — empty when cancelled or denied.
  final Future<List<String>> Function(ImageSource source) pickPictures;

  @override
  State<VisitCreateView> createState() => _VisitCreateViewState();
}

class _VisitCreateViewState extends State<VisitCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtr = TextEditingController(text: DateTime.now().formattedDate);

  /// When on the day the visit was. Starts at now, like the date.
  var _time = TimeOfDay.now();

  /// Ids of the ticked categories, as [AppMultiSelectInput] keys them.
  var _categoryIds = <String>[];
  var _pictures = <AppPickedFile>[];

  @override
  void dispose() {
    _dateCtr.dispose();
    super.dispose();
  }

  Future<List<AppPickedFile>?> _pick() async {
    final source = await PictureSourceSheet.show();
    if (source == null) return null;
    final paths = await widget.pickPictures(source);
    return [
      for (final path in paths)
        AppPickedFile(name: p.basename(path), path: path),
    ];
  }

  void _create(List<CategoryModel> categories) {
    if (!_formKey.isValid) return;
    context.read<VisitCreateBloc>().add(
      VisitCreateRequested(
        visit: VisitModel(
          id: 0,
          workId: widget.workId,
          date: _time.onDate(_dateCtr.text.toDateTime()!),
          categories: [
            for (final category in categories)
              if (_categoryIds.contains('${category.id}')) category,
          ],
        ),
        picturePaths: [
          for (final picture in _pictures)
            if (picture.path != null) picture.path!,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nova Visita")),
      body: SafeArea(
        child: BlocConsumer<VisitCreateBloc, VisitCreateState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage ||
              previous.successMessage != current.successMessage ||
              previous.createdVisitId != current.createdVisitId,
          listener: (context, state) {
            final error = state.errorMessage;
            if (error != null) AppToast.error(context, error);

            final success = state.successMessage;
            if (success != null) AppToast.success(context, success);

            // `true` tells the detail screen to reload its visits.
            if (state.createdVisitId != null) context.pop(true);
          },
          builder: (context, state) => AppStatusView(
            status: state.status,
            message: state.errorMessage,
            onRetry: () =>
                context.read<VisitCreateBloc>().add(const VisitCreateStarted()),
            builder: (context) {
              return AppSingleScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    spacing: AppConstants.space16,
                    children: [
                      Row(
                        spacing: AppConstants.space12,
                        children: [
                          Expanded(
                            child: AppDateInput(
                              label: "Data da Visita",
                              required: true,
                              controller: _dateCtr,
                            ),
                          ),
                          Expanded(
                            child: AppTimeInput(
                              label: "Hora",
                              required: true,
                              initialValue: _time,
                              onChanged: (time) => _time = time,
                            ),
                          ),
                        ],
                      ),
                      AppMultiSelectInput<CategoryModel>(
                        label: "Categorias",
                        hint: "Escolher categorias",
                        searchHint: "Pesquisar",
                        emptyLabel: "Nenhuma categoria encontrada",
                        items: state.categories,
                        idOf: (category) => '${category.id}',
                        labelOf: (category) => category.name,
                        selectedIds: _categoryIds,
                        onChanged: (ids) => setState(() => _categoryIds = ids),
                      ),
                      AppFilePickerField(
                        label: "Fotografias",
                        hint: "Adicionar fotografia",
                        files: _pictures,
                        onPick: _pick,
                        onChanged: (files) => setState(() => _pictures = files),
                      ),
                      AppButton(
                        variant: AppButtonVariant.primary,
                        label: "Criar Visita",
                        isLoading: state.isSubmitting,
                        onPressed: () => _create(state.categories),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
